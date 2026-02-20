# 設計書: テストカバレッジ向上 Phase 1（Issue #90）

## テスト対象の依存関係

### ItemRepository

```
ItemRepository
├── DataService (Firebase操作) → MockDataService（既存）
├── DataCacheManager (キャッシュ) → FakeDataCacheManager（新規）
└── DataProviderState (状態フラグ) → 直接インスタンス化
```

### ShopRepository

```
ShopRepository
├── DataService (Firebase操作) → MockDataService（既存）
├── DataCacheManager (キャッシュ) → FakeDataCacheManager（新規）
└── DataProviderState (状態フラグ) → 直接インスタンス化
```

## 新規作成ファイル

### テストヘルパー

| ファイル | 内容 |
|---|---|
| `test/helpers/fake_data_cache_manager.dart` | DataCacheManagerのFake実装。items/shopsリストを公開フィールドで保持 |

### テストファイル

| ファイル | テスト対象 |
|---|---|
| `test/providers/repositories/item_repository_test.dart` | ItemRepository |
| `test/providers/repositories/shop_repository_test.dart` | ShopRepository |

## FakeDataCacheManager設計

DataCacheManagerのパブリックインターフェースを最小限実装:

```dart
class FakeDataCacheManager {
  List<ListItem> items = [];
  List<Shop> shops = [];
  bool isDataLoaded = false;
  bool isLocalMode = false;

  void addItemToCache(ListItem item) → items.insert(0, item)
  void updateItemInCache(ListItem item) → items内のID一致を置換
  void removeItemFromCache(String itemId) → items内のID一致を除去
  void addShopToCache(Shop shop) → shops.add(shop)
  void updateShopInCache(Shop shop) → shops内のID一致を置換
  void removeShopFromCache(String shopId) → shops内のID一致を除去
  void associateItemsWithShops() → items→shops.itemIdsへの関連付け
}
```

## テスト戦略

### ItemRepository テストケース

| グループ | テストケース | 検証内容 |
|---|---|---|
| addItem | 新規アイテム追加 | キャッシュに追加・Firebase保存呼び出し |
| addItem | ID重複時はupdateに委譲 | updateItem呼び出し確認 |
| addItem | Firebase保存失敗時ロールバック | キャッシュから除去される |
| updateItem | アイテム更新 | キャッシュ更新・pendingUpdates登録 |
| updateItem | shops内のアイテム同期更新 | shop.itemIds内のアイテムも更新 |
| updateItemsBatch | バッチ更新 | 複数アイテムの一括更新 |
| deleteItem | アイテム削除 | キャッシュから除去・Firebase削除 |
| deleteItem | 存在しないID | 例外スロー |
| deleteItem | Firebase失敗時ロールバック | キャッシュに復元 |
| deleteItems | 複数削除 | バッチ削除・isBatchUpdating制御 |
| deleteItems | 空リスト | 早期return |

### ShopRepository テストケース

| グループ | テストケース | 検証内容 |
|---|---|---|
| ensureDefaultShop | ローカルモード時 | デフォルトショップ作成 |
| ensureDefaultShop | 非ローカルモード時 | 何もしない |
| addShop | 通常追加 | キャッシュ追加・Firebase保存 |
| addShop | デフォルトショップ(id='0') | 制限スキップ |
| updateShop | ショップ更新 | キャッシュ更新・pendingUpdates |
| updateShop | バッチ更新中 | notifyListeners抑止 |
| deleteShop | 通常削除 | sharedTabsから除去・Firebase削除 |
| deleteShop | デフォルトショップ削除 | 永続化処理 |
| updateShopName | 名前変更 | インデックス指定で更新 |
| updateShopBudget | 予算変更 | インデックス指定で更新 |
| clearAllItems | アイテム全削除 | shop.itemIds空化 |
| updateSortMode | ソートモード変更 | isIncompleteで分岐 |

## 既存テストとの整合性

- `data_provider_test.dart`はDataProviderファサード経由のテスト → Repository直接テストとは重複しない
- `shared_group_service_test.dart`はSharedGroupServiceの純粋関数テスト → SharedGroupManagerとは別レイヤー
