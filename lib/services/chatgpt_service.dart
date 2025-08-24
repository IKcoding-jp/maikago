import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:maikago/config.dart';

class ChatGptItemResult {
  final String name;
  final int price;
  ChatGptItemResult({required this.name, required this.price});
}

class ChatGptService {
  final String apiKey;

  ChatGptService({String? apiKey}) : apiKey = apiKey ?? openAIApiKey;

  /// OCRテキストから「商品名」「税込価格」を抽出
  /// - 役割: 整理・ノイズ除去のみ。推測は最小限
  /// - 出力: JSON {"name": string, "price": number}
  Future<ChatGptItemResult?> extractNameAndPrice(String ocrText) async {
    if (apiKey.isEmpty) {
      debugPrint(
          '⚠️ OpenAI APIキーが未設定です。--dart-define=OPENAI_API_KEY=... を指定してください');
      return null;
    }

    try {
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

      // JSON出力を強制するためのシステム/ユーザープロンプト
      const systemPrompt = 'あなたはOCRで得たテキストから買い物用の情報を整理するアシスタントです。' //
          '必ず税込価格を最優先し、商品名と価格のみを抽出してください。' ////
          '推測は最小限にし、不明な場合は空文字または0を返してください。' //
          '価格選択の優先順位：税込価格 > 本体価格 > その他の価格';

      final userPrompt = {
        'instruction': '以下のOCRテキストから商品名と税込価格のみを抽出してください。' //
            '特に、カンマ区切りの価格（例：214,92円）は必ず214円として処理してください。',
        'rules': [
          '複数の価格がある場合は、必ず税込価格を選択（例：199円と214円がある場合、214円を選択）',
          '価格処理ルール：',
          '  - 21492円 → 21492円（そのまま）',
          '  - 123456円 → 123456円（そのまま）',
          '  - 123,345円 → 123345円（カンマ除去）',
          '  - 123.45円 → 123円（小数点切り捨て）',
          '  - 278.46円 → 278円（小数点切り捨て）',
          '  - 278円 + 46円 → 278.46円 → 278円（分離小数点価格の結合）',
          '  - 27864円 → 278.64円 → 278円（小数点誤認識の修正）',
          'カンマ区切りの価格（例：214,92円、1,234,567円）は必ず正しく計算して整数で返す',
          '小数点価格は切り捨てて整数に変換（例：214.92円 → 214円、12345.6円 → 12345円）',
          'OCR誤認識修正：21492円)k → 21492円（末尾のkや)は無視、価格はそのまま）',
          '小数点誤認識修正：27864円 → 278.64円 → 278円（4桁以上の価格で末尾2桁が小数部分の可能性）',
          '分離小数点価格結合：278円 + 46円 → 278.46円 → 278円（整数部分と小数部分が分離されている場合）',
          '通貨は日本円で数値のみ（円や記号は付与しない）',
          '価格は整数（四捨五入ではなく小数切り捨て）',
          '商品名は宣伝文・メーカー名・JAN等を除外',
          'ノイズは削除し短く明確な商品名に整形',
          '価格選択の優先順位：税込価格 > 本体価格 > その他',
          '価格上限：10,000,000円まで対応（家電、家具、高級品対応）',
          '重要：価格は基本的にそのまま使用し、明らかな誤認識の場合のみ修正する',
          '税込価格のキーワード：「税込」「税込み」「定価」を優先的に探す',
          '本体価格のキーワード：「本体価格」「税抜」「税抜き」は2番目に優先',
          '価格の妥当性：100円〜5000円の範囲を優先、それ以外は慎重に判断',
        ],
        'text': ocrText,
      };

      // response_format: { type: 'json_object' } は JSON モード
      final body = jsonEncode({
        'model': openAIModel,
        'temperature': 0,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content':
                '次の入力をJSONで返答してください。スキーマ: {"name": string, "price": number}. 入力:\n${jsonEncode(userPrompt)}'
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
          .timeout(const Duration(seconds: 30));

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
      final rawName = (parsed['name'] ?? '').toString().trim();
      final rawPrice = parsed['price'];

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

      debugPrint('✅ OpenAI整形結果: name=$rawName, price=$price');
      return ChatGptItemResult(name: rawName, price: price);
    } catch (e) {
      debugPrint('❌ OpenAI整形エラー: $e');
      return null;
    }
  }
}
