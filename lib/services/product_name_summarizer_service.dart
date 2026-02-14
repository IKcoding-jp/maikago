import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maikago/config.dart';

/// 商品名を簡潔に要約するサービス
/// GPT-5-nanoを使用してメーカー、商品名、重さなどの基本情報のみを抽出
class ProductNameSummarizerService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// 商品名を簡潔に要約する
  /// 例: "味の素 コンソメ 顆粒 50g 袋入 AJINOMOTO 調味料 洋風スープ 煮込み料理 野菜のコク 炒め物 スープ ブイヨン まとめ買い プロの味 料理 洋食"
  /// → "味の素 コンソメ 顆粒 50g"
  static Future<String> summarizeProductName(String originalName) async {
    // APIキーが設定されていない場合はフォールバック機能を使用
    if (openAIApiKey.isEmpty || openAIApiKey == 'YOUR_OPENAI_API_KEY') {
      debugPrint('⚠️ OpenAI APIキーが設定されていません。フォールバック要約を使用します。');
      return _fallbackSummarize(originalName);
    }

    // リトライ機能付きでAPI呼び出し
    for (int attempt = 1; attempt <= chatGptMaxRetries; attempt++) {
      try {
        debugPrint('🤖 商品名要約API呼び出し試行 $attempt/$chatGptMaxRetries');
        final result = await _callOpenAIForSummarization(originalName);
        if (result.isNotEmpty) {
          debugPrint('✅ 商品名要約API呼び出し成功（試行 $attempt）');
          return result;
        }
      } catch (e) {
        debugPrint('❌ 商品名要約API呼び出し失敗（試行 $attempt）: $e');
        if (attempt < chatGptMaxRetries) {
          final waitTime = attempt * 2; // 2秒、4秒、6秒と待機時間を増加
          debugPrint('⏳ $waitTime秒後に再試行します...');
          await Future.delayed(Duration(seconds: waitTime));
        } else {
          debugPrint('❌ 最大リトライ回数（$chatGptMaxRetries）に達しました');
        }
      }
    }

    return _fallbackSummarize(originalName);
  }

  /// OpenAI API呼び出しの実装（商品名要約）
  static Future<String> _callOpenAIForSummarization(String originalName) async {
    try {
      debugPrint('🤖 商品名要約開始: ${originalName.length}文字');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIApiKey',
        },
        body: jsonEncode({
          'model': openAIModel, // GPT-5-nanoを使用
          'messages': [
            {
              'role': 'system',
              'content': '''あなたは商品名を簡潔に要約する専門家です。
以下のルールに従って商品名を要約してください：

1. メーカー名、商品名のみを抽出
2. 商品名の核心部分を判断し、以下の不要な説明文・キーワードを削除：
   - 内容量・個数（「50g」「1L」「500ml」「104個」「12錠」など）
   - 商品名の後に付く説明文（「子供用」「おやつ用」「朝食用」など）
   - 用途説明（「煮込み料理用」「炒め物用」「スープ用」など）
   - キャッチフレーズ（「プロの味」「本格」「特選」など）
   - 成分・特徴の説明（「無添加」「オーガニック」「低カロリー」など）
   - 包装・容器の説明（「袋入」「瓶入」「缶入」など）
   - 配送・販売関連（「送料無料」「即納」「在庫あり」「まとめ買い」など）
   - その他の宣伝文句や説明文
3. ただし、商品名の一部として必要なキーワードは保持：
   - 商品名に含まれる味の種類（「甘口」「辛口」「濃口」など）
   - 商品名に含まれる形状（「顆粒」「粉末」「液体」など）
   - 商品名に含まれる種類（「タブレット」「スナック」「ドリンク」など）
4. 最大20文字以内に収める
5. 日本語で回答

例：
入力: "味の素 コンソメ 顆粒 50g 袋入 AJINOMOTO 調味料 洋風スープ 煮込み料理 野菜のコク 炒め物 スープ ブイヨン まとめ買い プロの味 料理 洋食"
出力: "味の素 コンソメ 顆粒"

入力: "キッコーマン しょうゆ 濃口 1L 瓶入 醤油 調味料 和食 料理 日本製 本醸造"
出力: "キッコーマン しょうゆ 濃口"

入力: "塩分チャージタブレッツ 子供 おやつ 粒状 袋入 スポーツ 汗対策"
出力: "塩分チャージタブレッツ"

入力: "明治 アーモンドチョコレート 甘口 子供用 おやつ 袋入"
出力: "明治 アーモンドチョコレート 甘口"

入力: "森永 ビスケット 子供用 おやつ 朝食用 袋入"
出力: "森永 ビスケット"

入力: "カルピス ウォーター 500ml 送料無料 即納 在庫あり"
出力: "カルピス ウォーター"

入力: "日清 カップヌードル 醤油味 送料無料 まとめ買い 特価"
出力: "日清 カップヌードル 醤油味"'''
            },
            {'role': 'user', 'content': '以下の商品名を要約してください：\n$originalName'}
          ],
          'max_tokens': 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // OpenAIのレスポンス形式はモデルやバージョンで差があるため、複数の候補を順に試す
        String extractContentFromChoice(dynamic choice) {
          if (choice is Map<String, dynamic>) {
            final msg = choice['message'];
            if (msg is Map && msg['content'] != null) {
              return msg['content'].toString();
            }
            if (choice['text'] != null) return choice['text'].toString();
            if (choice['delta'] is Map && choice['delta']['content'] != null) {
              return choice['delta']['content'].toString();
            }
          }
          return '';
        }

        String summarizedName = '';
        if (data is Map && data['choices'] is List) {
          final choices = data['choices'] as List;
          for (final c in choices) {
            final candidate = extractContentFromChoice(c).trim();
            if (candidate.isNotEmpty) {
              summarizedName = candidate;
              break;
            }
          }
        }

        // 抽出できなければフォールバック
        if (summarizedName.isEmpty) {
          debugPrint(
              '⚠️ OpenAIレスポンスから要約が抽出できませんでした。フォールバックを使用します。レスポンス: ${response.body}');
          return _fallbackSummarize(originalName);
        }

        summarizedName = summarizedName.trim();
        debugPrint('✅ 商品名要約完了: $summarizedName');
        return summarizedName;
      } else {
        debugPrint('❌ 商品名要約エラー: HTTP ${response.statusCode}');
        debugPrint('📝 レスポンスボディ: ${response.body}');

        // 具体的なエラーコードに応じたメッセージ
        if (response.statusCode == 401) {
          debugPrint('🔑 認証エラー: APIキーが無効または期限切れです');
        } else if (response.statusCode == 429) {
          debugPrint('⏰ レート制限: APIの使用制限に達しました');
        } else if (response.statusCode == 500) {
          debugPrint('🔧 サーバーエラー: OpenAIのサーバーで問題が発生しています');
        } else if (response.statusCode == 503) {
          debugPrint('🚫 サービス利用不可: OpenAIのサービスが一時的に利用できません');
        }

        return _fallbackSummarize(originalName);
      }
    } catch (e) {
      debugPrint('❌ 商品名要約例外: $e');
      debugPrint('📝 エラータイプ: ${e.runtimeType}');
      if (e.toString().contains('TimeoutException')) {
        debugPrint('⏰ タイムアウトエラー: ネットワーク接続またはAPI応答が遅延しています');
      } else if (e.toString().contains('SocketException')) {
        debugPrint('🌐 ネットワークエラー: インターネット接続を確認してください');
      } else if (e.toString().contains('FormatException')) {
        debugPrint('📄 フォーマットエラー: APIレスポンスの形式が正しくありません');
      }
      return _fallbackSummarize(originalName);
    }
  }

  /// APIが利用できない場合のフォールバック要約
  static String _fallbackSummarize(String originalName) {
    debugPrint('🔄 フォールバック要約を使用');

    // 不要なキーワードを除外するパターン
    final excludePatterns = [
      RegExp(r'\b(子供|大人|高齢者|赤ちゃん|幼児|小学生|中学生|高校生)\b'),
      RegExp(r'\b(おやつ|朝食|夜食|おつまみ|お弁当|昼食|夕食)\b'),
      RegExp(r'\b(甘い|辛い|酸っぱい|香り|味|風味)\b'),
      RegExp(r'\b(粒|粉|液体|固形|タブレット|顆粒|粉末)\b'),
      RegExp(r'\b(袋入|瓶入|缶入|パック|箱入|個装)\b'),
      RegExp(r'\b(プロの味|本格|特選|プレミアム|高級|上質)\b'),
      RegExp(r'\b(煮込み|炒め物|スープ|和食|洋食|中華|料理)\b'),
      RegExp(r'\b(無添加|オーガニック|低カロリー|ヘルシー|健康)\b'),
      RegExp(r'\b(送料無料|即納|在庫あり|まとめ買い|特価|セール|お得)\b'),
      RegExp(r'\b(限定|数量限定|期間限定|新発売|人気|おすすめ)\b'),
      RegExp(r'\b(調味料|スープ|ブイヨン|だし|味噌|醤油|ソース)\b'),
      RegExp(r'\b(まとめ買い|プロ|味|料理|洋食|和食|中華)\b'),
    ];

    String cleanedName = originalName;

    // 不要なキーワードを除外
    for (final pattern in excludePatterns) {
      cleanedName = cleanedName.replaceAll(pattern, '').trim();
    }

    // 複数のスペースを1つに統一
    cleanedName = cleanedName.replaceAll(RegExp(r'\s+'), ' ');

    // 基本的な要約ロジック
    final words = cleanedName.split(' ');
    final result = <String>[];

    for (final word in words) {
      if (word.isEmpty) continue;

      // 容量・重さのパターンを検出
      if (RegExp(r'\d+[gmlL]').hasMatch(word)) {
        result.add(word);
        continue;
      }

      // メーカー名や商品名の基本部分を保持（最大4単語まで）
      if (result.length < 4 && word.length > 1) {
        result.add(word);
      }
    }

    final summarized = result.join(' ');
    debugPrint('📝 フォールバック要約結果: $summarized');
    return summarized.isNotEmpty ? summarized : originalName;
  }
}
