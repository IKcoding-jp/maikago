// Firestore Streamの購読、楽観的更新との競合回避、バッチ更新制御
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/data_service.dart';
import '../../models/list.dart';
import '../../models/shop.dart';
import '../managers/data_cache_manager.dart';
import '../repositories/item_repository.dart';
import '../repositories/shop_repository.dart';

/// リアルタイム同期とバッチ更新制御を管理するクラス。
/// - Firestore Streamの購読（items/shops）
/// - 楽観的更新との競合回避（バウンス抑止）
/// - バッチ更新中の同期スキップ
class RealtimeSyncManager {
  final DataService _dataService;
  final DataCacheManager _cacheManager;
  final ItemRepository _itemRepository;
  final ShopRepository _shopRepository;
  final bool Function() _shouldUseAnonymousSession;
  final VoidCallback _notifyListeners;
  final void Function(bool) _setSynced;

  // リアルタイム同期用の購読
  StreamSubscription<List<ListItem>>? _itemsSubscription;
  StreamSubscription<List<Shop>>? _shopsSubscription;

  // バッチ更新中フラグ（並べ替え処理中はnotifyListeners()を抑制）
  bool _isBatchUpdating = false;
  bool get isBatchUpdating => _isBatchUpdating;

  RealtimeSyncManager({
    required DataService dataService,
    required DataCacheManager cacheManager,
    required ItemRepository itemRepository,
    required ShopRepository shopRepository,
    required bool Function() shouldUseAnonymousSession,
    required VoidCallback notifyListeners,
    required void Function(bool) setSynced,
  })  : _dataService = dataService,
        _cacheManager = cacheManager,
        _itemRepository = itemRepository,
        _shopRepository = shopRepository,
        _shouldUseAnonymousSession = shouldUseAnonymousSession,
        _notifyListeners = notifyListeners,
        _setSynced = setSynced;

  // --- バッチ更新制御 ---

  /// バッチ更新を実行（notifyListeners抑制付き）
  Future<T> runBatchUpdate<T>(Future<T> Function() operation) async {
    _isBatchUpdating = true;
    try {
      return await operation();
    } finally {
      _isBatchUpdating = false;
      _notifyListeners();
    }
  }

  // --- リアルタイム同期 ---

  /// リアルタイム同期の開始（items/shops を購読）
  void startRealtimeSync() {
    debugPrint('=== _startRealtimeSync ===');

    // すでに購読している場合は一旦解除
    cancelRealtimeSync();

    // ローカルモードの場合は同期をスキップ
    if (_cacheManager.isLocalMode) {
      debugPrint('ローカルモードのためリアルタイム同期をスキップ');
      return;
    }

    try {
      debugPrint('アイテムのリアルタイム同期を開始');
      _itemsSubscription = _dataService
          .getItems(isAnonymous: _shouldUseAnonymousSession())
          .listen(
        (remoteItems) {
          debugPrint('リスト同期: ${remoteItems.length}件受信');

          // バッチ更新中はリアルタイム同期を完全に無視
          if (_isBatchUpdating) {
            debugPrint('バッチ更新中のためリアルタイム同期をスキップ');
            return;
          }

          // 古い保留をクリーンアップ
          final now = DateTime.now();
          _itemRepository.pendingUpdates.removeWhere(
            (_, ts) => now.difference(ts) > const Duration(seconds: 10),
          );

          // 直前にローカルが更新したアイテムは短時間ローカル版を優先
          final currentLocal = List<ListItem>.from(_cacheManager.items);
          final merged = <ListItem>[];
          for (final remote in remoteItems) {
            final pendingAt = _itemRepository.pendingUpdates[remote.id];
            if (pendingAt != null &&
                now.difference(pendingAt) < const Duration(seconds: 10)) {
              final local = currentLocal.firstWhere(
                (i) => i.id == remote.id,
                orElse: () => remote,
              );
              merged.add(local);
            } else {
              merged.add(remote);
            }
          }

          _cacheManager.updateItems(merged);
          _cacheManager.associateItemsWithShops();
          _cacheManager.removeDuplicateItems();
          _setSynced(true);
          _notifyListeners();
        },
        onError: (error) {
          debugPrint('リスト同期エラー: $error');
        },
      );

      debugPrint('ショップのリアルタイム同期を開始');
      _shopsSubscription = _dataService
          .getShops(isAnonymous: _shouldUseAnonymousSession())
          .listen(
        (remoteShops) {
          debugPrint('ショップ同期: ${remoteShops.length}件受信');

          // バッチ更新中はリアルタイム同期を完全に無視
          if (_isBatchUpdating) {
            debugPrint('バッチ更新中のためショップ同期をスキップ');
            return;
          }

          // 古い保留をクリーンアップ
          final now = DateTime.now();
          _shopRepository.pendingUpdates.removeWhere(
            (_, ts) => now.difference(ts) > const Duration(seconds: 10),
          );

          // 直前にローカルが更新したショップは短時間ローカル版を優先
          final currentLocal = List<Shop>.from(_cacheManager.shops);
          final merged = <Shop>[];
          for (final remote in remoteShops) {
            final pendingAt = _shopRepository.pendingUpdates[remote.id];
            if (pendingAt != null &&
                now.difference(pendingAt) < const Duration(seconds: 10)) {
              final local = currentLocal.firstWhere(
                (s) => s.id == remote.id,
                orElse: () => remote,
              );
              merged.add(local);
            } else {
              merged.add(remote);
            }
          }

          _cacheManager.updateShops(merged);
          _cacheManager.associateItemsWithShops();
          _cacheManager.removeDuplicateItems();
          _setSynced(true);
          _notifyListeners();
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
  void cancelRealtimeSync() {
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
}
