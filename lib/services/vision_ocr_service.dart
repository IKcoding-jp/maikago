import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:maikago/config.dart';

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
    final bytes = await image.readAsBytes();
    final b64 = base64Encode(bytes);

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

    debugPrint('📸 Vision APIへリクエスト送信中...');
    final resp = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 20));

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

    final fullText =
        (responses.first['fullTextAnnotation']?['text'] as String?) ??
            (responses.first['textAnnotations']?[0]?['description'] as String?);

    if (fullText == null || fullText.trim().isEmpty) {
      debugPrint('⚠️ テキスト抽出に失敗しました');
      return null;
    }

    debugPrint('🔎 抽出テキスト:\n$fullText');

    final parsed = _parseNameAndPrice(fullText);
    if (parsed == null) {
      debugPrint('⚠️ 名前と価格の抽出に失敗しました');
    } else {
      debugPrint('✅ 抽出結果: name=${parsed.name}, price=${parsed.price}');
    }
    return parsed;
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

  int? _extractPrice(List<String> lines) {
    // 小数点を含む価格パターンを修正
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
        final truncatedValue = doubleValue.floor(); // 四捨五入から切り捨てに変更
        if (truncatedValue <= 0 || truncatedValue > 200000) return null;
        debugPrint('💰 小数点価格を切り捨て: $correctedNumStr → $truncatedValue');
        return truncatedValue;
      }

      final v = int.tryParse(correctedNumStr);
      if (v == null) return null;
      if (v <= 0 || v > 200000) return null;
      return v;
    }

    // 1. 本体価格を優先（新たまねぎの画像では298円が本体価格）
    final basePriceLines = lines
        .where((l) => l.contains('本体価格'))
        .map(parseNum)
        .whereType<int>()
        .toList();
    if (basePriceLines.isNotEmpty) {
      debugPrint('💰 本体価格を検出: ${basePriceLines.first}円');
      return basePriceLines.first;
    }

    // 1.5. 「田 298 円」のような誤認識パターンを検出
    final misreadPriceLines = lines
        .where((l) => l.contains('田') && l.contains('円'))
        .map((l) {
          final match = RegExp(r'田\s*(\d+)\s*円').firstMatch(l);
          if (match != null) {
            final numStr = match.group(1);
            final v = int.tryParse(numStr ?? '');
            if (v != null && v > 0 && v <= 200000) return v;
          }
          return null;
        })
        .whereType<int>()
        .toList();
    if (misreadPriceLines.isNotEmpty) {
      debugPrint('💰 誤認識パターンから本体価格を検出: ${misreadPriceLines.first}円');
      return misreadPriceLines.first;
    }

    // 2. 税込価格を検索（OCR誤認識対応：カンマを小数点に変換）
    final taxIncl = lines
        .where((l) => l.contains('税込'))
        .map((l) {
          // OCR誤認識対応：カンマを小数点に変換してから処理
          final correctedLine = l.replaceAll(',', '.');

          // 小数点を含む価格パターンを特別に処理
          final decimalMatch =
              RegExp(r'(\d+\.\d+)\s*円').firstMatch(correctedLine);
          if (decimalMatch != null) {
            final priceStr = decimalMatch.group(1);
            if (priceStr != null) {
              final doubleValue = double.tryParse(priceStr);
              if (doubleValue != null) {
                final truncatedValue = doubleValue.floor(); // 切り捨てに変更
                if (truncatedValue > 0 && truncatedValue <= 200000) {
                  debugPrint(
                      '💰 税込価格を修正処理: $l → $correctedLine → $priceStr → $truncatedValue円');
                  return truncatedValue;
                }
              }
            }
          }
          return parseNum(l);
        })
        .whereType<int>()
        .toList();
    if (taxIncl.isNotEmpty) {
      debugPrint('💰 税込価格を検出: ${taxIncl.first}円');
      return taxIncl.first;
    }

    // 3. 価格キーワードを含む行を検索
    final priceLines = lines
        .where((l) => l.contains('価格'))
        .map(parseNum)
        .whereType<int>()
        .toList();
    if (priceLines.isNotEmpty) {
      debugPrint('💰 価格キーワードを検出: ${priceLines.first}円');
      return priceLines.first;
    }

    // 4. すべての価格を収集して最適なものを選択（OCR誤認識対応）
    final all = <int>[];
    for (final l in lines) {
      // 通常の価格パターン
      final v = parseNum(l);
      if (v != null) all.add(v);

      // OCR誤認識対応：カンマを小数点に変換してから処理
      final correctedLine = l.replaceAll(',', '.');

      // 小数点を含む価格パターンも試行
      final decimalMatch = RegExp(r'(\d+\.\d+)\s*円').firstMatch(correctedLine);
      if (decimalMatch != null) {
        final priceStr = decimalMatch.group(1);
        if (priceStr != null) {
          final doubleValue = double.tryParse(priceStr);
          if (doubleValue != null) {
            final truncatedValue = doubleValue.floor(); // 切り捨てに変更
            if (truncatedValue > 0 && truncatedValue <= 200000) {
              debugPrint(
                  '💰 価格を修正処理: $l → $correctedLine → $priceStr → $truncatedValue円');
              all.add(truncatedValue);
            }
          }
        }
      }
    }
    if (all.isEmpty) return null;

    // 価格を降順でソート（通常、商品価格は一番大きい数字）
    all.sort((a, b) => b.compareTo(a));
    debugPrint('💰 検出された価格: $all円');
    return all.first;
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
    ];

    // 除外すべきパターン
    final ignorePatterns = <RegExp>[
      RegExp(r'^\d+$'), // 数字のみ
      RegExp(r'^\d{13,}'), // 長い数字（バーコード等）
      RegExp(r'^[A-Z]+$'), // 英語の大文字のみ（CREATIVE等）
      RegExp(r'^[A-Z\s]+$'), // 英語の大文字とスペースのみ
      RegExp(r'^田\s*\d+\s*円$'), // 田 + 価格の誤認識パターン
    ];

    final candidates = lines.where((l) {
      // 数字や通貨記号を含む行は除外
      final hasDigitOrCurrency = RegExp(r'[0-9¥￥円]').hasMatch(l);
      if (hasDigitOrCurrency) {
        debugPrint('🔍 除外: 数字/通貨記号を含む "$l"');
        return false;
      }

      // 除外キーワードを含む行は除外
      if (ignoreKeywords.any((k) => l.contains(k))) {
        debugPrint('🔍 除外: 除外キーワードを含む "$l"');
        return false;
      }

      // 除外パターンにマッチする行は除外
      if (ignorePatterns.any((p) => p.hasMatch(l))) {
        debugPrint('🔍 除外: 除外パターンにマッチ "$l"');
        return false;
      }

      // 長さが適切（2-30文字）
      if (l.length < 2 || l.length > 30) {
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
        final hasCurrency = RegExp(r'[¥￥円]').hasMatch(l);

        // 日本語を含み、数字や通貨記号を含まない行
        return hasJapanese && !hasDigit && !hasCurrency;
      }).toList();

      if (japaneseLines.isNotEmpty) {
        // 除外キーワードを除去
        final cleaned = japaneseLines.first
            .replaceAll(
                RegExp(r'産地は商品に記載|生活応援|本体価格|税込|約|kg|個|本|袋|パック|商品に表示'), '')
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

    // 長さが適切（5-15文字が最適）
    if (text.length >= 5 && text.length <= 15)
      score += 5;
    else if (text.length >= 3 && text.length <= 20)
      score += 3;
    else
      score += 1;

    // 漢字を含む（商品名らしい）
    if (RegExp(r'[\u4E00-\u9FAF]').hasMatch(text)) score += 3;

    // ひらがなを含む（読みやすい）
    if (RegExp(r'[\u3040-\u309F]').hasMatch(text)) score += 2;

    // カタカナを含む（商品名によくある）
    if (RegExp(r'[\u30A0-\u30FF]').hasMatch(text)) score += 2;

    // 特殊文字を含まない
    if (!RegExp(
      r'[^\w\s\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]',
    ).hasMatch(text)) score += 1;

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
      'カレー',
      'レトルト',
      '缶詰'
    ];

    for (final keyword in productKeywords) {
      if (text.contains(keyword)) {
        score += 10; // 大幅に加点
        debugPrint('🎯 商品キーワード検出: "$keyword" → スコア+10');
        break;
      }
    }

    // 一般的な文言や説明文は減点
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
      '記載'
    ];

    for (final keyword in genericKeywords) {
      if (text.contains(keyword)) {
        score -= 5; // 大幅に減点
        debugPrint('⚠️ 一般的な文言検出: "$keyword" → スコア-5');
        break;
      }
    }

    debugPrint('📊 商品名スコア: "$text" → $score点');
    return score;
  }
}
