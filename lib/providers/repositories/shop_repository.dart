// ショップのCRUD操作、楽観的更新、デフォルトショップ管理
import 'package:flutter/foundation.dart';
import 'package:maikago/services/data_service.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/models/sort_mode.dart';
import 'package:maikago/drawer/settings/settings_persistence.dart';
import 'package:maikago/providers/managers/data_cache_manager.dart';
import 'package:maikago/services/debug_service.dart';
import 'package:maikago/utils/exceptions.dart';

/// ショップのCRUD操作を管理するリポジトリ。
/// - 楽観的更新（即座にキャッシュを更新し、バックグラウンドでFirebase保存）
/// - バウンス抑止（保留中のショップIDを追跡）
/// - デフォルトショップの自動作成
/// - エラー時のロールバック
class ShopRepository {
  ShopRepository({
    required DataService dataService,
    required DataCacheManager cacheManager,
    required bool Function() shouldUseAnonymousSession,
    required VoidCallback notifyListeners,
    required void Function(bool) setSynced,
    required bool Function() getIsBatchUpdating,
  })  : _dataService = dataService,
        _cacheManager = cacheManager,
        _shouldUseAnonymousSession = shouldUseAnonymousSession,
        _notifyListeners = notifyListeners,
        _setSynced = setSynced,
        _getIsBatchUpdating = getIsBatchUpdating;

  final DataService _dataService;
  final DataCacheManager _cacheManager;
  final bool Function() _shouldUseAnonymousSession;
  final VoidCallback _notifyListeners;
  final void Function(bool) _setSynced;
  final bool Function() _getIsBatchUpdating;

  /// 直近で更新を行ったショップのIDとタイムスタンプ（楽観更新のバウンス抑止）
  final Map<String, DateTime> pendingUpdates = {};

  // --- デフォルトショップ管理 ---

  /// デフォルトショップ（id:'0'）を確保（ローカルモード時のみ自動作成）
  Future<void> ensureDefaultShop() async {
    // ログイン中（ローカルモードでない）場合はデフォルトショップを自動作成しない
    if (!_cacheManager.isLocalMode) {
      DebugService().log('デフォルトショップ自動作成はローカルモード時のみ実行します');
      return;
    }
    // デフォルトショップが削除されているかチェック
    final isDefaultShopDeleted =
        await SettingsPersistence.loadDefaultShopDeleted();

    if (isDefaultShopDeleted) {
      DebugService().log('デフォルトショップは削除済みのため作成しません');
      return;
    }

    // 既存のデフォルトショップがあるかチェック
    final hasDefaultShop = _cacheManager.shops.any((shop) => shop.id == '0');

    if (!hasDefaultShop) {
      // デフォルトショップが存在しない場合のみ作成
      final defaultShop = Shop(
        id: '0',
        name: 'デフォルト',
        items: [],
        createdAt: DateTime.now(),
      );
      _cacheManager.addShopToCache(defaultShop);

      // 即座に通知してUIを更新
      _notifyListeners();
    }
  }

  // --- ショップ追加 ---

  Future<void> addShop(Shop shop) async {
    DebugService().log('ショップ追加: ${shop.name}');

    // デフォルトショップ（ID: '0'）の場合は制限チェックをスキップ
    if (shop.id == '0') {
      final Shop newShop = shop.copyWith(createdAt: DateTime.now());
      // デフォルトショップの削除状態をリセット
      await SettingsPersistence.saveDefaultShopDeleted(false);

      _cacheManager.addShopToCache(newShop);
      _notifyListeners(); // 即座にUIを更新

      // ローカルモードでない場合のみFirebaseに保存
      if (!_cacheManager.isLocalMode) {
        try {
          await _dataService.saveShop(
            newShop,
            isAnonymous: _shouldUseAnonymousSession(),
          );
          _setSynced(true);
        } catch (e) {
          _setSynced(false);
          DebugService().log('Firebase保存エラー: $e');

          // エラーが発生した場合は追加を取り消し
          _cacheManager.shops.removeLast();
          _notifyListeners();
          rethrow;
        }
      }
      return;
    }

    // 通常のショップの場合は新しいIDを生成
    final newShop = shop.copyWith(
      id: '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}_${_cacheManager.shops.length}',
      createdAt: DateTime.now(),
    );

    _cacheManager.addShopToCache(newShop);
    _notifyListeners(); // 即座にUIを更新

    // ローカルモードでない場合のみFirebaseに保存
    if (!_cacheManager.isLocalMode) {
      try {
        await _dataService.saveShop(
          newShop,
          isAnonymous: _shouldUseAnonymousSession(),
        );
        _setSynced(true);
      } catch (e) {
        _setSynced(false);
        DebugService().log('Firebase保存エラー: $e');

        // エラーが発生した場合は追加を取り消し
        _cacheManager.shops.removeLast();

        // デフォルトショップの場合は削除状態を復元
        if (shop.id == '0') {
          await SettingsPersistence.saveDefaultShopDeleted(true);
        }

        _notifyListeners();
        rethrow;
      }
    }
  }

