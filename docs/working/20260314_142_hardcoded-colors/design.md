# 設計書: ハードコード色をテーマ変数に置換

## Issue

- **Issue番号**: #142
- **作成日**: 2026-03-14

---

## 1. 設計方針

### 1-1. 置換戦略

ハードコード色の置換は以下の3つのパターンに分類される:

| パターン | 説明 | 例 |
|---------|------|---|
| **A. テーマ変数置換** | `Theme.of(context)` 経由でテーマから取得 | `Colors.white` → `colorScheme.onPrimary` |
| **B. AppColors 定数置換** | `AppColors` クラスに定数を追加し参照 | `Colors.blue` → `AppColors.featureBlue` |
| **C. 許容（コメント付与）** | テーマ定義自体での使用。許容しコメントで意図を明記 | `settings_theme.dart` の `generateTheme()` 内 |

### 1-2. 判断基準

```
ハードコード色を発見
  ├─ Colors.transparent → 対象外（テーマに依存しない）
  ├─ settings_theme.dart の AppColors 定数定義内 → パターンC（許容）
  ├─ settings_theme.dart の generateTheme() / ヘルパーメソッド内 → パターンC（許容）
  ├─ プライマリカラー背景上の白色 → パターンA: colorScheme.onPrimary
  ├─ 通常テキスト色 → パターンA: colorScheme.onSurface
  ├─ 影色 → パターンA: theme.cardShadowColor（ThemeUtils拡張）
  ├─ カード/背景色 → パターンA: theme.cardColor / colorScheme.surface
  ├─ 装飾・機能説明用の色 → パターンB: AppColors.featureXxx
  ├─ カメラUI固有の色 → パターンB: AppColors.cameraXxx
  └─ ステータス色 → パターンB: AppColors.statusXxx
```

---

## 2. AppColors 追加定数

### 2-1. カメラUI用定数

`lib/services/settings_theme.dart` の `AppColors` クラスに追加:

```dart
// === カメラUI色 ===
static const Color cameraBackground = Colors.black;
static const Color cameraForeground = Colors.white;
static const Color cameraDisabled = Colors.grey;
```

**理由**: カメラ画面は常に暗い背景で表示されるため、テーマに依存しない固定色が必要。ただしマジックナンバーを避けるため、意味のある名前で定義する。

### 2-2. 機能装飾用定数（upcoming_features_screen 用）

既存の `featureXxx` パターンに合わせて追加:

```dart
// === 機能説明・装飾色（追加分） ===
static const Color featureBlue = Color(0xFF2196F3);      // Colors.blue
static const Color featureCyan = Color(0xFF00BCD4);       // Colors.cyan
static const Color featureDeepPurple = Color(0xFF673AB7); // Colors.deepPurple
static const Color featureTeal = Color(0xFF009688);       // Colors.teal
static const Color featureIndigo = Color(0xFF3F51B5);     // Colors.indigo
static const Color featureAmber = Color(0xFFFF9800);      // Colors.amber（≒ featureOrange と統合検討）
static const Color featurePink = Color(0xFFE91E63);       // Colors.pink
static const Color featureLightBlue = Color(0xFF03A9F4);  // Colors.lightBlue
static const Color featureLightGreen = Color(0xFF8BC34A); // Colors.lightGreen
static const Color featureDeepOrange = Color(0xFFFF5722); // Colors.deepOrange
```

**注意**: `AppColors.featureMaterialBlue` (0xFF2196F3) と `featureBlue` が同値になる可能性がある。命名の統一について実装時に確認すること。

### 2-3. ステータス色定数

```dart
// === ステータス色 ===
static const Color statusInDevelopment = Color(0xFFFF9800); // Colors.orange
static const Color statusPlanned = Color(0xFF2196F3);       // Colors.blue
```

---

## 3. ファイル別置換マッピング

### 3-1. camera_screen.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 288 | `Colors.black` | `AppColors.cameraBackground` | B |
| 310 | `Colors.white` | `AppColors.cameraForeground` | B |
| 321 | `Colors.white` | `AppColors.cameraForeground` | B |

### 3-2. camera_top_bar.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 39 | `Colors.black.withValues(alpha: 0.7)` | `AppColors.cameraBackground.withValues(alpha: 0.7)` | B |
| 48 | `Colors.white` | `AppColors.cameraForeground` | B |
| 55 | `Colors.white` | `AppColors.cameraForeground` | B |
| 65 | `Colors.white` | `AppColors.cameraForeground` | B |
| 70 | `Colors.white` | `AppColors.cameraForeground` | B |

