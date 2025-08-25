import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:maikago/config.dart';
import 'package:maikago/services/security_audit_service.dart';

class ChatGptItemResult {
  final String name;
  final int price;
  final String priceType; // '税込' | '税抜' | '推定' | '不明'
  final double confidence;
  final List<dynamic> rawMatches;

  ChatGptItemResult({
    required this.name,
    required this.price,
    required this.priceType,
    required this.confidence,
    required this.rawMatches,
  });
}

class ChatGptService {
  final String apiKey;
  final SecurityAuditService _securityAudit = SecurityAuditService();

  ChatGptService({String? apiKey}) : apiKey = apiKey ?? openAIApiKey;

  /// OCRテキストから「商品名」「税込価格」を抽出
  /// - 役割: 整理・ノイズ除去のみ。推測は最小限
  /// - 出力: JSON {"name": string, "price": number}
  Future<ChatGptItemResult?> extractNameAndPrice(String ocrText) async {
    // セキュリティ監査の記録
    _securityAudit.recordOpenApiCall();

    if (apiKey.isEmpty) {
      debugPrint(
          '⚠️ OpenAI APIキーが未設定です。--dart-define=OPENAI_API_KEY=... を指定してください');
      return null;
    }

    try {
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

      // 高精度画像解析のためのシステム/ユーザープロンプト
      const systemPrompt = '''あなたはOCRテキストから買い物用データを抽出するアシスタントです。
出力は必ずJSONのみ。商品名は短く整形し、価格は日本円の整数のみで返してください。

【重要な指示】
1. OCRテキストには誤認識やノイズが含まれる可能性があります
2. 商品名と価格を正確に識別し、不要な情報は除外してください
3. 税込価格を最優先で抽出し、税抜価格の場合は明示してください
4. 信頼度が低い場合は適切にconfidenceを下げてください

【商品名抽出ルール】
- 商品の実際の名称を抽出（メーカー名+商品名の組み合わせも可）
- 価格、説明文、プロモーション文言は除外
- 長すぎる商品名は適切に短縮
- 誤認識された文字は可能な限り修正

【価格抽出ルール - 税込優先】
- 税込価格を最優先（「税込」「税込み」「税込価格」「税込(」「内税」のラベルを絶対重視）
- 参考価格として表示されている税込価格も優先（「参考税込」「参考」+「税込」）
- 小数点を含む価格は税込価格の可能性が非常に高い（例：181.44円、537.84円）
- 税抜価格の判定は厳密に行う（「税抜」「税抜き」「本体価格」「税別」「外税」の明確なラベルのみ）
- ラベルが不明確な場合は税込価格として扱う
- 取り消し線価格は除外

【税込価格の検出パターン】
1. 明確なラベル: 「税込」「税込み」「税込価格」「税込(」「内税」
2. 参考価格: 「参考税込」「参考」+「税込」「(税込 価格)」
3. 小数点価格: 181.44円、537.84円、298.00円など
4. 端数がある価格: 末尾に.44、.84、.46などの端数がある価格
5. 一般的な小売価格: 100円〜5000円の範囲で、端数がある価格

【税抜価格の判定基準】
- 明確に「税抜」「税抜き」「本体価格」「税別」「外税」と表示されている場合のみ
- ラベルが曖昧な場合は税込価格として扱う
- 推定は避け、明確な証拠がある場合のみ税抜と判定

【OCR誤認識修正】
- 末尾文字除去: 21492円)k → 21492円
- 小数点誤認識: 17064円 → 170.64円 → 170円
- 小数点誤認識（税込）: 税込14904円) → 税込149.04円 → 149円
- 分離認識: 278円 + 46円 → 278.46円 → 278円
- 異常価格修正: 2149200円 → 21492円

【小数点価格の誤認識パターン】
- OCRで小数点が誤認識されて大きな数字になる場合がある
- 例：149.04円 → 14904円、181.44円 → 18144円
- 税込価格で4桁以上の数字が検出された場合は小数点誤認識の可能性を考慮
- 整数部分が100円〜500円の範囲で、小数部分が2桁以内の場合は修正を適用

【confidence算出】
- 0.9-1.0: 明確な税込ラベルと価格、商品名が一致
- 0.7-0.8: 小数点価格など税込の証拠があるがラベル不明
- 0.5-0.6: 推測が必要だが合理的な結果
- 0.3以下: 信頼度が低い、不明な場合''';

      final userPrompt = {
        "instruction":
            "以下のOCRテキストから商品名と税込価格を抽出してJSONで返してください。税込価格を最優先で検出してください。",
        "rules": [
          "出力スキーマ: { product_name: string, price_jpy: integer, price_type: '税込'|'税抜'|'推定'|'不明', confidence: 0.0-1.0, raw_matches: [ ... ] }",
          "税込価格の絶対優先:",
          " - 「税込」「税込み」「税込価格」「税込(」「内税」のラベルがあれば必ずその価格を選択",
          " - 「参考税込」「参考」+「税込」「(税込 価格)」のパターンも税込価格として優先",
          " - 小数点を含む価格（181.44円、537.84円、298.00円など）は税込価格として扱う",
          " - 端数がある価格（末尾に.44、.84、.46など）は税込価格の可能性が高い",
          " - ラベルが不明確な場合は税込価格として扱う",
          "税抜価格の厳密判定:",
          " - 「税抜」「税抜き」「本体価格」「税別」「外税」の明確なラベルのみ",
          " - ラベルが曖昧な場合は税込価格として扱う",
          " - 推定は避け、明確な証拠がある場合のみ税抜と判定",
          "OCR誤認識修正:",
          " - 末尾文字除去: 21492円)k → 21492円",
          " - 小数点誤認識: 17064円 → 170.64円 → 170円",
          " - 小数点誤認識（税込）: 税込14904円) → 税込149.04円 → 149円",
          " - 分離認識: 278円 + 46円 → 278.46円 → 278円",
          " - 異常価格修正: 2149200円 → 21492円",
          "商品名抽出:",
          " - メーカー名+商品名の組み合わせを優先",
          " - 価格、説明文、プロモーション文言は除外",
          " - 誤認識文字の修正（例：田 → 日、CREATIVE → 誤認識として除外）",
          "confidence算出: 税込ラベルの有無(+0.4), 小数点価格(+0.2), 文字列整合性(+0.2), 妥当性スコア(+0.2) で計算し0..1に正規化",
          "不明・低信頼時は price_jpy=0, price_type='不明', confidence<=0.5 とする",
          "必ずraw_matchesに検出した全価格文字列とそのラベル近接情報を入れて返す"
        ],
        'text': ocrText,
      };

      // response_format: { type: 'json_object' } は JSON モード
      final body = jsonEncode({
        'model': openAIModel,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content':
                '次の入力をJSONで返答してください。スキーマ: {"product_name": string, "price_jpy": number, "price_type": string, "confidence": number, "raw_matches": array}. 入力:\n${jsonEncode(userPrompt)}'
          },
        ],
      });

