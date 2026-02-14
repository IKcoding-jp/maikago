import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:maikago/config.dart';

/// 商品名を簡潔に要約するサービス
/// Cloud Functions経由でGPT-4o-miniを使用してメーカー、商品名、重さなどの基本情報のみを抽出
class ProductNameSummarizerService {
  /// 商品名を簡潔に要約する（Cloud Functions経由）
  static Future<String> summarizeProductName(String originalName) async {
    // リトライ機能付きでAPI呼び出し
    for (int attempt = 1; attempt <= chatGptMaxRetries; attempt++) {
      try {
        debugPrint('🤖 商品名要約API呼び出し試行 $attempt/$chatGptMaxRetries');
        final result = await _callCloudFunction(originalName);
        if (result.isNotEmpty) {
          debugPrint('✅ 商品名要約API呼び出し成功（試行 $attempt）');
          return result;
        }
      } catch (e) {
        debugPrint('❌ 商品名要約API呼び出し失敗（試行 $attempt）: $e');
        if (attempt < chatGptMaxRetries) {
          final waitTime = attempt * 2;
          debugPrint('⏳ $waitTime秒後に再試行します...');
          await Future.delayed(Duration(seconds: waitTime));
        } else {
          debugPrint('❌ 最大リトライ回数（$chatGptMaxRetries）に達しました');
        }
      }
    }

    return _fallbackSummarize(originalName);
  }

  /// Cloud Functions呼び出しの実装（商品名要約）
  static Future<String> _callCloudFunction(String originalName) async {
    try {
      debugPrint('🤖 商品名要約開始（Cloud Functions経由）: ${originalName.length}文字');

      final callable =
          FirebaseFunctions.instance.httpsCallable('summarizeProductName');
      final response = await callable.call<Map<String, dynamic>>({
        'originalName': originalName,
      }).timeout(const Duration(seconds: 15));

      final data = response.data;

      if (data['success'] == true) {
        final summarizedName = data['summarizedName'] as String? ?? '';
        if (summarizedName.isNotEmpty) {
          debugPrint('✅ 商品名要約完了: $summarizedName');
          return summarizedName;
        }
      }

      return _fallbackSummarize(originalName);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ 商品名要約Cloud Functionsエラー: [${e.code}] ${e.message}');
      return _fallbackSummarize(originalName);
    } catch (e) {
      debugPrint('❌ 商品名要約例外: $e');
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
