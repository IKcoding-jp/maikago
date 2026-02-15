# テスト計画: データモデルのイミュータブル化 & reorderItemsのレイヤー違反修正

## 既存テスト（変更なしで通ること）

- `test/models/list_item_test.dart` — copyWith, toJson/fromJson, toMap/fromMap, priceWithTax
- `test/models/shop_test.dart` — copyWith, toJson/fromJson, toMap/fromMap, clearBudget等
- `test/providers/data_provider_test.dart` — DataProviderの統合テスト

## 追加テスト

### ListItemイミュータブル性テスト
- final化によりコンパイルエラーで直接変更が防止されることを確認（コンパイル時保証）
- copyWithで変更した場合、元のインスタンスが変更されないことを確認

### Shopイミュータブル性テスト
- items リストが外部から変更できないことを確認（UnsupportedError）
- copyWithでitems変更時、元のインスタンスが影響を受けないことを確認

### toJson/toMap統合テスト
- toJson()とtoMap()が同じ結果を返すことを確認
- fromJson()とfromMap()が同じ結果を返すことを確認

### fromJsonの型安全性テスト
- nameがnullの場合にデフォルト値が適用されることを確認
- quantityがnullの場合にデフォルト値が適用されることを確認
- priceがnullの場合にデフォルト値が適用されることを確認

## テスト実行コマンド

```bash
flutter test test/models/list_item_test.dart
flutter test test/models/shop_test.dart
flutter test test/providers/data_provider_test.dart
flutter test  # 全テスト
flutter analyze  # 静的解析
```
