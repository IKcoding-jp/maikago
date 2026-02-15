# 設計書: Lint設定の強化（#44 + #48）

## 対象ファイル

### 設定ファイル
- `analysis_options.yaml` — lint設定の変更

### #44: mounted チェック追加対象
- `lib/screens/main/ocr_result_confirm_screen.dart` — `_showSelectExistingItemDialog()` の setState前

### #48: 追加lintルールによる修正対象
- 追加するルールに応じて影響範囲が変動
- `flutter analyze` 実行結果で特定

## 設計方針

### analysis_options.yaml の変更
```yaml
include: package:lints/recommended.yaml

analyzer:
  errors:
    # use_build_context_synchronously を有効化（ignore削除）

linter:
  rules:
    avoid_print: true
    # 追加ルール（段階的に追加）
    sort_constructors_first: true
    unawaited_futures: true
    # 他のルールは影響範囲を確認してから追加
```

### mounted チェックのパターン
- StatefulWidget: `if (!mounted) return;`
- StatelessWidget callback: `if (!context.mounted) return;`
