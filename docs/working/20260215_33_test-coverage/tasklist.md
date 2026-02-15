# タスクリスト: テストカバレッジの向上（Phase 1）

**ステータス**: 進行中
**開始日**: 2026-02-15

## Phase 1: サービス層ユニットテスト

### 1. テスト基盤の準備
- [ ] 必要なモッククラスの追加（mocks.dart更新）
- [ ] テストヘルパーの拡充（必要に応じて）

### 2. FeatureAccessControl テスト
- [ ] `test/services/feature_access_control_test.dart` 作成
- [ ] プレミアム判定ロジックのテスト
- [ ] 各FeatureType/LimitReachedTypeの判定テスト
- [ ] アップグレードプラン取得のテスト
- [ ] 使用状況統計のテスト

### 3. ItemService テスト
- [ ] `test/services/item_service_test.dart` 作成
- [ ] createNewItem のテスト（ID生成、タイムスタンプ）
- [ ] saveItem / updateItem / deleteItem のテスト
- [ ] updateItemsBatch のテスト（バッチ処理）
- [ ] deleteItems のテスト（一括削除）
- [ ] associateItemsWithShops のテスト（関連付け・重複除去）
- [ ] エラーハンドリングのテスト

### 4. ShopService テスト
- [ ] `test/services/shop_service_test.dart` 作成
- [ ] createNewShop のテスト（デフォルトショップ・通常ショップ）
- [ ] saveShop / updateShop / deleteShop のテスト
- [ ] removeSharedTabReferences のテスト
- [ ] createDefaultShop / shouldCreateDefaultShop のテスト
- [ ] clearAllItems のテスト
- [ ] エラーハンドリングのテスト

### 5. SharedGroupService テスト
- [ ] `test/services/shared_group_service_test.dart` 作成
- [ ] getSharedGroupTotal のテスト（合計計算）
- [ ] getSharedGroupBudget のテスト（予算取得）
- [ ] prepareSharedGroupUpdate のテスト（共有グループ更新準備）
- [ ] prepareRemoveFromSharedGroup のテスト（グループから削除）
- [ ] syncSharedGroupBudget のテスト（予算同期）
- [ ] saveShops のテスト（複数ショップ保存）

### 6. 検証
- [ ] `flutter test` 全テスト通過
- [ ] `flutter analyze` Lintエラーなし
- [ ] 既存テストが壊れていないことを確認
