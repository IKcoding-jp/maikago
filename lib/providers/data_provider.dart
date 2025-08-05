import 'package:flutter/widgets.dart';
import '../services/data_service.dart';
import '../models/item.dart';
import '../models/shop.dart';
import '../models/sort_mode.dart';
// debugPrint用
import 'auth_provider.dart';
import '../drawer/settings/settings_persistence.dart';
import 'dart:async';

class DataProvider extends ChangeNotifier {
  final DataService _dataService = DataService();
  AuthProvider? _authProvider;

  List<Item> _items = [];
  List<Shop> _shops = [];
  bool _isLoading = false;
  bool _isSynced = false;
  bool _isDataLoaded = false; // キャッシュフラグ
  bool _isLocalMode = false; // ローカルモードフラグ
  DateTime? _lastSyncTime; // 最終同期時刻

  // 共有データ変更の通知用StreamController
  static final StreamController<Map<String, dynamic>>
  _sharedDataStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // 共有データ変更の通知Stream
  static Stream<Map<String, dynamic>> get sharedDataStream =>
      _sharedDataStreamController.stream;

  DataProvider() {
    debugPrint('DataProvider: 初期化完了');
    // 初期化時にデータを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  // 認証プロバイダーを設定
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // 現在のユーザーが匿名セッションを使用すべきかどうかを判定
  bool get _shouldUseAnonymousSession {
    if (_authProvider == null) return false;
    return !_authProvider!.isLoggedIn;
  }

  // デフォルトショップを確保
  Future<void> _ensureDefaultShop() async {
    // 既存のデフォルトショップがあるかチェック
    final existingDefaultShop = _shops
        .where((shop) => shop.id == '0')
        .firstOrNull;

    if (existingDefaultShop == null) {
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

  // ローカルモードを設定
  void setLocalMode(bool isLocal) {
    _isLocalMode = isLocal;
    if (isLocal) {
      _isSynced = true; // ローカルモードでは常に同期済みとして扱う
    }
    notifyListeners();
  }

  // アイテムの操作
  Future<void> addItem(Item item) async {
    debugPrint('アイテム追加: ${item.name}');

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

    notifyListeners(); // 即座にUIを更新

    // 共有合計を更新（アイテム追加時は必ず更新）
    await _updateSharedTotalIfNeeded();

    // ローカルモードでない場合のみFirebaseに保存
    if (!_isLocalMode) {
      try {
        await _dataService.saveItem(
          newItem,
          isAnonymous: _shouldUseAnonymousSession,
        );
        _isSynced = true;
      } catch (e) {
        _isSynced = false;
        debugPrint('Firebase保存エラー: $e');

        // エラーが発生した場合は追加を取り消し
        _items.removeAt(0);

        // ショップからも削除
        if (shopIndex != -1) {
          final shop = _shops[shopIndex];
          final revertedItems = shop.items
              .where((item) => item.id != newItem.id)
              .toList();
          _shops[shopIndex] = shop.copyWith(items: revertedItems);
        }

        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> updateItem(Item item) async {
    debugPrint('アイテム更新: ${item.name}');

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

    // 共有合計を更新（アイテム更新時は必ず更新）
    await _updateSharedTotalIfNeeded();

    // 個別モードでの商品状態変更時の通知
    final isSharedMode = await SettingsPersistence.loadBudgetSharingEnabled();
    if (!isSharedMode) {
      // 個別モードの場合、該当するショップの合計変更を通知
      final shop = _shops.firstWhere(
        (s) => s.items.any((item) => item.id == item.id),
        orElse: () => _shops.first,
      );
      final total = shop.items.where((item) => item.isChecked).fold<int>(0, (
        sum,
        item,
      ) {
        final price = (item.price * (1 - item.discount)).round();
        return sum + (price * item.quantity);
      });

      // 個別合計変更を通知
      _notifyIndividualTotalChanged(shop.id, total);
    }

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

    // 共有合計を更新（アイテム削除時は必ず更新）
    await _updateSharedTotalIfNeeded();

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

  /// 複数のアイテムを一括削除（最適化版）
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
      final updatedItems = shop.items
          .where((item) => !itemIds.contains(item.id))
          .toList();
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

    // 楽観的更新：UIを即座に更新
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
        notifyListeners();
        rethrow;
      }
    }
  }

  // データの読み込み
  Future<void> loadData() async {
    debugPrint('データ読み込み開始');

    // 既にデータが読み込まれている場合はスキップ（キャッシュ最適化）
    if (_isDataLoaded && _items.isNotEmpty) {
      // 5分以内の再取得はスキップ
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
        // アイテムとショップを並行して読み込み
        await Future.wait([_loadItems(), _loadShops()]);
      }

      // デフォルトショップを確実に確保（最初に実行）
      await _ensureDefaultShop();

      // アイテムをショップに正しく関連付ける
      _associateItemsWithShops();

      // 最終的な重複チェック
      _removeDuplicateItems();

      // データ読み込みが成功したら同期済みとしてマーク
      _isSynced = true;
      _isDataLoaded = true; // キャッシュフラグを設定
      _lastSyncTime = DateTime.now(); // 同期時刻を記録
      debugPrint('データ読み込み完了: アイテム${_items.length}件、ショップ${_shops.length}件');
    } catch (e) {
      debugPrint('データ読み込みエラー: $e');
      _isSynced = false;

      // エラーが発生してもデフォルトショップは確保
      await _ensureDefaultShop();
    } finally {
      _setLoading(false);
      notifyListeners(); // 最後に一度だけ通知
    }
  }

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

  // アイテムをショップに関連付ける
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

  // 重複アイテムを除去
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

  // データの同期状態をチェック
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

  // データをクリア（ログアウト時など）
  void clearData() {
    debugPrint('データをクリア中...');

    _items.clear();
    _shops.clear();
    _isSynced = false;
    _isDataLoaded = false; // キャッシュフラグをリセット
    _isLocalMode = false; // ローカルモードフラグをリセット
    _lastSyncTime = null; // 同期時刻をリセット

    debugPrint('データクリア完了');
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

  // 表示用合計を取得（非同期）
  Future<int> getDisplayTotal(Shop shop) async {
    // チェック済みアイテムの合計を計算
    final checkedItems = shop.items.where((item) => item.isChecked).toList();
    final total = checkedItems.fold<int>(0, (sum, item) => sum + item.price);

    // 非同期処理をシミュレート（実際のアプリではデータベースクエリなど）
    await Future.delayed(Duration(milliseconds: 10));

    return total;
  }

  /// 共有モードでの合計金額更新
  Future<void> _updateSharedTotalIfNeeded() async {
    final isSharedMode = await SettingsPersistence.loadBudgetSharingEnabled();
    if (!isSharedMode) return;

    // 全タブのチェック済みアイテムの合計を計算
    int totalSum = 0;
    for (final shop in _shops) {
      for (final item in shop.items.where((item) => item.isChecked)) {
        final price = (item.price * (1 - item.discount)).round();
        totalSum += price * item.quantity;
      }
    }

    // 共有合計を保存
    await SettingsPersistence.saveSharedTotal(totalSum);

    // 各タブにも同じ合計を保存（タブ切り替え時の表示用）
    for (final shop in _shops) {
      await SettingsPersistence.saveTabTotal(shop.id, totalSum);
    }

    // 共有データ変更を全タブに通知
    _notifySharedDataChanged(totalSum);

    // UIを更新するために通知
    notifyListeners();
  }

  /// 共有データ変更の通知を送信
  static void _notifySharedDataChanged(int sharedTotal) {
    _sharedDataStreamController.add({
      'type': 'total_updated',
      'sharedTotal': sharedTotal,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 共有予算変更の通知を送信
  static void notifySharedBudgetChanged(int? sharedBudget) {
    _sharedDataStreamController.add({
      'type': 'budget_updated',
      'sharedBudget': sharedBudget,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 個別予算変更の通知を送信
  static void notifyIndividualBudgetChanged(String shopId, int? budget) {
    _sharedDataStreamController.add({
      'type': 'individual_budget_updated',
      'shopId': shopId,
      'budget': budget,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 個別合計変更の通知を送信
  static void _notifyIndividualTotalChanged(String shopId, int total) {
    _sharedDataStreamController.add({
      'type': 'individual_total_updated',
      'shopId': shopId,
      'total': total,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 共有モードのデータを初期化
  Future<void> initializeSharedModeIfNeeded() async {
    final isSharedMode = await SettingsPersistence.loadBudgetSharingEnabled();

    if (!isSharedMode || _shops.isEmpty) {
      return;
    }

    // 最初のタブの予算を共有予算として初期化
    await SettingsPersistence.initializeSharedBudget(_shops.first.id);

    // 全タブの合計を共有合計として同期
    await _updateSharedTotalIfNeeded();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  // ショップ名を更新
  void updateShopName(int index, String newName) {
    if (index >= 0 && index < _shops.length) {
      _shops[index] = _shops[index].copyWith(name: newName);
      _dataService.saveShop(
        _shops[index],
        isAnonymous: _shouldUseAnonymousSession,
      );
      notifyListeners();
    }
  }

  // ショップの予算を更新
  void updateShopBudget(int index, int? budget) {
    if (index >= 0 && index < _shops.length) {
      _shops[index] = _shops[index].copyWith(budget: budget);
      _dataService.saveShop(
        _shops[index],
        isAnonymous: _shouldUseAnonymousSession,
      );
      notifyListeners();
    }
  }

  // すべてのアイテムを削除
  void clearAllItems(int shopIndex) {
    if (shopIndex >= 0 && shopIndex < _shops.length) {
      _shops[shopIndex] = _shops[shopIndex].copyWith(items: []);
      _dataService.saveShop(
        _shops[shopIndex],
        isAnonymous: _shouldUseAnonymousSession,
      );
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
      _dataService.saveShop(
        _shops[shopIndex],
        isAnonymous: _shouldUseAnonymousSession,
      );
      notifyListeners();
    }
  }
}