  // --- ショップ更新 ---

  Future<void> updateShop(Shop shop) async {
    DebugService().log('ショップ更新: ${shop.name}');

    // 楽観的更新：UIを即座に更新
    final index = _cacheManager.shops.indexWhere((s) => s.id == shop.id);
    Shop? originalShop;

    if (index != -1) {
      originalShop = _cacheManager.shops[index]; // 元の状態を保存
      _cacheManager.shops[index] = shop;
      // 楽観的更新の保護
      pendingUpdates[shop.id] = DateTime.now();

      // バッチ更新中でない場合のみUIを更新
      if (!_getIsBatchUpdating()) {
        _notifyListeners(); // 即座にUIを更新
      }
    }

    // ローカルモードでない場合のみFirebaseに保存
    if (!_cacheManager.isLocalMode) {
      try {
        await _dataService.updateShop(
          shop,
          isAnonymous: _shouldUseAnonymousSession(),
        );
        _setSynced(true);
      } catch (e) {
        _setSynced(false);
        DebugService().log('Firebase更新エラー: $e');

        // エラーが発生した場合は元に戻す
        if (index != -1 && originalShop != null) {
          _cacheManager.shops[index] = originalShop; // 元の状態に戻す
          _notifyListeners();
        }

        throw convertToAppException(e, contextMessage: 'ショップの更新');
      }
    }
  }

  // --- ショップ削除 ---

  Future<void> deleteShop(String shopId) async {
    DebugService().log('ショップ削除: $shopId');

    // 楽観的更新：UIを即座に更新
    final shopToDelete = _cacheManager.shops.firstWhere(
      (shop) => shop.id == shopId,
      orElse: () => throw Exception('削除対象のショップが見つかりません'),
    );

    // 削除されたタブを他のタブのsharedTabsから削除
    DebugService().log(
        '共有タブ参照削除処理開始: 削除対象=$shopId, 全タブ数=${_cacheManager.shops.length}');
    for (int i = 0; i < _cacheManager.shops.length; i++) {
      final shop = _cacheManager.shops[i];
      DebugService().log('タブ ${shop.id} の共有タブ: ${shop.sharedTabs}');
      if (shop.sharedTabs.contains(shopId)) {
        DebugService().log('タブ ${shop.id} から削除対象 $shopId への参照を削除');
        // 削除されたタブへの参照を削除
        final updatedSharedTabs =
            shop.sharedTabs.where((id) => id != shopId).toList();
        DebugService().log('更新後の共有タブ: $updatedSharedTabs');

        // 共有相手がいなくなった場合は共有マークも削除
        final updatedShop = shop.copyWith(
          sharedTabs: updatedSharedTabs,
          clearSharedGroupId: updatedSharedTabs.isEmpty,
          clearSharedGroupIcon: updatedSharedTabs.isEmpty,
        );

        DebugService().log(
            '更新前: sharedGroupId=${shop.sharedGroupId}, sharedGroupIcon=${shop.sharedGroupIcon}');
        DebugService().log(
            '更新後: sharedGroupId=${updatedShop.sharedGroupId}, sharedGroupIcon=${updatedShop.sharedGroupIcon}');

        _cacheManager.shops[i] = updatedShop;
        pendingUpdates[shop.id] = DateTime.now();
        DebugService().log('削除されたタブ $shopId への参照をタブ ${shop.id} から削除完了');
      }
    }

    _cacheManager.removeShopFromCache(shopId);

    // 更新後の状態をデバッグ出力
    DebugService().log('削除処理完了後のタブ状態:');
    for (final shop in _cacheManager.shops) {
      DebugService().log(
          'タブ ${shop.id}: sharedGroupId=${shop.sharedGroupId}, sharedGroupIcon=${shop.sharedGroupIcon}, sharedTabs=${shop.sharedTabs}');
    }

    _notifyListeners(); // 即座にUIを更新

    // デフォルトショップが削除された場合は状態を記録
    if (shopId == '0') {
      await SettingsPersistence.saveDefaultShopDeleted(true);
      DebugService().log('デフォルトショップの削除を記録しました');
    }

    // ローカルモードでない場合のみFirebaseから削除
    if (!_cacheManager.isLocalMode) {
      try {
        await _dataService.deleteShop(
          shopId,
          isAnonymous: _shouldUseAnonymousSession(),
        );

        // 更新された共有タブをFirestoreに保存
        DebugService().log(
            'Firestore保存処理開始: 更新対象タブ数=${pendingUpdates.length}');
        for (final shop in _cacheManager.shops) {
          if (pendingUpdates.containsKey(shop.id)) {
            DebugService().log('タブ ${shop.id} をFirestoreに保存中...');
            await _dataService.updateShop(
              shop,
              isAnonymous: _shouldUseAnonymousSession(),
            );
            DebugService().log('更新されたタブ ${shop.id} をFirestoreに保存完了');
          }
        }

        _setSynced(true);
      } catch (e) {
        _setSynced(false);
        DebugService().log('Firebase削除エラー: $e');

        // エラーが発生した場合は削除を取り消し
        _cacheManager.addShopToCache(shopToDelete);

        // 更新された共有タブの変更も取り消し
        for (final shop in _cacheManager.shops) {
          if (pendingUpdates.containsKey(shop.id)) {
            pendingUpdates.remove(shop.id);
          }
        }

        // デフォルトショップの削除記録も取り消し
        if (shopId == '0') {
          await SettingsPersistence.saveDefaultShopDeleted(false);
        }

        _notifyListeners();
        rethrow;
      }
    }
  }

