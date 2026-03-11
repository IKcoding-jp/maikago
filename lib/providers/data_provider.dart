// アプリの業務ロジック（一覧/編集/同期/共有合計）を集約し、UI層に通知
import 'dart:async';
import 'package:maikago/services/data_service.dart';
import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/models/sort_mode.dart';
import 'package:maikago/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:maikago/providers/data_provider_state.dart';
import 'package:maikago/providers/managers/data_cache_manager.dart';
import 'package:maikago/providers/managers/realtime_sync_manager.dart';
import 'package:maikago/providers/managers/shared_group_manager.dart';
import 'package:maikago/providers/repositories/item_repository.dart';
import 'package:maikago/providers/repositories/shop_repository.dart';
import 'package:maikago/services/debug_service.dart';
import 'package:maikago/services/settings_persistence.dart';

/// データの状態管理と同期を担う Provider（ファサード）。
/// 各責務を専用クラスに委譲し、外部インターフェースを維持する。
class DataProvider extends ChangeNotifier {
  DataProvider({
    DataService? dataService,
  }) : _dataService = dataService ?? DataService() {
    _state = DataProviderState(
      notifyListeners: () => notifyListeners(),
    );
    _cacheManager = DataCacheManager(
      dataService: _dataService,
      state: _state,
    );
    _itemRepository = ItemRepository(
      dataService: _dataService,
      cacheManager: _cacheManager,
      state: _state,
    );
    _shopRepository = ShopRepository(
      dataService: _dataService,
      cacheManager: _cacheManager,
      state: _state,
    );
    _syncManager = RealtimeSyncManager(
      dataService: _dataService,
      cacheManager: _cacheManager,
      itemRepository: _itemRepository,
      shopRepository: _shopRepository,
      state: _state,
    );
    _sharedGroupManager = SharedGroupManager(
      dataService: _dataService,
      cacheManager: _cacheManager,
      shopRepository: _shopRepository,
      state: _state,
    );
  }

  final DataService _dataService;
  late final DataProviderState _state;
  late final DataCacheManager _cacheManager;
  late final ItemRepository _itemRepository;
  late final ShopRepository _shopRepository;
  late final RealtimeSyncManager _syncManager;
  late final SharedGroupManager _sharedGroupManager;

  AuthProvider? _authProvider;
  VoidCallback? _authListener;

  bool _isLoading = false;

  // --- 認証連携 ---

  void setAuthProvider(AuthProvider authProvider) {
    if (_authProvider == authProvider) return;

    if (_authListener != null) {
      _authProvider?.removeListener(_authListener!);
      _authListener = null;
    }

    _authProvider = authProvider;
    _syncAuthState();

    // ゲスト→ログイン時のデータマイグレーションコールバックを設定
    authProvider.setGuestDataMigrationCallback(() => migrateGuestDataToCloud());

    _authListener = () {
      _syncAuthState();

      if (authProvider.isLoggedIn) {
        DebugService().logInfo('ログイン検出: データを完全にリセットして再読み込みします');
        _resetDataForLogin();
        loadData();
      } else if (authProvider.isGuestMode) {
        DebugService().logInfo('ゲストモード検出: ローカルモードでデータを初期化');
        _initGuestMode();
      } else {
        DebugService().logInfo('ログアウト検出: データをクリアしてローカルモードに切り替え');
        clearData();
      }
    };

    authProvider.addListener(_authListener!);

    // リスナー登録前にnotifyListenersが発火済みの場合に備え、
    // 現在の認証状態に基づいてデータを読み込む
    if (authProvider.isLoggedIn && !authProvider.isLoading) {
      _resetDataForLogin();
      loadData();
    } else if (authProvider.isGuestMode) {
      // アプリ起動時の復元: データクリアせずloadDataでローカルストレージから復元
      _initGuestMode(isRestoredSession: true);
    }
  }

  void _resetDataForLogin() {
    _syncManager.cancelRealtimeSync();

    _cacheManager.clearData();
    _cacheManager.clearLastSyncTime();
    _itemRepository.pendingUpdates.clear();

    _state.isSynced = false;
    _cacheManager.setLocalMode(false);

    notifyListeners();
  }

  /// ゲストモード用の初期化（ローカルモードでデフォルトショップを用意）
  /// [isRestoredSession] が true の場合はデータクリアせず、ローカルストレージから復元する
  Future<void> _initGuestMode({bool isRestoredSession = false}) async {
    _cacheManager.setLocalMode(true);
    _syncManager.cancelRealtimeSync();

    if (!isRestoredSession) {
      // 新規ゲストセッション: データをクリアして新規開始
      _cacheManager.clearData();
    }

    _state.isSynced = true;
    await _shopRepository.ensureDefaultShop();
    _cacheManager.associateItemsWithShops();
    notifyListeners();
  }

