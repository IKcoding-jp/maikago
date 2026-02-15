# 設計書: Issue #35 テーマ色分岐・SnackBar等のコード重複解消

## 方針

### 1. テーマ色分岐の解消

**現状パターン（置換対象）:**

```dart
// パターンA: 三項演算子の連鎖
color: currentTheme == 'dark' ? Colors.white : Colors.black87,

// パターンB: switch文の重複
Color _getCardColor() {
  switch (widget.currentTheme) {
    case 'dark': return const Color(0xFF2D2D2D);
    default: return Colors.white;
  }
}
```

**解決策: `Theme.of(context).colorScheme` のセマンティックカラーを活用**

- `colorScheme.onSurface` → テキスト色（dark: white, light: black87）
- `colorScheme.surface` → カード背景色
- `colorScheme.primary` → プライマリカラー
- 既に `generateTheme()` で正しく設定済み。各ファイルのハードコード分岐を colorScheme 参照に置換

**追加ヘルパー（colorScheme で表現できない場合のみ）:**

```dart
// lib/utils/theme_utils.dart に追加
extension ThemeUtils on ThemeData {
  /// カード用の影色を取得
  Color get cardShadowColor =>
      brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.1);
}
```

### 2. SnackBar ユーティリティ

**新規ファイル: `lib/utils/snackbar_utils.dart`**

```dart
void showErrorSnackBar(BuildContext context, dynamic error) {
  final message = error is Exception
      ? error.toString().replaceAll('Exception: ', '')
      : error.toString();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: const Duration(seconds: 3),
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: Theme.of(context).colorScheme.primary,
      duration: const Duration(seconds: 3),
    ),
  );
}

void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ),
  );
}
```

## 影響範囲

### テーマ色分岐の置換対象ファイル

| ファイル | 箇所数 | 主な置換内容 |
|---------|--------|-------------|
| `main_screen.dart` | 多数 | `currentTheme == 'dark'` → `colorScheme` 参照 |
| `release_history_screen.dart` | 7+ | 同上 |
| `calculator_screen.dart` | 6+ | 同上 + `_getCardColor()` 等の削除 |
| `version_update_dialog.dart` | 6 | 同上 |

### SnackBar 置換対象ファイル（16ファイル）

- `main_screen.dart`, `bottom_summary_widget.dart`, `update_confirm_dialog.dart`
- `recipe_confirm_screen.dart`, `ocr_result_confirm_screen.dart`
- `enhanced_camera_screen.dart`, `login_screen.dart`, `camera_screen.dart`
- `subscription_screen_new.dart`, `one_time_purchase_screen.dart`
- `maikago_premium.dart`, `account_screen.dart`
- `donation_screen.dart`, `feedback_screen.dart`
- `budget_dialog.dart`, `item_edit_dialog.dart`
