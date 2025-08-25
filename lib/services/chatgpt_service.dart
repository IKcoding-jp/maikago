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
- 税込価格を最優先（「税込」「税込み」「税込価格」「税込(」のラベルを絶対重視）
- 小数点を含む価格は税込価格の可能性が非常に高い（例：181.44円、537.84円）
- 税抜価格の判定は厳密に行う（「税抜」「税抜き」「本体価格」「税別」「外税」の明確なラベルのみ）
- ラベルが不明確な場合は税込価格として扱う
- 取り消し線価格は除外

【税込価格の検出パターン】
1. 明確なラベル: 「税込」「税込み」「税込価格」「税込(」「内税」
2. 小数点価格: 181.44円、537.84円、278.46円など
3. 端数がある価格: 末尾に.44、.84、.46などの端数がある価格
4. 一般的な小売価格: 100円〜5000円の範囲で、端数がある価格

【税抜価格の判定基準】
- 明確に「税抜」「税抜き」「本体価格」「税別」「外税」と表示されている場合のみ
- ラベルが曖昧な場合は税込価格として扱う
- 推定は避け、明確な証拠がある場合のみ税抜と判定

【OCR誤認識修正】
- 末尾文字除去: 21492円)k → 21492円
- 小数点誤認識: 17064円 → 170.64円 → 170円
- 分離認識: 278円 + 46円 → 278.46円 → 278円
- 異常価格修正: 2149200円 → 21492円

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
          " - 小数点を含む価格（181.44円、537.84円など）は税込価格として扱う",
          " - 端数がある価格（末尾に.44、.84、.46など）は税込価格の可能性が高い",
          " - ラベルが不明確な場合は税込価格として扱う",
          "税抜価格の厳密判定:",
          " - 「税抜」「税抜き」「本体価格」「税別」「外税」の明確なラベルのみ",
          " - ラベルが曖昧な場合は税込価格として扱う",
          " - 推定は避け、明確な証拠がある場合のみ税抜と判定",
          "OCR誤認識修正:",
          " - 末尾文字除去: 21492円)k → 21492円",
          " - 小数点誤認識: 17064円 → 170.64円 → 170円",
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

          // 明確な税抜ラベルがない場合は税込価格として扱う
          if (!hasClearTaxExcludedLabel) {
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
