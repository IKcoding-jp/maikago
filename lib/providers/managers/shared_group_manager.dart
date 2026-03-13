// 共有グループのCRUD、合計・予算計算
import 'package:maikago/services/data_service.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/providers/data_provider_state.dart';
import 'package:maikago/providers/managers/data_cache_manager.dart';
import 'package:maikago/providers/repositories/shop_repository.dart';
import 'package:maikago/services/debug_service.dart';

/// 共有グループの管理を担うクラス。
/// - 共有グループの作成・更新・削除
/// - 共有タブ間の参照管理
/// - 合計・予算の計算
/// - Firestore保存
class SharedGroupManager {
  SharedGroupManager({
    required DataService dataService,
    required DataCacheManager cacheManager,
    required ShopRepository shopRepository,
    required DataProviderState state,
  })  : _dataService = dataService,
        _cacheManager = cacheManager,
        _shopRepository = shopRepository,
        _state = state;

  final DataService _dataService;
  final DataCacheManager _cacheManager;
  final ShopRepository _shopRepository;
  final DataProviderState _state;

  // --- 合計・予算計算 ---

  int getDisplayTotal(Shop shop) {
    final checkedItems = shop.items.where((item) => item.isChecked).toList();
    return checkedItems.fold<int>(0, (sum, item) {
      final itemTotal =
          (item.price * item.quantity * (1 - item.discount)).round();
      return sum + itemTotal;
    });
  }

  int getSharedGroupTotal(String sharedGroupId) {
    final sharedShops = _cacheManager.shops
        .where((shop) => shop.sharedGroupId == sharedGroupId)
        .toList();
    return sharedShops.fold<int>(
        0, (total, shop) => total + getDisplayTotal(shop));
  }

  int? getSharedGroupBudget(String sharedGroupId) {
    final sharedShops = _cacheManager.shops
        .where((shop) => shop.sharedGroupId == sharedGroupId)
        .toList();

    for (final shop in sharedShops) {
      if (shop.budget != null) {
        return shop.budget!;
      }
    }

    return null;
  }

  // --- 共有グループ管理 ---

  Future<void> updateSharedGroup(String shopId, List<String> selectedTabIds,
      {String? name, String? sharedGroupIcon}) async {
    String? sharedGroupId;
    final currentShop =
        _cacheManager.shops.firstWhere((shop) => shop.id == shopId);

    if (currentShop.sharedGroupId != null) {
      sharedGroupId = currentShop.sharedGroupId;
    } else {
      sharedGroupId = 'shared_${DateTime.now().millisecondsSinceEpoch}';
    }

    final previousSharedTabs = currentShop.sharedTabs;
    final removedTabIds =
        previousSharedTabs.where((id) => !selectedTabIds.contains(id)).toList();

    final updatedShop = currentShop.copyWith(
      name: name ?? currentShop.name,
      sharedTabs: selectedTabIds,
      sharedGroupId: selectedTabIds.isEmpty ? null : sharedGroupId,
      clearSharedGroupId: selectedTabIds.isEmpty,
      sharedGroupIcon: selectedTabIds.isEmpty ? null : sharedGroupIcon,
      clearSharedGroupIcon: selectedTabIds.isEmpty,
    );

    final shopIndex =
        _cacheManager.shops.indexWhere((shop) => shop.id == shopId);
    if (shopIndex != -1) {
      _cacheManager.shops[shopIndex] = updatedShop;
      _shopRepository.pendingUpdates[shopId] = DateTime.now();
    }

    // グループ全体のID（解除タブの参照除去に使用）
    final allInvolvedIds = {shopId, ...selectedTabIds, ...removedTabIds};

    // 解除されたタブからグループ全メンバーへの参照を除去
    for (final removedTabId in removedTabIds) {
      final removedTabIndex =
          _cacheManager.shops.indexWhere((shop) => shop.id == removedTabId);
      if (removedTabIndex != -1) {
        final removedTab = _cacheManager.shops[removedTabIndex];
        final updatedSharedTabs = removedTab.sharedTabs
            .where((id) => !allInvolvedIds.contains(id))
            .toList();
        final updatedRemovedTab = removedTab.copyWith(
          sharedTabs: updatedSharedTabs,
          clearSharedGroupId: updatedSharedTabs.isEmpty,
        );
        _cacheManager.shops[removedTabIndex] = updatedRemovedTab;
        _shopRepository.pendingUpdates[removedTabId] = DateTime.now();
      }
    }

    // 共有グループの全メンバーID（自身 + 選択タブ）
    final allGroupMemberIds = {shopId, ...selectedTabIds};

    // 選択されたタブのsharedTabsを正確なグループメンバーに置換
    for (final tabId in selectedTabIds) {
      final tabIndex =
          _cacheManager.shops.indexWhere((shop) => shop.id == tabId);
      if (tabIndex != -1) {
        // addAllではなく、正確なメンバーリストに置換（解除タブの残留を防止）
        final updatedSharedTabs = allGroupMemberIds
            .where((id) => id != tabId)
            .toList();
        final updatedTabShop = _cacheManager.shops[tabIndex].copyWith(
          sharedGroupId: sharedGroupId,
          sharedTabs: updatedSharedTabs,
          sharedGroupIcon: sharedGroupIcon,
        );
        _cacheManager.shops[tabIndex] = updatedTabShop;
        _shopRepository.pendingUpdates[tabId] = DateTime.now();
      }
    }

    _state.notifyListeners();

    if (!_cacheManager.isLocalMode) {
      try {
        await _dataService.updateShop(
          updatedShop,
          isAnonymous: _state.shouldUseAnonymousSession,
        );

        for (final removedTabId in removedTabIds) {
          final removedTabIndex =
              _cacheManager.shops.indexWhere((shop) => shop.id == removedTabId);
          if (removedTabIndex != -1) {
            await _dataService.updateShop(
              _cacheManager.shops[removedTabIndex],
              isAnonymous: _state.shouldUseAnonymousSession,
            );
          }
        }

        for (final tabId in selectedTabIds) {
          final tabIndex =
              _cacheManager.shops.indexWhere((shop) => shop.id == tabId);
          if (tabIndex != -1) {
            await _dataService.updateShop(
              _cacheManager.shops[tabIndex],
              isAnonymous: _state.shouldUseAnonymousSession,
            );
          }
        }

        _state.isSynced = true;
        DebugService().logInfo('共有グループ更新完了: ショップID=$shopId');
      } catch (e) {
        _state.isSynced = false;
        DebugService().logError('共有グループ更新エラー: $e');
        rethrow;
      }
    }
  }