  // --- ショップ補助メソッド ---

  // ショップ名を更新
  void updateShopName(int index, String newName) {
    if (index >= 0 && index < _cacheManager.shops.length) {
      _cacheManager.shops[index] =
          _cacheManager.shops[index].copyWith(name: newName);
      if (!_cacheManager.isLocalMode) {
        _dataService.saveShop(
          _cacheManager.shops[index],
          isAnonymous: _shouldUseAnonymousSession(),
        );
      }
      _notifyListeners();
    }
  }

  // ショップの予算を更新
  void updateShopBudget(int index, int? budget) {
    if (index >= 0 && index < _cacheManager.shops.length) {
      _cacheManager.shops[index] =
          _cacheManager.shops[index].copyWith(budget: budget);
      if (!_cacheManager.isLocalMode) {
        _dataService.saveShop(
          _cacheManager.shops[index],
          isAnonymous: _shouldUseAnonymousSession(),
        );
      }
      _notifyListeners();
    }
  }

  // すべてのリストを削除
  void clearAllItems(int shopIndex) {
    if (shopIndex >= 0 && shopIndex < _cacheManager.shops.length) {
      _cacheManager.shops[shopIndex] =
          _cacheManager.shops[shopIndex].copyWith(items: []);
      if (!_cacheManager.isLocalMode) {
        _dataService.saveShop(
          _cacheManager.shops[shopIndex],
          isAnonymous: _shouldUseAnonymousSession(),
        );
      }
      _notifyListeners();
    }
  }

  // ソートモードを更新
  void updateSortMode(int shopIndex, SortMode sortMode, bool isIncomplete) {
    if (shopIndex >= 0 && shopIndex < _cacheManager.shops.length) {
      if (isIncomplete) {
        _cacheManager.shops[shopIndex] =
            _cacheManager.shops[shopIndex].copyWith(incSortMode: sortMode);
      } else {
        _cacheManager.shops[shopIndex] =
            _cacheManager.shops[shopIndex].copyWith(comSortMode: sortMode);
      }
      if (!_cacheManager.isLocalMode) {
        _dataService.saveShop(
          _cacheManager.shops[shopIndex],
          isAnonymous: _shouldUseAnonymousSession(),
        );
      }
      _notifyListeners();
    }
  }
}
