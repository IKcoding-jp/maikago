import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 商品名を簡潔に要約するサービス
/// GPT-5-nanoを使用してメーカー、商品名、重さなどの基本情報のみを抽出
class ProductNameSummarizerService {
  static const String _apiKey = 'YOUR_OPENAI_API_KEY'; // OpenAI APIキーを設定
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// 商品名を簡潔に要約する
  /// 例: "味の素 コンソメ 顆粒 50g 袋入 AJINOMOTO 調味料 洋風スープ 煮込み料理 野菜のコク 炒め物 スープ ブイヨン まとめ買い プロの味 料理 洋食"
  /// → "味の素 コンソメ 顆粒 50g"
  static Future<String> summarizeProductName(String originalName) async {
    try {
      debugPrint('🤖 商品名要約開始: ${originalName.length}文字');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-5-nano', // GPT-5-nanoが利用可能になったら変更
          'messages': [
            {
              'role': 'system',
              'content': '''あなたは商品名を簡潔に要約する専門家です。
以下のルールに従って商品名を要約してください：

1. メーカー名、商品名、容量・重さのみを抽出
2. 不要な説明文、キーワード、キャッチフレーズは削除
3. 最大20文字以内に収める
4. 日本語で回答

例：
入力: "味の素 コンソメ 顆粒 50g 袋入 AJINOMOTO 調味料 洋風スープ 煮込み料理 野菜のコク 炒め物 スープ ブイヨン まとめ買い プロの味 料理 洋食"
出力: "味の素 コンソメ 顆粒 50g"

入力: "キッコーマン しょうゆ 濃口 1L 瓶入 醤油 調味料 和食 料理 日本製 本醸造"
出力: "キッコーマン しょうゆ 濃口 1L"'''
            },
            {'role': 'user', 'content': '以下の商品名を要約してください：\n$originalName'}
          ],
          'max_tokens': 50,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summarizedName = data['choices'][0]['message']['content'].trim();

        debugPrint('✅ 商品名要約完了: $summarizedName');
        return summarizedName;
      } else {
        debugPrint('❌ 商品名要約エラー: ${response.statusCode} - ${response.body}');
        return _fallbackSummarize(originalName);
      }
    } catch (e) {
      debugPrint('❌ 商品名要約例外: $e');
      return _fallbackSummarize(originalName);
    }
  }

  /// APIが利用できない場合のフォールバック要約
  static String _fallbackSummarize(String originalName) {
    debugPrint('🔄 フォールバック要約を使用');

    // 基本的な要約ロジック
    final words = originalName.split(' ');
    final result = <String>[];

    for (final word in words) {
      // 容量・重さのパターンを検出
      if (RegExp(r'\d+[gmlL]').hasMatch(word)) {
        result.add(word);
        break;
      }
      // メーカー名や商品名の基本部分を保持
      if (result.length < 3 && word.length > 1) {
        result.add(word);
      }
    }

    final summarized = result.join(' ');
    debugPrint('📝 フォールバック要約結果: $summarized');
    return summarized.isNotEmpty ? summarized : originalName;
  }
}