### 3-3. camera_bottom_controls.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 47 | `Colors.black.withValues(alpha: 0.7)` | `AppColors.cameraBackground.withValues(alpha: 0.7)` | B |
| 79 | `Colors.grey` | `AppColors.cameraDisabled` | B |
| 79 | `Colors.white` | `AppColors.cameraForeground` | B |
| 80 | `Colors.white` | `AppColors.cameraForeground` | B |
| 83 | `Colors.black` | `AppColors.cameraBackground` | B |
| 84 | `Colors.black` | `AppColors.cameraBackground` | B |
| 95 | `Colors.white70` | `AppColors.cameraForeground.withValues(alpha: 0.7)` | B |
| 106 | `Colors.black.withValues(alpha: 0.5)` | `AppColors.cameraBackground.withValues(alpha: 0.5)` | B |
| 116 | `Colors.white` | `AppColors.cameraForeground` | B |
| 128 | `Colors.white.withValues(alpha: 0.2)` | `AppColors.cameraForeground.withValues(alpha: 0.2)` | B |
| 134 | `Colors.white` | `AppColors.cameraForeground` | B |
| 144 | `Colors.white` | `AppColors.cameraForeground` | B |

### 3-4. splash_screen.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 152 | `Colors.white.withValues(alpha: 0.9)` | `colorScheme.onPrimary.withValues(alpha: 0.9)` | A |
| 156 | `Colors.black.withValues(alpha: 0.1)` | `theme.cardShadowColor` | A |
| 175 | `Colors.white` | `colorScheme.onPrimary` | A |
| 184 | `Colors.white.withValues(alpha: 0.8)` | `colorScheme.onPrimary.withValues(alpha: 0.8)` | A |
| 194 | `Colors.white.withValues(alpha: 0.8)` | `colorScheme.onPrimary.withValues(alpha: 0.8)` | A |
| 206 | `Colors.white.withValues(alpha: 0.7)` | `colorScheme.onPrimary.withValues(alpha: 0.7)` | A |
| 214 | `Colors.white.withValues(alpha: 0.7)` | `colorScheme.onPrimary.withValues(alpha: 0.7)` | A |

**注意**: `splash_screen.dart` では `const` ウィジェットが使えなくなる箇所がある。`const Text(...)` → `Text(...)` に変更が必要。

### 3-5. upcoming_features_screen.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 80 | `Colors.blue` | `AppColors.featureBlue` | B |
| 87 | `Colors.green` | `AppColors.featureMaterialGreen` | B |
| 95 | `Colors.cyan` | `AppColors.featureCyan` | B |
| 102 | `Colors.deepPurple` | `AppColors.featureDeepPurple` | B |
| 109 | `Colors.purple` | `AppColors.featurePurple` | B |
| 116 | `Colors.red` | `AppColors.featureRed` | B |
| 123 | `Colors.teal` | `AppColors.featureTeal` | B |
| 130 | `Colors.indigo` | `AppColors.featureIndigo` | B |
| 137 | `Colors.amber` | `AppColors.featureAmber` | B |
| 144 | `Colors.pink` | `AppColors.featurePink` | B |
| 151 | `Colors.lightBlue` | `AppColors.featureLightBlue` | B |
| 158 | `Colors.lightGreen` | `AppColors.featureLightGreen` | B |
| 165 | `Colors.deepOrange` | `AppColors.featureDeepOrange` | B |
| 187 | `Colors.orange` | `AppColors.statusInDevelopment` | B |
| 187 | `Colors.blue` | `AppColors.statusPlanned` | B |

### 3-6. font_select_screen.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 110 | `Colors.black.withValues(alpha: 0.05)` | `theme.cardShadowColor` (※alpha値が異なるため要検討) | A |
| 239 | `Colors.grey.withValues(alpha: 0.31)` | `colorScheme.outline.withValues(alpha: 0.31)` | A |
| 252 | `Colors.black.withValues(alpha: 0.03)` | `theme.cardShadowColor` | A |
| 292 | `Colors.white` | `colorScheme.onPrimary` | A |
| 297 | `Colors.white` | `colorScheme.onPrimary` | A |
| 312 | `Colors.grey` | `colorScheme.outline` | A |
| 318 | `Colors.white` | `colorScheme.onPrimary` | A |
| 323 | `Colors.white` | `colorScheme.onPrimary` | A |

### 3-7. font_size_select_screen.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 176 | `Colors.white` | `widget.theme.colorScheme.onPrimary` | A |

### 3-8. theme_select_screen.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 93 | `Colors.black.withValues(alpha: 0.05)` | `theme.cardShadowColor` | A |

### 3-9. usage_header.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 26 | `Colors.white` | `colorScheme.onPrimary` | A |
| 33 | `Colors.white` | `colorScheme.onPrimary` | A |
| 42 | `Colors.white` | `colorScheme.onPrimary` | A |

**注意**: ヘッダーはプライマリカラーのグラデーション背景上なので `onPrimary` が適切。

### 3-10. usage_step_card.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 30 | `Colors.black.withValues(alpha: 0.1)` | `theme.cardShadowColor` | A |
| 71 | `Colors.white` | `colorScheme.onPrimary` | A |

**注意**: L71 はステップ番号の円形バッジ内のテキスト。背景が `color`（featureXxx色）なので `onPrimary` が適切。

