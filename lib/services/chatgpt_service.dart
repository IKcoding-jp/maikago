import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:maikago/config.dart';
import 'package:maikago/services/security_audit_service.dart';

class ChatGptItemResult {
  final String name;
  final int price;
  ChatGptItemResult({required this.name, required this.price});
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
      const systemPrompt = 'あなたはOCRテキストから買い物用データを抽出するアシスタントです。' +
          '出力は必ずJSONのみ。商品名は短く整形し、価格は日本円の整数のみで返してください。' +
          '価格判定は明確なラベル重視：ラベル「税込」「税込み」「税込価格」があれば必ずその値を税込価格として選ぶ。' +
          'ラベル「税抜」「本体価格」「税抜き」があれば本体価格と明示する。' +
          'ラベルが無ければ下記の優先ロジックに従う。推測は最小限。';

      final userPrompt = {
        "instruction": "以下のOCRテキストから商品名と税込価格（可能なら税込と明示）を抽出してJSONで返してください。",
        "rules": [
          "出力スキーマ: { product_name: string, price_jpy: integer, price_type: '税込'|'税抜'|'推定'|'不明', confidence: 0.0-1.0, raw_matches: [ ... ] }",
          "ラベル優先: OCRに『税込』『税込み』『税込価格』『税込(』等があれば、その近傍の最も近い価格を税込として選択。",
          "本体優先: OCRに『本体価格』『税抜』『税抜き』等があればそれを本体価格として記録し、price_type='税抜'とする（ただし税込が明示されていれば税込を優先）。",
          "ラベル無い場合の推定ルール（順に適用）:",
          " 1) 同一領域に税込表示がないが、端数が小数点や末尾2桁に誤認識している可能性が高い場合は補正（下記参照）。",
          " 2) 100<=price<=5000 の整数値がある場合は税込の可能性を優先して選択（price_type='推定'）。",
          " 3) 複数候補があり1つが他より顕著に大きい場合は、ラベルの有無と妥当性で選ぶ。",
          "数値処理ルール:",
          " - カンマ区切りは除去（1,234 -> 1234）",
          " - 小数点は切り捨て（214.92 -> 214）だが、OCRで小数点誤認識の可能性がある5桁・4桁は後処理で補正（例は下記）",
          " - 明らかなノイズ文字は削除（末尾のkや)等）",
          "補正ヒューリスティック（OCR小数誤認識対策）:",
          " - 値 >= 10000 で末尾2桁 <= 99 の場合、'可能な小数誤認識'として floor(value/100) を候補として生成する（ただし他に妥当な候補がある場合のみ採用）",
          " - 値が5桁で他に同一商品で4桁または3桁の候補がある場合は小数補正を優先",
          "confidence算出: ラベルの有無(+0.5), 文字列整合性(+0.2), 妥当性スコア(+0.2), 補正が発生していない(-0.3) で計算し0..1に正規化",
          "不明・低信頼時は price_jpy=0, price_type='不明', confidence<=0.6 とする",
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

      debugPrint('🤖 OpenAIへ整形リクエスト送信中...');

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 15)); // 30秒 → 15秒に短縮

      if (resp.statusCode != 200) {
        debugPrint('❌ OpenAIエラー: HTTP ${resp.statusCode} ${resp.body}');
        return null;
      }

      final Map<String, dynamic> jsonMap = jsonDecode(resp.body);
      final choices = jsonMap['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        debugPrint('⚠️ OpenAIレスポンスにchoicesがありません');
        return null;
      }
      final content = choices.first['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        debugPrint('⚠️ OpenAIレスポンスにcontentがありません');
        return null;
      }

      // JSON モードのため content は JSON 文字列のはず
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final rawName = (parsed['product_name'] ?? '').toString().trim();
      final rawPrice = parsed['price_jpy'];
      final priceType = (parsed['price_type'] ?? '不明').toString();
      final confidence = (parsed['confidence'] ?? 0.0) as double;
      final rawMatches = parsed['raw_matches'] as List<dynamic>? ?? [];

      if (rawName.isEmpty) {
        debugPrint('⚠️ OpenAI: 商品名が空でした');
      }

      int price = 0;
      if (rawPrice is int) {
        price = rawPrice;
      } else if (rawPrice is double) {
        price = rawPrice.floor();
      } else if (rawPrice is String) {
        // カンマ区切りの価格を処理（例：214,92 → 214.92）
        final cleanedPrice = rawPrice.replaceAll(',', '.');
        final doubleValue = double.tryParse(cleanedPrice);
        if (doubleValue != null) {
          price = doubleValue.floor();
        } else {
          price = int.tryParse(rawPrice) ?? 0;
        }
      }

      // 価格の妥当性チェック（改善版）
      if (price < 0 || price > 10000000) {
        debugPrint('⚠️ OpenAI: 価格が不正値でした: $price');
        return null;
      }

      // 信頼度が低い場合の処理
      if (confidence <= 0.6 && priceType == '不明') {
        debugPrint(
            '⚠️ OpenAI: 信頼度が低いため除外 (confidence: $confidence, type: $priceType)');
        return null;
      }

      // 価格が0の場合は、実際に0円の商品かどうかを確認
      if (price == 0) {
        // 無料商品の可能性がある場合はそのまま使用
        if (rawName.contains('無料') ||
            rawName.contains('フリー') ||
            rawName.contains('0円')) {
          debugPrint('💰 OpenAI: 無料商品として認識: $rawName');
        } else {
          debugPrint('⚠️ OpenAI: 価格が0円で、無料商品の可能性が低いため除外');
          return null;
        }
      }

      if (rawName.isEmpty) {
        // 商品名が空の場合は除外
        return null;
      }

      debugPrint(
          '✅ OpenAI整形結果: name=$rawName, price=$price, type=$priceType, confidence=$confidence');
      debugPrint('🔍 検出された価格候補: $rawMatches');
      return ChatGptItemResult(name: rawName, price: price);
    } catch (e) {
      debugPrint('❌ OpenAI整形エラー: $e');
      return null;
    }
  }
}
