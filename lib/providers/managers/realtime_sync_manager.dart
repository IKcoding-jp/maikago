// Firestore Streamの購読、楽観的更新との競合回避、バッチ更新制御
import 'dart:async';
import 'dart:math' as math;
import 'package:maikago/services/data_service.dart';
import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/providers/data_provider_state.dart';
import 'package:maikago/providers/managers/data_cache_manager.dart';
import 'package:maikago/providers/repositories/item_repository.dart';
import 'package:maikago/providers/repositories/shop_repository.dart';
import 'package:maikago/services/debug_service.dart';

/// リアルタイム同期とバッチ更新制御を管理するクラス。
/// - Firestore Streamの購読（items/shops）
/// - 楽観的更新との競合回避（バウンス抑止）
/// - バッチ更新中の同期スキップ
class RealtimeSyncManager {
  RealtimeSyncManager({
    required DataService dataService,
    required DataCacheManager cacheManager,
    required ItemRepository itemRepository,
    required ShopRepository shopRepository,
    required DataProviderState state,
  })  : _dataService = dataService,
        _cacheManager = cacheManager,
        _itemRepository = itemRepository,
        _shopRepository = shopRepository,
        _state = state;

  final DataService _dataService;
  final DataCacheManager _cacheManager;
  final ItemRepository _itemRepository;
  final ShopRepository _shopRepository;
  final DataProviderState _state;

  // リアルタイム同期用の購読
  StreamSubscription<List<ListItem>>? _itemsSubscription;
  StreamSubscription<List<Shop>>? _shopsSubscription;

  // 購読状態追跡
  bool _isSubscriptionActive = false;

  // リトライ制御
  int _retryCount = 0;
  static const int _maxRetries = 5;
  Timer? _retryTimer;

  /// リアルタイム購読がアクティブかどうか
  bool get isSubscriptionActive => _isSubscriptionActive;

  // --- バッチ更新制御 ---

  /// バッチ更新を実行（notifyListeners抑制付き）
  Future<T> runBatchUpdate<T>(Future<T> Function() operation) async {
    _state.isBatchUpdating = true;
    try {
      return await operation();
    } finally {
      _state.isBatchUpdating = false;
      _state.notifyListeners();
    }
  }

  // --- リアルタイム同期 ---

  /// リアルタイム同期の開始（items/shops を購読）
  void startRealtimeSync() {
    DebugService().log('=== _startRealtimeSync ===');

    // すでに購読している場合は一旦解除
    cancelRealtimeSync();

    // ローカルモードの場合は同期をスキップ
    if (_cacheManager.isLocalMode) {
      DebugService().log('ローカルモードのためリアルタイム同期をスキップ');
      return;
    }

    try {
      DebugService().log('アイテムのリアルタイム同期を開始');
      _itemsSubscription = _dataService
          .getItems(isAnonymous: _state.shouldUseAnonymousSession)
          .listen(
        (remoteItems) {
          DebugService().log('リスト同期: ${remoteItems.length}件受信');
          _resetRetryCount();

          // バッチ更新中はリアルタイム同期を完全に無視
          if (_state.isBatchUpdating) {
            DebugService().log('バッチ更新中のためリアルタイム同期をスキップ');
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
          _state.isSynced = true;
          _state.notifyListeners();
        },
        onError: (error) {
          DebugService().log('リスト同期エラー: $error');
          _onSubscriptionError();
        },
        onDone: () {
          DebugService().log('リスト同期ストリームが終了しました');
          _onSubscriptionError();
        },
      );

      DebugService().log('ショップのリアルタイム同期を開始');
      _shopsSubscription = _dataService
          .getShops(isAnonymous: _state.shouldUseAnonymousSession)
          .listen(
        (remoteShops) {
          DebugService().log('ショップ同期: ${remoteShops.length}件受信');
          _resetRetryCount();

          // バッチ更新中はリアルタイム同期を完全に無視
          if (_state.isBatchUpdating) {
            DebugService().log('バッチ更新中のためショップ同期をスキップ');
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
          _state.isSynced = true;
          _state.notifyListeners();
        },
        onError: (error) {
          DebugService().log('ショップ同期エラー: $error');
          _onSubscriptionError();
        },
        onDone: () {
          DebugService().log('ショップ同期ストリームが終了しました');
          _onSubscriptionError();
        },
      );

      _isSubscriptionActive = true;
      _resetRetryCount();
      DebugService().log('リアルタイム同期開始完了');
    } catch (e) {
      _isSubscriptionActive = false;
      DebugService().log('リアルタイム同期開始エラー: $e');
      _scheduleRetry();
    }
  }

  /// リアルタイム同期の停止
  void cancelRealtimeSync() {
    DebugService().log('=== _cancelRealtimeSync ===');

    _retryTimer?.cancel();
    _retryTimer = null;

    if (_itemsSubscription != null) {
      DebugService().log('アイテム同期を停止');
      _itemsSubscription!.cancel();
      _itemsSubscription = null;
    }

    if (_shopsSubscription != null) {
      DebugService().log('ショップ同期を停止');
      _shopsSubscription!.cancel();
      _shopsSubscription = null;
    }

    _isSubscriptionActive = false;
    DebugService().log('リアルタイム同期停止完了');
  }

  // --- リトライ制御 ---

  /// 購読エラーまたはストリーム終了時の処理
  void _onSubscriptionError() {
    _isSubscriptionActive = false;
    _state.isSynced = false;
    _scheduleRetry();
  }

  /// 指数バックオフ付き自動再購読をスケジュール
  void _scheduleRetry() {
    if (_retryTimer != null) return; // 既にリトライ待機中
    if (_cacheManager.isLocalMode) return; // ローカルモードではリトライしない

    if (_retryCount >= _maxRetries) {
      DebugService()
          .log('リアルタイム同期: 最大リトライ回数($_maxRetries)に到達。手動再接続が必要');
      return;
    }

    final delaySec = math.min(math.pow(2, _retryCount).toInt(), 300);
    _retryCount++;
    DebugService()
        .log('リアルタイム同期: $delaySec秒後にリトライ ($_retryCount/$_maxRetries)');

    _retryTimer = Timer(Duration(seconds: delaySec), () {
      _retryTimer = null;
      if (!_cacheManager.isLocalMode) {
        DebugService().log('リアルタイム同期: リトライを実行');
        startRealtimeSync();
      }
    });
  }

  /// リトライカウントをリセット（正常受信時）
  void _resetRetryCount() {
    _retryCount = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
