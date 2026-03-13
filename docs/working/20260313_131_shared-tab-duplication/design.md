# 設計書

## 実装方針

### 変更対象ファイル

- `lib/providers/managers/data_cache_manager.dart` - `removeDuplicateShops()` メソッド追加
- `lib/providers/managers/realtime_sync_manager.dart` - ショップ同期後にdedup呼び出し追加
- `lib/providers/data_provider.dart` - loadData()でdedup追加 + 二重呼び出し防止
- `lib/providers/managers/shared_group_manager.dart` - クロスリファレンス修正

### 新規作成ファイル

なし

## 詳細設計

### 1. `removeDuplicateShops()` の実装

`DataCacheManager` に追加。`removeDuplicateItems()` と同じパターン:

```dart
void removeDuplicateShops() {
  final Map<String, Shop> uniqueShopsMap = {};
  final List<Shop> uniqueShops = [];

  for (final shop in _shops) {
    if (!uniqueShopsMap.containsKey(shop.id)) {
      uniqueShopsMap[shop.id] = shop;
      uniqueShops.add(shop);
    }
  }

  _shops = uniqueShops;
}
```

### 2. クロスリファレンス修正

`updateSharedGroup()` の `selectedTabIds` ループ内で、各タブの `sharedTabs` に `shopId` だけでなく、共有グループ内の全メンバーIDを追加する:

```dart
// 共有グループの全メンバーID（自身を含む）
final allGroupMemberIds = {shopId, ...selectedTabIds};

for (final tabId in selectedTabIds) {
  final tabIndex = _cacheManager.shops.indexWhere((shop) => shop.id == tabId);
  if (tabIndex != -1) {
    final tabShop = _cacheManager.shops[tabIndex];
    // 自身以外の全メンバーIDを追加
    final updatedSharedTabs = Set<String>.from(tabShop.sharedTabs)
      ..addAll(allGroupMemberIds)
      ..remove(tabId); // 自分自身は除外
    final updatedTabShop = tabShop.copyWith(
      sharedGroupId: sharedGroupId,
      sharedTabs: updatedSharedTabs.toList(),
      sharedGroupIcon: sharedGroupIcon,
    );
    _cacheManager.shops[tabIndex] = updatedTabShop;
    _shopRepository.pendingUpdates[tabId] = DateTime.now();
  }
}
```

### 3. loadData()二重呼び出し防止

`_isLoading` フラグを活用:

```dart
if (authProvider.isLoggedIn && !authProvider.isLoading) {
  _resetDataForLogin();
  if (!_isLoading) {
    loadData();
  }
}
```

## 影響範囲

- `SharedGroupManager` - クロスリファレンス修正により、既存の不整合データは次回共有設定変更時に自動修復される
- `DataCacheManager` - 新メソッド追加のみ、既存API変更なし
- `RealtimeSyncManager` - dedup呼び出し追加のみ
- `DataProvider` - ガード追加のみ

## Flutter固有の注意点

- `notifyListeners()` の呼び出し頻度は変更なし
- `removeDuplicateShops()` はUI再描画前に実行されるため、パフォーマンス影響は最小
- `TabController` の再生成は `sortedShops.length` の変化時のみなので、dedup によりタブ数が安定する