### 3-11. usage_screen_explanation_card.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 16 | `Colors.black.withValues(alpha: 0.1)` | `theme.cardShadowColor` | A |
| 110 | `Colors.grey[600]` | `theme.subtextColor` | A |

### 3-12. usage_list_operation_card.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 17 | `Colors.black.withValues(alpha: 0.1)` | `theme.cardShadowColor` | A |
| 127 | `Colors.white` | `colorScheme.onPrimary` | A |

**注意**: L127 はバッジ内テキスト。背景が `color`（featureXxx色）なので `onPrimary` が適切。

### 3-13. usage_camera_feature_card.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 17 | `Colors.black.withValues(alpha: 0.1)` | `theme.cardShadowColor` | A |

### 3-14. welcome_dialog.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 143 | `Colors.black.withValues(alpha: 0.15)` | `theme.cardShadowColor` | A |

### 3-15. image_analysis_progress_dialog.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 108 | `Colors.black.withValues(alpha: 0.1)` | `theme.cardShadowColor` | A |

### 3-16. camera_guidelines_dialog.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 206 | `Colors.white` | `colorScheme.onPrimary` | A |

**注意**: ボタンの `foregroundColor` であり、背景が `AppColors.primary` なので `onPrimary` が適切。

### 3-17. upgrade_promotion_widget.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 64 | `Colors.black.withValues(alpha: 0.1)` | `theme.cardShadowColor` | A |

### 3-18. main_screen.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 440 | `Colors.white`（`currentTheme == 'dark'` 分岐内） | `colorScheme.onPrimary` | A |
| 443 | `Colors.white`（`currentTheme == 'dark'` 分岐内） | `colorScheme.onPrimary` | A |

**注意**: ダークモード判定の三項演算子ごと削除し、テーマから直接取得する形に変更。テーマ側で吸収済みのはずなので、`colorScheme.primary` / `colorScheme.onSurface` 等が適切か実装時に確認。

### 3-19. item_edit_dialog.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 227 | `Colors.white`（`brightness == dark` 分岐） | `colorScheme.onSurface` | A |
| 236 | `Colors.white`（`brightness == dark` 分岐） | `colorScheme.onSurface` | A |

**注意**: ダーク/ライト分岐を削除し、`colorScheme.onSurface` に統一。

### 3-20. main_drawer.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 187 | `Colors.orange.shade700` | `AppColors.warning` | B |

**注意**: デバッグオーバーライド表示用テキスト色。`AppColors.warning` (0xFFFFB74D) が `orange.shade700` (0xFFF57C00) と若干異なるため、正確に合わせる場合は `AppColors` に専用定数を追加するか、`AppColors.warning` の値を調整する。

### 3-21. recipe_confirm_screen.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 410 | `Colors.white` | `theme.cardColor` | A |
| 413 | `Colors.black.withValues(alpha: 0.05)` | `theme.cardShadowColor` | A |
| 439 | `Colors.white` | `colorScheme.onPrimary` | A |

### 3-22. theme_utils.dart

| 行 | 現在のコード | 置換後 | カテゴリ |
|----|------------|--------|---------|
| 7 | `Colors.black.withValues(alpha: 0.3)` | 許容（テーマユーティリティ定義自体）。コメント付与 | C |
| 8 | `Colors.black.withValues(alpha: 0.1)` | 同上 | C |

---

## 4. const 制約への対応

テーマ変数への置換により、以下のパターンで `const` が使えなくなる:

```dart
// Before（const 可能）
const Icon(Icons.check, size: 12, color: Colors.white)

// After（const 不可 → const を外す）
Icon(Icons.check, size: 12, color: colorScheme.onPrimary)
```

影響ファイル:
- `camera_top_bar.dart`: `const Icon(...)` → `Icon(...)`
- `camera_bottom_controls.dart`: `const CircularProgressIndicator(...)` → `CircularProgressIndicator(...)`
- `splash_screen.dart`: `const Text(...)` → `Text(...)`
- `usage_header.dart`: `const Icon(...)` → `Icon(...)`
- `font_select_screen.dart`: `const Icon(...)`, `const Row(...)` → `Icon(...)`, `Row(...)`

パフォーマンスへの影響は無視できるレベル（ウィジェットの再構築コストは極めて小さい）。

---

## 5. BuildContext の取得

`StatelessWidget` で `Theme.of(context)` を使う場合、`build` メソッド内または `context` を引数に受け取るメソッド内でのみ使用可能。全対象ファイルでこの条件を満たしていることを確認済み。

`camera_bottom_controls.dart` では一部メソッド（`_buildCaptureButton`）が `context` を受け取っていないため、引数追加が必要:

```dart
// Before
Widget _buildCaptureButton() { ... }

// After（context 不要 - AppColors 定数なので）
// AppColors.cameraXxx は static const なので BuildContext 不要
Widget _buildCaptureButton() { ... }
```

`AppColors` の static const 定数を使う場合は `BuildContext` は不要なので、カメラ系ファイルの多くはメソッドシグネチャの変更不要。
