# 設計書: データモデルのイミュータブル化 & reorderItemsのレイヤー違反修正

## 変更対象ファイル

### モデル層
- `lib/models/list.dart` — ListItemクラスのイミュータブル化、toJson/toMap統合、型安全性
- `lib/models/shop.dart` — Shopクラスのイミュータブル化、toJson/toMap統合、型安全性

### Provider/Repository層
- `lib/providers/data_provider.dart` — reorderItemsの委譲化
- `lib/providers/repositories/item_repository.dart` — reorderItemsメソッド追加

### キャッシュ層（直接変更の修正）
- `lib/providers/managers/data_cache_manager.dart` — shop.items.clear()/add()をcopyWith化
- `lib/providers/repositories/item_repository.dart` — shop.items.add()をcopyWith化

### UI層
- `lib/screens/recipe_confirm_screen.dart` — _ingredients直接変更をcopyWith化（※特殊ケース）

### テスト
- `test/models/list_item_test.dart` — イミュータブル性テスト追加
- `test/models/shop_test.dart` — イミュータブル性テスト追加

## 設計詳細

### ListItemイミュータブル化

```dart
class ListItem {
  ListItem({
    required this.id,
    required this.name,
    // ...
  });

  final String id;        // final追加
  final String name;      // final追加
  final int quantity;     // final追加
  // ... 全フィールドにfinal追加
}
```

### Shopイミュータブル化

```dart
class Shop {
  Shop({
    required this.id,
    required this.name,
    List<ListItem>? items,
    // ...
  }) : _items = items != null ? List.unmodifiable(items) : const [];

  final String id;
  final String name;
  final List<ListItem> _items;  // 内部はprivateフィールド
  List<ListItem> get items => _items;  // getterで公開（UnmodifiableListView）
  // ...
}
```

### toJson/toMap統合

```dart
// ListItem
Map<String, dynamic> toJson() => { /* 実装 */ };
Map<String, dynamic> toMap() => toJson();  // エイリアス

// fromJson/fromMapも同様
factory ListItem.fromMap(Map<String, dynamic> map) => ListItem.fromJson(map);
```

### reorderItemsの移設

```dart
// ItemRepository に新メソッド追加
Future<void> reorderItems(Shop updatedShop, List<ListItem> updatedItems) async {
  // DataProviderから移設したロジック
  // _shopRepository.pendingUpdatesの代わりにpendingShopUpdatesパラメータを受け取る
}
```

```dart
// DataProvider では委譲
Future<void> reorderItems(Shop updatedShop, List<ListItem> updatedItems) async {
  await _syncManager.runBatchUpdate(() async {
    await _itemRepository.reorderItems(
      updatedShop,
      updatedItems,
      pendingShopUpdates: _shopRepository.pendingUpdates,
    );
  });
}
```

### recipe_confirm_screenの修正

`_ingredients` は `ListItem` ではなく独自の `Map` ベースの構造（`result['name']`, `result['quantity']`）のため、確認が必要。直接変更がある場合は `copyWith` に修正。

## 影響範囲

- キャッシュ層のリスト操作パターンが変わる（`shop.items.add()` → `shop.copyWith(items: [...shop.items, newItem])`）
- 外部API（DataProviderのメソッドシグネチャ）は変更なし
- UI層への影響は最小限
