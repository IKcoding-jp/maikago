# タスクリスト: データモデルのイミュータブル化 & reorderItemsのレイヤー違反修正

**ステータス**: 完了
**作成日**: 2026-02-15
**完了日**: 2026-02-15

## Phase 1: モデル層のイミュータブル化

- [x] 1.1 ListItemの全フィールドにfinal追加
- [x] 1.2 Shopの全フィールドにfinal追加、items をUnmodifiableListに
- [x] 1.3 ListItemのtoJson/toMap統合（toMapをtoJsonのエイリアス化）
- [x] 1.4 ShopのtoJson/toMap統合（toMapをtoJsonのエイリアス化）
- [x] 1.5 ListItemのfromJson/fromMap統合（fromMapをfromJsonのエイリアス化）
- [x] 1.6 ShopのfromJson/fromMap統合（fromMapをfromJsonのエイリアス化）
- [x] 1.7 ListItem fromJsonの型安全性向上（name, quantity, price等）
- [x] 1.8 Shop fromJsonの型安全性向上（name等）

## Phase 2: 直接変更箇所の修正

- [x] 2.1 data_cache_manager.dart: shop.items.clear()/add()をcopyWith化
- [x] 2.2 item_repository.dart: shop.items.add()をcopyWith化（addItem内）
- [x] 2.3 recipe_confirm_screen.dart: 確認済み（RecipeIngredientクラスでありスコープ外）

## Phase 3: reorderItemsのレイヤー修正（#42）

- [x] 3.1 ItemRepositoryにreorderItemsメソッド追加
- [x] 3.2 DataProvider.reorderItemsを委譲パターンに変更

## Phase 4: テスト・検証

- [x] 4.1 ListItemのイミュータブル性テスト追加
- [x] 4.2 Shopのイミュータブル性テスト追加
- [x] 4.3 toJson/toMap統合のテスト確認
- [x] 4.4 flutter analyze 通過
- [x] 4.5 flutter test 全テスト通過（70テスト）
