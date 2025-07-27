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
      // まずドキュメントが存在するかチェック
      final docRef = _userItemsCollection.doc(item.id);
      final doc = await docRef.get();

      if (doc.exists) {
        // ドキュメントが存在する場合は更新
        final updateData = item.toMap();
        print(
          'アイテム更新: ID=${item.id}, isChecked=${item.isChecked}, データ=$updateData',
        );
        await docRef.update(updateData);
      } else {
        // ドキュメントが存在しない場合は新規作成
        final createData = item.toMap();
        print(
          'アイテム新規作成: ID=${item.id}, isChecked=${item.isChecked}, データ=$createData',
        );
        await docRef.set(createData);
      }
    } catch (e) {
      print('アイテム更新エラー: $e');
      if (e.toString().contains('not-found')) {
        // ドキュメントが見つからない場合は新規作成を試行
        try {
          final createData = item.toMap();
          print(
            'アイテム新規作成（エラー後）: ID=${item.id}, isChecked=${item.isChecked}, データ=$createData',
          );
          await _userItemsCollection.doc(item.id).set(createData);
        } catch (setError) {
          print('アイテム新規作成エラー: $setError');
          rethrow;
        }
      } else {
        rethrow;
      }
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

  // すべてのアイテムを取得（一度だけ）
  Future<List<Item>> getItemsOnce() async {
    try {
      final snapshot = await _userItemsCollection.get();

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        final item = Item.fromMap(data);
        print(
          'アイテム読み込み: ID=${item.id}, isChecked=${item.isChecked}, データ=$data',
        );
        return item;
      }).toList();

      print('総アイテム数: ${items.length}');
      return items;
    } catch (e) {
      print('アイテム取得エラー: $e');
      rethrow;
    }
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
      // まずドキュメントが存在するかチェック
      final docRef = _userShopsCollection.doc(shop.id);
      final doc = await docRef.get();

      if (doc.exists) {
        // ドキュメントが存在する場合は更新
        await docRef.update(shop.toMap());
      } else {
        // ドキュメントが存在しない場合は新規作成
        await docRef.set(shop.toMap());
      }
    } catch (e) {
      print('ショップ更新エラー: $e');
      if (e.toString().contains('not-found')) {
        // ドキュメントが見つからない場合は新規作成を試行
        try {
          await _userShopsCollection.doc(shop.id).set(shop.toMap());
        } catch (setError) {
          print('ショップ新規作成エラー: $setError');
          rethrow;
        }
      } else {
        rethrow;
      }
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

  // すべてのショップを取得（一度だけ）
  Future<List<Shop>> getShopsOnce() async {
    try {
      final snapshot = await _userShopsCollection.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Shop.fromMap(data);
      }).toList();
    } catch (e) {
      print('ショップ取得エラー: $e');
      rethrow;
    }
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

      // ユーザーがログインしていれば同期可能
      return true;
    } catch (e) {
      print('同期状態チェックエラー: $e');
      return false;
    }
  }
}
