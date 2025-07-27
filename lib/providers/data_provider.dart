import 'package:flutter/widgets.dart';
import '../services/data_service.dart';
import '../models/item.dart';
import '../models/shop.dart';

class DataProvider extends ChangeNotifier {
  final DataService _dataService = DataService();

  List<Item> _items = [];
  List<Shop> _shops = [];
  bool _isLoading = false;
  bool _isSynced = false;
  bool _isDataLoaded = false; // キャッシュフラグ

  DataProvider() {
    // 初期化時にデータを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  // デフォルトショップを確保
  void _ensureDefaultShop() {
    if (_shops.isEmpty) {
      final defaultShop = Shop(
        id: '0',
        name: 'デフォルト',
        items: [],
        createdAt: DateTime.now(),
      );
      _shops.add(defaultShop);

      // デフォルトショップをFirebaseに保存
      _dataService.saveShop(defaultShop).catchError((e) {
        print('デフォルトショップ保存エラー: $e');
      });

      notifyListeners();
    }
  }

  List<Item> get items => _items;
  List<Shop> get shops => _shops;
  bool get isLoading => _isLoading;
  bool get isSynced => _isSynced;

  // アイテムの操作
  Future<void> addItem(Item item) async {
    // 重複チェック
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingIndex != -1) {
      await updateItem(item);
      return;
    }

    // 楽観的更新：UIを即座に更新
    final newItem = item.copyWith(
      id: '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}',
      createdAt: DateTime.now(),
    );

    _items.insert(0, newItem);
    notifyListeners(); // 即座にUIを更新

    // バックグラウンドでFirebaseに保存
    try {
      await _dataService.saveItem(newItem);
      _isSynced = true;
    } catch (e) {
      print('アイテム追加エラー: $e');
      _isSynced = false;

      // エラーが発生した場合は追加を取り消し
      _items.removeAt(0);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem(Item item) async {
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
        _shops[i] = shop.copyWith(items: updatedItems);
      }
    }

    notifyListeners(); // 即座にUIを更新

    // バックグラウンドでFirebaseに保存
    try {
      await _dataService.updateItem(item);
      _isSynced = true;
    } catch (e) {
      print('アイテム更新エラー: $e');
      _isSynced = false;

      // エラーが発生した場合は元に戻す
      if (index != -1) {
        _items[index] = _items[index]; // 元の状態に戻す
      }

      // shopsリストも元に戻す
      for (int i = 0; i < _shops.length; i++) {
        final shop = _shops[i];
        final itemIndex = shop.items.indexWhere(
          (shopItem) => shopItem.id == item.id,
        );
        if (itemIndex != -1) {
          final revertedItems = List<Item>.from(shop.items);
          revertedItems[itemIndex] = revertedItems[itemIndex]; // 元のアイテムに戻す
          _shops[i] = shop.copyWith(items: revertedItems);
        }
      }

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
  }

  Future<void> deleteItem(String itemId) async {
    // 楽観的更新：UIを即座に更新
    final itemToDelete = _items.firstWhere((item) => item.id == itemId);
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners(); // 即座にUIを更新

    // バックグラウンドでFirebaseから削除
    try {
      await _dataService.deleteItem(itemId);
      _isSynced = true;
    } catch (e) {
      print('アイテム削除エラー: $e');
      _isSynced = false;

      // エラーが発生した場合は削除を取り消し
      _items.add(itemToDelete);
      notifyListeners();
      rethrow;
    }
  }

  // ショップの操作
  Future<void> addShop(Shop shop) async {
    // 楽観的更新：UIを即座に更新
    final newShop = shop.copyWith(
      id: '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}',
      createdAt: DateTime.now(),
    );

    _shops.insert(0, newShop);
    notifyListeners(); // 即座にUIを更新

    // バックグラウンドでFirebaseに保存
    try {
      await _dataService.saveShop(newShop);
      _isSynced = true;
    } catch (e) {
      print('ショップ追加エラー: $e');
      _isSynced = false;

      // エラーが発生した場合は追加を取り消し
      _shops.removeAt(0);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateShop(Shop shop) async {
    // 楽観的更新：UIを即座に更新
    final index = _shops.indexWhere((s) => s.id == shop.id);
    if (index != -1) {
      _shops[index] = shop;
      notifyListeners(); // 即座にUIを更新
    }

    // バックグラウンドでFirebaseに保存
    try {
      await _dataService.updateShop(shop);
      _isSynced = true;
    } catch (e) {
      print('ショップ更新エラー: $e');
      _isSynced = false;

      // エラーが発生した場合は元に戻す
      if (index != -1) {
        _shops[index] = _shops[index]; // 元の状態に戻す
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

  Future<void> deleteShop(String shopId) async {
    // 楽観的更新：UIを即座に更新
    final shopToDelete = _shops.firstWhere((shop) => shop.id == shopId);
    _shops.removeWhere((shop) => shop.id == shopId);
    notifyListeners(); // 即座にUIを更新

    // バックグラウンドでFirebaseから削除
    try {
      await _dataService.deleteShop(shopId);
      _isSynced = true;
    } catch (e) {
      print('ショップ削除エラー: $e');
      _isSynced = false;

      // エラーが発生した場合は削除を取り消し
      _shops.add(shopToDelete);
      notifyListeners();
      rethrow;
    }
  }

  // データの読み込み
  Future<void> loadData() async {
    // 既にデータが読み込まれている場合はスキップ
    if (_isDataLoaded && _items.isNotEmpty) {
      return;
    }

    _setLoading(true);

    try {
      // アイテムとショップを並行して読み込み
      await Future.wait([_loadItems(), _loadShops()]);

      // デフォルトショップを確保
      _ensureDefaultShop();

      // アイテムをショップに正しく関連付ける
      _associateItemsWithShops();

      // データ読み込みが成功したら同期済みとしてマーク
      _isSynced = true;
      _isDataLoaded = true; // キャッシュフラグを設定
    } catch (e) {
      print('データ読み込みエラー: $e');
      _isSynced = false;

      // エラーが発生してもデフォルトショップは確保
      _ensureDefaultShop();
    } finally {
      _setLoading(false);
      notifyListeners(); // 最後に一度だけ通知
    }
  }

  Future<void> _loadItems() async {
    try {
      // 一度だけ取得するメソッドを使用
      _items = await _dataService.getItemsOnce();
    } catch (e) {
      print('アイテム読み込みエラー: $e');
      rethrow;
    }
  }

  Future<void> _loadShops() async {
    try {
      // 一度だけ取得するメソッドを使用
      _shops = await _dataService.getShopsOnce();
    } catch (e) {
      print('ショップ読み込みエラー: $e');
      rethrow;
    }
  }

  // アイテムをショップに関連付ける
  void _associateItemsWithShops() {
    print('アイテム関連付け開始: 元のアイテム数=${_items.length}');

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
        print('ユニークアイテム追加: ID=${item.id}, isChecked=${item.isChecked}');
      } else {
        print('重複アイテムスキップ: ID=${item.id}, isChecked=${item.isChecked}');
      }
    }

    // ユニークなアイテムをショップに追加
    for (var item in uniqueItems) {
      final shopIndex = shopMap[item.shopId];
      if (shopIndex != null) {
        _shops[shopIndex].items.add(item);
        print(
          'ショップにアイテム追加: ショップID=${item.shopId}, アイテムID=${item.id}, isChecked=${item.isChecked}',
        );
      }
    }

    // 重複が除去されたアイテムリストで更新
    _items = uniqueItems;
    print('アイテム関連付け完了: 最終アイテム数=${_items.length}');
  }

  // データの同期状態をチェック
  Future<void> checkSyncStatus() async {
    try {
      _isSynced = await _dataService.isDataSynced();
      notifyListeners();
    } catch (e) {
      _isSynced = false;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // データをクリア（ログアウト時など）
  void clearData() {
    _items.clear();
    _shops.clear();
    _isSynced = false;
    _isDataLoaded = false; // キャッシュフラグをリセット
    notifyListeners();
  }
}