      debugPrint('🤖 OpenAIへ解析リクエスト送信中...');

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) {
        debugPrint('❌ OpenAI APIエラー: HTTP ${resp.statusCode} ${resp.body}');
        return null;
      }

      final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = (jsonMap['choices'] as List?) ?? const [];
      if (choices.isEmpty) {
        debugPrint('⚠️ OpenAI APIレスポンスが空でした');
        return null;
      }

      final content = choices.first['message']['content'] as String?;
      if (content == null || content.isEmpty) {
        debugPrint('⚠️ OpenAI APIコンテンツが空でした');
        return null;
      }

      debugPrint('🤖 OpenAI APIレスポンス: $content');

      try {
        final result = jsonDecode(content) as Map<String, dynamic>;

        final productName = result['product_name'] as String? ?? '';
        final priceJpy = result['price_jpy'] as int? ?? 0;
        final priceType = result['price_type'] as String? ?? '不明';
        final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
        final rawMatches = result['raw_matches'] as List<dynamic>? ?? [];

        // 税込価格の後処理強化
        String finalPriceType = priceType;
        int finalPrice = priceJpy;
        double finalConfidence = confidence;

        // 税抜価格の判定を厳密に行う
        if (priceType == '税抜') {
          // 明確な税抜ラベルのみを税抜として扱う
          final taxExcludedPatterns = [
            RegExp(r'税抜'),
            RegExp(r'税抜き'),
            RegExp(r'本体価格'),
            RegExp(r'税別'),
            RegExp(r'外税'),
          ];

          bool hasClearTaxExcludedLabel = false;
          for (final pattern in taxExcludedPatterns) {
            if (pattern.hasMatch(ocrText)) {
              hasClearTaxExcludedLabel = true;
              break;
            }
          }

          // 税込価格が明確に表示されている場合は税込価格を優先
          bool hasClearTaxIncludedLabel = false;
          final taxIncludedPatterns = [
            RegExp(r'税込'),
            RegExp(r'税込み'),
            RegExp(r'参考税込'),
            RegExp(r'\(税込\s*\d+円\)'),
          ];

          for (final pattern in taxIncludedPatterns) {
            if (pattern.hasMatch(ocrText)) {
              hasClearTaxIncludedLabel = true;
              break;
            }
          }

          // 税込価格が明確に表示されている場合は税込価格を優先
          if (hasClearTaxIncludedLabel) {
            finalPriceType = '税込';
            finalConfidence = (confidence + 0.2).clamp(0.0, 1.0);
            debugPrint('🔧 税込価格が明確に表示されているため税込価格として修正');
          }
          // 明確な税抜ラベルがない場合は税込価格として扱う
          else if (!hasClearTaxExcludedLabel) {
            finalPriceType = '税込';
            finalConfidence = (confidence + 0.1).clamp(0.0, 1.0);
            debugPrint('🔧 明確な税抜ラベルがないため税込価格として修正');
          }
        }

        // 小数点価格や端数がある価格を税込価格として扱う
        if (finalPriceType == '税抜' || finalPriceType == '推定') {
          // rawMatchesから小数点価格や端数がある価格を探す
          bool hasDecimalPrice = false;
          for (final match in rawMatches) {
            if (match is Map<String, dynamic>) {
              final priceStr = match['price_str']?.toString() ?? '';
              // 小数点価格の検出
              if (priceStr.contains('.') && priceStr.contains('円')) {
                final doubleValue =
                    double.tryParse(priceStr.replaceAll('円', ''));
                if (doubleValue != null && doubleValue > 0) {
                  finalPrice = doubleValue.floor();
                  finalPriceType = '税込';
                  finalConfidence = (confidence + 0.2).clamp(0.0, 1.0);
                  hasDecimalPrice = true;
                  debugPrint('🔧 小数点価格を税込価格として修正: $priceStr → $finalPrice円');
                  break;
                }
              }
              // 端数がある価格の検出（末尾に.44、.84、.46など）
              final decimalPattern = RegExp(r'(\d+)\.(\d{1,2})円');
              final decimalMatch = decimalPattern.firstMatch(priceStr);
              if (decimalMatch != null) {
                final intPart = int.tryParse(decimalMatch.group(1) ?? '');
                final decimalPart = int.tryParse(decimalMatch.group(2) ?? '');
                if (intPart != null &&
                    decimalPart != null &&
                    decimalPart <= 99) {
                  finalPrice = intPart;
                  finalPriceType = '税込';
                  finalConfidence = (confidence + 0.2).clamp(0.0, 1.0);
                  hasDecimalPrice = true;
                  debugPrint('🔧 端数価格を税込価格として修正: $priceStr → $finalPrice円');
                  break;
                }
              }
            }
          }

          // 税込ラベルが検出されている場合は税込価格として扱う
          if (!hasDecimalPrice && ocrText.contains('税込')) {
            finalPriceType = '税込';
            finalConfidence = (confidence + 0.1).clamp(0.0, 1.0);
            debugPrint('🔧 税込ラベルを検出したため税込価格として修正');
          }

          // 参考税込価格の検出
          if (!hasDecimalPrice && !ocrText.contains('税込')) {
            // 「参考税込」パターンの検出
            if (ocrText.contains('参考税込')) {
              finalPriceType = '税込';
              finalConfidence = (confidence + 0.15).clamp(0.0, 1.0);
              debugPrint('🔧 参考税込ラベルを検出したため税込価格として修正');
            }
            // 「参考」+「税込」パターンの検出
            else if (ocrText.contains('参考') && ocrText.contains('税込')) {
              finalPriceType = '税込';
              finalConfidence = (confidence + 0.15).clamp(0.0, 1.0);
              debugPrint('🔧 参考+税込ラベルを検出したため税込価格として修正');
            }
            // 「(税込 価格)」パターンの検出
            else if (RegExp(r'\(税込\s*\d+円\)').hasMatch(ocrText)) {
              finalPriceType = '税込';
              finalConfidence = (confidence + 0.2).clamp(0.0, 1.0);
              debugPrint('🔧 (税込 価格)パターンを検出したため税込価格として修正');
            }
          }

          // 参考税込価格の数値抽出
          if (finalPriceType == '税込' &&
              (ocrText.contains('参考') || ocrText.contains('税込'))) {
            // 「(税込 2838円)」のようなパターンから価格を抽出
            final taxIncludedPattern = RegExp(r'\(税込\s*(\d+)円\)');
            final taxIncludedMatch = taxIncludedPattern.firstMatch(ocrText);
            if (taxIncludedMatch != null) {
              final extractedPrice =
                  int.tryParse(taxIncludedMatch.group(1) ?? '');
              if (extractedPrice != null && extractedPrice > 0) {
                finalPrice = extractedPrice;
                finalConfidence = (confidence + 0.25).clamp(0.0, 1.0);
                debugPrint(
                    '🔧 参考税込価格を抽出: (税込 ${extractedPrice}円) → ${extractedPrice}円');
              }
            }

            // 「参考税込 2838円」のようなパターンから価格を抽出
            final referenceTaxIncludedPattern = RegExp(r'参考税込\s*(\d+)円');
            final referenceTaxIncludedMatch =
                referenceTaxIncludedPattern.firstMatch(ocrText);
            if (referenceTaxIncludedMatch != null) {
              final extractedPrice =
                  int.tryParse(referenceTaxIncludedMatch.group(1) ?? '');
              if (extractedPrice != null && extractedPrice > 0) {
                finalPrice = extractedPrice;
                finalConfidence = (confidence + 0.25).clamp(0.0, 1.0);
                debugPrint(
                    '🔧 参考税込価格を抽出: 参考税込 ${extractedPrice}円 → ${extractedPrice}円');
              }
            }
          }

          // OCR誤認識による小数点価格の修正
          if (finalPriceType == '税込') {
            // rawMatchesから小数点価格の誤認識を検出
            for (final match in rawMatches) {
              if (match is Map<String, dynamic>) {
                final priceStr = match['text']?.toString() ?? '';
                final label = match['label']?.toString() ?? '';

                // 税込価格ラベルで4桁以上の数字を検出した場合
                if (label.contains('税込') && priceStr.contains('円')) {
                  final misreadPattern = RegExp(r'(\d{4,})円');
                  final misreadMatch = misreadPattern.firstMatch(priceStr);
                  if (misreadMatch != null) {
                    final misreadPrice =
                        int.tryParse(misreadMatch.group(1) ?? '');
                    if (misreadPrice != null && misreadPrice >= 1000) {
                      // 4桁以上の価格で、末尾2桁が小数部分の可能性をチェック
                      final intPart = misreadPrice ~/ 100;
                      final decimalPart = misreadPrice % 100;

                      // 整数部分が妥当な範囲（100円〜500円）で、小数部分が2桁以内の場合
                      if (intPart >= 100 &&
                          intPart <= 500 &&
                          decimalPart <= 99) {
                        final correctedPrice = intPart;
                        finalPrice = correctedPrice;
                        finalConfidence = (confidence + 0.3).clamp(0.0, 1.0);
                        debugPrint(
                            '🔧 rawMatchesから小数点誤認識修正: $priceStr → 税込${correctedPrice}.${decimalPart}円 → ${correctedPrice}円');
                        break;
                      }
                    }
                  }
                }
              }
            }

            // 「税込14904円)」のような誤認識パターンを修正
            final misreadDecimalPattern = RegExp(r'税込(\d{4,})円\)');
            final misreadMatch = misreadDecimalPattern.firstMatch(ocrText);
            if (misreadMatch != null) {
              final misreadPrice = int.tryParse(misreadMatch.group(1) ?? '');
              if (misreadPrice != null && misreadPrice >= 1000) {
                // 4桁以上の価格で、末尾2桁が小数部分の可能性をチェック
                final intPart = misreadPrice ~/ 100;
                final decimalPart = misreadPrice % 100;

                // 整数部分が妥当な範囲（100円〜500円）で、小数部分が2桁以内の場合
                if (intPart >= 100 && intPart <= 500 && decimalPart <= 99) {
                  final correctedPrice = intPart;
                  finalPrice = correctedPrice;
                  finalConfidence = (confidence + 0.3).clamp(0.0, 1.0);
                  debugPrint(
                      '🔧 OCR小数点誤認識修正: 税込${misreadPrice}円) → 税込${correctedPrice}.${decimalPart}円 → ${correctedPrice}円');
                }
              }
            }

            // 「税込価格 149.04円」のような正しいパターンから価格を抽出
            final correctDecimalPattern = RegExp(r'税込価格\s*(\d+)\.(\d{1,2})円');
            final correctMatch = correctDecimalPattern.firstMatch(ocrText);
            if (correctMatch != null) {
              final intPart = int.tryParse(correctMatch.group(1) ?? '');
              final decimalPart = int.tryParse(correctMatch.group(2) ?? '');
              if (intPart != null && decimalPart != null && decimalPart <= 99) {
                finalPrice = intPart;
                finalConfidence = (confidence + 0.3).clamp(0.0, 1.0);
                debugPrint(
                    '🔧 正しい小数点価格を抽出: 税込価格 ${intPart}.${decimalPart}円 → ${intPart}円');
              }
            }

            // 「(税込価格 149.04円)」のような括弧付きパターンから価格を抽出
            final parenthesizedDecimalPattern =
                RegExp(r'\(税込価格\s*(\d+)\.(\d{1,2})円\)');
            final parenthesizedMatch =
                parenthesizedDecimalPattern.firstMatch(ocrText);
            if (parenthesizedMatch != null) {
              final intPart = int.tryParse(parenthesizedMatch.group(1) ?? '');
              final decimalPart =
                  int.tryParse(parenthesizedMatch.group(2) ?? '');
              if (intPart != null && decimalPart != null && decimalPart <= 99) {
                finalPrice = intPart;
                finalConfidence = (confidence + 0.3).clamp(0.0, 1.0);
                debugPrint(
                    '🔧 括弧付き小数点価格を抽出: (税込価格 ${intPart}.${decimalPart}円) → ${intPart}円');
              }
            }
          }

          // OCRテキスト全体から税込価格の証拠を検出
          if (!hasDecimalPrice && !ocrText.contains('税込')) {
            // 小数点価格パターンの検出
            final decimalPricePattern = RegExp(r'(\d+\.\d+)\s*円');
            final decimalMatches = decimalPricePattern.allMatches(ocrText);
            for (final match in decimalMatches) {
              final priceStr = match.group(1);
              if (priceStr != null) {
                final doubleValue = double.tryParse(priceStr);
                if (doubleValue != null &&
                    doubleValue > 0 &&
                    doubleValue <= 10000) {
                  finalPrice = doubleValue.floor();
                  finalPriceType = '税込';
                  finalConfidence = (confidence + 0.15).clamp(0.0, 1.0);
                  debugPrint('🔧 OCRテキストから小数点価格を検出: $priceStr円 → $finalPrice円');
                  break;
                }
              }
            }

            // 端数がある価格パターンの検出（例：181.44円、537.84円）
            final fractionalPricePattern = RegExp(r'(\d{3,4})\.(\d{1,2})\s*円');
            final fractionalMatches =
                fractionalPricePattern.allMatches(ocrText);
            for (final match in fractionalMatches) {
              final intPart = int.tryParse(match.group(1) ?? '');
              final decimalPart = int.tryParse(match.group(2) ?? '');
              if (intPart != null &&
                  decimalPart != null &&
                  intPart >= 100 &&
                  intPart <= 5000 &&
                  decimalPart <= 99) {
                finalPrice = intPart;
                finalPriceType = '税込';
                finalConfidence = (confidence + 0.15).clamp(0.0, 1.0);
                debugPrint(
                    '🔧 OCRテキストから端数価格を検出: ${match.group(0)} → $finalPrice円');
                break;
              }
            }
          }
        }

        // 価格が0の場合は、実際に0円の商品かどうかを確認
        if (finalPrice == 0) {
          // 無料商品の可能性がある場合はそのまま使用
          if (productName.contains('無料') ||
              productName.contains('フリー') ||
              productName.contains('0円')) {
            debugPrint('💰 無料商品として認識: $productName');
          } else {
            debugPrint('⚠️ 価格が0円で、無料商品の可能性が低いため除外');
            return null;
          }
        }

        // 商品名が空の場合は除外
        if (productName.isEmpty) {
          debugPrint('⚠️ 商品名が空のため除外');
          return null;
        }

        debugPrint(
            '📊 ChatGPT解析結果: name="$productName", price=$finalPrice, type=$finalPriceType, confidence=$finalConfidence');

        return ChatGptItemResult(
          name: productName,
          price: finalPrice,
          priceType: finalPriceType,
          confidence: finalConfidence,
          rawMatches: rawMatches,
        );
      } catch (e) {
        debugPrint('❌ ChatGPT結果のJSON解析に失敗: $e');
        return null;
      }
    } catch (e) {
      debugPrint('❌ ChatGPT API呼び出しエラー: $e');
      return null;
    }
  }
}
