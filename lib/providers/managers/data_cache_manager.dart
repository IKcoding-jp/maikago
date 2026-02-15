// データの保持、キャッシュTTL管理、ローカルモード管理、データロード
import 'dart:async';
import 'package:maikago/services/data_service.dart';
import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/services/debug_service.dart';

/// データのインメモリキャッシュとロードを管理するクラス。
/// - items/shopsの保持
/// - キャッシュTTL管理（5分）
/// - データロード（Firebase/ローカル）
/// - アイテム⇔ショップの関連付け
/// - 重複除去
class DataCacheManager {
  DataCacheManager({
    required DataService dataService,
    required bool Function() shouldUseAnonymousSession,
  })  : _dataService = dataService,
        _shouldUseAnonymousSession = shouldUseAnonymousSession;

  final DataService _dataService;
  final bool Function() _shouldUseAnonymousSession;

  List<ListItem> _items = [];
  List<Shop> _shops = [];
  bool _isDataLoaded = false;
  DateTime? _lastSyncTime;
  bool _isLocalMode = false;

  // --- Getter ---
  List<ListItem> get items => _items;
  List<Shop> get shops => _shops;
  bool get isDataLoaded => _isDataLoaded;
  bool get isLocalMode => _isLocalMode;
  DateTime? get lastSyncTime => _lastSyncTime;

  // --- ローカルモード ---
  void setLocalMode(bool isLocal) {
    _isLocalMode = isLocal;
  }

  // --- データロード ---

  /// 初回/認証状態変更時のデータ読み込み（キャッシュ/TTLあり）
  /// [forceReload] が true の場合はキャッシュを無視して再読み込み
  Future<void> loadData({bool forceReload = false}) async {
    DebugService().log('=== DataCacheManager.loadData ===');
    DebugService().log(
        '現在の状態: ローカルモード=$_isLocalMode, データ読み込み済み=$_isDataLoaded');

    // 既にデータが読み込まれている場合はスキップ（キャッシュ最適化）
    if (!forceReload && _isDataLoaded && _items.isNotEmpty) {
      if (_lastSyncTime != null &&
          DateTime.now().difference(_lastSyncTime!).inMinutes < 5) {
        DebugService().log('データは既に読み込まれているためスキップ');
        return;
      }
    }

    // 既存データをクリアしてから読み込み
    _items.clear();
    _shops.clear();

    // ローカルモードでない場合のみFirebaseから読み込み
    if (!_isLocalMode) {
      DebugService().log('Firebaseからデータを読み込み中...');
      await Future.wait([
        _loadItems(),
        _loadShops(),
      ]).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          DebugService().log('データ読み込みタイムアウト');
          throw TimeoutException(
              'データ読み込みがタイムアウトしました', const Duration(seconds: 30));
        },
      );
    } else {
      DebugService().log('ローカルモード: Firebase読み込みをスキップ');
    }

    _isDataLoaded = true;
    _lastSyncTime = DateTime.now();
    DebugService().log(
        'データ読み込み完了: アイテム${_items.length}件、ショップ${_shops.length}件');
  }

  Future<void> _loadItems() async {
    try {
      _items = await _dataService.getItemsOnce(
        isAnonymous: _shouldUseAnonymousSession(),
      );
    } catch (e) {
      DebugService().log('リスト読み込みエラー: $e');
      rethrow;
    }
  }

  Future<void> _loadShops() async {
    try {
      _shops = await _dataService.getShopsOnce(
        isAnonymous: _shouldUseAnonymousSession(),
      );
    } catch (e) {
      DebugService().log('ショップ読み込みエラー: $e');
      rethrow;
    }
  }

  // --- キャッシュ操作（Item） ---

  void addItemToCache(ListItem item) {
    _items.insert(0, item);
  }

  void updateItemInCache(ListItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
  }

  void removeItemFromCache(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
  }

  /// リアルタイム同期用：アイテムリストを一括置換
  void updateItems(List<ListItem> items) {
    _items = items;
  }

  // --- キャッシュ操作（Shop） ---

  void addShopToCache(Shop shop) {
    _shops.add(shop);
  }

  void updateShopInCache(Shop shop) {
    final index = _shops.indexWhere((s) => s.id == shop.id);
    if (index != -1) {
      _shops[index] = shop;
    }
  }

  void removeShopFromCache(String shopId) {
    _shops.removeWhere((shop) => shop.id == shopId);
  }

  /// リアルタイム同期用：ショップリストを一括置換
  void updateShops(List<Shop> shops) {
    _shops = shops;
  }

  // --- 関連付け・重複除去 ---

  /// アイテムをショップに関連付ける（重複除去とIDインデックス化）
  /// [skipIfBatchUpdating] が true で呼び出し元がバッチ更新中の場合はスキップ
  void associateItemsWithShops({bool skipIfBatchUpdating = false}) {
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
    final uniqueItems = <ListItem>[];

    for (var item in _items) {
      if (!processedItemIds.contains(item.id)) {
        processedItemIds.add(item.id);
        uniqueItems.add(item);
      }
    }

    for (var item in uniqueItems) {
      final shopIndex = shopMap[item.shopId];
      if (shopIndex != null) {
        _shops[shopIndex].items.add(item);
      }
    }

    _items = uniqueItems;
  }

  /// 重複アイテムを除去
  void removeDuplicateItems() {
    final Map<String, ListItem> uniqueItemsMap = {};
    final List<ListItem> uniqueItems = [];

    for (final item in _items) {
      if (!uniqueItemsMap.containsKey(item.id)) {
        uniqueItemsMap[item.id] = item;
        uniqueItems.add(item);
      }
    }

    _items = uniqueItems;
  }

  // --- データクリア ---

  /// データとフラグをすべてクリア
  void clearData() {
    _items.clear();
    _shops.clear();
    _isDataLoaded = false;
    _lastSyncTime = null;
  }

  /// フラグのみリセット（ログイン時のデータ切り替え用）
  void resetFlags() {
    _isDataLoaded = false;
    _lastSyncTime = null;
  }
}
