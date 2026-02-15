// アプリの業務ロジック（一覧/編集/同期/共有合計）を集約し、UI層に通知
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
    DebugService().log('データプロバイダー: 初期化完了');
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

    if (kDebugMode) {
      DebugService().log('=== setAuthProvider ===');
      DebugService().log(
        '認証プロバイダーを設定: ${authProvider.isLoggedIn ? 'ログイン済み' : '未ログイン'}',
      );
    }

    if (_authListener != null) {
      _authProvider?.removeListener(_authListener!);
      _authListener = null;
    }

    _authProvider = authProvider;
    _syncAuthState();

    _authListener = () {
      DebugService().log('認証状態が変更されました: ${authProvider.isLoggedIn ? 'ログイン' : 'ログアウト'}');
      _syncAuthState();

      if (authProvider.isLoggedIn) {
        DebugService().log('ログイン検出: データを完全にリセットして再読み込みします');
        _resetDataForLogin();
        loadData();
      } else {
        DebugService().log('ログアウト検出: データをクリアしてローカルモードに切り替え');
        clearData();
      }
    };

    authProvider.addListener(_authListener!);
  }

  Future<void> saveUserTaxRateOverride(
      String productName, double? taxRate) async {
    DebugService().log('税率保存機能は一時的に無効化されています: $productName, $taxRate');
  }

  void _resetDataForLogin() {
    DebugService().log('ログイン時のデータ完全リセットを実行');

    _syncManager.cancelRealtimeSync();

    _cacheManager.clearData();
    _itemRepository.pendingUpdates.clear();

    _state.isSynced = false;
    _cacheManager.setLocalMode(false);

    notifyListeners();
  }

  void _syncAuthState() {
    _state.shouldUseAnonymousSession =
        _authProvider == null ? false : !_authProvider!.isLoggedIn;
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
    await _syncManager.runBatchUpdate(() async {
      await _itemRepository.reorderItems(
        updatedShop,
        updatedItems,
        pendingShopUpdates: _shopRepository.pendingUpdates,
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
    DebugService().log('=== loadData ===');
    DebugService().log(
        '現在の状態: ローカルモード=${_cacheManager.isLocalMode}, データ読み込み済み=${_cacheManager.isDataLoaded}');

    bool shouldForceReload = false;

    if (_authProvider != null) {
      if (_cacheManager.lastSyncTime != null) {
        DebugService().log('ログイン状態が変更されたため強制再読み込み');
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
        DebugService().log('リアルタイム同期を開始');
        _syncManager.startRealtimeSync();
      } else {
        DebugService().log('ローカルモード: リアルタイム同期をスキップ');
      }

      _state.isSynced = true;
      DebugService().log(
          'データ読み込み完了: アイテム${_cacheManager.items.length}件、ショップ${_cacheManager.shops.length}件');
    } catch (e) {
      DebugService().log('データ読み込みエラー: $e');
      _state.isSynced = false;

      try {
        await _shopRepository.ensureDefaultShop();
      } catch (ensureError) {
        DebugService().log('デフォルトショップ確保エラー: $ensureError');
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
      DebugService().log('同期状態チェックエラー: $e');
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

  void clearData() {
    DebugService().log('=== clearData ===');
    DebugService().log('データをクリア中...');

    _syncManager.cancelRealtimeSync();

    _cacheManager.clearData();
    _itemRepository.pendingUpdates.clear();

    _state.isSynced = false;
    _cacheManager.setLocalMode(!(_authProvider?.isLoggedIn ?? false));

    DebugService().log('データクリア完了: ローカルモード=${_cacheManager.isLocalMode}');
    notifyListeners();
  }

  Future<void> clearAnonymousSession() async {
    try {
      await _dataService.clearAnonymousSession();
    } catch (e) {
      DebugService().log('匿名セッションクリアエラー: $e');
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

  Future<int> getDisplayTotal(Shop shop) async {
    return _sharedGroupManager.getDisplayTotal(shop);
  }

  Future<int> getSharedGroupTotal(String sharedGroupId) async {
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
