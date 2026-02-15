# 要件定義: データモデルのイミュータブル化 & reorderItemsのレイヤー違反修正

## Issue
- #30: [High/Architecture] データモデルのイミュータブル化
- #42: [Medium/Architecture] DataProvider reorderItemsのレイヤー違反修正

## 背景
`ListItem` と `Shop` のデータモデルが完全にミュータブルで、外部から直接フィールド変更可能。
また `DataProvider.reorderItems` がRepository層をバイパスしてキャッシュを直接操作している。

## 要件一覧

### R1: ListItemフィールドのfinal化
- 全フィールドに `final` を追加
- `copyWith` 経由での変更のみ許可
- 直接変更している箇所を `copyWith` に修正

### R2: Shopフィールドのfinal化
- 全フィールドに `final` を追加
- `items` を `List<ListItem>` から `UnmodifiableListView` に変更（または内部で防御コピー）
- `shop.items.add()`, `shop.items.clear()` 等の直接操作を `copyWith` に修正

### R3: toJson/toMapの重複解消
- `ListItem`: `toMap()` を `toJson()` のエイリアスにする
- `Shop`: `toMap()` を `toJson()` のエイリアスにする
- `fromMap()` も同様に `fromJson()` のエイリアスにする

### R4: fromJson/fromMapの型安全性向上
- `name`, `quantity`, `price` 等の必須フィールドにデフォルト値付き安全キャストを追加
- `?.toString()`, `as int? ?? 0` 等のnullセーフ変換

### R5: reorderItemsのItemRepositoryへの移設
- `DataProvider.reorderItems` のロジックを `ItemRepository` に移動
- `DataProvider` からは委譲パターンで呼び出す
- 既存の `updateItemsBatch` と同様のパターンに統一

## 制約
- 外部インターフェース（メソッドシグネチャ）は変更しない
- 既存テストが全て通ること
- `flutter analyze` でエラーなし
