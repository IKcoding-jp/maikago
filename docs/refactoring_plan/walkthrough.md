# まいカゴ リファクタリング - フェーズ1 中間報告

## 実施日時
2026-01-08

## 完了項目

### ダイアログの切り出し (3ファイル)

| ダイアログ | 新ファイル | 行数 |
|-----------|-----------|------|
| BudgetDialog | [budget_dialog.dart](file:///d:/Dev/maikago/lib/screens/main/dialogs/budget_dialog.dart) | 約200行 |
| SortDialog | [sort_dialog.dart](file:///d:/Dev/maikago/lib/screens/main/dialogs/sort_dialog.dart) | 約90行 |
| ItemEditDialog | [item_edit_dialog.dart](file:///d:/Dev/maikago/lib/screens/main/dialogs/item_edit_dialog.dart) | 約285行 |

## 成果

### main_screen.dart の削減

| 指標 | 変更前 | 変更後 | 削減量 |
|------|--------|--------|--------|
| 行数 | 3,530行 | 2,990行 | **540行削減** |
| バイトサイズ | 154KB | 132KB | **22KB削減** |

### 新規ディレクトリ構造

```
lib/screens/
├── main_screen.dart          (2,990行)
└── main/
    ├── dialogs/
    │   ├── budget_dialog.dart    ✅ 新規
    │   ├── item_edit_dialog.dart ✅ 新規
    │   └── sort_dialog.dart      ✅ 新規
    └── widgets/                  (次フェーズで使用)
```

## 検証結果

- **Dartアナライザ**: エラー0件
- **警告**: 既存コードの非推奨メソッド使用のみ（今回の変更とは無関係）

## 設計上の工夫

1. **コールバック方式**
   - 広告表示などの親コンテキスト依存処理はコールバックとして渡す
   - テスト容易性を確保

2. **静的showメソッド**
   - 各ダイアログに `Dialog.show()` ヘルパーを追加
   - 呼び出し側のコードを簡潔化

```dart
// 変更前
showDialog(context: context, builder: (ctx) => _BudgetDialog(shop: shop));

// 変更後
BudgetDialog.show(context, shop);
```

## 残り作業

- [ ] TabEditDialog の切り出し（`getCustomTheme()` 依存のため要検討）
- [ ] BottomSummaryWidget の独立ファイル化
- [ ] TabBarWidget / ItemListWidget の切り出し

## 次のアクション

1. **継続**: 残りのUI分割を実施
2. **確認**: 実機でのテスト（任意）
