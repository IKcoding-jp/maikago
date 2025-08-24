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
          '必ず税込価格を優先し、商品名と価格のみを抽出してください。' //
          'カンマ区切りの価格（例：214,92円）は必ず214.92として計算し、214円として返してください。' //
          '推測は最小限にし、不明な場合は空文字または0を返してください。';

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
          'OCR誤認識修正ルール（重要・慎重に適用）：',
          '  - 27864円 → 278円（5桁の価格で、末尾が64の場合は278.64円の誤認識の可能性、ただし修正後の価格が500円以下の場合のみ）',
          '  - 21492円 → 214円（5桁の価格で、末尾が92の場合は214.92円の誤認識の可能性、ただし修正後の価格が500円以下の場合のみ）',
          '  - 18900円 → 189円（5桁の価格で、末尾が00の場合は189.00円の誤認識の可能性、ただし修正後の価格が1000円以下の場合のみ）',
          '  - 12345円 → 123円（5桁の価格で、末尾が45の場合は123.45円の誤認識の可能性、ただし修正後の価格が500円以下の場合のみ）',
          '  - 10000円以上で末尾が00の場合は、100で割って修正（例：18900円 → 189円、ただし修正後の価格が1000円以下の場合のみ）',
          '  - 1000円以上で末尾が00の場合は、10で割って修正（例：1890円 → 189円、ただし修正後の価格が1000円以下の場合のみ）',
          '  - 高額商品（500円超）の場合は誤認識修正を適用しない（例：27864円の実際の商品はそのまま27864円として扱う）',
          'カンマ区切りの価格（例：214,92円、1,234,567円）は必ず正しく計算して整数で返す',
          '小数点価格は切り捨てて整数に変換（例：214.92円 → 214円、12345.6円 → 12345円）',
          'OCR誤認識修正：21492円)k → 21492円（末尾のkや)は無視、価格はそのまま）',
          '通貨は日本円で数値のみ（円や記号は付与しない）',
          '価格は整数（四捨五入ではなく小数切り捨て）',
          '商品名は宣伝文・メーカー名・JAN等を除外',
          'ノイズは削除し短く明確な商品名に整形',
          '価格選択の優先順位：税込価格 > 本体価格 > その他',
          '価格上限：10,000,000円まで対応（家電、家具、高級品対応）',
          '重要：価格は基本的にそのまま使用し、明らかな誤認識の場合のみ修正する',
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

      // OCR誤認識修正ロジック
      price = _fixOcrPrice(price);

      if (price < 0 || price > 10000000) {
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

  /// OCR誤認識の価格を修正する
  int _fixOcrPrice(int price) {
    if (price <= 0) return price;

    // 5桁の価格で、末尾が00の場合は100で割って修正（例：18900円 → 189円）
    if (price >= 10000 && price <= 99999 && price % 100 == 0) {
      final correctedPrice = price ~/ 100;
      if (correctedPrice > 0 && correctedPrice <= 1000) {
        debugPrint('🔧 OCR誤認識修正: ${price}円 → ${correctedPrice}円 (100で割り算)');
        return correctedPrice;
      }
    }

    // 4桁の価格で、末尾が00の場合は10で割って修正（例：1890円 → 189円）
    if (price >= 1000 && price <= 9999 && price % 10 == 0) {
      final correctedPrice = price ~/ 10;
      if (correctedPrice > 0 && correctedPrice <= 1000) {
        debugPrint('🔧 OCR誤認識修正: ${price}円 → ${correctedPrice}円 (10で割り算)');
        return correctedPrice;
      }
    }

    // 5桁の価格で小数点価格の誤認識を修正（より慎重な条件）
    if (price >= 10000 && price <= 99999) {
      final lastTwoDigits = price % 100;
      final firstThreeDigits = price ~/ 100;

      // 小数点価格によく見られるパターンのみ修正
      final commonDecimalPatterns = [
        64,
        92,
        45,
        80,
        50,
        25,
        75,
        99,
        88,
        66,
        44,
        22,
        11,
        33,
        55,
        77
      ];

      // 末尾が小数点価格によく見られるパターンで、かつ修正後の価格が一般的な商品価格範囲内の場合のみ修正
      if (commonDecimalPatterns.contains(lastTwoDigits) &&
          firstThreeDigits > 0 &&
          firstThreeDigits <= 500) {
        // 500円以下に制限
        debugPrint('🔧 OCR誤認識修正: ${price}円 → ${firstThreeDigits}円 (小数点価格の誤認識)');
        return firstThreeDigits;
      }
    }

    return price;
  }
}
