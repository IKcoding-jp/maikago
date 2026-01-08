import 'package:flutter/foundation.dart';

import 'data_service.dart';
import '../models/shop.dart';

/// 共有グループ管理を担当するサービス
///
/// 複数のタブ間での合計金額/予算の共有機能を提供。
/// DataProviderから分離されたビジネスロジックを含む。
class SharedGroupService {
  final DataService _dataService;

  SharedGroupService({DataService? dataService})
      : _dataService = dataService ?? DataService();

  /// 共有グループ内の合計金額を計算
  Future<int> getSharedGroupTotal(
    List<Shop> shops,
    String sharedGroupId,
    Future<int> Function(Shop) getDisplayTotal,
  ) async {
    final sharedShops =
        shops.where((shop) => shop.sharedGroupId == sharedGroupId).toList();

    int total = 0;
    for (final shop in sharedShops) {
      final shopTotal = await getDisplayTotal(shop);
      total += shopTotal;
    }

    return total;
  }

  /// 共有グループ内の予算を取得（最初のショップの予算を使用）
  int? getSharedGroupBudget(List<Shop> shops, String sharedGroupId) {
    final sharedShops =
        shops.where((shop) => shop.sharedGroupId == sharedGroupId).toList();

    for (final shop in sharedShops) {
      if (shop.budget != null) {
        return shop.budget!;
      }
    }

    return null;
  }

  /// 新しい共有グループIDを生成
  String generateSharedGroupId() {
    return 'shared_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 共有グループの更新準備（楽観的更新用のデータ生成）
  ///
  /// 返り値は更新対象のショップリスト
  List<Shop> prepareSharedGroupUpdate({
    required List<Shop> shops,
    required String shopId,
    required List<String> selectedTabIds,
    String? sharedGroupIcon,
    String? name,
  }) {
    final result = <Shop>[];

    // 現在のショップを取得
    final currentShop = shops.firstWhere((shop) => shop.id == shopId);

    // 共有グループIDを生成または再利用
    String? sharedGroupId = currentShop.sharedGroupId;
    if (sharedGroupId == null && selectedTabIds.isNotEmpty) {
      sharedGroupId = generateSharedGroupId();
    }

    // 以前共有していたタブから削除されたタブを検出
    final previousSharedTabs = currentShop.sharedTabs;
    final removedTabIds =
        previousSharedTabs.where((id) => !selectedTabIds.contains(id)).toList();

    // 現在のショップを更新
    final updatedCurrentShop = currentShop.copyWith(
      name: name ?? currentShop.name,
      sharedTabs: selectedTabIds,
      sharedGroupId: selectedTabIds.isEmpty ? null : sharedGroupId,
      clearSharedGroupId: selectedTabIds.isEmpty,
      sharedGroupIcon: selectedTabIds.isEmpty ? null : sharedGroupIcon,
      clearSharedGroupIcon: selectedTabIds.isEmpty,
    );
    result.add(updatedCurrentShop);

    // 削除されたタブから参照を削除
    for (final removedTabId in removedTabIds) {
      final removedTab = shops.firstWhere(
        (shop) => shop.id == removedTabId,
        orElse: () => throw Exception('タブが見つかりません: $removedTabId'),
      );
      final updatedSharedTabs =
          removedTab.sharedTabs.where((id) => id != shopId).toList();
      final updatedRemovedTab = removedTab.copyWith(
        sharedTabs: updatedSharedTabs,
        clearSharedGroupId: updatedSharedTabs.isEmpty,
      );
      result.add(updatedRemovedTab);
    }

    // 選択されたタブに現在のショップを追加
    for (final tabId in selectedTabIds) {
      final tabShop = shops.firstWhere(
        (shop) => shop.id == tabId,
        orElse: () => throw Exception('タブが見つかりません: $tabId'),
      );
      final updatedSharedTabs = Set<String>.from(tabShop.sharedTabs)
        ..add(shopId);
      final updatedTabShop = tabShop.copyWith(
        sharedGroupId: sharedGroupId,
        sharedTabs: updatedSharedTabs.toList(),
        sharedGroupIcon: sharedGroupIcon,
      );
      result.add(updatedTabShop);
    }

    return result;
  }

  /// 共有グループからタブを削除するための準備
  List<Shop> prepareRemoveFromSharedGroup({
    required List<Shop> shops,
    required String shopId,
  }) {
    final result = <Shop>[];

    final shop = shops.firstWhere(
      (s) => s.id == shopId,
      orElse: () => throw Exception('ショップが見つかりません: $shopId'),
    );

    // 現在のショップから共有情報をクリア
    final updatedShop = shop.copyWith(
      sharedTabs: [],
      clearSharedGroupId: true,
      clearSharedGroupIcon: true,
    );
    result.add(updatedShop);

    // 自分を共有していた他のタブからも削除
    for (final relatedTabId in shop.sharedTabs) {
      final relatedTab = shops.firstWhere(
        (s) => s.id == relatedTabId,
        orElse: () => throw Exception('タブが見つかりません: $relatedTabId'),
      );
      final updatedSharedTabs =
          relatedTab.sharedTabs.where((id) => id != shopId).toList();
      final updatedRelatedTab = relatedTab.copyWith(
        sharedTabs: updatedSharedTabs,
        clearSharedGroupId: updatedSharedTabs.isEmpty,
        clearSharedGroupIcon: updatedSharedTabs.isEmpty,
      );
      result.add(updatedRelatedTab);
    }

    return result;
  }

  /// 共有グループ内の予算を同期
  List<Shop> syncSharedGroupBudget({
    required List<Shop> shops,
    required String sharedGroupId,
    required int? newBudget,
  }) {
    final result = <Shop>[];

    for (final shop in shops) {
      if (shop.sharedGroupId == sharedGroupId) {
        result.add(shop.copyWith(budget: newBudget));
      }
    }

    return result;
  }

  /// 複数のショップをFirestoreに保存
  Future<void> saveShops(
    List<Shop> shops, {
    required bool isAnonymous,
  }) async {
    try {
      for (final shop in shops) {
        await _dataService.updateShop(shop, isAnonymous: isAnonymous);
      }
      debugPrint('✅ 共有グループ保存完了: ${shops.length}件');
    } catch (e) {
      debugPrint('❌ 共有グループ保存エラー: $e');
      rethrow;
    }
  }
}
