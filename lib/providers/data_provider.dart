import 'package:flutter/widgets.dart';
import '../services/data_service.dart';
import '../models/item.dart';
import '../models/shop.dart';
// debugPrint用
import 'auth_provider.dart';

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

  DataProvider() {
    debugPrint('=== DataProvider コンストラクタ ===');
    // 初期化時にデータを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('DataProvider: 初期データ読み込みを開始');
      loadData();
    });
  }

  // 認証プロバイダーを設定
  void setAuthProvider(AuthProvider authProvider) {
    debugPrint('=== setAuthProvider ===');
    debugPrint('認証プロバイダーを設定: ${authProvider.isLoggedIn ? 'ログイン済み' : '未ログイン'}');
    _authProvider = authProvider;
  }

  // 現在のユーザーが匿名セッションを使用すべきかどうかを判定
  bool get _shouldUseAnonymousSession {
    if (_authProvider == null) {
      debugPrint('_shouldUseAnonymousSession: 認証プロバイダーがnullのためfalse');
      return false;
    }
    final result = !_authProvider!.isLoggedIn;
    debugPrint(
      '_shouldUseAnonymousSession: ${_authProvider!.isLoggedIn ? 'ログイン済み' : '未ログイン'} -> $result',
    );
    return result;
  }

  // デフォルトショップを確保
  Future<void> _ensureDefaultShop() async {
    debugPrint('=== _ensureDefaultShop ===');

    // 既存のデフォルトショップがあるかチェック
    final existingDefaultShop = _shops
        .where((shop) => shop.id == '0')
        .firstOrNull;

    debugPrint('既存のデフォルトショップ: ${existingDefaultShop?.name}');

    if (existingDefaultShop == null) {
      debugPrint('デフォルトショップが存在しないため作成します');

      // デフォルトショップが存在しない場合のみ作成
      final defaultShop = Shop(
        id: '0',
        name: 'デフォルト',
        items: [],
        createdAt: DateTime.now(),
      );
      _shops.add(defaultShop);

      debugPrint('デフォルトショップを作成: ${defaultShop.name}');

      // ローカルモードでない場合のみFirebaseに保存
      if (!_isLocalMode) {
        _dataService
            .saveShop(defaultShop, isAnonymous: _shouldUseAnonymousSession)
            .catchError((e) {
              // エラーログは本番環境では削除
              debugPrint('デフォルトショップ保存エラー: $e');
            });
      }

      // 即座に通知してUIを更新
      notifyListeners();
    }
  }

  List<Item> get items {
    debugPrint('DataProvider.items: ${_items.length}件');
    return _items;
  }

  List<Shop> get shops {
    debugPrint('DataProvider.shops: ${_shops.length}件');
    return _shops;
  }

  bool get isLoading {
    debugPrint('DataProvider.isLoading: $_isLoading');
    return _isLoading;
  }

  bool get isSynced {
    debugPrint('DataProvider.isSynced: $_isSynced');
    return _isSynced;
  }

  bool get isLocalMode {
    debugPrint('DataProvider.isLocalMode: $_isLocalMode');
    return _isLocalMode;
  }

  // ローカルモードを設定
  void setLocalMode(bool isLocal) {
    debugPrint('=== setLocalMode ===');
    debugPrint('ローカルモード設定: $isLocal');

    _isLocalMode = isLocal;
    if (isLocal) {
      _isSynced = true; // ローカルモードでは常に同期済みとして扱う
      debugPrint('ローカルモードに設定、同期済みとしてマーク');
    } else {
      debugPrint('オンラインモードに設定');
    }
    notifyListeners();
  }

  // アイテムの操作
  Future<void> addItem(Item item) async {
    debugPrint('=== addItem ===');
    debugPrint(
      '追加するアイテム: ${item.name}, ショップID: ${item.shopId}, チェック済み: ${item.isChecked}',
    );

    // 重複チェック（IDが空の場合は新規追加として扱う）
    if (item.id.isNotEmpty) {
      final existingIndex = _items.indexWhere((i) => i.id == item.id);
      if (existingIndex != -1) {
        debugPrint('既存アイテムを更新します');
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

    debugPrint('新しいアイテムID: ${newItem.id}');

    // 楽観的更新：UIを即座に更新
    _items.insert(0, newItem);

    // 対応するショップにも追加
    final shopIndex = _shops.indexWhere((shop) => shop.id == newItem.shopId);
    if (shopIndex != -1) {
      _shops[shopIndex].items.add(newItem);
      debugPrint('ショップ ${_shops[shopIndex].name} にアイテムを追加');
    } else {
      debugPrint('ショップID ${newItem.shopId} が見つかりません');
    }

    // 共有合計を更新（チェック済みアイテムの場合のみ）
    if (newItem.isChecked) {
      debugPrint('チェック済みアイテムのため共有合計を更新');
      // await _updateSharedTotalIfNeeded(); // 共有合計は個別タブごとに管理
    }

    notifyListeners(); // 即座にUIを更新

    // ローカルモードでない場合のみFirebaseに保存
    if (!_isLocalMode) {
      try {
        await _dataService.saveItem(
          newItem,
          isAnonymous: _shouldUseAnonymousSession,
        );
        _isSynced = true;
        debugPrint('Firebaseにアイテムを保存完了');
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
    } else {
      debugPrint('ローカルモードのためFirebase保存をスキップ');
    }
  }

  Future<void> updateItem(Item item) async {
    debugPrint('=== updateItem ===');
    debugPrint(
      '更新するアイテム: ${item.name}, ショップID: ${item.shopId}, チェック済み: ${item.isChecked}',
    );

    // 楽観的更新：UIを即座に更新
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      debugPrint('アイテムリストを更新');
    } else {
      debugPrint('アイテムリストにアイテムが見つかりません');
    }

    // shopsリスト内のアイテムも更新
    for (int i = 0; i < _shops.length; i++) {
      final shop = _shops[i];
      final itemIndex = shop.items.indexWhere(
        (shopItem) => shopItem.id == item.id,
      );
      if (itemIndex != -1) {
        debugPrint('更新前のショップ予算: ${shop.budget}'); // デバッグ用
        final updatedItems = List<Item>.from(shop.items);
        updatedItems[itemIndex] = item;
        final updatedShop = shop.copyWith(items: updatedItems);
        debugPrint('更新後のショップ予算: ${updatedShop.budget}'); // デバッグ用
        _shops[i] = updatedShop;
        debugPrint('ショップ ${shop.name} のアイテムを更新');
      }
    }

    // 共有合計を更新
    debugPrint('共有合計を更新中...');
    // await _updateSharedTotalIfNeeded(); // 共有合計は個別タブごとに管理

    notifyListeners(); // 即座にUIを更新

    // ローカルモードでない場合のみFirebaseに保存
    if (!_isLocalMode) {
      try {
        await _dataService.updateItem(
          item,
          isAnonymous: _shouldUseAnonymousSession,
        );
        _isSynced = true;
        debugPrint('Firebaseにアイテム更新を保存完了');
      } catch (e) {
        _isSynced = false;
        debugPrint('Firebase更新エラー: $e');

        // エラーが発生した場合は元に戻す
        // 注意: 元のアイテムの状態を保持する必要があるため、
        // 実際のアプリケーションでは元のアイテムのバックアップを取る必要があります
        notifyListeners();

        // エラーメッセージをユーザーに表示
        if (e.toString().contains('not-found')) {
          throw Exception('アイテムが見つかりませんでした。再度お試しください。');
        } else if (e.toString().contains('permission-denied')) {
          throw Exception('権限がありません。ログイン状態を確認してください。');
        } else {
          throw Exception('アイテムの更新に失敗しました。ネットワーク接続を確認してください。');
        }
      }
    } else {
      debugPrint('ローカルモードのためFirebase更新をスキップ');
    }
  }

  Future<void> deleteItem(String itemId) async {
    debugPrint('=== deleteItem ===');
    debugPrint('削除するアイテムID: $itemId');

    // 削除対象のアイテムを事前に取得
    final itemToDelete = _items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('削除対象のアイテムが見つかりません'),
    );

    debugPrint(
      '削除するアイテム: ${itemToDelete.name}, チェック済み: ${itemToDelete.isChecked}',
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
        debugPrint('ショップ ${shop.name} からアイテムを削除');
      }
    }

    // 共有合計を更新（削除されたアイテムがチェック済みの場合）
    if (itemToDelete.isChecked) {
      debugPrint('チェック済みアイテムのため共有合計を更新');
      // await _updateSharedTotalIfNeeded(); // 共有合計は個別タブごとに管理
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
        debugPrint('Firebaseからアイテム削除完了');
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
    } else {
      debugPrint('ローカルモードのためFirebase削除をスキップ');
    }
  }

  // ショップの操作
  Future<void> addShop(Shop shop) async {
    debugPrint('=== addShop ===');
    debugPrint('追加するショップ: ${shop.name}, 予算: ${shop.budget}');

    // 楽観的更新：UIを即座に更新
    final newShop = shop.copyWith(
      id: '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}_${_shops.length}',
      createdAt: DateTime.now(),
    );

    debugPrint('作成されたショップ: ${newShop.name}, 予算: ${newShop.budget}');
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
        debugPrint('Firebaseにショップを保存完了');
      } catch (e) {
        _isSynced = false;
        debugPrint('Firebase保存エラー: $e');

        // エラーが発生した場合は追加を取り消し
        _shops.removeLast();
        notifyListeners();
        rethrow;
      }
    } else {
      debugPrint('ローカルモードのためFirebase保存をスキップ');
    }
  }

  Future<void> updateShop(Shop shop) async {
    debugPrint('=== updateShop ===');
    debugPrint('更新するショップ: ${shop.name} (${shop.id})');
    debugPrint('更新前の予算: ${shop.budget}'); // デバッグ用

    // 楽観的更新：UIを即座に更新
    final index = _shops.indexWhere((s) => s.id == shop.id);
    Shop? originalShop;

    if (index != -1) {
      originalShop = _shops[index]; // 元の状態を保存
      debugPrint('元のショップ予算: ${originalShop.budget}'); // デバッグ用
      _shops[index] = shop;
      debugPrint('更新後のショップ予算: ${_shops[index].budget}'); // デバッグ用
      notifyListeners(); // 即座にUIを更新
    } else {
      debugPrint('ショップが見つかりません');
    }

    // ローカルモードでない場合のみFirebaseに保存
    if (!_isLocalMode) {
      try {
        await _dataService.updateShop(
          shop,
          isAnonymous: _shouldUseAnonymousSession,
        );
        _isSynced = true;
        debugPrint('Firebaseにショップ更新を保存完了');
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
    } else {
      debugPrint('ローカルモードのためFirebase更新をスキップ');
    }
  }

  Future<void> deleteShop(String shopId) async {
    debugPrint('=== deleteShop ===');
    debugPrint('削除するショップID: $shopId');

    // 楽観的更新：UIを即座に更新
    final shopToDelete = _shops.firstWhere(
      (shop) => shop.id == shopId,
      orElse: () => throw Exception('削除対象のショップが見つかりません'),
    );
    debugPrint('削除するショップ: ${shopToDelete.name}');

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
        debugPrint('Firebaseからショップ削除完了');
      } catch (e) {
        _isSynced = false;
        debugPrint('Firebase削除エラー: $e');

        // エラーが発生した場合は削除を取り消し
        _shops.add(shopToDelete);
        notifyListeners();
        rethrow;
      }
    } else {
      debugPrint('ローカルモードのためFirebase削除をスキップ');
    }
  }

  // データの読み込み
  Future<void> loadData() async {
    debugPrint('=== loadData ===');

    // 既にデータが読み込まれている場合はスキップ（キャッシュ最適化）
    if (_isDataLoaded && _items.isNotEmpty) {
      // 5分以内の再取得はスキップ
      if (_lastSyncTime != null &&
          DateTime.now().difference(_lastSyncTime!).inMinutes < 5) {
        debugPrint('データは既に読み込まれているためスキップ');
        return;
      }
    }

    debugPrint('データ読み込みを開始');
    _setLoading(true);

    try {
      // 既存データをクリアしてから読み込み
      _items.clear();
      _shops.clear();
      debugPrint('既存データをクリア');

      // ローカルモードでない場合のみFirebaseから読み込み
      if (!_isLocalMode) {
        debugPrint('Firebaseからデータを読み込み中...');
        // アイテムとショップを並行して読み込み
        await Future.wait([_loadItems(), _loadShops()]);
        debugPrint('Firebaseからの読み込み完了');
      } else {
        debugPrint('ローカルモードのためFirebaseからの読み込みをスキップ');
      }

      // デフォルトショップを確実に確保（最初に実行）
      debugPrint('デフォルトショップを確保中...');
      await _ensureDefaultShop();

      // アイテムをショップに正しく関連付ける
      debugPrint('アイテムをショップに関連付け中...');
      _associateItemsWithShops();

      // 最終的な重複チェック
      debugPrint('重複チェック中...');
      _removeDuplicateItems();

      // データ読み込みが成功したら同期済みとしてマーク
      _isSynced = true;
      _isDataLoaded = true; // キャッシュフラグを設定
      _lastSyncTime = DateTime.now(); // 同期時刻を記録
      debugPrint('データ読み込み完了');
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
      debugPrint('=== _loadItems ===');
      // 一度だけ取得するメソッドを使用
      _items = await _dataService.getItemsOnce(
        isAnonymous: _shouldUseAnonymousSession,
      );
      debugPrint('アイテム読み込み完了: ${_items.length}件');
    } catch (e) {
      debugPrint('アイテム読み込みエラー: $e');
      rethrow;
    }
  }

  Future<void> _loadShops() async {
    try {
      debugPrint('=== _loadShops ===');
      // 一度だけ取得するメソッドを使用
      _shops = await _dataService.getShopsOnce(
        isAnonymous: _shouldUseAnonymousSession,
      );
      debugPrint('ショップ読み込み完了: ${_shops.length}件');
    } catch (e) {
      debugPrint('ショップ読み込みエラー: $e');
      rethrow;
    }
  }

  // アイテムをショップに関連付ける
  void _associateItemsWithShops() {
    debugPrint('=== _associateItemsWithShops ===');
    debugPrint('アイテム数: ${_items.length}');
    debugPrint('ショップ数: ${_shops.length}');

    // 各ショップのアイテムリストをクリア
    for (var shop in _shops) {
      shop.items.clear();
    }

    // ショップIDでインデックスを作成（高速化のため）
    final shopMap = <String, int>{};
    for (int i = 0; i < _shops.length; i++) {
      shopMap[_shops[i].id] = i;
    }

    debugPrint('ショップマップ: $shopMap');

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

    debugPrint('ユニークアイテム数: ${uniqueItems.length}');

    // ユニークなアイテムをショップに追加
    for (var item in uniqueItems) {
      final shopIndex = shopMap[item.shopId];
      if (shopIndex != null) {
        _shops[shopIndex].items.add(item);
        debugPrint('アイテム ${item.name} をショップ ${_shops[shopIndex].name} に追加');
      } else {
        debugPrint('アイテム ${item.name} のショップID ${item.shopId} が見つかりません');
      }
    }

    // 重複が除去されたアイテムリストで更新
    _items = uniqueItems;

    debugPrint('関連付け完了');
  }

  // 重複アイテムを除去
  void _removeDuplicateItems() {
    debugPrint('=== _removeDuplicateItems ===');
    debugPrint('重複除去前のアイテム数: ${_items.length}');

    final Map<String, Item> uniqueItemsMap = {};
    final List<Item> uniqueItems = [];

    for (final item in _items) {
      if (!uniqueItemsMap.containsKey(item.id)) {
        uniqueItemsMap[item.id] = item;
        uniqueItems.add(item);
      } else {
        debugPrint('重複アイテムを除去: ${item.name} (ID: ${item.id})');
      }
    }

    _items = uniqueItems;
    debugPrint('重複除去後のアイテム数: ${_items.length}');
  }

  // データの同期状態をチェック
  Future<void> checkSyncStatus() async {
    debugPrint('=== checkSyncStatus ===');

    // ローカルモードの場合は常に同期済み
    if (_isLocalMode) {
      debugPrint('ローカルモードのため同期済みとしてマーク');
      _isSynced = true;
      notifyListeners();
      return;
    }

    try {
      debugPrint('同期状態をチェック中...');
      _isSynced = await _dataService.isDataSynced();
      debugPrint('同期状態: $_isSynced');
      notifyListeners();
    } catch (e) {
      debugPrint('同期状態チェックエラー: $e');
      _isSynced = false;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      debugPrint('_setLoading: $_isLoading -> $loading');
      _isLoading = loading;
      notifyListeners();
    }
  }

  // 外部から安全に通知を送信するメソッド
  void notifyDataChanged() {
    debugPrint('notifyDataChanged: データ変更を通知');
    notifyListeners();
  }

  // データをクリア（ログアウト時など）
  void clearData() {
    debugPrint('=== clearData ===');
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
    debugPrint('=== clearAnonymousSession ===');
    try {
      await _dataService.clearAnonymousSession();
      debugPrint('匿名セッションをクリア完了');
    } catch (e) {
      debugPrint('匿名セッションクリアエラー: $e');
    }
  }

  // 表示用合計のキャッシュをクリア
  void clearDisplayTotalCache() {
    debugPrint('=== clearDisplayTotalCache ===');
    debugPrint('表示用合計のキャッシュをクリア');
    notifyListeners();
  }

  // 表示用合計を取得（非同期）
  Future<int> getDisplayTotal(Shop shop) async {
    debugPrint('=== getDisplayTotal ===');
    debugPrint('ショップ: ${shop.name} の表示用合計を計算中...');

    // チェック済みアイテムの合計を計算
    final checkedItems = shop.items.where((item) => item.isChecked).toList();
    final total = checkedItems.fold<int>(0, (sum, item) => sum + item.price);

    debugPrint('表示用合計: $total (チェック済みアイテム数: ${checkedItems.length})');

    // 非同期処理をシミュレート（実際のアプリではデータベースクエリなど）
    await Future.delayed(Duration(milliseconds: 10));

    return total;
  }

  @override
  void notifyListeners() {
    debugPrint('DataProvider.notifyListeners: リスナーに通知');
    super.notifyListeners();
  }
}
