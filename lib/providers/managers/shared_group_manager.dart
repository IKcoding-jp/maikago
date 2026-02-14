// 共有グループのCRUD、合計・予算計算
import 'package:flutter/foundation.dart';
import '../../services/data_service.dart';
import '../../models/shop.dart';
import '../managers/data_cache_manager.dart';
import '../repositories/shop_repository.dart';

/// 共有グループの管理を担うクラス。
/// - 共有グループの作成・更新・削除
/// - 共有タブ間の参照管理
/// - 合計・予算の計算
/// - Firestore保存
class SharedGroupManager {
  final DataService _dataService;
  final DataCacheManager _cacheManager;
  final ShopRepository _shopRepository;
  final bool Function() _shouldUseAnonymousSession;
  final VoidCallback _notifyListeners;
  final void Function(bool) _setSynced;

  SharedGroupManager({
    required DataService dataService,
    required DataCacheManager cacheManager,
    required ShopRepository shopRepository,
    required bool Function() shouldUseAnonymousSession,
    required VoidCallback notifyListeners,
    required void Function(bool) setSynced,
  })  : _dataService = dataService,
        _cacheManager = cacheManager,
        _shopRepository = shopRepository,
        _shouldUseAnonymousSession = shouldUseAnonymousSession,
        _notifyListeners = notifyListeners,
        _setSynced = setSynced;

  // --- 合計・予算計算 ---

  Future<int> getDisplayTotal(Shop shop) async {
    final checkedItems = shop.items.where((item) => item.isChecked).toList();
    final total = checkedItems.fold<int>(0, (sum, item) {
      final itemTotal =
          (item.price * item.quantity * (1 - item.discount)).round();
      return sum + itemTotal;
    });

    await Future.delayed(const Duration(milliseconds: 10));
    return total;
  }

  Future<int> getSharedGroupTotal(String sharedGroupId) async {
    final sharedShops = _cacheManager.shops
        .where((shop) => shop.sharedGroupId == sharedGroupId)
        .toList();
    int total = 0;

    for (final shop in sharedShops) {
      final shopTotal = await getDisplayTotal(shop);
      total += shopTotal;
    }

    return total;
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
    debugPrint('共有グループ更新: ショップID=$shopId, 選択タブ=${selectedTabIds.length}個');

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

    debugPrint('削除されたタブ: ${removedTabIds.length}個');

    final updatedShop = currentShop.copyWith(
      name: name ?? currentShop.name,
      sharedTabs: selectedTabIds,
      sharedGroupId: selectedTabIds.isEmpty ? null : sharedGroupId,
      clearSharedGroupId: selectedTabIds.isEmpty,
      sharedGroupIcon: selectedTabIds.isEmpty ? null : sharedGroupIcon,
      clearSharedGroupIcon: selectedTabIds.isEmpty,
    );

    if (selectedTabIds.isEmpty) {
      debugPrint('共有タブがすべて解除されました。タブ $shopId の共有マークを非表示にします。');
    }

    final shopIndex =
        _cacheManager.shops.indexWhere((shop) => shop.id == shopId);
    if (shopIndex != -1) {
      _cacheManager.shops[shopIndex] = updatedShop;
      _shopRepository.pendingUpdates[shopId] = DateTime.now();
    }

    for (final removedTabId in removedTabIds) {
      final removedTabIndex =
          _cacheManager.shops.indexWhere((shop) => shop.id == removedTabId);
      if (removedTabIndex != -1) {
        final removedTab = _cacheManager.shops[removedTabIndex];
        final updatedSharedTabs =
            removedTab.sharedTabs.where((id) => id != shopId).toList();
        final updatedRemovedTab = removedTab.copyWith(
          sharedTabs: updatedSharedTabs,
          clearSharedGroupId: updatedSharedTabs.isEmpty,
        );
        _cacheManager.shops[removedTabIndex] = updatedRemovedTab;
        _shopRepository.pendingUpdates[removedTabId] = DateTime.now();
        debugPrint('削除されたタブ $removedTabId から現在のタブ $shopId を削除');
      }
    }

    for (final tabId in selectedTabIds) {
      final tabIndex =
          _cacheManager.shops.indexWhere((shop) => shop.id == tabId);
      if (tabIndex != -1) {
        final tabShop = _cacheManager.shops[tabIndex];
        final updatedSharedTabs = Set<String>.from(tabShop.sharedTabs)
          ..add(shopId);
        final updatedTabShop = tabShop.copyWith(
          sharedGroupId: sharedGroupId,
          sharedTabs: updatedSharedTabs.toList(),
          sharedGroupIcon: sharedGroupIcon,
        );
        _cacheManager.shops[tabIndex] = updatedTabShop;
        _shopRepository.pendingUpdates[tabId] = DateTime.now();
      }
    }

    _notifyListeners();

    if (!_cacheManager.isLocalMode) {
      try {
        await _dataService.updateShop(
          updatedShop,
          isAnonymous: _shouldUseAnonymousSession(),
        );

        for (final removedTabId in removedTabIds) {
          final removedTabIndex =
              _cacheManager.shops.indexWhere((shop) => shop.id == removedTabId);
          if (removedTabIndex != -1) {
            await _dataService.updateShop(
              _cacheManager.shops[removedTabIndex],
              isAnonymous: _shouldUseAnonymousSession(),
            );
          }
        }

        for (final tabId in selectedTabIds) {
          final tabIndex =
              _cacheManager.shops.indexWhere((shop) => shop.id == tabId);
          if (tabIndex != -1) {
            await _dataService.updateShop(
              _cacheManager.shops[tabIndex],
              isAnonymous: _shouldUseAnonymousSession(),
            );
          }
        }

        _setSynced(true);
        debugPrint('✅ 共有グループ更新完了');
      } catch (e) {
        _setSynced(false);
        debugPrint('❌ 共有グループ更新エラー: $e');
        rethrow;
      }
    }
  }

  Future<void> removeFromSharedGroup(String shopId,
      {String? originalSharedGroupId, String? name}) async {
    debugPrint('共有グループから削除: ショップID=$shopId');

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

    _notifyListeners();

    if (!_cacheManager.isLocalMode) {
      try {
        await _dataService.updateShop(
          updatedShop,
          isAnonymous: _shouldUseAnonymousSession(),
        );

        for (final affectedId in affectedShopIds) {
          final affectedIndex =
              _cacheManager.shops.indexWhere((shop) => shop.id == affectedId);
          if (affectedIndex == -1) continue;
          await _dataService.updateShop(
            _cacheManager.shops[affectedIndex],
            isAnonymous: _shouldUseAnonymousSession(),
          );
        }

        _setSynced(true);
        debugPrint('✅ 共有グループから削除完了');
      } catch (e) {
        _setSynced(false);
        debugPrint('❌ 共有グループ削除エラー: $e');
        rethrow;
      }
    }
  }

  Future<void> syncSharedGroupBudget(
      String sharedGroupId, int? newBudget) async {
    debugPrint('共有グループ予算同期: グループID=$sharedGroupId, 予算=$newBudget');

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

    _notifyListeners();

    if (!_cacheManager.isLocalMode) {
      try {
        for (final shop in sharedShops) {
          final updatedShop =
              _cacheManager.shops.firstWhere((s) => s.id == shop.id);
          await _dataService.updateShop(
            updatedShop,
            isAnonymous: _shouldUseAnonymousSession(),
          );
        }

        _setSynced(true);
        debugPrint('✅ 共有グループ予算同期完了');
      } catch (e) {
        _setSynced(false);
        debugPrint('❌ 共有グループ予算同期エラー: $e');
        rethrow;
      }
    }
  }
}
