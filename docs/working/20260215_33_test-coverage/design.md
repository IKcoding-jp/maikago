# 設計書: テストカバレッジの向上（Phase 1）

## テスト対象サービスの依存関係

### 1. FeatureAccessControl
```
FeatureAccessControl (ChangeNotifier)
  └── OneTimePurchaseService（initialize()で注入）
       ├── isPremiumUnlocked: bool
       ├── isTrialActive: bool
       ├── trialRemainingDuration: Duration?
       ├── isStoreAvailable: bool
       ├── error: String?
       └── isLoading: bool
```
**テスト方針**: OneTimePurchaseServiceをモック化。プレミアム/非プレミアム状態を切り替えてテスト。

### 2. ItemService
```
ItemService
  └── DataService（コンストラクタDI）
       ├── saveItem(item, isAnonymous)
       ├── updateItem(item, isAnonymous)
       └── deleteItem(itemId, isAnonymous)
```
**テスト方針**: DataServiceをモック化（既存MockDataService再利用）。純粋なビジネスロジック（createNewItem, associateItemsWithShops）はモックなしでテスト可能。

### 3. ShopService
```
ShopService
  └── DataService（コンストラクタDI）
       ├── saveShop(shop, isAnonymous)
       ├── updateShop(shop, isAnonymous)
       ├── deleteShop(shopId, isAnonymous)
       └── deleteItem(itemId, isAnonymous)
  └── SettingsPersistence（静的メソッド呼び出し）
       ├── saveDefaultShopDeleted(bool)
       └── loadDefaultShopDeleted() -> bool
```
**テスト方針**: DataServiceはモック化。SettingsPersistenceはSharedPreferencesのモック初期値で対応。純粋ロジック（createNewShop, removeSharedTabReferences, createDefaultShop）はモックなしで可能。

### 4. SharedGroupService
```
SharedGroupService
  └── DataService（コンストラクタDI）
       └── updateShop(shop, isAnonymous)
```
**テスト方針**: 大半が純粋なデータ変換ロジック（prepareSharedGroupUpdate等）のためモックなしでテスト可能。saveShopsのみDataServiceモック必要。

## 追加モッククラス

```dart
// test/mocks.dart に追加
@GenerateMocks([
  DataService,        // 既存
  OneTimePurchaseService,  // 新規追加
])
```

## テストファイル構成

```
test/
├── helpers/
│   └── test_helpers.dart     # 既存（拡充不要）
├── mocks.dart                # モック定義（OneTimePurchaseService追加）
├── mocks.mocks.dart          # 自動生成（再生成必要）
├── models/                   # 既存
├── providers/                # 既存
└── services/                 # 新規ディレクトリ
    ├── feature_access_control_test.dart
    ├── item_service_test.dart
    ├── shop_service_test.dart
    └── shared_group_service_test.dart
```

## テストパターン

既存テストと同じパターンを踏襲:
- **setUp**: モックの初期化、テスト対象のインスタンス化
- **group**: 機能ごとにグループ化
- **test**: 正常系・異常系・境界値
- **verify/verifyNever**: モック呼び出しの検証
- **when/thenAnswer**: スタブ設定

## 注意点
- `DebugService()`はシングルトンのため、テスト時はそのまま呼び出し可能（ログ出力のみ）
- `convertToAppException`は`utils/exceptions.dart`から。実際の例外変換ロジックもテスト対象
- `SettingsPersistence`はSharedPreferencesを使用。テスト時は`SharedPreferences.setMockInitialValues()`で初期化
