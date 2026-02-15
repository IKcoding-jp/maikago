# タスクリスト: Issue #39 + #43

**ステータス**: 進行中
**開始日**: 2026-02-15

## Phase 1: DataProviderState 導入 (#43)

- [ ] 1.1 `DataProviderState` クラス作成
- [ ] 1.2 `DataCacheManager` をState参照に変更
- [ ] 1.3 `ItemRepository` をState参照に変更
- [ ] 1.4 `ShopRepository` をState参照に変更
- [ ] 1.5 `RealtimeSyncManager` をState参照に変更
- [ ] 1.6 `SharedGroupManager` をState参照に変更
- [ ] 1.7 `DataProvider` をState経由に更新

## Phase 2: Firestoreコスト最適化 (#39)

- [ ] 2.1 `updateItem` を `set(merge: true)` に統合
- [ ] 2.2 `updateShop` を `set(merge: true)` に統合
- [ ] 2.3 `deleteItem` の不要な `get()` を削除

## Phase 3: 検証

- [ ] 3.1 `flutter analyze` 通過
- [ ] 3.2 `flutter test` 通過
