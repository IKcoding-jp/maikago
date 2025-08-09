// Firestore へのCRUD（アイテム/ショップ/プロフィール）と匿名セッション管理を担当
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../models/shop.dart';
// debugPrintを追加

/// データアクセス層。
/// - 認証ユーザー用コレクション: `users/{uid}/items`, `users/{uid}/shops`
/// - 匿名セッション用コレクション: `anonymous/{sessionId}/items`, `anonymous/{sessionId}/shops`
/// - 例外は上位へ再throw し、UI/Provider層でメッセージ整形
class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _anonymousSessionKey = 'anonymous_session_id';

  /// 匿名セッションIDを取得（未保存なら生成して保存）
  Future<String> _getAnonymousSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString(_anonymousSessionKey);

    if (sessionId == null) {
      // 新しいセッションIDを生成
      sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_anonymousSessionKey, sessionId);
    }

    return sessionId;
  }

  /// 認証ユーザーのアイテムコレクション参照
  CollectionReference<Map<String, dynamic>> get _userItemsCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');
    return _firestore.collection('users').doc(user.uid).collection('items');
  }

  /// 認証ユーザーのショップコレクション参照
  CollectionReference<Map<String, dynamic>> get _userShopsCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');
    return _firestore.collection('users').doc(user.uid).collection('shops');
  }

  /// 匿名セッションのアイテムコレクション参照
  Future<CollectionReference<Map<String, dynamic>>>
  get _anonymousItemsCollection async {
    final sessionId = await _getAnonymousSessionId();
    return _firestore
        .collection('anonymous')
        .doc(sessionId)
        .collection('items');
  }

  /// 匿名セッションのショップコレクション参照
  Future<CollectionReference<Map<String, dynamic>>>
  get _anonymousShopsCollection async {
    final sessionId = await _getAnonymousSessionId();
    return _firestore
        .collection('anonymous')
        .doc(sessionId)
        .collection('shops');
  }

  /// アイテムを保存（認証ユーザー/匿名セッションを切り替え）
  Future<void> saveItem(Item item, {bool isAnonymous = false}) async {
    try {
      if (isAnonymous) {
        final collection = await _anonymousItemsCollection;
        await collection.doc(item.id).set(item.toMap());
      } else {
        final user = _auth.currentUser;
        if (user == null) throw Exception('ユーザーがログインしていません');
        await _userItemsCollection.doc(item.id).set(item.toMap());
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('Firebaseの権限エラーです。セキュリティルールを確認してください。');
      }
      rethrow;
    }
  }

  /// アイテムを更新（存在しない場合は作成）
  Future<void> updateItem(Item item, {bool isAnonymous = false}) async {
    try {
      CollectionReference<Map<String, dynamic>> collection;

      if (isAnonymous) {
        collection = await _anonymousItemsCollection;
      } else {
        collection = _userItemsCollection;
      }

      // まずドキュメントが存在するかチェック
      final docRef = collection.doc(item.id);
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
          CollectionReference<Map<String, dynamic>> collection;
          if (isAnonymous) {
            collection = await _anonymousItemsCollection;
          } else {
            collection = _userItemsCollection;
          }
          final createData = item.toMap();
          await collection.doc(item.id).set(createData);
        } catch (setError) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  /// アイテムを削除（存在しない場合は何もしない）
  Future<void> deleteItem(String itemId, {bool isAnonymous = false}) async {
    try {
      CollectionReference<Map<String, dynamic>> collection;

      if (isAnonymous) {
        collection = await _anonymousItemsCollection;
      } else {
        collection = _userItemsCollection;
      }

      // まずドキュメントが存在するかチェック
      final docRef = collection.doc(itemId);
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

  /// すべてのアイテムを取得（リアルタイム購読）
  Stream<List<Item>> getItems({bool isAnonymous = false}) {
    if (isAnonymous) {
      // 匿名セッションIDのFutureからStreamを作成し、その後snapshotsに展開
      return Stream.fromFuture(_anonymousItemsCollection).asyncExpand(
        (collection) => collection
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return Item.fromMap(data);
              }).toList();
            }),
      );
    } else {
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
  }

  /// すべてのアイテムを取得（一度だけ）
  Future<List<Item>> getItemsOnce({bool isAnonymous = false}) async {
    try {
      CollectionReference<Map<String, dynamic>> collection;

      if (isAnonymous) {
        collection = await _anonymousItemsCollection;
      } else {
        collection = _userItemsCollection;
      }

      final snapshot = await collection.get();

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

  /// ショップを保存
  Future<void> saveShop(Shop shop, {bool isAnonymous = false}) async {
    try {
      if (isAnonymous) {
        final collection = await _anonymousShopsCollection;
        await collection.doc(shop.id).set(shop.toMap());
      } else {
        final user = _auth.currentUser;
        if (user == null) throw Exception('ユーザーがログインしていません');
        await _userShopsCollection.doc(shop.id).set(shop.toMap());
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('Firebaseの権限エラーです。セキュリティルールを確認してください。');
      }
      rethrow;
    }
  }

  /// ショップを更新（存在しない場合は作成）
  Future<void> updateShop(Shop shop, {bool isAnonymous = false}) async {
    try {
      CollectionReference<Map<String, dynamic>> collection;

      if (isAnonymous) {
        collection = await _anonymousShopsCollection;
      } else {
        collection = _userShopsCollection;
      }

      // まずドキュメントが存在するかチェック
      final docRef = collection.doc(shop.id);
      final doc = await docRef.get();

      if (doc.exists) {
        // ドキュメントが存在する場合は更新
        final updateData = <String, dynamic>{};
        final shopMap = shop.toMap();

        // null値を明示的に削除するためにFieldValue.delete()を使用
        shopMap.forEach((key, value) {
          if (value == null) {
            updateData[key] = FieldValue.delete();
          } else {
            updateData[key] = value;
          }
        });

        await docRef.update(updateData);
      } else {
        // ドキュメントが存在しない場合は新規作成
        await docRef.set(shop.toMap());
      }
    } catch (e) {
      if (e.toString().contains('not-found')) {
        // ドキュメントが見つからない場合は新規作成を試行
        try {
          CollectionReference<Map<String, dynamic>> collection;
          if (isAnonymous) {
            collection = await _anonymousShopsCollection;
          } else {
            collection = _userShopsCollection;
          }
          await collection.doc(shop.id).set(shop.toMap());
        } catch (setError) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  /// ショップを削除（存在しない場合は何もしない）
  Future<void> deleteShop(String shopId, {bool isAnonymous = false}) async {
    try {
      CollectionReference<Map<String, dynamic>> collection;

      if (isAnonymous) {
        collection = await _anonymousShopsCollection;
      } else {
        collection = _userShopsCollection;
      }

      // まずドキュメントが存在するかチェック
      final docRef = collection.doc(shopId);
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

  /// すべてのショップを取得（リアルタイム購読）
  Stream<List<Shop>> getShops({bool isAnonymous = false}) {
    if (isAnonymous) {
      return Stream.fromFuture(_anonymousShopsCollection).asyncExpand(
        (collection) => collection
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return Shop.fromMap(data);
              }).toList();
            }),
      );
    } else {
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
  }

  /// すべてのショップを取得（一度だけ）
  Future<List<Shop>> getShopsOnce({bool isAnonymous = false}) async {
    try {
      CollectionReference<Map<String, dynamic>> collection;

      if (isAnonymous) {
        collection = await _anonymousShopsCollection;
      } else {
        collection = _userShopsCollection;
      }

      final snapshot = await collection.get();

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

  /// ユーザープロフィールを保存（merge）
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

  /// ユーザープロフィールを取得
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

  /// データの同期状態をチェック（ログインしていれば同期可）
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

  /// 匿名セッションIDをクリア
  Future<void> clearAnonymousSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_anonymousSessionKey);
    } catch (e) {
      // エラーは無視
    }
  }
}
