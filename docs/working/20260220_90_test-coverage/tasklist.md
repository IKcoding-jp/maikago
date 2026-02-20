# タスクリスト: テストカバレッジ向上 Phase 1（Issue #90）

**ステータス**: 実装中
**対象**: providers/repositories/ のユニットテスト

## Phase 1: テスト基盤整備

- [x] 1.1 DataCacheManagerのFake実装 → 不要（実DataCacheManager + MockDataServiceで対応）
- [x] 1.2 DataProviderStateのテスト用インスタンス化パターン確認

## Phase 2: ItemRepository テスト

- [x] 2.1 `test/providers/repositories/item_repository_test.dart` 作成
- [x] 2.2 addItem テストケース（正常系・重複・ロールバック）— 13テスト
- [x] 2.3 updateItem テストケース（正常系・shops同期）— 7テスト
- [x] 2.4 updateItemsBatch テストケース — 6テスト
- [x] 2.5 deleteItem テストケース（正常系・不存在・ロールバック）— 8テスト
- [x] 2.6 deleteItems テストケース（正常系・空リスト）— 8テスト
- [x] 2.7 applyReorderToCache / persistReorderToFirebase テストケース — 6テスト

## Phase 3: ShopRepository テスト

- [x] 3.1 `test/providers/repositories/shop_repository_test.dart` 作成
- [x] 3.2 ensureDefaultShop テストケース（ローカル/非ローカル）— 5テスト
- [x] 3.3 addShop テストケース（通常・デフォルト）— 9テスト
- [x] 3.4 updateShop テストケース（通常・バッチ更新中）— 7テスト
- [x] 3.5 deleteShop テストケース（通常・デフォルト・sharedTabs除去）— 9テスト
- [x] 3.6 updateShopName / updateShopBudget テストケース — 8テスト
- [x] 3.7 clearAllItems テストケース — 4テスト
- [x] 3.8 updateSortMode テストケース — 5テスト

## Phase 4: 検証

- [x] 4.1 `flutter analyze` 通過
- [x] 4.2 `flutter test` 全テスト通過（233件）