  Future<void> removeFromSharedGroup(String shopId,
      {String? originalSharedGroupId, String? name}) async {
    final shopIndex =
        _cacheManager.shops.indexWhere((shop) => shop.id == shopId);
    if (shopIndex == -1) return;

    final currentShop = _cacheManager.shops[shopIndex];
    String? sharedGroupId = originalSharedGroupId ?? currentShop.sharedGroupId;
    if (sharedGroupId == null) {
      for (final shop in _cacheManager.shops) {
        if (shop.sharedTabs.contains(shopId)) {
          sharedGroupId = shop.sharedGroupId;
          break;
        }
      }
    }

    final updatedShop = currentShop.copyWith(
      name: name ?? currentShop.name,
      sharedTabs: [],
      clearSharedGroupId: true,
    );
    _cacheManager.shops[shopIndex] = updatedShop;
    _shopRepository.pendingUpdates[shopId] = DateTime.now();

    final affectedShopIds = <String>[];

    for (int i = 0; i < _cacheManager.shops.length; i++) {
      final otherShop = _cacheManager.shops[i];
      if (otherShop.id == shopId) continue;
      if (!otherShop.sharedTabs.contains(shopId)) continue;

      final updatedSharedTabs =
          otherShop.sharedTabs.where((id) => id != shopId).toList();
      final updatedOtherShop = otherShop.copyWith(
        sharedTabs: updatedSharedTabs,
        clearSharedGroupId: updatedSharedTabs.isEmpty,
      );
      _cacheManager.shops[i] = updatedOtherShop;
      _shopRepository.pendingUpdates[updatedOtherShop.id] = DateTime.now();
      affectedShopIds.add(updatedOtherShop.id);
    }

    _state.notifyListeners();

    if (!_cacheManager.isLocalMode) {
      try {
        await _dataService.updateShop(
          updatedShop,
          isAnonymous: _state.shouldUseAnonymousSession,
        );

        for (final affectedId in affectedShopIds) {
          final affectedIndex =
              _cacheManager.shops.indexWhere((shop) => shop.id == affectedId);
          if (affectedIndex == -1) continue;
          await _dataService.updateShop(
            _cacheManager.shops[affectedIndex],
            isAnonymous: _state.shouldUseAnonymousSession,
          );
        }

        _state.isSynced = true;
        DebugService().logInfo('共有グループから離脱完了: ショップID=$shopId');
      } catch (e) {
        _state.isSynced = false;
        DebugService().logError('共有グループ削除エラー: $e');
        rethrow;
      }
    }
  }

  Future<void> syncSharedGroupBudget(
      String sharedGroupId, int? newBudget) async {
    final sharedShops = _cacheManager.shops
        .where((shop) => shop.sharedGroupId == sharedGroupId)
        .toList();

    for (final shop in sharedShops) {
      final updatedShop = (newBudget == null || newBudget == 0)
          ? shop.copyWith(clearBudget: true)
          : shop.copyWith(budget: newBudget);
      final shopIndex =
          _cacheManager.shops.indexWhere((s) => s.id == shop.id);
      if (shopIndex != -1) {
        _cacheManager.shops[shopIndex] = updatedShop;
      }
    }

    _state.notifyListeners();

    if (!_cacheManager.isLocalMode) {
      try {
        for (final shop in sharedShops) {
          final updatedShop =
              _cacheManager.shops.firstWhere((s) => s.id == shop.id);
          await _dataService.updateShop(
            updatedShop,
            isAnonymous: _state.shouldUseAnonymousSession,
          );
        }

        _state.isSynced = true;
      } catch (e) {
        _state.isSynced = false;
        DebugService().logError('共有グループ予算同期エラー: $e');
        rethrow;
      }
    }
  }
}