  void _syncAuthState() {
    final isGuest = _authProvider?.isGuestMode ?? false;
    final isLoggedIn = _authProvider?.isLoggedIn ?? false;
    _state.shouldUseAnonymousSession = !isLoggedIn && !isGuest;
  }

  // --- Getter ---

  List<ListItem> get items => _cacheManager.items;
  List<Shop> get shops => _cacheManager.shops;
  bool get isLoading => _isLoading;
  bool get isSynced => _state.isSynced;
  bool get isLocalMode => _cacheManager.isLocalMode;

  void setLocalMode(bool isLocal) {
    _cacheManager.setLocalMode(isLocal);
    if (isLocal) {
      _syncManager.cancelRealtimeSync();
      _state.isSynced = true;
    }
    notifyListeners();
  }

  // --- アイテム操作（ItemRepositoryに委譲） ---

  Future<void> addItem(ListItem item) async {
    await _itemRepository.addItem(item);
  }

  Future<void> updateItem(ListItem item) async {
    await _itemRepository.updateItem(item);
  }

  Future<void> updateItemsBatch(List<ListItem> items) async {
    await _syncManager.runBatchUpdate(() async {
      await _itemRepository.updateItemsBatch(
        items,
        pendingShopUpdates: _shopRepository.pendingUpdates,
      );
    });
  }

  Future<void> reorderItems(
      Shop updatedShop, List<ListItem> updatedItems) async {
    // 1. キャッシュを即座に更新（同期）
    _itemRepository.applyReorderToCache(
      updatedShop,
      updatedItems,
      pendingShopUpdates: _shopRepository.pendingUpdates,
    );

    // 2. UI即時反映（isBatchUpdating前なのでオーバーライドにブロックされない）
    super.notifyListeners();

    // 3. Firebase書き込みはバッチ更新で実行（リアルタイム同期の競合を防止）
    await _syncManager.runBatchUpdate(() async {
      await _itemRepository.persistReorderToFirebase(
        updatedShop,
        updatedItems,
      );
    });
  }

  Future<void> deleteItem(String itemId) async {
    await _itemRepository.deleteItem(itemId);
  }

  Future<void> deleteItems(List<String> itemIds) async {
    await _itemRepository.deleteItems(itemIds);
  }

  // --- ショップ操作（ShopRepositoryに委譲） ---

  Future<void> addShop(Shop shop) async {
    await _shopRepository.addShop(shop);
  }

  Future<void> updateShop(Shop shop) async {
    await _shopRepository.updateShop(shop);
  }

  Future<void> deleteShop(String shopId) async {
    await _shopRepository.deleteShop(shopId);
  }

  void updateShopName(int index, String newName) {
    _shopRepository.updateShopName(index, newName);
  }

  void updateShopBudget(int index, int? budget) {
    _shopRepository.updateShopBudget(index, budget);
  }

  void clearAllItems(int shopIndex) {
    _shopRepository.clearAllItems(shopIndex);
  }

  void updateSortMode(int shopIndex, SortMode sortMode, bool isIncomplete) {
    _shopRepository.updateSortMode(shopIndex, sortMode, isIncomplete);
  }

  // --- データロード ---

