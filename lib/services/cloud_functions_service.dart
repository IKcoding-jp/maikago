// Firebase Cloud Functions を呼び出すためのサービス
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maikago/services/debug_service.dart';

/// Firebase Cloud Functions を呼び出すためのサービス
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 認証されたユーザーでCloud Functionsを呼び出す
  Future<dynamic> callFunction(
      String functionName, Map<String, dynamic> data) async {
    try {
      DebugService().log('Cloud Functions呼び出し開始: $functionName');

      // 認証状態を確認
      final user = _auth.currentUser;
      if (user == null) {
        DebugService().log('ユーザーが認証されていません');
        throw Exception('ユーザーが認証されていません');
      }

      // httpsCallable は自動で認証トークンを送信するため、手動送信は不要
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call(data);

      DebugService().log('Cloud Functions呼び出し成功: $functionName');
      return result.data;
    } catch (e) {
      DebugService().log('Cloud Functions呼び出しエラー: $functionName - $e');
      rethrow;
    }
  }

  /// 画像解析用のCloud Functionsを呼び出す
  Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    try {
      DebugService().log('画像解析開始');
      final preview =
          imageUrl.length > 50 ? imageUrl.substring(0, 50) : imageUrl;
      DebugService().log(
          '送信データ: hasImageUrl=${imageUrl.isNotEmpty}, imageUrlLength=${imageUrl.length}, imageUrlPreview=$preview...');

      final result = await callFunction('analyzeImage', {
        'imageUrl': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });
      DebugService().log('画像解析完了');
      return result as Map<String, dynamic>;
    } catch (e) {
      DebugService().log('画像解析エラー: $e');
      rethrow;
    }
  }

  /// 商品情報取得用のCloud Functionsを呼び出す
  Future<Map<String, dynamic>> getProductInfo(String productId) async {
    try {
      DebugService().log('商品情報取得開始: $productId');

      final result = await callFunction('getProductInfo', {
        'productId': productId,
      });

      DebugService().log('商品情報取得完了');
      return result as Map<String, dynamic>;
    } catch (e) {
      DebugService().log('商品情報取得エラー: $e');
      rethrow;
    }
  }

  /// データ同期用のCloud Functionsを呼び出す
  Future<Map<String, dynamic>> syncData(Map<String, dynamic> syncData) async {
    try {
      DebugService().log('データ同期開始');

      final result = await callFunction('syncData', {
        'syncData': syncData,
        'timestamp': DateTime.now().toIso8601String(),
      });

      DebugService().log('データ同期完了');
      return result as Map<String, dynamic>;
    } catch (e) {
      DebugService().log('データ同期エラー: $e');
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
