import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:maikago/config.dart';
import 'package:image/image.dart' as img;
import 'package:maikago/services/chatgpt_service.dart';

class OcrItemResult {
  final String name;
  final int price;
  OcrItemResult({required this.name, required this.price});
}

class VisionOcrService {
  final String apiKey;
  VisionOcrService({String? apiKey}) : apiKey = apiKey ?? googleVisionApiKey;

  Future<OcrItemResult?> detectItemFromImage(File image) async {
    if (apiKey.isEmpty) {
      debugPrint(
        '⚠️ Vision APIキーが未設定です。--dart-define=GOOGLE_VISION_API_KEY=... を指定してください',
      );
      return null;
    }

    try {
      // 画像をリサイズしてファイルサイズを削減
      final resizedBytes = await _resizeImage(image);
      final b64 = base64Encode(resizedBytes);

      final url = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
      );
      final body = jsonEncode({
        'requests': [
          {
            'image': {'content': b64},
            'features': [
              {'type': 'TEXT_DETECTION'},
            ],
            'imageContext': {
              'languageHints': ['ja'],
            },
          },
        ],
      });

      debugPrint(
          '📸 Vision APIへリクエスト送信中... (画像サイズ: ${resizedBytes.length} bytes)');

      // タイムアウト時間を延長（30秒）
      final resp = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) {
        debugPrint('❌ Vision APIエラー: HTTP ${resp.statusCode} ${resp.body}');
        return null;
      }

      final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
      final responses = (jsonMap['responses'] as List?) ?? const [];
      if (responses.isEmpty) {
        debugPrint('⚠️ Vision APIレスポンスが空でした');
        return null;
      }

      final fullText = (responses.first['fullTextAnnotation']?['text']
              as String?) ??
          (responses.first['textAnnotations']?[0]?['description'] as String?);

      if (fullText == null || fullText.trim().isEmpty) {
        debugPrint('⚠️ テキスト抽出に失敗しました');
        return null;
      }

      debugPrint('🔎 抽出テキスト:\n$fullText');

      // 1) ChatGPTで整形（税込優先・ノイズ除去のみ）
      ChatGptItemResult? llm;
      try {
        final chat = ChatGptService();
        llm = await chat.extractNameAndPrice(fullText);
      } catch (e) {
        debugPrint('⚠️ ChatGPT整形呼び出し失敗: $e');
      }

      if (llm != null) {
        debugPrint('✅ ChatGPT整形を採用: name=${llm.name}, price=${llm.price}');
        return OcrItemResult(name: llm.name, price: llm.price);
      }

