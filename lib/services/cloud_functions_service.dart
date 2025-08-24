// Firebase Cloud Functions を呼び出すためのサービス
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Functions を呼び出すためのサービス
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 認証されたユーザーでCloud Functionsを呼び出す
  Future<dynamic> callFunction(
      String functionName, Map<String, dynamic> data) async {
    try {
      debugPrint('🔥 Cloud Functions呼び出し開始: $functionName');

      // 認証状態を確認
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ ユーザーが認証されていません');
        throw Exception('ユーザーが認証されていません');
      }

      // IDトークンを取得
      final idToken = await user.getIdToken();
      debugPrint('✅ IDトークン取得完了');

      // Cloud Functionsを呼び出し
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call({
        ...data,
        'authToken': idToken, // 認証トークンを追加
      });

      debugPrint('✅ Cloud Functions呼び出し成功: $functionName');
      return result.data;
    } catch (e) {
      debugPrint('❌ Cloud Functions呼び出しエラー: $functionName - $e');
      rethrow;
    }
  }

  /// 認証なしでCloud Functionsを呼び出す（公開関数用）
  Future<dynamic> callPublicFunction(
      String functionName, Map<String, dynamic> data) async {
    try {
      debugPrint('🔥 公開Cloud Functions呼び出し開始: $functionName');

      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call(data);

      debugPrint('✅ 公開Cloud Functions呼び出し成功: $functionName');
      return result.data;
    } catch (e) {
      debugPrint('❌ 公開Cloud Functions呼び出しエラー: $functionName - $e');
      rethrow;
    }
  }

  /// 画像解析用のCloud Functionsを呼び出す
  Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    try {
      debugPrint('🖼️ 画像解析開始: $imageUrl');

      final result = await callFunction('analyzeImage', {
        'imageUrl': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ 画像解析完了');
      return result as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ 画像解析エラー: $e');
      rethrow;
    }
  }

  /// 商品情報取得用のCloud Functionsを呼び出す
  Future<Map<String, dynamic>> getProductInfo(String productId) async {
    try {
      debugPrint('📦 商品情報取得開始: $productId');

      final result = await callFunction('getProductInfo', {
        'productId': productId,
      });

      debugPrint('✅ 商品情報取得完了');
      return result as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ 商品情報取得エラー: $e');
      rethrow;
    }
  }

  /// データ同期用のCloud Functionsを呼び出す
  Future<Map<String, dynamic>> syncData(Map<String, dynamic> syncData) async {
    try {
      debugPrint('🔄 データ同期開始');

      final result = await callFunction('syncData', {
        'syncData': syncData,
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ データ同期完了');
      return result as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ データ同期エラー: $e');
      rethrow;
    }
  }

  /// エラーハンドリング用のヘルパーメソッド
  String getErrorMessage(dynamic error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'unavailable':
          return 'サービスが一時的に利用できません';
        case 'permission-denied':
          return 'アクセス権限がありません';
        case 'unauthenticated':
          return '認証が必要です';
        case 'invalid-argument':
          return '無効なパラメータです';
        case 'not-found':
          return 'リソースが見つかりません';
        case 'already-exists':
          return '既に存在します';
        case 'resource-exhausted':
          return 'リソースが不足しています';
        case 'failed-precondition':
          return '前提条件が満たされていません';
        case 'aborted':
          return '操作が中止されました';
        case 'out-of-range':
          return '範囲外の値です';
        case 'unimplemented':
          return '実装されていません';
        case 'internal':
          return '内部エラーが発生しました';
        case 'data-loss':
          return 'データが失われました';
        default:
          return 'エラーが発生しました: ${error.message}';
      }
    }
    return '予期しないエラーが発生しました: $error';
  }
}
