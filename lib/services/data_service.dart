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
        await docRef.update(updateData);
      } else {
        // ドキュメントが存在しない場合は新規作成
        final createData = item.toMap();
        await docRef.set(createData);
      }
    } catch (e) {
      if (e.toString().contains('not-found')) {
        // ドキュメントが見つからない場合は新規作成を試行
        try {
          final createData = item.toMap();
          await _userItemsCollection.doc(item.id).set(createData);
        } catch (setError) {
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
      // まずドキュメントが存在するかチェック
      final docRef = _userItemsCollection.doc(itemId);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.delete();
      } else {
        // ドキュメントが存在しない場合は成功として扱う
      }
    } catch (e) {
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

      // 重複を除去するためのマップ
      final Map<String, Item> uniqueItemsMap = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final item = Item.fromMap(data);

        // 同じIDのアイテムが既に存在する場合は、より新しい方を保持
        if (uniqueItemsMap.containsKey(item.id)) {
          final existingItem = uniqueItemsMap[item.id]!;
          final itemCreatedAt = item.createdAt ?? DateTime.now();
          final existingCreatedAt = existingItem.createdAt ?? DateTime.now();

          if (itemCreatedAt.isAfter(existingCreatedAt)) {
            uniqueItemsMap[item.id] = item;
          }
        } else {
          uniqueItemsMap[item.id] = item;
        }
      }

      final items = uniqueItemsMap.values.toList();
      return items;
    } catch (e) {
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
      if (e.toString().contains('not-found')) {
        // ドキュメントが見つからない場合は新規作成を試行
        try {
          await _userShopsCollection.doc(shop.id).set(shop.toMap());
        } catch (setError) {
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
      // まずドキュメントが存在するかチェック
      final docRef = _userShopsCollection.doc(shopId);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.delete();
      } else {
        // ドキュメントが存在しない場合は成功として扱う
      }
    } catch (e) {
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

      // 重複を除去するためのマップ
      final Map<String, Shop> uniqueShopsMap = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final shop = Shop.fromMap(data);

        // 同じIDのショップが既に存在する場合は、より新しい方を保持
        if (uniqueShopsMap.containsKey(shop.id)) {
          final existingShop = uniqueShopsMap[shop.id]!;
          final shopCreatedAt = shop.createdAt ?? DateTime.now();
          final existingCreatedAt = existingShop.createdAt ?? DateTime.now();

          if (shopCreatedAt.isAfter(existingCreatedAt)) {
            uniqueShopsMap[shop.id] = shop;
          }
        } else {
          uniqueShopsMap[shop.id] = shop;
        }
      }

      final shops = uniqueShopsMap.values.toList();
      return shops;
    } catch (e) {
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
      return false;
    }
  }
}