      // 2) フォールバック：ローカル規則ベース抽出
      final parsed = _parseNameAndPrice(fullText);
      if (parsed == null) {
        debugPrint('⚠️ 名前と価格の抽出に失敗しました');
      } else {
        debugPrint('✅ 抽出結果: name=${parsed.name}, price=${parsed.price}');
      }
      return parsed;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        debugPrint('⏰ Vision APIタイムアウト: ネットワーク接続またはAPI応答が遅延しています');
        debugPrint('💡 対策: インターネット接続を確認し、しばらく待ってから再試行してください');
      } else {
        debugPrint('❌ Vision APIエラー: $e');
      }
      return null;
    }
  }

  /// 画像をリサイズしてファイルサイズを削減
  Future<Uint8List> _resizeImage(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        debugPrint('⚠️ 画像のデコードに失敗しました');
        return bytes;
      }

      // 画像サイズが大きい場合のみリサイズ
      if (originalImage.width > 1024 || originalImage.height > 1024) {
        final resizedImage = img.copyResize(
          originalImage,
          width: 1024,
          height: 1024,
          interpolation: img.Interpolation.linear,
        );

        final resizedBytes = img.encodeJpg(resizedImage, quality: 85);
        debugPrint(
            '📏 画像をリサイズ: ${originalImage.width}x${originalImage.height} → ${resizedImage.width}x${resizedImage.height}');
        return resizedBytes;
      }

      return bytes;
    } catch (e) {
      debugPrint('⚠️ 画像リサイズエラー: $e');
      return await image.readAsBytes();
    }
  }

  OcrItemResult? _parseNameAndPrice(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    final price = _extractPrice(lines);
    if (price == null) return null;

    final name = _extractName(lines);
    if (name == null) return null;

    return OcrItemResult(name: name, price: price);
  }

  /// 価格抽出（税込価格を最優先）
  int? _extractPrice(List<String> lines) {
    debugPrint('🔍 価格抽出開始: ${lines.length}行');

    // 価格パターンマッチング
    final pricePattern = RegExp(r'(?:¥|￥)?\s*([0-9][0-9,.]{1,8})\s*(?:円)?');

    int? parseNum(String s) {
      final m = pricePattern.firstMatch(s);
      if (m == null) return null;

      // OCR誤認識対応：カンマを小数点に変換してから処理
      final correctedNumStr = (m.group(1) ?? '').replaceAll(',', '.');

      // 小数点を含む場合は切り捨てて整数に変換
      if (correctedNumStr.contains('.')) {
        final doubleValue = double.tryParse(correctedNumStr);
        if (doubleValue == null) return null;
        final truncatedValue = doubleValue.floor();
        if (truncatedValue <= 0 || truncatedValue > 10000000) return null;
        debugPrint('💰 小数点価格を切り捨て: $correctedNumStr → $truncatedValue');
        return truncatedValue;
      }

      final v = int.tryParse(correctedNumStr);
      if (v == null) return null;
      if (v <= 0 || v > 10000000) return null;
      return v;
    }

    // OCR誤認識修正：末尾文字付き価格の修正
    int? fixOcrPrice(String line) {
      // 末尾に「k」や「)」が付いた価格の修正（例：21492円)k → 21492円）
      final priceWithSuffixMatch = RegExp(r'(\d+)\s*円\s*[k)]').firstMatch(line);
      if (priceWithSuffixMatch != null) {
        final priceStr = priceWithSuffixMatch.group(1);
        if (priceStr != null) {
          final price = int.tryParse(priceStr);
          if (price != null && price > 0 && price <= 10000000) {
            debugPrint('🔧 OCR誤認識修正（末尾文字除去）: $price円)k → $price円');
            return price;
          }
        }
      }

      // 明らかに異常な価格の場合のみ修正（例：2149200円 → 21492円）
      final abnormalPriceMatch = RegExp(r'(\d{7,})\s*円').firstMatch(line);
      if (abnormalPriceMatch != null) {
        final priceStr = abnormalPriceMatch.group(1);
        if (priceStr != null) {
          final price = int.tryParse(priceStr);
          if (price != null && price >= 1000000) {
            // 7桁以上の価格は誤認識の可能性が高い
            final correctedPrice = price / 100;
            final truncatedPrice = correctedPrice.floor();
            if (truncatedPrice > 0 && truncatedPrice <= 10000000) {
              debugPrint(
                  '🔧 OCR異常価格修正: $price円 → $correctedPrice円 → $truncatedPrice円');
              return truncatedPrice;
            }
          }
        }
      }

      // 末尾に「k」や「)」が付いた価格の修正（例：21492円)k → 21492円）
      final priceWithSuffixMatch2 =
          RegExp(r'(\d{5,})\s*円\s*[k)]').firstMatch(line);
      if (priceWithSuffixMatch2 != null) {
        final priceStr = priceWithSuffixMatch2.group(1);
        if (priceStr != null) {
          final price = int.tryParse(priceStr);
          if (price != null && price >= 10000) {
            // 高額商品対応：複数パターンの修正を試行
            final patterns = [
              price / 100, // 21492 → 214.92
              price / 10, // 123456 → 12345.6
              price.toDouble(), // そのまま使用
            ];

            for (final correctedPrice in patterns) {
              final truncatedPrice = correctedPrice.floor();
              if (truncatedPrice > 0 && truncatedPrice <= 10000000) {
                debugPrint(
                    '🔧 OCR誤認識修正（末尾文字付き）: $price円)k → $correctedPrice円 → $truncatedPrice円');
                return truncatedPrice;
              }
            }
          }
        }
      }

      return null;
    }

    // 小数点価格候補を収集（税込価格の可能性が高い）
    final decimalCandidates = <int>[];

    // 1. 税込価格を最優先検索（改善版：小数点価格も含む）
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 税込価格キーワードを含む行を検索
      if (line.contains('税込') || line.contains('定価')) {
        debugPrint('🔍 税込価格キーワードを発見: "$line"');

        // 同じ行に価格がある場合
        final sameLinePrice = parseNum(line);
        if (sameLinePrice != null) {
          debugPrint('💰 税込価格を同一行で検出: $sameLinePrice円');
          return sameLinePrice;
        }

        // 次の行に価格がある場合（税込価格の下に価格が表示されるパターン）
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1];

          // OCR誤認識修正を試行
          final fixedPrice = fixOcrPrice(nextLine);
          if (fixedPrice != null) {
            debugPrint('💰 税込価格をOCR修正で検出: "$nextLine" → $fixedPrice円');
            return fixedPrice;
          }

          final nextLinePrice = parseNum(nextLine);
          if (nextLinePrice != null) {
            debugPrint('💰 税込価格を次の行で検出: "$nextLine" → $nextLinePrice円');
            return nextLinePrice;
          }

          // 小数点価格が別々の行に分かれている場合の処理（例：278円 + 64円)）
          if (i + 2 < lines.length) {
            final nextNextLine = lines[i + 2];
            final combinedPrice = _combineDecimalPrice(nextLine, nextNextLine);
            if (combinedPrice != null) {
              debugPrint(
                  '💰 税込価格を結合行で検出: "$nextLine" + "$nextNextLine" → $combinedPrice円');
              return combinedPrice;
            }
          }
        }

        // 前の行に価格がある場合（価格の上に税込価格が表示されるパターン）
        if (i > 0) {
          final prevLine = lines[i - 1];

          // OCR誤認識修正を試行
          final fixedPrice = fixOcrPrice(prevLine);
          if (fixedPrice != null) {
            debugPrint('💰 税込価格を前の行のOCR修正で検出: "$prevLine" → $fixedPrice円');
            return fixedPrice;
          }

          final prevLinePrice = parseNum(prevLine);
          if (prevLinePrice != null) {
            debugPrint('💰 税込価格を前の行で検出: "$prevLine" → $prevLinePrice円');
            return prevLinePrice;
          }
        }

        // 小数点を含む価格パターンを特別に処理（次の行）
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          final correctedLine = nextLine.replaceAll(',', '.');
          final decimalMatch =
              RegExp(r'(\d+\.\d+)\s*円').firstMatch(correctedLine);
          if (decimalMatch != null) {
            final priceStr = decimalMatch.group(1);
            if (priceStr != null) {
              final doubleValue = double.tryParse(priceStr);
              if (doubleValue != null) {
                final truncatedValue = doubleValue.floor();
                if (truncatedValue > 0 && truncatedValue <= 200000) {
                  debugPrint(
                      '💰 税込価格を次の行の小数点で検出: "$nextLine" → $truncatedValue円');
                  return truncatedValue;
                }
              }
            }
          }
        }
      }

      // 小数点価格候補を収集（税込価格の可能性が高い）
      final decimalMatch = RegExp(r'(\d+\.\d+)\s*円').firstMatch(line);
      if (decimalMatch != null) {
        final priceStr = decimalMatch.group(1);
        if (priceStr != null) {
          final doubleValue = double.tryParse(priceStr);
          if (doubleValue != null) {
            final truncatedValue = doubleValue.floor();
            if (truncatedValue > 0 && truncatedValue <= 200000) {
              decimalCandidates.add(truncatedValue);
              debugPrint('💰 小数点価格候補を収集: "$line" → $truncatedValue円');
            }
          }
        }
      }
    }

    // 小数点価格候補がある場合は最大値を返す（税込価格の可能性が高い）
    if (decimalCandidates.isNotEmpty) {
      final maxDecimalPrice = decimalCandidates.reduce((a, b) => a > b ? a : b);
      debugPrint('💰 小数点価格候補から最大値を選択: $maxDecimalPrice円');
      return maxDecimalPrice;
    }

    // 2. 本体価格を検索
    final basePriceLines = lines
        .where((l) => l.contains('本体価格'))
        .map(parseNum)
        .whereType<int>()
        .toList();
    if (basePriceLines.isNotEmpty) {
      debugPrint('💰 本体価格を検出: ${basePriceLines.first}円');
      return basePriceLines.first;
    }

    // 3. 「田 298 円」のような誤認識パターンを検出
    final misreadPriceLines = lines
        .where((l) => l.contains('田') && l.contains('円'))
        .map((l) {
          final match = RegExp(r'田\s*(\d+)\s*円').firstMatch(l);
          if (match != null) {
            final priceStr = match.group(1);
            if (priceStr != null) {
              final price = int.tryParse(priceStr);
              if (price != null && price > 0 && price <= 200000) {
                debugPrint('🔧 誤認識修正: "$l" → $price円');
                return price;
              }
            }
          }
          return null;
        })
        .whereType<int>()
        .toList();
    if (misreadPriceLines.isNotEmpty) {
      debugPrint('💰 誤認識修正価格を検出: ${misreadPriceLines.first}円');
      return misreadPriceLines.first;
    }

    // 4. 一般的な価格パターンを検索
    final allPrices = lines.map(parseNum).whereType<int>().toList();

    if (allPrices.isNotEmpty) {
      // 価格の範囲でフィルタリング（100円〜2000円の範囲を優先）
      final reasonablePrices =
          allPrices.where((p) => p >= 100 && p <= 2000).toList();
      if (reasonablePrices.isNotEmpty) {
        final selectedPrice = reasonablePrices.first;
        debugPrint('💰 一般的な価格パターンを検出: $selectedPrice円');
        return selectedPrice;
      }

      // 範囲外の価格も含めて選択
      final selectedPrice = allPrices.first;
      debugPrint('💰 価格を検出: $selectedPrice円');
      return selectedPrice;
    }

    debugPrint('❌ 価格を検出できませんでした');
    return null;
  }

  /// 別々の行に分かれた小数点価格を結合する（例：278円 + 64円) → 278.64円）
  int? _combineDecimalPrice(String line1, String line2) {
    // 最初の行から整数部分を抽出（例：278円）
    final intMatch = RegExp(r'(\d+)\s*円').firstMatch(line1);
    if (intMatch == null) return null;

    final intPart = int.tryParse(intMatch.group(1) ?? '');
    if (intPart == null) return null;

    // 2番目の行から小数部分を抽出（例：64円)）
    final decimalMatch = RegExp(r'(\d+)\s*円\)').firstMatch(line2);
    if (decimalMatch == null) return null;

    final decimalPart = int.tryParse(decimalMatch.group(1) ?? '');
    if (decimalPart == null) return null;

    // 小数部分が2桁以内の場合のみ結合
    if (decimalPart >= 0 && decimalPart <= 99) {
      final combinedValue = intPart + (decimalPart / 100);
      final truncatedValue = combinedValue.floor();

      if (truncatedValue > 0 && truncatedValue <= 200000) {
        debugPrint(
            '🔗 小数点価格を結合: $intPart + $decimalPart/100 = $combinedValue → $truncatedValue円');
        return truncatedValue;
      }
    }

    return null;
  }

  String? _extractName(List<String> lines) {
    // 除外すべきキーワードを拡張
    final ignoreKeywords = <String>[
      '税込',
      '税抜',
      '本体価格',
      '価格',
      '円',
      '特価',
      '割引',
      '値引',
      'OFF',
      '％',
      '%',
      'ポイント',
      '会員',
      'カード',
      'QR',
      'バーコード',
      'JAN',
      '税',
      '小計',
      '合計',
      '産地は商品に記載', // 新たまねぎの画像で誤認識される文言
      '産地',
      '商品に記載',
      '商品に表示', // 商品名抽出で除外するキーワード
      '生活応援', // プロモーション文言
      '約',
      'kg',
      '個',
      '本',
      '袋',
      'パック',
      'CREATIVE', // 誤認識される英語
      '田', // 価格の前の誤認識文字
      '満足品質', // プロモーション文言
      '驚きの価格', // プロモーション文言
      'おさえて', // 説明文
      'コクある', // 説明文
      '味わいに', // 説明文
      'しました', // 説明文
      '定価', // 価格関連
      '100gあたり', // 単位価格
      '体', // 本体価格の略
    ];

    // 除外すべきパターン
    final ignorePatterns = <RegExp>[
      RegExp(r'^\d+$'), // 数字のみ
      RegExp(r'^\d{13,}'), // 長い数字（バーコード等）
      RegExp(r'^[A-Z]+$'), // 英語の大文字のみ（CREATIVE等）
      RegExp(r'^[A-Z\s]+$'), // 英語の大文字とスペースのみ
      RegExp(r'^田\s*\d+\s*円$'), // 田 + 価格の誤認識パターン
      RegExp(r'^[€¥￥]+$'), // 通貨記号のみ
      RegExp(r'^\d+%$'), // パーセンテージのみ
      RegExp(r'^\d+g$'), // 重量のみ
      RegExp(r'^\d+\.\d+円$'), // 価格のみ
    ];

    final candidates = lines.where((l) {
      // 数字や通貨記号を含む行は除外
      final hasDigitOrCurrency = RegExp(r'[0-9¥￥円€]').hasMatch(l);
      if (hasDigitOrCurrency) {
        debugPrint('🔍 除外: 数字/通貨記号を含む "$l"');
        return false;
      }

      // 除外キーワードを含む行は除外（ただし、商品名の一部として含まれる場合は除外しない）
      bool shouldExclude = false;
      for (final keyword in ignoreKeywords) {
        if (l.contains(keyword)) {
          // 商品名の一部として含まれる場合は除外しない
          if (l.length > keyword.length + 3) {
            debugPrint('🔍 除外: 除外キーワードを含む "$l"');
            shouldExclude = true;
            break;
          }
        }
      }
      if (shouldExclude) return false;

      // 除外パターンにマッチする行は除外
      if (ignorePatterns.any((p) => p.hasMatch(l))) {
        debugPrint('🔍 除外: 除外パターンにマッチ "$l"');
        return false;
      }

      // 長さが適切（2-25文字）- 商品名は長めでもOK
      if (l.length < 2 || l.length > 25) {
        debugPrint('🔍 除外: 長さ不適切 "$l" (${l.length}文字)');
        return false;
      }

      // ひらがな・カタカナ・漢字を含む（日本語を含む）
      final hasJapanese = RegExp(
        r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]',
      ).hasMatch(l);
      if (!hasJapanese) {
        debugPrint('🔍 除外: 日本語を含まない "$l"');
        return false;
      }

      // 英語のみの行は除外（CREATIVE等）
      final isEnglishOnly = RegExp(r'^[A-Za-z\s]+$').hasMatch(l);
      if (isEnglishOnly) {
        debugPrint('🔍 除外: 英語のみ "$l"');
        return false;
      }

      debugPrint('✅ 候補として選択: "$l"');
      return true;
    }).toList();

    if (candidates.isEmpty) {
      debugPrint('⚠️ 候補が見つかりません。フォールバック処理を実行');

      // フォールバック: 日本語を含む行から商品名を抽出
      final japaneseLines = lines.where((l) {
        final hasJapanese = RegExp(
          r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]',
        ).hasMatch(l);
        final hasDigit = RegExp(r'[0-9]').hasMatch(l);
        final hasCurrency = RegExp(r'[¥￥円€]').hasMatch(l);

        // 日本語を含み、数字や通貨記号を含まない行
        return hasJapanese && !hasDigit && !hasCurrency;
      }).toList();

      if (japaneseLines.isNotEmpty) {
        // 除外キーワードを除去
        final cleaned = japaneseLines.first
            .replaceAll(
                RegExp(
                    r'産地は商品に記載|生活応援|本体価格|税込|約|kg|個|本|袋|パック|商品に表示|満足品質|驚きの価格|おさえて|コクある|味わいに|しました|定価|100gあたり|体'),
                '')
            .trim();

        if (cleaned.isNotEmpty) {
          debugPrint('🔄 フォールバックで商品名を抽出: "$cleaned"');
          return cleaned;
        }
      }

      debugPrint('❌ フォールバックでも商品名を抽出できませんでした');
      return null;
    }

    // 候補をスコアリングして最適なものを選択
    candidates.sort((a, b) {
      int scoreA = _calculateNameScore(a);
      int scoreB = _calculateNameScore(b);
      return scoreB.compareTo(scoreA); // 降順（スコアが高い順）
    });

    return candidates.first;
  }

  /// 商品名のスコアを計算
  int _calculateNameScore(String text) {
    int score = 0;

    // 長さが適切（3-15文字が最適）- 商品名は長めでもOK
    if (text.length >= 3 && text.length <= 15) {
      score += 10; // 大幅に加点
    } else if (text.length >= 2 && text.length <= 20) {
      score += 5;
    } else {
      score += 1;
    }

    // 漢字を含む（商品名らしい）
    if (RegExp(r'[\u4E00-\u9FAF]').hasMatch(text)) score += 3;

    // ひらがなを含む（読みやすい）
    if (RegExp(r'[\u3040-\u309F]').hasMatch(text)) score += 2;

    // カタカナを含む（商品名によくある）
    if (RegExp(r'[\u30A0-\u30FF]').hasMatch(text)) score += 2;

    // 特殊文字を含まない
    if (!RegExp(
      r'[^\w\s\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]',
    ).hasMatch(text)) {
      score += 1;
    }

    // 具体的な商品名らしいキーワードを含む場合は大幅に加点
    final productKeywords = [
      'アスパラ',
      'トマト',
      'キャベツ',
      'にんじん',
      'たまねぎ',
      'じゃがいも',
      'きゅうり',
      'なす',
      'ピーマン',
      '白菜',
      'バナナ',
      'りんご',
      'みかん',
      'ぶどう',
      'しいたけ',
      'しめじ',
      'まいたけ',
      'えのきたけ',
      'えりんぎ',
      'まつたけ',
      '牛',
      '豚',
      '鶏',
      '魚',
      '卵',
      '牛乳',
      '豆腐',
      'パン',
      '麺',
      '米',
      'パスタ',
      'ラーメン',
      'カレー', // 大幅に加点
      'レッドカレー', // 大幅に加点
      'レトルト',
      '缶詰',
      'マヨネーズ', // 追加
      'ケチャップ', // 追加
      'ソース', // 追加
      'ドレッシング', // 追加
      '醤油', // 追加
      '味噌', // 追加
      '塩', // 追加
      '砂糖', // 追加
      '油', // 追加
      'バター', // 追加
      'チーズ', // 追加
      'ヨーグルト', // 追加
      'アイス', // 追加
      'ジュース', // 追加
      'お茶', // 追加
      'コーヒー', // 追加
      'ビール', // 追加
      'ワイン', // 追加
      '清酒', // 追加
      '焼酎', // 追加
    ];

    for (final keyword in productKeywords) {
      if (text.contains(keyword)) {
        score += 20; // 大幅に加点
        debugPrint('🎯 商品キーワード検出: "$keyword" → スコア+20');
        break;
      }
    }

    // メーカー名は大幅減点
    final manufacturerKeywords = [
      '凸版食品',
      'トッパン',
      '日清',
      '味の素',
      'キッコーマン',
      'キューピー',
      'ハウス',
      'エスビー',
      'S&B',
      '江崎グリコ',
      'グリコ',
      '明治',
      '森永',
      'カルビー',
      '湖池屋',
      'ヤマザキ',
      '山崎',
      '敷島',
      'Pasco',
      'パスコ',
    ];

    for (final keyword in manufacturerKeywords) {
      if (text.contains(keyword)) {
        score -= 25; // 大幅に減点
        debugPrint('⚠️ メーカー名検出: "$keyword" → スコア-25');
        break;
      }
    }

    // 価格関連の単語は大幅減点
    final priceKeywords = [
      '価格',
      '円',
      '本体',
      '税込',
      '税抜',
      '定価',
      '特価',
      '割引',
    ];

    for (final keyword in priceKeywords) {
      if (text.contains(keyword)) {
        score -= 30; // 大幅に減点
        debugPrint('⚠️ 価格関連単語検出: "$keyword" → スコア-30');
        break;
      }
    }

    // 一般的な文言や説明文は大幅減点
    final genericKeywords = [
      '商品に表示',
      '産地は商品に記載',
      '商品に記載',
      'お買得品',
      'おすすめ',
      '保存方法',
      '高温を避けて',
      '油とも相性',
      'エビやベーコン',
      '炒め物',
      'ボイルして',
      'サラダやパスタ',
      '天ぷらにも',
      '産地',
      '表示',
      '記載',
      '満足品質',
      '驚きの価格',
      'おさえて',
      'コクある',
      '味わいに',
      'しました',
      'トップバリュ',
      'ベストプライス',
      'トッシュ',
      '本気の', // 修飾語は減点
    ];

    for (final keyword in genericKeywords) {
      if (text.contains(keyword)) {
        score -= 15; // 大幅に減点
        debugPrint('⚠️ 一般的な文言検出: "$keyword" → スコア-15');
        break;
      }
    }

    // 長い説明文は大幅減点
    if (text.length > 20) {
      score -= 10;
      debugPrint('⚠️ 長い説明文: "${text.length}文字" → スコア-10');
    }

    debugPrint('📊 商品名スコア: "$text" → $score点');
    return score;
  }
}
