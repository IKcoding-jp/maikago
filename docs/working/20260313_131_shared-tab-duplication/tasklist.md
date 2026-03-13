# タスクリスト

## フェーズ1: 防御的重複除去の実装

- [x] `DataCacheManager` に `removeDuplicateShops()` メソッドを追加
  - IDベースの重複除去（`removeDuplicateItems()` と同様のパターン）
- [x] `RealtimeSyncManager.startRealtimeSync()` のショップ同期後に `removeDuplicateShops()` を呼び出す
- [x] `DataProvider.loadData()` で `associateItemsWithShops()` の前に `removeDuplicateShops()` を呼び出す

## フェーズ2: クロスリファレンスバグの修正

- [x] `SharedGroupManager.updateSharedGroup()` の `selectedTabIds` ループを修正
  - 各選択タブに `shopId` だけでなく、他の選択タブIDも `sharedTabs` に追加する
- [x] `SharedGroupService.prepareSharedGroupUpdate()` も同様に修正

## フェーズ3: loadData二重呼び出し防止

- [x] `DataProvider.setAuthProvider()` で `loadData()` の二重呼び出しを防止するガードを追加
  - `_isLoading` フラグを活用して排他制御

## 依存関係

- フェーズ1 → フェーズ2 → フェーズ3（順次実行）
- フェーズ1は独立して安全にデプロイ可能（防御的修正のため）
