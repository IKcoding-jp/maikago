import 'package:flutter/foundation.dart';
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

  DataProvider() {
    // 初期化時にデータを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  List<Item> get items => _items;
  List<Shop> get shops => _shops;
  bool get isLoading => _isLoading;
  bool get isSynced => _isSynced;

  // アイテムの操作
  Future<void> addItem(Item item) async {
    // 楽観的更新：UIを即座に更新
    final newItem = item.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      notifyListeners(); // 即座にUIを更新
    }

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
        notifyListeners();
      }

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

      // データ読み込みが成功したら同期済みとしてマーク
      _isSynced = true;
    } catch (e) {
      print('データ読み込みエラー: $e');
      _isSynced = false;
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