  Future<void> loadData() async {
    bool shouldForceReload = false;

    if (_authProvider != null) {
      if (_cacheManager.lastSyncTime != null) {
        shouldForceReload = true;
      }
    }

    _setLoading(true);

    try {
      await _cacheManager.loadData(forceReload: shouldForceReload);

      await _shopRepository.ensureDefaultShop();

      _cacheManager.associateItemsWithShops();
      _cacheManager.removeDuplicateItems();

      if (!_cacheManager.isLocalMode) {
        if (!_syncManager.isSubscriptionActive) {
          _syncManager.startRealtimeSync();
        }
      }

      _state.isSynced = true;
      DebugService().logInfo(
          'データ読み込み完了: アイテム${_cacheManager.items.length}件、ショップ${_cacheManager.shops.length}件');
    } catch (e) {
      DebugService().logError('データ読み込みエラー: $e');
      _state.isSynced = false;

      try {
        await _shopRepository.ensureDefaultShop();
      } catch (ensureError) {
        DebugService().logError('デフォルトショップ確保エラー: $ensureError');
      }
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> checkSyncStatus() async {
    if (_cacheManager.isLocalMode) {
      _state.isSynced = true;
      notifyListeners();
      return;
    }

    try {
      _state.isSynced = await _dataService.isDataSynced();
      notifyListeners();
    } catch (e) {
      DebugService().logError('同期状態チェックエラー: $e');
      _state.isSynced = false;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void notifyDataChanged() {
    notifyListeners();
  }

  /// ショップのアイテムを更新してUIに通知する（楽観的更新のロールバック用）
  void updateShopAt(int shopIndex, Shop updatedShop) {
    _cacheManager.shops[shopIndex] = updatedShop;
    notifyListeners();
  }

  /// ゲストモードのローカルデータをFirestoreへマイグレーション
  /// ログイン成功後、ゲストモード終了前に呼ばれる
  Future<void> migrateGuestDataToCloud() async {
    // 1. 現在のローカルデータをキャプチャ
    final localShops = List<Shop>.from(_cacheManager.shops);
    final localItems = List<ListItem>.from(_cacheManager.items);

    if (localShops.isEmpty && localItems.isEmpty) {
      return;
    }

    DebugService().logInfo(
        'マイグレーション開始: ショップ${localShops.length}件、アイテム${localItems.length}件');

    // 2. ローカルモードをオフにしてFirestoreへの書き込みを有効化
    _cacheManager.setLocalMode(false);
    _state.shouldUseAnonymousSession = false;

    try {
      // 3. ショップをFirestoreに保存（デフォルトショップID '0' の競合を考慮）
      for (final shop in localShops) {
        try {
          // 新しいIDでショップを作成（クラウドのデータとの競合を回避）
          final cloudShop = shop.copyWith(
            id: shop.id == '0'
                ? '0' // デフォルトショップはID '0' のまま
                : 'migrated_${shop.id}_${DateTime.now().millisecondsSinceEpoch}',
            createdAt: shop.createdAt ?? DateTime.now(),
          );

          await _dataService.saveShop(
            cloudShop,
            isAnonymous: false,
          );

          // 4. ショップに紐づくアイテムを保存（shopIdを更新）
          final shopItems =
              localItems.where((item) => item.shopId == shop.id).toList();
          for (final item in shopItems) {
            try {
              final cloudItem = item.copyWith(
                shopId: cloudShop.id,
                createdAt: item.createdAt ?? DateTime.now(),
              );
              await _dataService.saveItem(
                cloudItem,
                isAnonymous: false,
              );
            } catch (e) {
              DebugService().logError('アイテム移行失敗（スキップ）: ${item.name} - $e');
            }
          }
        } catch (e) {
          DebugService().logError('ショップ移行失敗（スキップ）: ${shop.name} - $e');
        }
      }

      // マイグレーション成功後、ローカルストレージのゲストデータをクリア
      unawaited(SettingsPersistence.clearGuestData());
      DebugService().logInfo('ゲストデータのFirestoreマイグレーション完了');
    } catch (e) {
      DebugService().logError('マイグレーション中にエラー: $e');
      // マイグレーション失敗してもアプリは動作可能（データは失われる可能性あり）
    }
  }

  void clearData() {
    _syncManager.cancelRealtimeSync();

    _cacheManager.clearData();
    _itemRepository.pendingUpdates.clear();

    _state.isSynced = false;
    final isLoggedIn = _authProvider?.isLoggedIn ?? false;
    final isGuest = _authProvider?.isGuestMode ?? false;
    _cacheManager.setLocalMode(!isLoggedIn || isGuest);

    notifyListeners();
  }

  Future<void> clearAnonymousSession() async {
    try {
      await _dataService.clearAnonymousSession();
    } catch (e) {
      DebugService().logError('匿名セッションクリアエラー: $e');
    }
  }

  void clearDisplayTotalCache() {
    notifyListeners();
  }

  @override
  void dispose() {
    if (_authListener != null) {
      _authProvider?.removeListener(_authListener!);
      _authListener = null;
    }
    _syncManager.cancelRealtimeSync();
    super.dispose();
  }

  // --- 合計・予算計算（SharedGroupManagerに委譲） ---

  int getDisplayTotal(Shop shop) {
    return _sharedGroupManager.getDisplayTotal(shop);
  }

  int getSharedGroupTotal(String sharedGroupId) {
    return _sharedGroupManager.getSharedGroupTotal(sharedGroupId);
  }

  int? getSharedGroupBudget(String sharedGroupId) {
    return _sharedGroupManager.getSharedGroupBudget(sharedGroupId);
  }

  // --- 共有グループ管理（SharedGroupManagerに委譲） ---

  Future<void> updateSharedGroup(String shopId, List<String> selectedTabIds,
      {String? name, String? sharedGroupIcon}) async {
    await _sharedGroupManager.updateSharedGroup(shopId, selectedTabIds,
        name: name, sharedGroupIcon: sharedGroupIcon);
  }

  Future<void> removeFromSharedGroup(String shopId,
      {String? originalSharedGroupId, String? name}) async {
    await _sharedGroupManager.removeFromSharedGroup(shopId,
        originalSharedGroupId: originalSharedGroupId, name: name);
  }

  Future<void> syncSharedGroupBudget(
      String sharedGroupId, int? newBudget) async {
    await _sharedGroupManager.syncSharedGroupBudget(sharedGroupId, newBudget);
  }

  @override
  void notifyListeners() {
    if (_state.isBatchUpdating) return;
    super.notifyListeners();
  }
}
