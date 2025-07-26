import 'package:flutter/foundation.dart';
import '../services/data_service.dart';
import '../models/item.dart';
import '../models/shop.dart';

class DataProvider extends ChangeNotifier {
  final DataService _dataService = DataService();

  List<Item> _items = [];
  List<Shop> _shops = [];
  bool _isLoading = false;
  bool _isSynced = false;

  List<Item> get items => _items;
  List<Shop> get shops => _shops;
  bool get isLoading => _isLoading;
  bool get isSynced => _isSynced;

  // アイテムの操作
  Future<void> addItem(Item item) async {
    try {
      final newItem = item.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
      );

      await _dataService.saveItem(newItem);
      _items.insert(0, newItem);
      _isSynced = true; // データが保存されたので同期済み
      notifyListeners();
    } catch (e) {
      print('アイテム追加エラー: $e');
      _isSynced = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem(Item item) async {
    try {
      await _dataService.updateItem(item);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = item;
        _isSynced = true; // データが更新されたので同期済み
        notifyListeners();
      }
    } catch (e) {
      print('アイテム更新エラー: $e');
      _isSynced = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _dataService.deleteItem(itemId);
      _items.removeWhere((item) => item.id == itemId);
      _isSynced = true; // データが削除されたので同期済み
      notifyListeners();
    } catch (e) {
      print('アイテム削除エラー: $e');
      _isSynced = false;
      notifyListeners();
      rethrow;
    }
  }

  // ショップの操作
  Future<void> addShop(Shop shop) async {
    try {
      final newShop = shop.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
      );

      await _dataService.saveShop(newShop);
      _shops.insert(0, newShop);
      _isSynced = true; // データが保存されたので同期済み
      notifyListeners();
    } catch (e) {
      print('ショップ追加エラー: $e');
      _isSynced = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateShop(Shop shop) async {
    try {
      await _dataService.updateShop(shop);
      final index = _shops.indexWhere((s) => s.id == shop.id);
      if (index != -1) {
        _shops[index] = shop;
        _isSynced = true; // データが更新されたので同期済み
        notifyListeners();
      }
    } catch (e) {
      print('ショップ更新エラー: $e');
      _isSynced = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteShop(String shopId) async {
    try {
      await _dataService.deleteShop(shopId);
      _shops.removeWhere((shop) => shop.id == shopId);
      _isSynced = true; // データが削除されたので同期済み
      notifyListeners();
    } catch (e) {
      print('ショップ削除エラー: $e');
      _isSynced = false;
      notifyListeners();
      rethrow;
    }
  }

  // データの読み込み
  Future<void> loadData() async {
    _setLoading(true);

    try {
      // アイテムとショップを並行して読み込み
      await Future.wait([_loadItems(), _loadShops()]);

      // データの同期状態を確認
      await checkSyncStatus();
    } catch (e) {
      print('データ読み込みエラー: $e');
      _isSynced = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadItems() async {
    try {
      final itemsStream = _dataService.getItems();
      await for (final items in itemsStream) {
        _items = items;
        notifyListeners();
        break; // 最初のデータを取得したら終了
      }
    } catch (e) {
      print('アイテム読み込みエラー: $e');
      rethrow;
    }
  }

  Future<void> _loadShops() async {
    try {
      final shopsStream = _dataService.getShops();
      await for (final shops in shopsStream) {
        _shops = shops;
        notifyListeners();
        break; // 最初のデータを取得したら終了
      }
    } catch (e) {
      print('ショップ読み込みエラー: $e');
      rethrow;
    }
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
    notifyListeners();
  }
}
