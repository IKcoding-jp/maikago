// Firestore へのCRUD（リスト/ショップ/プロフィール）と匿名セッション管理を担当
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maikago/services/debug_service.dart';
import 'package:maikago/services/data/data_service_base.dart';
import 'package:maikago/services/data/item_data_operations.dart';
import 'package:maikago/services/data/shop_data_operations.dart';

// モデルの再エクスポート（既存のインポートとの互換性維持）
export 'package:maikago/services/data/data_service_base.dart';
export 'package:maikago/services/data/item_data_operations.dart';
export 'package:maikago/services/data/shop_data_operations.dart';

/// データアクセス層。
/// - 認証ユーザー用コレクション: `users/{uid}/items`, `users/{uid}/shops`
/// - 匿名セッション用コレクション: `anonymous/{sessionId}/items`, `anonymous/{sessionId}/shops`
/// - 例外は上位へ再throw し、UI/Provider層でメッセージ整形
///
/// Item CRUD は [ItemDataOperations]、Shop CRUD は [ShopDataOperations] に委譲。
/// プロフィール・同期状態・匿名セッション管理はこのクラスに残す。
class DataService extends DataServiceBase
    with ItemDataOperations, ShopDataOperations {
  /// ユーザープロフィールを保存（merge）
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    // Firebaseが利用できない場合はスキップ
    if (!isFirebaseAvailable) return;

    try {
      final user = auth.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      await firestore.collection('users').doc(user.uid).set({
        ...profile,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザープロフィールを取得
  Future<Map<String, dynamic>?> getUserProfile() async {
    // Firebaseが利用できない場合はnullを返す
    if (!isFirebaseAvailable) return null;

    try {
      final user = auth.currentUser;
      if (user == null) return null;

      final doc = await firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// データの同期状態をチェック（ログインしていれば同期可）
  Future<bool> isDataSynced() async {
    // Firebaseが利用できない場合はfalseを返す
    if (!isFirebaseAvailable) return false;

    try {
      final user = auth.currentUser;
      if (user == null) return false;

      // ユーザーがログインしていれば同期可能
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 匿名セッションIDをクリア
  Future<void> clearAnonymousSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(DataServiceBase.anonymousSessionKey);
    } catch (e) {
      DebugService().logError('匿名セッション削除エラー: $e');
    }
  }
}
