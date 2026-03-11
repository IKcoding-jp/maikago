---
paths:
  - "lib/**/*.dart"
---

# Dart/Flutter コーディング規約

## 色の使用（最重要）

ハードコード色は禁止。テーマ変数を使うこと:

| 用途 | 使うべき変数 | 禁止パターン |
|------|------------|------------|
| エラー/削除 | `colorScheme.error` | `Colors.red` |
| テキスト | `colorScheme.onSurface` | `Colors.black87`, `Colors.black54` |
| 背景 | `theme.cardColor` | `Colors.white`, `Colors.grey[800]` |
| 区切り線 | `theme.dividerColor` | `Colors.grey.shade300` |
| サブテキスト | `colorScheme.onSurface.withValues(alpha: 0.6)` | `Colors.white70` |

## 共通コンポーネント必須

- ダイアログ → `CommonDialog`（`lib/widgets/common_dialog.dart`）
- SnackBar → `snackbar_utils.dart` 経由（`ScaffoldMessenger` 直接使用禁止）
- 数値入力フォーマッター → `input_formatters.dart` の `noLeadingZeroFormatter`

## ファイルサイズ

- 500行超 → 責務分割を検討
- 同一ロジック2箇所以上 → `lib/utils/` に共通化

## 非同期処理

- `context.pop()` 後の非同期処理 → `mounted` チェック必須
- Firestore書き込み → 楽観的更新（UI即座クローズ → バックグラウンド書き込み）
