import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item.dart';
import '../models/shop.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 現在のユーザーのコレクション参照を取得
  CollectionReference<Map<String, dynamic>> get _userItemsCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');
    return _firestore.collection('users').doc(user.uid).collection('items');
  }

  CollectionReference<Map<String, dynamic>> get _userShopsCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');
    return _firestore.collection('users').doc(user.uid).collection('shops');
  }

  // アイテムを保存
  Future<void> saveItem(Item item) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      await _userItemsCollection.doc(item.id).set(item.toMap());
    } catch (e) {
      print('アイテム保存エラー: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception('Firebaseの権限エラーです。セキュリティルールを確認してください。');
      }
      rethrow;
    }
  }

  // アイテムを更新
  Future<void> updateItem(Item item) async {
    try {
      await _userItemsCollection.doc(item.id).update(item.toMap());
    } catch (e) {
      print('アイテム更新エラー: $e');
      rethrow;
    }
  }

  // アイテムを削除
  Future<void> deleteItem(String itemId) async {
    try {
      await _userItemsCollection.doc(itemId).delete();
    } catch (e) {
      print('アイテム削除エラー: $e');
      rethrow;
    }
  }

  // すべてのアイテムを取得
  Stream<List<Item>> getItems() {
    return _userItemsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Item.fromMap(data);
          }).toList();
        });
  }

  // ショップを保存
  Future<void> saveShop(Shop shop) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      await _userShopsCollection.doc(shop.id).set(shop.toMap());
    } catch (e) {
      print('ショップ保存エラー: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception('Firebaseの権限エラーです。セキュリティルールを確認してください。');
      }
      rethrow;
    }
  }

  // ショップを更新
  Future<void> updateShop(Shop shop) async {
    try {
      await _userShopsCollection.doc(shop.id).update(shop.toMap());
    } catch (e) {
      print('ショップ更新エラー: $e');
      rethrow;
    }
  }

  // ショップを削除
  Future<void> deleteShop(String shopId) async {
    try {
      await _userShopsCollection.doc(shopId).delete();
    } catch (e) {
      print('ショップ削除エラー: $e');
      rethrow;
    }
  }

  // すべてのショップを取得
  Stream<List<Shop>> getShops() {
    return _userShopsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Shop.fromMap(data);
          }).toList();
        });
  }

  // ユーザープロフィールを保存
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      await _firestore.collection('users').doc(user.uid).set({
        ...profile,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('プロフィール保存エラー: $e');
      rethrow;
    }
  }

  // ユーザープロフィールを取得
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      print('プロフィール取得エラー: $e');
      return null;
    }
  }

  // データの同期状態をチェック
  Future<bool> isDataSynced() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // アイテムとショップのコレクションが存在するかチェック
      final itemsSnapshot = await _userItemsCollection.limit(1).get();
      final shopsSnapshot = await _userShopsCollection.limit(1).get();

      // 少なくとも1つのコレクションにデータがあるか、または両方とも空であることを確認
      return true; // ユーザーがログインしていれば同期可能
    } catch (e) {
      print('同期状態チェックエラー: $e');
      return false;
    }
  }
}
