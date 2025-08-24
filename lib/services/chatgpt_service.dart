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
      final systemPrompt = 'あなたはOCRで得たテキストから買い物用の情報を整理するアシスタントです。' //
          '必ず税込価格を優先し、商品名と価格のみを抽出してください。' //
          '推測は最小限にし、不明な場合は空文字または0を返してください。';

      final userPrompt = {
        'instruction': '以下のOCRテキストから商品名と税込価格のみを抽出してください。',
        'rules': [
          '税込が複数ある場合は最も代表的な価格を選択',
          '通貨は日本円で数値のみ（円や記号は付与しない）',
          '価格は整数（四捨五入ではなく小数切り捨て）',
          '商品名は宣伝文・メーカー名・JAN等を除外',
          'ノイズは削除し短く明確な商品名に整形',
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
        price = int.tryParse(rawPrice) ?? 0;
      }

      if (price < 0 || price > 200000) {
        debugPrint('⚠️ OpenAI: 価格が不正値でした: $price');
        return null;
      }

      if (rawName.isEmpty || price == 0) {
        // 情報不足はnullにしてフォールバックへ
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
