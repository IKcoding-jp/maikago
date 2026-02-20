# 要件定義: テストカバレッジ向上（Issue #90）

## 概要

テストカバレッジを現在の約9%（98ファイル中9ファイル）から段階的に向上させる。
バイブコーディングにより「動くコード」の生成に偏り、テスト不足によるリグレッションリスクが高い状態を改善する。

## 現状

### テスト済み（7ファイル）

| ファイル | テスト数 | カバー範囲 |
|---|---|---|
| `test/models/list_item_test.dart` | - | ListItemモデル |
| `test/models/shop_test.dart` | - | Shopモデル |
| `test/models/sort_mode_test.dart` | - | SortModeモデル |
| `test/providers/data_provider_test.dart` | 36 | DataProvider（ファサード） |
| `test/providers/theme_provider_test.dart` | 14 | ThemeProvider |
| `test/services/feature_access_control_test.dart` | 20 | FeatureAccessControl |
| `test/services/shared_group_service_test.dart` | 20 | SharedGroupService |

### テスト基盤

- **モック**: `mockito` + `build_runner`（`MockDataService`自動生成済み）
- **ヘルパー**: `test/helpers/test_helpers.dart`（`createSampleItem`, `createSampleShop`, `createSampleItems`）
- **既存Fake**: `feature_access_control_test.dart`内に手動Fakeパターンあり

## 作業スコープ（Phase 1のみ）

本チケットでは **Phase 1: providers/repositories/ のユニットテスト** を対象とする。

### 対象ファイル

1. **`lib/providers/repositories/item_repository.dart`**
   - addItem, updateItem, updateItemsBatch, deleteItem, deleteItems
   - applyReorderToCache, persistReorderToFirebase

2. **`lib/providers/repositories/shop_repository.dart`**
   - ensureDefaultShop, addShop, updateShop, deleteShop
   - updateShopName, updateShopBudget, clearAllItems, updateSortMode

## 要件

1. 各Repositoryの全パブリックメソッドに対するユニットテストを作成
2. 楽観的更新・ロールバックのエッジケースをカバー
3. 既存のモックパターン（`MockDataService`）を活用
4. 新規Fake（`DataCacheManager`, `DataProviderState`）を作成
5. `flutter test` で全テスト通過
6. `flutter analyze` でLintエラーなし

## 非スコープ

- Phase 2〜5（managers, services, screens, widgets）は別Issue/別PRで対応
- テスタビリティのためのプロダクションコード変更は最小限に留める
