# テスト計画: テストカバレッジの向上（Phase 1）

## テスト戦略

### アプローチ
- 既存テストパターンを踏襲（Mockito + flutter_test）
- サービス層のユニットテストに集中
- 純粋ロジック → モック不要のテストを優先
- Firebase依存 → MockDataServiceで分離

### テスト実行
```bash
flutter test                                          # 全テスト
flutter test test/services/                           # サービス層のみ
flutter test test/services/item_service_test.dart     # 個別
```

## テストケース一覧

### 1. FeatureAccessControl（推定15テスト）

| グループ | テストケース | 種別 |
|---------|------------|------|
| 初期化 | initialize()でOneTimePurchaseServiceのリスナーが登録される | 正常系 |
| 初期化 | dispose()でリスナーが解除される | 正常系 |
| プレミアム判定 | プレミアム時にisPremiumUnlocked=true | 正常系 |
| プレミアム判定 | 非プレミアム時にisPremiumUnlocked=false | 正常系 |
| 機能判定 | プレミアム時にcanCustomizeTheme()=true | 正常系 |
| 機能判定 | 非プレミアム時にcanCustomizeTheme()=false | 正常系 |
| 機能判定 | プレミアム時にshouldShowAds()=false | 正常系 |
| 機能判定 | 非プレミアム時にshouldShowAds()=true | 正常系 |
| isFeatureAvailable | 各FeatureTypeの判定（3パターン） | 正常系 |
| isFeatureLocked | isFeatureAvailableの逆 | 正常系 |
| hasReachedLimit | 各LimitReachedTypeの判定 | 正常系 |
| アップグレード | プレミアム時のアップグレードプラン（isAlreadyOwned=true） | 正常系 |
| アップグレード | 非プレミアム時のアップグレードプラン | 正常系 |
| 通知 | OneTimePurchaseService変更時にnotifyListenersが呼ばれる | 正常系 |

### 2. ItemService（推定18テスト）

| グループ | テストケース | 種別 |
|---------|------------|------|
| createNewItem | IDが空の場合に自動生成される | 正常系 |
| createNewItem | IDが設定済みの場合はそのまま使用 | 正常系 |
| createNewItem | createdAtが現在時刻に設定される | 正常系 |
| saveItem | DataService.saveItemが呼ばれる | 正常系 |
| saveItem | isAnonymousパラメータが渡される | 正常系 |
| saveItem | DataService失敗時にrethrow | 異常系 |
| updateItem | DataService.updateItemが呼ばれる | 正常系 |
| updateItem | DataService失敗時にAppExceptionがスローされる | 異常系 |
| deleteItem | DataService.deleteItemが呼ばれる | 正常系 |
| deleteItem | DataService失敗時にAppExceptionがスローされる | 異常系 |
| updateItemsBatch | バッチサイズに分割して処理される | 正常系 |
| updateItemsBatch | 全アイテムが更新される | 正常系 |
| updateItemsBatch | エラー時にrethrow | 異常系 |
| deleteItems | バッチサイズに分割して削除される | 正常系 |
| deleteItems | エラー時にAppExceptionがスローされる | 異常系 |
| associateItemsWithShops | アイテムが対応するショップに関連付けられる | 正常系 |
| associateItemsWithShops | 重複アイテムが除去される | 正常系 |
| associateItemsWithShops | ショップに属さないアイテムは無視される | 境界値 |

### 3. ShopService（推定16テスト）

| グループ | テストケース | 種別 |
|---------|------------|------|
| createNewShop | デフォルトショップ(id='0')はIDそのまま | 正常系 |
| createNewShop | 通常ショップはID自動生成 | 正常系 |
| createNewShop | createdAtが設定される | 正常系 |
| saveShop | DataService.saveShopが呼ばれる | 正常系 |
| saveShop | エラー時にrethrow | 異常系 |
| updateShop | DataService.updateShopが呼ばれる | 正常系 |
| updateShop | エラー時にAppExceptionがスローされる | 異常系 |
| deleteShop | DataService.deleteShopが呼ばれる | 正常系 |
| deleteShop | デフォルトショップ削除時にSettingsPersistenceが記録 | 正常系 |
| deleteShop | エラー時にAppExceptionがスローされる | 異常系 |
| removeSharedTabReferences | 削除対象のIDが他ショップから除去される | 正常系 |
| removeSharedTabReferences | 共有相手がいなくなった場合に共有マークが削除される | 正常系 |
| createDefaultShop | デフォルトショップが正しく生成される | 正常系 |
| shouldCreateDefaultShop | 既存のデフォルトショップがある場合はfalse | 正常系 |
| shouldCreateDefaultShop | 削除済みの場合はfalse | 正常系 |
| clearAllItems | アイテム削除後にショップが更新される | 正常系 |

### 4. SharedGroupService（推定14テスト）

| グループ | テストケース | 種別 |
|---------|------------|------|
| getSharedGroupTotal | 共有グループ内の合計が計算される | 正常系 |
| getSharedGroupTotal | 対象ショップがない場合は0 | 境界値 |
| getSharedGroupBudget | 最初のショップの予算が返される | 正常系 |
| getSharedGroupBudget | 予算が設定されていない場合はnull | 境界値 |
| generateSharedGroupId | ユニークなIDが生成される | 正常系 |
| prepareSharedGroupUpdate | 現在のショップが更新される | 正常系 |
| prepareSharedGroupUpdate | 選択されたタブに現在のショップが追加される | 正常系 |
| prepareSharedGroupUpdate | 削除されたタブから参照が除去される | 正常系 |
| prepareSharedGroupUpdate | 選択タブが空の場合にsharedGroupIdがクリアされる | 正常系 |
| prepareRemoveFromSharedGroup | 対象ショップの共有情報がクリアされる | 正常系 |
| prepareRemoveFromSharedGroup | 関連タブからも参照が削除される | 正常系 |
| syncSharedGroupBudget | グループ内全ショップの予算が更新される | 正常系 |
| saveShops | DataService.updateShopが全ショップ分呼ばれる | 正常系 |
| saveShops | エラー時にrethrow | 異常系 |

## 合計テスト数（見込み）
- FeatureAccessControl: 15テスト
- ItemService: 18テスト
- ShopService: 16テスト
- SharedGroupService: 14テスト
- **合計: 約63テスト**（既存122テスト + 新規63テスト = 185テスト）
