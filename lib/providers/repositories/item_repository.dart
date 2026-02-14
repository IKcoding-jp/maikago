// アイテムのCRUD操作、楽観的更新、ロールバック
import 'package:flutter/foundation.dart';
import '../../services/data_service.dart';
import '../../models/list.dart';
import '../managers/data_cache_manager.dart';

/// アイテムのCRUD操作を管理するリポジトリ。
/// - 楽観的更新（即座にキャッシュを更新し、バックグラウンドでFirebase保存）
/// - バウンス抑止（保留中のアイテムIDを追跡）
/// - エラー時のロールバック
class ItemRepository {
  final DataService _dataService;
  final DataCacheManager _cacheManager;
  final bool Function() _shouldUseAnonymousSession;
  final VoidCallback _notifyListeners;
  final void Function(bool) _setSynced;

  /// 直近で更新を行ったアイテムのIDとタイムスタンプ（楽観更新のバウンス抑止）
  final Map<String, DateTime> pendingUpdates = {};

  ItemRepository({
    required DataService dataService,
    required DataCacheManager cacheManager,
    required bool Function() shouldUseAnonymousSession,
    required VoidCallback notifyListeners,
    required void Function(bool) setSynced,
  })  : _dataService = dataService,
        _cacheManager = cacheManager,
        _shouldUseAnonymousSession = shouldUseAnonymousSession,
        _notifyListeners = notifyListeners,
        _setSynced = setSynced;

  // --- アイテム追加 ---

  Future<void> addItem(ListItem item) async {
    debugPrint('🚀 リスト追加開始: ${item.name}');

    // 重複チェック（IDが空の場合は新規追加として扱う）
    if (item.id.isNotEmpty) {
      final existingIndex =
          _cacheManager.items.indexWhere((i) => i.id == item.id);
      if (existingIndex != -1) {
        await updateItem(item);
        return;
      }
    }

    // 新規アイテムを追加
    final newItem = item.copyWith(
      id: item.id.isEmpty
          ? '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}_${_cacheManager.items.length}'
          : item.id,
      createdAt: DateTime.now(),
    );

    // 楽観的更新：UIを即座に更新
    _cacheManager.addItemToCache(newItem);

    // 対応するショップにも追加
    final shopIndex =
        _cacheManager.shops.indexWhere((shop) => shop.id == newItem.shopId);
    if (shopIndex != -1) {
      _cacheManager.shops[shopIndex].items.add(newItem);
    }

    // UI更新を即座に実行
    _notifyListeners();

    // バックグラウンドで非同期処理を実行
    await _performBackgroundSave(newItem, shopIndex);
  }

  /// バックグラウンドでFirebase保存を実行（UIブロックを防ぐ）
  Future<void> _performBackgroundSave(
      ListItem newItem, int shopIndex) async {
    try {
      // ローカルモードでない場合のみFirebaseに保存
      if (!_cacheManager.isLocalMode) {
        await _dataService.saveItem(
          newItem,
          isAnonymous: _shouldUseAnonymousSession(),
        );
        _setSynced(true);
        debugPrint('✅ アイテム追加完了: ${newItem.name}');
      } else {
        debugPrint('✅ ローカルモードでアイテム追加完了: ${newItem.name}');
      }
    } catch (e) {
      _setSynced(false);
      debugPrint('❌ Firebase保存エラー: $e');

      // エラーが発生した場合は追加を取り消し
      _cacheManager.items.removeAt(0);

      // ショップからも削除
      if (shopIndex != -1) {
        final shop = _cacheManager.shops[shopIndex];
        final revertedItems =
            shop.items.where((item) => item.id != newItem.id).toList();
        _cacheManager.shops[shopIndex] = shop.copyWith(items: revertedItems);
      }

      _notifyListeners();
      rethrow;
    }
  }

  // --- アイテム更新 ---

