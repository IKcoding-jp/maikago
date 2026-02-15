# タスクリスト: テストカバレッジの向上（Phase 1）

**ステータス**: 完了
**開始日**: 2026-02-15
**完了日**: 2026-02-15

## Phase 1: サービス層ユニットテスト

### 1. テスト基盤の準備
- [x] 必要なモッククラスの追加（mocks.dart更新）
- [x] テストヘルパーの拡充（必要に応じて）

### 2. FeatureAccessControl テスト
- [x] `test/services/feature_access_control_test.dart` 作成
- [x] プレミアム判定ロジックのテスト
- [x] 各FeatureType/LimitReachedTypeの判定テスト
- [x] アップグレードプラン取得のテスト
- [x] 使用状況統計のテスト

### 3. ItemService テスト
- [x] `test/services/item_service_test.dart` 作成
- [x] createNewItem のテスト（ID生成、タイムスタンプ）
- [x] saveItem / updateItem / deleteItem のテスト
- [x] updateItemsBatch のテスト（バッチ処理）
- [x] deleteItems のテスト（一括削除）
- [x] associateItemsWithShops のテスト（関連付け・重複除去）
- [x] エラーハンドリングのテスト

### 4. ShopService テスト
- [x] `test/services/shop_service_test.dart` 作成
- [x] createNewShop のテスト（デフォルトショップ・通常ショップ）
- [x] saveShop / updateShop / deleteShop のテスト
- [x] removeSharedTabReferences のテスト
- [x] createDefaultShop / shouldCreateDefaultShop のテスト
- [x] clearAllItems のテスト
- [x] エラーハンドリングのテスト

### 5. SharedGroupService テスト
- [x] `test/services/shared_group_service_test.dart` 作成
- [x] getSharedGroupTotal のテスト（合計計算）
- [x] getSharedGroupBudget のテスト（予算取得）
- [x] prepareSharedGroupUpdate のテスト（共有グループ更新準備）
- [x] prepareRemoveFromSharedGroup のテスト（グループから削除）
- [x] syncSharedGroupBudget のテスト（予算同期）
- [x] saveShops のテスト（複数ショップ保存）

### 6. 検証
- [x] `flutter test` 全テスト通過
- [x] `flutter analyze` Lintエラーなし
- [x] 既存テストが壊れていないことを確認
