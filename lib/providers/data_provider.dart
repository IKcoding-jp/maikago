// アプリの業務ロジック（一覧/編集/同期/共有合計）を集約し、UI層に通知
import '../services/data_service.dart';
import '../models/item.dart';
import '../models/shop.dart';
import '../models/sort_mode.dart';
// debugPrint用
import 'auth_provider.dart';
import '../drawer/settings/settings_persistence.dart';
import 'dart:async'; // TimeoutException用
import 'package:flutter/foundation.dart'; // kDebugMode用

/// データの状態管理と同期を担う Provider。
/// - アイテム/ショップのCRUD（楽観的更新）
/// - 匿名セッションとログインユーザーの切替
/// - 共有モードの合計/予算の配信（Stream ブロードキャスト）
class DataProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  AuthProvider? _authProvider;
  VoidCallback? _authListener; // 認証リスナーを保持

  List<Item> _items = [];
  List<Shop> _shops = [];
  bool _isLoading = false;
  bool _isSynced = false;
  bool _isDataLoaded = false; // キャッシュフラグ
  bool _isLocalMode = false; // ローカルモードフラグ
  DateTime? _lastSyncTime; // 最終同期時刻
  // 直近で更新を行ったアイテムのIDとタイムスタンプ（楽観更新のバウンス抑止）
  final Map<String, DateTime> _pendingItemUpdates = {};

  // リアルタイム同期用の購読
  StreamSubscription<List<Item>>? _itemsSubscription;
  StreamSubscription<List<Shop>>? _shopsSubscription;

  DataProvider() {
    debugPrint('データプロバイダー: 初期化完了');
  }

  /// 認証プロバイダーを設定し、状態変化に追従してデータ読み直し/クリアを行う
  void setAuthProvider(AuthProvider authProvider) {
    // 同じ認証プロバイダーが既に設定されている場合は何もしない
    if (_authProvider == authProvider) {
      return;
    }

    if (kDebugMode) {
      debugPrint('=== setAuthProvider ===');
      debugPrint(
        '認証プロバイダーを設定: ${authProvider.isLoggedIn ? 'ログイン済み' : '未ログイン'}',
      );
    }

    // 既存のリスナーを削除
    if (_authListener != null) {
      _authProvider?.removeListener(_authListener!);
      _authListener = null;
    }

    _authProvider = authProvider;

    // 認証状態の変更を監視してデータを再読み込み
    _authListener = () {
      debugPrint('認証状態が変更されました: ${authProvider.isLoggedIn ? 'ログイン' : 'ログアウト'}');

      // 認証状態が変更されたらデータを完全にリセット
      if (authProvider.isLoggedIn) {
        debugPrint('ログイン検出: データを完全にリセットして再読み込みします');
        // データを完全にクリアしてから再読み込み
        _resetDataForLogin();
        loadData();
      } else {
        debugPrint('ログアウト検出: データをクリアしてローカルモードに切り替え');
        clearData();
      }
    };

    authProvider.addListener(_authListener!);
  }

  /// ユーザーがアプリ内で税率を修正した際に履歴DB（SharedPreferences）へ保存
  Future<void> saveUserTaxRateOverride(
      String productName, double? taxRate) async {
    // UserTaxHistoryServiceは削除されたため、この機能は一時的に無効化
    debugPrint('税率保存機能は一時的に無効化されています: $productName, $taxRate');
  }

  /// ログイン時のデータ完全リセット
  void _resetDataForLogin() {
    debugPrint('ログイン時のデータ完全リセットを実行');

    // リアルタイム購読を停止
    _cancelRealtimeSync();

    // データを完全にクリア
    _items.clear();
    _shops.clear();
    _pendingItemUpdates.clear();

    // フラグをリセット
    _isSynced = false;
    _isDataLoaded = false;
    _isLocalMode = false; // ログイン時はオンラインモード
    _lastSyncTime = null;

    // UIに即座に通知
    notifyListeners();
  }

  /// 現在のユーザーが匿名セッションを使用すべきかどうか
  bool get _shouldUseAnonymousSession {
    if (_authProvider == null) return false;
    return !_authProvider!.isLoggedIn;
  }

  /// デフォルトショップ（id:'0'）を確保（ローカルモード時のみ自動作成）
  Future<void> _ensureDefaultShop() async {
    // ログイン中（ローカルモードでない）場合はデフォルトショップを自動作成しない
    if (!_isLocalMode) {
      debugPrint('デフォルトショップ自動作成はローカルモード時のみ実行します');
      return;
    }
    // デフォルトショップが削除されているかチェック
    final isDefaultShopDeleted =
        await SettingsPersistence.loadDefaultShopDeleted();

    if (isDefaultShopDeleted) {
      debugPrint('デフォルトショップは削除済みのため作成しません');
      return;
    }

    // 既存のデフォルトショップがあるかチェック
    final hasDefaultShop = _shops.any((shop) => shop.id == '0');

    if (!hasDefaultShop) {
      // デフォルトショップが存在しない場合のみ作成
      final defaultShop = Shop(
        id: '0',
        name: 'デフォルト',
        items: [],
        createdAt: DateTime.now(),
      );
      _shops.add(defaultShop);

      // ローカルモードでない場合のみFirebaseに保存
      if (!_isLocalMode) {
        _dataService
            .saveShop(defaultShop, isAnonymous: _shouldUseAnonymousSession)
            .catchError((e) {
          debugPrint('デフォルトショップ保存エラー: $e');
        });
      }

      // 即座に通知してUIを更新
      notifyListeners();
    }
  }

  List<Item> get items => _items;
  List<Shop> get shops => _shops;
  bool get isLoading => _isLoading;
  bool get isSynced => _isSynced;
  bool get isLocalMode => _isLocalMode;

  /// ローカルモードを設定（true の場合は常に同期済み扱い）
  void setLocalMode(bool isLocal) {
    _isLocalMode = isLocal;
    if (isLocal) {
      _isSynced = true; // ローカルモードでは常に同期済みとして扱う
    }
    notifyListeners();
  }

  // アイテムの操作
  Future<void> addItem(Item item) async {
    debugPrint('🚀 アイテム追加開始: ${item.name}');

    // 商品アイテム数制限チェック（一時的に無効化）
    // if (!_purchaseService.isPremiumUnlocked) {
    //   throw Exception('商品アイテム数の制限に達しました。プレミアムプランにアップグレードしてください。');
    // }

    // 重複チェック（IDが空の場合は新規追加として扱う）
    if (item.id.isNotEmpty) {
      final existingIndex = _items.indexWhere((i) => i.id == item.id);
      if (existingIndex != -1) {
        await updateItem(item);
        return;
      }
    }

    // 新規アイテムを追加
    final newItem = item.copyWith(
      id: item.id.isEmpty
          ? '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}_${_items.length}'
          : item.id,
      createdAt: DateTime.now(),
    );

    // 楽観的更新：UIを即座に更新
    _items.insert(0, newItem);

    // 対応するショップにも追加
    final shopIndex = _shops.indexWhere((shop) => shop.id == newItem.shopId);
    if (shopIndex != -1) {
      _shops[shopIndex].items.add(newItem);
    }

    // UI更新を即座に実行
    notifyListeners();

    // バックグラウンドで非同期処理を実行
    _performBackgroundOperations(newItem, shopIndex);
  }

  /// バックグラウンドで非同期処理を実行（UIブロックを防ぐ）
  Future<void> _performBackgroundOperations(Item newItem, int shopIndex) async {
    try {
      // ローカルモードでない場合のみFirebaseに保存
      if (!_isLocalMode) {
        await _dataService.saveItem(
          newItem,
          isAnonymous: _shouldUseAnonymousSession,
        );
        _isSynced = true;
        debugPrint('✅ アイテム追加完了: ${newItem.name}');
      } else {
        debugPrint('✅ ローカルモードでアイテム追加完了: ${newItem.name}');
      }
    } catch (e) {
      _isSynced = false;
      debugPrint('❌ Firebase保存エラー: $e');

      // エラーが発生した場合は追加を取り消し
      _items.removeAt(0);

      // ショップからも削除
      if (shopIndex != -1) {
        final shop = _shops[shopIndex];
        final revertedItems =
            shop.items.where((item) => item.id != newItem.id).toList();
        _shops[shopIndex] = shop.copyWith(items: revertedItems);
      }

      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem(Item item) async {
    debugPrint('アイテム更新: ${item.name}');

    // バウンス抑止のため保留中リストに追加
    _pendingItemUpdates[item.id] = DateTime.now();

    // 楽観的更新：UIを即座に更新
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }

    // shopsリスト内のアイテムも更新
    for (int i = 0; i < _shops.length; i++) {
      final shop = _shops[i];
      final itemIndex = shop.items.indexWhere(
        (shopItem) => shopItem.id == item.id,
      );
      if (itemIndex != -1) {
        final updatedItems = List<Item>.from(shop.items);
        updatedItems[itemIndex] = item;
        final updatedShop = shop.copyWith(items: updatedItems);
        _shops[i] = updatedShop;
      }
    }

    notifyListeners(); // 即座にUIを更新

    // ローカルモードでない場合のみFirebaseに保存
    if (!_isLocalMode) {
      try {
        await _dataService.updateItem(
          item,
          isAnonymous: _shouldUseAnonymousSession,
        );
        _isSynced = true;
      } catch (e) {
        _isSynced = false;
        debugPrint('Firebase更新エラー: $e');

        // エラーメッセージをユーザーに表示
        if (e.toString().contains('not-found')) {
          throw Exception('アイテムが見つかりませんでした。再度お試しください。');
        } else if (e.toString().contains('permission-denied')) {
          throw Exception('権限がありません。ログイン状態を確認してください。');
        } else {
          throw Exception('アイテムの更新に失敗しました。ネットワーク接続を確認してください。');
        }
      }
      // 保留状態はTTLで自然に消える（数秒間はローカル優先）
    } else {
      // ローカルモードでも保留はTTLで自然消滅
    }
  }

  Future<void> deleteItem(String itemId) async {
    debugPrint('アイテム削除: $itemId');

    // 削除対象のアイテムを事前に取得
    final itemToDelete = _items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('削除対象のアイテムが見つかりません'),
    );

    // 楽観的更新：UIを即座に更新
    _items.removeWhere((item) => item.id == itemId);

    // ショップからも削除
    for (int i = 0; i < _shops.length; i++) {
      final shop = _shops[i];
      final itemIndex = shop.items.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final updatedItems = List<Item>.from(shop.items);
        updatedItems.removeAt(itemIndex);
        _shops[i] = shop.copyWith(items: updatedItems);
      }
    }

    notifyListeners(); // 即座にUIを更新

    // ローカルモードでない場合のみFirebaseから削除
    if (!_isLocalMode) {
      try {
        await _dataService.deleteItem(
          itemId,
          isAnonymous: _shouldUseAnonymousSession,
        );
        _isSynced = true;
      } catch (e) {
        _isSynced = false;
        debugPrint('Firebase削除エラー: $e');

        // エラーが発生した場合は削除を取り消し
        _items.add(itemToDelete);

        // ショップにも復元
        for (int i = 0; i < _shops.length; i++) {
          final shop = _shops[i];
          final itemIndex = shop.items.indexWhere((item) => item.id == itemId);
          if (itemIndex == -1) {
            // アイテムが存在しない場合は追加
            final updatedItems = List<Item>.from(shop.items);
            updatedItems.add(itemToDelete);
            _shops[i] = shop.copyWith(items: updatedItems);
          }
        }

        notifyListeners();

        // エラーメッセージをユーザーに表示
        if (e.toString().contains('not-found')) {
          throw Exception('アイテムが見つかりませんでした。再度お試しください。');
        } else if (e.toString().contains('permission-denied')) {
          throw Exception('権限がありません。ログイン状態を確認してください。');
        } else {
          throw Exception('アイテムの削除に失敗しました。ネットワーク接続を確認してください。');
        }
      }
    }
  }

  /// 複数のアイテムを一括削除（最適化版、並列バッチ）
  Future<void> deleteItems(List<String> itemIds) async {
    debugPrint('一括削除: ${itemIds.length}件');

    // 削除対象のアイテムを事前に取得
    final itemsToDelete = <Item>[];
    for (final itemId in itemIds) {
      try {
        final item = _items.firstWhere((item) => item.id == itemId);
        itemsToDelete.add(item);
      } catch (e) {
        debugPrint('アイテムID $itemId が見つかりません: $e');
      }
    }

    if (itemsToDelete.isEmpty) {
      return;
    }

    // 楽観的更新：UIを即座に更新
    _items.removeWhere((item) => itemIds.contains(item.id));

    // ショップからも一括削除
    for (int i = 0; i < _shops.length; i++) {
      final shop = _shops[i];
      final updatedItems =
          shop.items.where((item) => !itemIds.contains(item.id)).toList();
      if (updatedItems.length != shop.items.length) {
        _shops[i] = shop.copyWith(items: updatedItems);
      }
    }

    notifyListeners(); // 即座にUIを更新

    // ローカルモードでない場合のみFirebaseから一括削除
    if (!_isLocalMode) {
      try {
        // 並列で削除を実行（最大5つずつ）
        const batchSize = 5;
        for (int i = 0; i < itemIds.length; i += batchSize) {
          final batch = itemIds.skip(i).take(batchSize).toList();
          await Future.wait(
            batch.map(
              (itemId) => _dataService.deleteItem(
                itemId,
                isAnonymous: _shouldUseAnonymousSession,
              ),
            ),
          );
        }

        _isSynced = true;
      } catch (e) {
        _isSynced = false;
        debugPrint('Firebase一括削除エラー: $e');

        // エラーが発生した場合は削除を取り消し
        _items.addAll(itemsToDelete);

        // ショップにも復元
        for (int i = 0; i < _shops.length; i++) {
          final shop = _shops[i];
          final updatedItems = List<Item>.from(shop.items);
          for (final item in itemsToDelete) {
            if (!updatedItems.any(
              (existingItem) => existingItem.id == item.id,
            )) {
              updatedItems.add(item);
            }
          }
          _shops[i] = shop.copyWith(items: updatedItems);
        }

        notifyListeners();

        // エラーメッセージをユーザーに表示
        if (e.toString().contains('not-found')) {
          throw Exception('一部のアイテムが見つかりませんでした。再度お試しください。');
        } else if (e.toString().contains('permission-denied')) {
          throw Exception('権限がありません。ログイン状態を確認してください。');
        } else {
          throw Exception('アイテムの削除に失敗しました。ネットワーク接続を確認してください。');
        }
      }
    }
  }

  // ショップの操作
  Future<void> addShop(Shop shop) async {
    debugPrint('ショップ追加: ${shop.name}');

    // デフォルトショップ（ID: '0'）の場合は制限チェックをスキップ
    if (shop.id == '0') {
      Shop newShop = shop.copyWith(createdAt: DateTime.now());
      // デフォルトショップの削除状態をリセット
      await SettingsPersistence.saveDefaultShopDeleted(false);

      _shops.add(newShop);
      notifyListeners(); // 即座にUIを更新

      // ローカルモードでない場合のみFirebaseに保存
      if (!_isLocalMode) {
        try {
          await _dataService.saveShop(
            newShop,
            isAnonymous: _shouldUseAnonymousSession,
          );
          _isSynced = true;
        } catch (e) {
          _isSynced = false;
          debugPrint('Firebase保存エラー: $e');

          // エラーが発生した場合は追加を取り消し
          _shops.removeLast();
          notifyListeners();
          rethrow;
        }
      }
      return;
    }

    // 通常のショップの場合は制限チェックをスキップ（UI側で既にチェック済み）

    // 通常のショップの場合は新しいIDを生成
    final newShop = shop.copyWith(
      id: '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}_${_shops.length}',
      createdAt: DateTime.now(),
    );

    _shops.add(newShop);
    notifyListeners(); // 即座にUIを更新

    // ローカルモードでない場合のみFirebaseに保存
    if (!_isLocalMode) {
      try {
        await _dataService.saveShop(
          newShop,
          isAnonymous: _shouldUseAnonymousSession,
        );
        _isSynced = true;
      } catch (e) {
        _isSynced = false;
        debugPrint('Firebase保存エラー: $e');

        // エラーが発生した場合は追加を取り消し
        _shops.removeLast();

        // デフォルトショップの場合は削除状態を復元
        if (shop.id == '0') {
          await SettingsPersistence.saveDefaultShopDeleted(true);
        }

        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> updateShop(Shop shop) async {
    debugPrint('ショップ更新: ${shop.name}');

    // 楽観的更新：UIを即座に更新
    final index = _shops.indexWhere((s) => s.id == shop.id);
    Shop? originalShop;

    if (index != -1) {
      originalShop = _shops[index]; // 元の状態を保存
      _shops[index] = shop;
      notifyListeners(); // 即座にUIを更新
    }

    // ローカルモードでない場合のみFirebaseに保存
    if (!_isLocalMode) {
      try {
        await _dataService.updateShop(
          shop,
          isAnonymous: _shouldUseAnonymousSession,
        );
        _isSynced = true;
      } catch (e) {
        _isSynced = false;
        debugPrint('Firebase更新エラー: $e');

        // エラーが発生した場合は元に戻す
        if (index != -1 && originalShop != null) {
          _shops[index] = originalShop; // 元の状態に戻す
          notifyListeners();
        }

        // エラーメッセージをユーザーに表示
        if (e.toString().contains('not-found')) {
          throw Exception('ショップが見つかりませんでした。再度お試しください。');
        } else if (e.toString().contains('permission-denied')) {
          throw Exception('権限がありません。ログイン状態を確認してください。');
        } else {
          throw Exception('ショップの更新に失敗しました。ネットワーク接続を確認してください。');
        }
      }
    }
  }

  Future<void> deleteShop(String shopId) async {
    debugPrint('ショップ削除: $shopId');

    // 楽観的更新：UIを即座に更新
    final shopToDelete = _shops.firstWhere(
      (shop) => shop.id == shopId,
      orElse: () => throw Exception('削除対象のショップが見つかりません'),
    );

    _shops.removeWhere((shop) => shop.id == shopId);
    notifyListeners(); // 即座にUIを更新

    // デフォルトショップが削除された場合は状態を記録
    if (shopId == '0') {
      await SettingsPersistence.saveDefaultShopDeleted(true);
      debugPrint('デフォルトショップの削除を記録しました');
    }

    // ローカルモードでない場合のみFirebaseから削除
    if (!_isLocalMode) {
      try {
        await _dataService.deleteShop(
          shopId,
          isAnonymous: _shouldUseAnonymousSession,
        );
        _isSynced = true;
      } catch (e) {
        _isSynced = false;
        debugPrint('Firebase削除エラー: $e');

        // エラーが発生した場合は削除を取り消し
        _shops.add(shopToDelete);

        // デフォルトショップの削除記録も取り消し
        if (shopId == '0') {
          await SettingsPersistence.saveDefaultShopDeleted(false);
        }

        notifyListeners();
        rethrow;
      }
    }
  }

  /// 初回/認証状態変更時のデータ読み込み（キャッシュ/TTLあり）
  Future<void> loadData() async {
    debugPrint('=== loadData ===');
    debugPrint('現在の状態: ローカルモード=$_isLocalMode, データ読み込み済み=$_isDataLoaded');

    bool shouldForceReload = false;

    // 認証状態の変更を検出
    if (_authProvider != null) {
      // 認証状態が変更された場合は強制再読み込み
      if (_lastSyncTime != null) {
        debugPrint('ログイン状態が変更されたため強制再読み込み');
        shouldForceReload = true;
      }
    }

    // 既にデータが読み込まれている場合はスキップ（キャッシュ最適化）
    if (!shouldForceReload && _isDataLoaded && _items.isNotEmpty) {
      // 5分以内の再取得はスキップ（ただし認証状態変更時は除く）
      if (_lastSyncTime != null &&
          DateTime.now().difference(_lastSyncTime!).inMinutes < 5) {
        debugPrint('データは既に読み込まれているためスキップ');
        return;
      }
    }

    _setLoading(true);

    try {
      // 既存データをクリアしてから読み込み
      _items.clear();
      _shops.clear();

      // ローカルモードでない場合のみFirebaseから読み込み
      if (!_isLocalMode) {
        debugPrint('Firebaseからデータを読み込み中...');
        // アイテムとショップを並行して読み込み（30秒でタイムアウト）
        await Future.wait([
          _loadItems(),
          _loadShops(),
        ]).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('データ読み込みタイムアウト');
            throw TimeoutException(
                'データ読み込みがタイムアウトしました', const Duration(seconds: 30));
          },
        );
      } else {
        debugPrint('ローカルモード: Firebase読み込みをスキップ');
      }

      // デフォルトショップを確実に確保（最初に実行）
      await _ensureDefaultShop();

      // アイテムをショップに正しく関連付ける
      _associateItemsWithShops();

      // 最終的な重複チェック
      _removeDuplicateItems();

      // リアルタイム同期開始（ローカルモードでない場合）
      if (!_isLocalMode) {
        debugPrint('リアルタイム同期を開始');
        _startRealtimeSync();
      } else {
        debugPrint('ローカルモード: リアルタイム同期をスキップ');
      }

      // データ読み込みが成功したら同期済みとしてマーク
      _isSynced = true;
      _isDataLoaded = true; // キャッシュフラグを設定
      _lastSyncTime = DateTime.now(); // 同期時刻を記録
      debugPrint('データ読み込み完了: アイテム${_items.length}件、ショップ${_shops.length}件');
    } catch (e) {
      debugPrint('データ読み込みエラー: $e');
      _isSynced = false;

      // エラーが発生してもデフォルトショップは確保
      try {
        await _ensureDefaultShop();
      } catch (ensureError) {
        debugPrint('デフォルトショップ確保エラー: $ensureError');
      }
    } finally {
      _setLoading(false);
      notifyListeners(); // 最後に一度だけ通知
    }
  }

  /// アイテムリストの一括ロード（単発）
  Future<void> _loadItems() async {
    try {
      // 一度だけ取得するメソッドを使用
      _items = await _dataService.getItemsOnce(
        isAnonymous: _shouldUseAnonymousSession,
      );
    } catch (e) {
      debugPrint('アイテム読み込みエラー: $e');
      rethrow;
    }
  }

  /// ショップリストの一括ロード（単発）
  Future<void> _loadShops() async {
    try {
      // 一度だけ取得するメソッドを使用
      _shops = await _dataService.getShopsOnce(
        isAnonymous: _shouldUseAnonymousSession,
      );
    } catch (e) {
      debugPrint('ショップ読み込みエラー: $e');
      rethrow;
    }
  }

  /// アイテムをショップに関連付ける（重複除去とIDインデックス化）
  void _associateItemsWithShops() {
    // 各ショップのアイテムリストをクリア
    for (var shop in _shops) {
      shop.items.clear();
    }

    // ショップIDでインデックスを作成（高速化のため）
    final shopMap = <String, int>{};
    for (int i = 0; i < _shops.length; i++) {
      shopMap[_shops[i].id] = i;
    }

    // アイテムを対応するショップに追加（重複チェック付き）
    final processedItemIds = <String>{};
    final uniqueItems = <Item>[];

    // 重複を除去してユニークなアイテムリストを作成
    for (var item in _items) {
      if (!processedItemIds.contains(item.id)) {
        processedItemIds.add(item.id);
        uniqueItems.add(item);
      }
    }

    // ユニークなアイテムをショップに追加
    for (var item in uniqueItems) {
      final shopIndex = shopMap[item.shopId];
      if (shopIndex != null) {
        _shops[shopIndex].items.add(item);
      }
    }

    // 重複が除去されたアイテムリストで更新
    _items = uniqueItems;
  }

  /// 重複アイテムを除去
  void _removeDuplicateItems() {
    final Map<String, Item> uniqueItemsMap = {};
    final List<Item> uniqueItems = [];

    for (final item in _items) {
      if (!uniqueItemsMap.containsKey(item.id)) {
        uniqueItemsMap[item.id] = item;
        uniqueItems.add(item);
      }
    }

    _items = uniqueItems;
  }

  /// データの同期状態をチェック
  Future<void> checkSyncStatus() async {
    // ローカルモードの場合は常に同期済み
    if (_isLocalMode) {
      _isSynced = true;
      notifyListeners();
      return;
    }

    try {
      _isSynced = await _dataService.isDataSynced();
      notifyListeners();
    } catch (e) {
      debugPrint('同期状態チェックエラー: $e');
      _isSynced = false;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // 外部から安全に通知を送信するメソッド
  void notifyDataChanged() {
    notifyListeners();
  }

  /// データをクリア（ログアウト時など）
  void clearData() {
    debugPrint('=== clearData ===');
    debugPrint('データをクリア中...');

    // リアルタイム購読を停止
    _cancelRealtimeSync();

    // データを完全にクリア
    _items.clear();
    _shops.clear();
    _pendingItemUpdates.clear();

    // フラグをリセット
    _isSynced = false;
    _isDataLoaded = false; // キャッシュフラグをリセット
    _lastSyncTime = null; // 同期時刻をリセット

    // 認証状態に応じてローカルモードを設定
    // セキュリティ根拠: 未ログイン時はローカルモードで動作し、Firestoreへアクセスしない
    _isLocalMode = !(_authProvider?.isLoggedIn ?? false);

    debugPrint('データクリア完了: ローカルモード=$_isLocalMode');
    notifyListeners();
  }

  // 匿名セッションをクリア
  Future<void> clearAnonymousSession() async {
    try {
      await _dataService.clearAnonymousSession();
    } catch (e) {
      debugPrint('匿名セッションクリアエラー: $e');
    }
  }

  // 表示用合計のキャッシュをクリア
  void clearDisplayTotalCache() {
    notifyListeners();
  }

  @override
  void dispose() {
    // 認証リスナーをクリーンアップ
    if (_authListener != null) {
      _authProvider?.removeListener(_authListener!);
      _authListener = null;
    }
    // リアルタイム購読をクリーンアップ
    _cancelRealtimeSync();
    super.dispose();
  }

  // 表示用合計を取得（非同期／簡易版：割引/数量は未考慮）
  Future<int> getDisplayTotal(Shop shop) async {
    // チェック済みアイテムの合計を計算
    final checkedItems = shop.items.where((item) => item.isChecked).toList();
    final total = checkedItems.fold<int>(0, (sum, item) => sum + item.price);

    // 非同期処理をシミュレート（実際のアプリではデータベースクエリなど）
    await Future.delayed(const Duration(milliseconds: 10));

    return total;
  }

  /// リアルタイム同期の開始（items/shops を購読）
  void _startRealtimeSync() {
    debugPrint('=== _startRealtimeSync ===');

    // すでに購読している場合は一旦解除
    _cancelRealtimeSync();

    // ローカルモードの場合は同期をスキップ
    if (_isLocalMode) {
      debugPrint('ローカルモードのためリアルタイム同期をスキップ');
      return;
    }

    try {
      debugPrint('アイテムのリアルタイム同期を開始');
      _itemsSubscription =
          _dataService.getItems(isAnonymous: _shouldUseAnonymousSession).listen(
        (remoteItems) {
          debugPrint('アイテム同期: ${remoteItems.length}件受信');

          // 古い保留をクリーンアップ
          final now = DateTime.now();
          _pendingItemUpdates.removeWhere(
            (_, ts) => now.difference(ts) > const Duration(seconds: 5),
          );

          // 直前にローカルが更新したアイテムは短時間ローカル版を優先
          final currentLocal = List<Item>.from(_items);
          final merged = <Item>[];
          for (final remote in remoteItems) {
            final pendingAt = _pendingItemUpdates[remote.id];
            if (pendingAt != null &&
                now.difference(pendingAt) < const Duration(seconds: 3)) {
              final local = currentLocal.firstWhere(
                (i) => i.id == remote.id,
                orElse: () => remote,
              );
              merged.add(local);
            } else {
              merged.add(remote);
            }
          }

          _items = merged;
          // Shops と関連付けを更新
          _associateItemsWithShops();
          _removeDuplicateItems();
          _isSynced = true;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('アイテム同期エラー: $error');
        },
      );

      debugPrint('ショップのリアルタイム同期を開始');
      _shopsSubscription =
          _dataService.getShops(isAnonymous: _shouldUseAnonymousSession).listen(
        (shops) {
          debugPrint('ショップ同期: ${shops.length}件受信');

          _shops = shops;
          // Items との関連付けを更新
          _associateItemsWithShops();
          _removeDuplicateItems();
          _isSynced = true;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('ショップ同期エラー: $error');
        },
      );

      debugPrint('リアルタイム同期開始完了');
    } catch (e) {
      debugPrint('リアルタイム同期開始エラー: $e');
    }
  }

  /// リアルタイム同期の停止
  void _cancelRealtimeSync() {
    debugPrint('=== _cancelRealtimeSync ===');

    if (_itemsSubscription != null) {
      debugPrint('アイテム同期を停止');
      _itemsSubscription!.cancel();
      _itemsSubscription = null;
    }

    if (_shopsSubscription != null) {
      debugPrint('ショップ同期を停止');
      _shopsSubscription!.cancel();
      _shopsSubscription = null;
    }

    debugPrint('リアルタイム同期停止完了');
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  // ショップ名を更新
  void updateShopName(int index, String newName) {
    if (index >= 0 && index < _shops.length) {
      _shops[index] = _shops[index].copyWith(name: newName);
      if (!_isLocalMode) {
        _dataService.saveShop(
          _shops[index],
          isAnonymous: _shouldUseAnonymousSession,
        );
      }
      notifyListeners();
    }
  }

  // ショップの予算を更新
  void updateShopBudget(int index, int? budget) {
    if (index >= 0 && index < _shops.length) {
      _shops[index] = _shops[index].copyWith(budget: budget);
      if (!_isLocalMode) {
        _dataService.saveShop(
          _shops[index],
          isAnonymous: _shouldUseAnonymousSession,
        );
      }
      notifyListeners();
    }
  }

  // すべてのアイテムを削除
  void clearAllItems(int shopIndex) {
    if (shopIndex >= 0 && shopIndex < _shops.length) {
      _shops[shopIndex] = _shops[shopIndex].copyWith(items: []);
      if (!_isLocalMode) {
        _dataService.saveShop(
          _shops[shopIndex],
          isAnonymous: _shouldUseAnonymousSession,
        );
      }
      notifyListeners();
    }
  }

  // ソートモードを更新
  void updateSortMode(int shopIndex, SortMode sortMode, bool isIncomplete) {
    if (shopIndex >= 0 && shopIndex < _shops.length) {
      if (isIncomplete) {
        _shops[shopIndex] = _shops[shopIndex].copyWith(incSortMode: sortMode);
      } else {
        _shops[shopIndex] = _shops[shopIndex].copyWith(comSortMode: sortMode);
      }
      if (!_isLocalMode) {
        _dataService.saveShop(
          _shops[shopIndex],
          isAnonymous: _shouldUseAnonymousSession,
        );
      }
      notifyListeners();
    }
  }
}