  Future<void> updateItem(ListItem item) async {
    debugPrint('リスト更新: ${item.name}');

    // バウンス抑止のため保留中リストに追加
    pendingUpdates[item.id] = DateTime.now();

    // 楽観的更新：UIを即座に更新
    _cacheManager.updateItemInCache(item);

    // shopsリスト内のアイテムも更新
    for (int i = 0; i < _cacheManager.shops.length; i++) {
      final shop = _cacheManager.shops[i];
      final itemIndex = shop.items.indexWhere(
        (shopItem) => shopItem.id == item.id,
      );
      if (itemIndex != -1) {
        final updatedItems = List<ListItem>.from(shop.items);
        updatedItems[itemIndex] = item;
        final updatedShop = shop.copyWith(items: updatedItems);
        _cacheManager.shops[i] = updatedShop;
      }
    }

    _notifyListeners(); // 即座にUIを更新

    // ローカルモードでない場合のみFirebaseに保存
    if (!_cacheManager.isLocalMode) {
      try {
        await _dataService.updateItem(
          item,
          isAnonymous: _shouldUseAnonymousSession(),
        );
        _setSynced(true);
      } catch (e) {
        _setSynced(false);
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

  // --- バッチ更新 ---

  /// 複数のアイテムをバッチで更新（並べ替え処理用）
  /// DataProviderが_isBatchUpdatingフラグの管理とnotifyListenersを行う
  Future<void> updateItemsBatch(
    List<ListItem> items, {
    required Map<String, DateTime> pendingShopUpdates,
  }) async {
    debugPrint('バッチ更新開始: ${items.length}個のリスト');

    // 事前に全アイテムIDを保留リストに登録（Firebase保存前）
    final now = DateTime.now();
    for (final item in items) {
      pendingUpdates[item.id] = now;
    }

    // 楽観的更新：UIを即座に更新
    for (final item in items) {
      final index =
          _cacheManager.items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _cacheManager.items[index] = item;
      }
    }

    // shopsリスト内のアイテムも更新
    for (int i = 0; i < _cacheManager.shops.length; i++) {
      final shop = _cacheManager.shops[i];
      bool hasChanges = false;
      final updatedItems = List<ListItem>.from(shop.items);

      for (final item in items) {
        final itemIndex = updatedItems.indexWhere(
          (shopItem) => shopItem.id == item.id,
        );
        if (itemIndex != -1) {
          updatedItems[itemIndex] = item;
          hasChanges = true;
        }
      }

      if (hasChanges) {
        _cacheManager.shops[i] = shop.copyWith(items: updatedItems);
        // shopも保護リストに追加（リアルタイム同期による上書きを防ぐ）
        pendingShopUpdates[shop.id] = now;
      }
    }

    // ローカルモードでない場合のみFirebaseに保存
    if (!_cacheManager.isLocalMode) {
      try {
        // 並列で更新を実行（最大5つずつ）
        const batchSize = 5;
        for (int i = 0; i < items.length; i += batchSize) {
          final batch = items.skip(i).take(batchSize);
          await Future.wait(
            batch.map((item) => _dataService.updateItem(
                  item,
                  isAnonymous: _shouldUseAnonymousSession(),
                )),
          );
        }
        _setSynced(true);
      } catch (e) {
        _setSynced(false);
        debugPrint('Firebaseバッチ更新エラー: $e');
        rethrow;
      }
    }
  }

  // --- アイテム削除 ---

  Future<void> deleteItem(String itemId) async {
    debugPrint('リスト削除: $itemId');

    // 削除対象のアイテムを事前に取得
    final itemToDelete = _cacheManager.items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('削除対象のアイテムが見つかりません'),
    );

    // 楽観的更新：UIを即座に更新
    _cacheManager.removeItemFromCache(itemId);

    // ショップからも削除
    for (int i = 0; i < _cacheManager.shops.length; i++) {
      final shop = _cacheManager.shops[i];
      final itemIndex = shop.items.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final updatedItems = List<ListItem>.from(shop.items);
        updatedItems.removeAt(itemIndex);
        _cacheManager.shops[i] = shop.copyWith(items: updatedItems);
      }
    }

    _notifyListeners(); // 即座にUIを更新

    // ローカルモードでない場合のみFirebaseから削除
    if (!_cacheManager.isLocalMode) {
      try {
        await _dataService.deleteItem(
          itemId,
          isAnonymous: _shouldUseAnonymousSession(),
        );
        _setSynced(true);
      } catch (e) {
        _setSynced(false);
        debugPrint('Firebase削除エラー: $e');

        // エラーが発生した場合は削除を取り消し
        _cacheManager.items.add(itemToDelete);

        // ショップにも復元
        for (int i = 0; i < _cacheManager.shops.length; i++) {
          final shop = _cacheManager.shops[i];
          final existingIndex =
              shop.items.indexWhere((item) => item.id == itemId);
          if (existingIndex == -1) {
            // アイテムが存在しない場合は追加
            final updatedItems = List<ListItem>.from(shop.items);
            updatedItems.add(itemToDelete);
            _cacheManager.shops[i] = shop.copyWith(items: updatedItems);
          }
        }

        _notifyListeners();

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

  // --- 一括削除 ---

  /// 複数のアイテムを一括削除（最適化版、並列バッチ）
  Future<void> deleteItems(List<String> itemIds) async {
    debugPrint('一括削除: ${itemIds.length}件');

    // 削除対象のアイテムを事前に取得
    final itemsToDelete = <ListItem>[];
    for (final itemId in itemIds) {
      try {
        final item =
            _cacheManager.items.firstWhere((item) => item.id == itemId);
        itemsToDelete.add(item);
      } catch (e) {
        debugPrint('アイテムID $itemId が見つかりません: $e');
      }
    }

    if (itemsToDelete.isEmpty) {
      return;
    }

    // 楽観的更新：UIを即座に更新
    _cacheManager.items.removeWhere((item) => itemIds.contains(item.id));

    // ショップからも一括削除
    for (int i = 0; i < _cacheManager.shops.length; i++) {
      final shop = _cacheManager.shops[i];
      final updatedItems =
          shop.items.where((item) => !itemIds.contains(item.id)).toList();
      if (updatedItems.length != shop.items.length) {
        _cacheManager.shops[i] = shop.copyWith(items: updatedItems);
      }
    }

    _notifyListeners(); // 即座にUIを更新

    // ローカルモードでない場合のみFirebaseから一括削除
    if (!_cacheManager.isLocalMode) {
      try {
        // 並列で削除を実行（最大5つずつ）
        const batchSize = 5;
        for (int i = 0; i < itemIds.length; i += batchSize) {
          final batch = itemIds.skip(i).take(batchSize).toList();
          await Future.wait(
            batch.map(
              (itemId) => _dataService.deleteItem(
                itemId,
                isAnonymous: _shouldUseAnonymousSession(),
              ),
            ),
          );
        }

        _setSynced(true);
      } catch (e) {
        _setSynced(false);
        debugPrint('Firebase一括削除エラー: $e');

        // エラーが発生した場合は削除を取り消し
        _cacheManager.items.addAll(itemsToDelete);

        // ショップにも復元
        for (int i = 0; i < _cacheManager.shops.length; i++) {
          final shop = _cacheManager.shops[i];
          final updatedItems = List<ListItem>.from(shop.items);
          for (final item in itemsToDelete) {
            if (!updatedItems.any(
              (existingItem) => existingItem.id == item.id,
            )) {
              updatedItems.add(item);
            }
          }
          _cacheManager.shops[i] = shop.copyWith(items: updatedItems);
        }

        _notifyListeners();

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
}
