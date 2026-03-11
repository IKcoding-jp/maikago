---
paths:
  - "lib/screens/**/*.dart"
  - "lib/widgets/**/*.dart"
---

# UI コンポーネント規約

## ダイアログ

新しいダイアログを作る際は `CommonDialog` を使用すること:

```dart
return CommonDialog(
  title: 'タイトル',
  content: ...,
  actions: [
    CommonDialog.cancelButton(context),
    CommonDialog.primaryButton(context, label: '保存', onPressed: _save),
  ],
);
```

- 表示: `CommonDialog.show()` 経由
- TextField: `CommonDialog.textFieldDecoration()` で統一
- ローディング: `CommonDialog.loading()`
- 危険操作: `CommonDialog.destructiveButton()`

## デザイン定数

- ダイアログ角丸: 20px
- カード角丸: 14px
- TextField角丸: 12px
- ボタン角丸: 20px

## テーマ対応

- 新しい画面/ウィジェット追加時は、ライトモード＋ダークモードの両方で確認すること
- 色はテーマ変数を使用（`.claude/rules/dart-style.md` 参照）
