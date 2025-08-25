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

【価格抽出ルール】
- 税込価格を最優先（「税込」「税込み」「税込価格」のラベルを重視）
- 税抜価格の場合は明示（price_type='税抜'）
- OCR誤認識の修正（例：21492円)k → 21492円、17064円 → 170円）
- 小数点価格の処理（例：181.44円 → 181円）
- 取り消し線価格は除外

【confidence算出】
- 0.9-1.0: 明確なラベルと価格、商品名が一致
- 0.7-0.8: ラベルは不明だが妥当な価格と商品名
- 0.5-0.6: 推測が必要だが合理的な結果
- 0.3以下: 信頼度が低い、不明な場合''';

      final userPrompt = {
        "instruction": "以下のOCRテキストから商品名と税込価格を抽出してJSONで返してください。",
        "rules": [
          "出力スキーマ: { product_name: string, price_jpy: integer, price_type: '税込'|'税抜'|'推定'|'不明', confidence: 0.0-1.0, raw_matches: [ ... ] }",
          "税込価格優先: OCRに『税込』『税込み』『税込価格』『税込(』等があれば、その近傍の最も近い価格を税込として選択。",
          "税込価格の特徴: 小数点を含む価格（例：537.84円）は税込価格の可能性が高い。",
          "本体価格: OCRに『本体価格』『税抜』『税抜き』等があればそれを本体価格として記録し、price_type='税抜'とする（ただし税込が明示されていれば税込を優先）。",
          "OCR誤認識修正:",
          " - 末尾文字除去: 21492円)k → 21492円",
          " - 小数点誤認識: 17064円 → 170.64円 → 170円",
          " - 分離認識: 278円 + 46円 → 278.46円 → 278円",
          " - 異常価格修正: 2149200円 → 21492円",
          "商品名抽出:",
          " - メーカー名+商品名の組み合わせを優先",
          " - 価格、説明文、プロモーション文言は除外",
          " - 誤認識文字の修正（例：田 → 日、CREATIVE → 誤認識として除外）",
          "confidence算出: ラベルの有無(+0.3), 文字列整合性(+0.2), 妥当性スコア(+0.3), 補正の有無(-0.2) で計算し0..1に正規化",
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

        debugPrint(
            '📊 ChatGPT解析結果: name="$productName", price=$priceJpy, type=$priceType, confidence=$confidence');

        return ChatGptItemResult(
          name: productName,
          price: priceJpy,
          priceType: priceType,
          confidence: confidence,
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
