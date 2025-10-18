import '../models/shop.dart';

/// タブの並び順を管理するユーティリティクラス
class TabSorter {
  /// 共有グループごとにタブを隣接させる並び順を生成
  ///
  /// 並び順のルール:
  /// 1. 共有グループごとにグループ化
  /// 2. 各グループ内では作成日時順（古い順）
  /// 3. 共有していないタブは最後に配置
  /// 4. 同じグループのタブは隣接して表示
  static List<Shop> sortShopsBySharedGroups(List<Shop> shops) {
    if (shops.isEmpty) return shops;

    // 1. 共有グループごとに分類
    final Map<String, List<Shop>> sharedGroups = {};
    final List<Shop> unsharedShops = [];

    for (final shop in shops) {
      if (shop.sharedGroupId != null) {
        final groupId = shop.sharedGroupId!;
        if (!sharedGroups.containsKey(groupId)) {
          sharedGroups[groupId] = [];
        }
        sharedGroups[groupId]!.add(shop);
      } else {
        unsharedShops.add(shop);
      }
    }

    // 2. 各共有グループ内で作成日時順（古い順）にソート
    for (final groupShops in sharedGroups.values) {
      groupShops.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(1970);
        final bDate = b.createdAt ?? DateTime(1970);
        return aDate.compareTo(bDate);
      });
    }

    // 3. 共有グループをグループID順（作成日時順）でソート
    final sortedGroups = sharedGroups.entries.toList()
      ..sort((a, b) {
        // 各グループの最初のタブの作成日時で比較
        final aFirstShop = a.value.first;
        final bFirstShop = b.value.first;
        final aDate = aFirstShop.createdAt ?? DateTime(1970);
        final bDate = bFirstShop.createdAt ?? DateTime(1970);
        return aDate.compareTo(bDate);
      });

    // 4. 共有していないタブも作成日時順（古い順）にソート
    unsharedShops.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(1970);
      final bDate = b.createdAt ?? DateTime(1970);
      return aDate.compareTo(bDate);
    });

    // 5. 最終的な並び順を構築
    final List<Shop> sortedShops = [];

    // 共有グループを順番に追加
    for (final group in sortedGroups) {
      sortedShops.addAll(group.value);
    }

    // 共有していないタブを最後に追加
    sortedShops.addAll(unsharedShops);

    return sortedShops;
  }

  /// タブの並び順を取得（共有グループ優先）
  ///
  /// 戻り値: ソートされたタブのリストと、元のインデックスから新しいインデックスへのマッピング
  static Map<String, dynamic> getSortedTabsWithMapping(
      List<Shop> originalShops) {
    final sortedShops = sortShopsBySharedGroups(originalShops);

    // 元のインデックスから新しいインデックスへのマッピングを作成
    final Map<int, int> indexMapping = {};
    for (int i = 0; i < originalShops.length; i++) {
      final originalShop = originalShops[i];
      final newIndex =
          sortedShops.indexWhere((shop) => shop.id == originalShop.id);
      if (newIndex != -1) {
        indexMapping[i] = newIndex;
      }
    }

    return {
      'sortedShops': sortedShops,
      'indexMapping': indexMapping,
    };
  }

  /// 指定されたタブが属する共有グループの他のタブを取得
  static List<Shop> getSharedGroupMembers(
      Shop targetShop, List<Shop> allShops) {
    if (targetShop.sharedGroupId == null) return [];

    return allShops
        .where((shop) =>
            shop.sharedGroupId == targetShop.sharedGroupId &&
            shop.id != targetShop.id)
        .toList();
  }

  /// 共有グループの情報を取得
  static Map<String, dynamic> getSharedGroupInfo(
      Shop shop, List<Shop> allShops) {
    if (shop.sharedGroupId == null) {
      return {
        'hasSharedGroup': false,
        'groupMembers': [],
        'groupIcon': null,
      };
    }

    final groupMembers =
        allShops.where((s) => s.sharedGroupId == shop.sharedGroupId).toList();

    return {
      'hasSharedGroup': true,
      'groupMembers': groupMembers,
      'groupIcon': shop.sharedGroupIcon,
      'groupSize': groupMembers.length,
    };
  }
}
