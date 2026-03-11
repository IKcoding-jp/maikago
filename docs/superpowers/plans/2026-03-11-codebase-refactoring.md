# まいカゴ コードベース リファクタリング計画

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** CLAUDE.md規約への完全準拠、技術的負債の解消、コード品質の統一的改善

**Architecture:** テーマ基盤を先に整備し、その上でハードコード色を排除。共通コンポーネント（CommonDialog, snackbar_utils）への統一を並行実施。最後に大規模ファイルの責務分割。

**Tech Stack:** Flutter/Dart, Provider, Material 3 ColorScheme, go_router

---

## 依存関係グラフ

```
Issue #1 (テーマ基盤) ─┬→ Issue #2 (色: メイン画面)
                       ├→ Issue #3 (色: Drawer画面)
                       ├→ Issue #4 (色: ウィジェット)
                       └→ Issue #5 (色: 課金画面)

Issue #6 (CommonDialog統一)     ← 独立
Issue #7 (SnackBar統一)         ← 独立
Issue #8 (withAlpha移行)        ← 独立
Issue #9 (重複/死コード整理)     ← 独立
Issue #10 (責務分割: donation)   ← Issue #3 の後
Issue #11 (責務分割: その他)     ← Issue #2,#4 の後
```

**並行実行可能グループ:**
- Group A: Issue #1 → #2, #3, #4, #5
- Group B: Issue #6, #7, #8, #9（全て独立、並行可能）
- Group C: Issue #10, #11（Group A完了後）

---

## Chunk 1: テーマ基盤とユーティリティ修正

### Issue #1: テーマ基盤の改善 — settings_theme.dart + theme_utils.dart

**優先度:** 最高（他Issue の前提条件）
**影響範囲:** 全画面のテーマカラー派生に影響
**推定規模:** 中（2ファイル、約40箇所）

**背景:**
- `settings_theme.dart` の `getTextColor()` 等がテーマキーを受け取りハードコード色を返している
- `theme_utils.dart` の `subtextColor` が `Colors.white70` / `Colors.black54` をハードコード
- `generateTheme()` 内の `error: Colors.red` は ColorScheme 定義値なので許容
- `snackbar_utils.dart` の `showWarningSnackBar` が `Colors.orange` をハードコード
- `common_dialog.dart:161` の `fillColor: isDark ? Colors.grey[800] : Colors.white` がテーマ変数未使用

**Files:**
- Modify: `lib/utils/theme_utils.dart` (14行 → 全体書き換え)
- Modify: `lib/utils/snackbar_utils.dart:50` (showWarningSnackBar の Colors.orange)
- Modify: `lib/widgets/common_dialog.dart:161` (fillColor のハードコード)
- Modify: `lib/services/settings_theme.dart:309-327` (getTextColor等の非推奨メソッド)
- Test: `test/utils/theme_utils_test.dart` (新規)
- Test: `test/utils/snackbar_utils_test.dart` (新規)

**Steps:**

- [ ] **Step 1: theme_utils.dart のテスト作成**

```dart
// test/utils/theme_utils_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maikago/utils/theme_utils.dart';

void main() {
  group('ThemeUtils', () {
    test('subtextColor uses colorScheme.onSurface with alpha for light theme', () {
      final theme = ThemeData(
        colorScheme: const ColorScheme.light(),
      );
      final color = theme.subtextColor;
      // onSurface with alpha 0.6 — 不透明度のみ検証
      expect(color.a, closeTo(0.6, 0.05));
    });

    test('subtextColor uses colorScheme.onSurface with alpha for dark theme', () {
      final theme = ThemeData(
        colorScheme: const ColorScheme.dark(),
      );
      final color = theme.subtextColor;
      expect(color.a, closeTo(0.6, 0.05));
    });

    test('cardShadowColor returns lower alpha for light theme', () {
      final theme = ThemeData(brightness: Brightness.light);
      final color = theme.cardShadowColor;
      expect(color.a, closeTo(0.1, 0.05));
    });

    test('cardShadowColor returns higher alpha for dark theme', () {
      final theme = ThemeData(brightness: Brightness.dark);
      final color = theme.cardShadowColor;
      expect(color.a, closeTo(0.3, 0.05));
    });
  });
}
```

- [ ] **Step 2: テスト実行 → 失敗確認**

Run: `flutter test test/utils/theme_utils_test.dart`
Expected: subtextColor のテストが FAIL（現在は Colors.white70/black54 を返すため alpha が一致しない）

- [ ] **Step 3: theme_utils.dart を修正**

```dart
// lib/utils/theme_utils.dart
extension ThemeUtils on ThemeData {
  Color get cardShadowColor => brightness == Brightness.dark
      ? Colors.black.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.1);

  Color get subtextColor =>
      colorScheme.onSurface.withValues(alpha: 0.6);
}
```

- [ ] **Step 4: テスト実行 → 成功確認**

Run: `flutter test test/utils/theme_utils_test.dart`
Expected: ALL PASS

- [ ] **Step 5: snackbar_utils.dart の Colors.orange を修正**

`showWarningSnackBar` の背景色を `Theme.of(context).colorScheme.tertiary` または
`Theme.of(context).colorScheme.secondaryContainer` に変更。

- [ ] **Step 6: common_dialog.dart の fillColor を修正**

`isDark ? Colors.grey[800] : Colors.white` → `theme.cardColor` に変更。

- [ ] **Step 7: settings_theme.dart の getTextColor 等に @Deprecated 注記追加**

```dart
@Deprecated('Use Theme.of(context).colorScheme.onSurface instead')
static Color getTextColor(String selectedTheme) { ... }

@Deprecated('Use Theme.of(context).textTheme with subtextColor extension instead')
static Color getSubtextColor(String selectedTheme) { ... }
```

注: 呼び出し元を全て修正するまでは削除せず、Deprecated アノテーションで警告を出す。

- [ ] **Step 8: flutter analyze 実行**

Run: `flutter analyze`
Expected: 新規エラー 0件

- [ ] **Step 9: コミット**

```bash
git add lib/utils/theme_utils.dart lib/utils/snackbar_utils.dart lib/widgets/common_dialog.dart lib/services/settings_theme.dart test/utils/theme_utils_test.dart
git commit -m "refactor(theme): テーマ基盤改善 — subtextColor/snackbar/dialog のハードコード色排除"
```

---

### Issue #7: SnackBar統一 — ScaffoldMessenger直接構築の排除

**優先度:** 中（独立実行可能）
**影響範囲:** 2ファイル
**推定規模:** 小

**Files:**
- Modify: `lib/screens/login_screen.dart:85`
- Modify: `lib/screens/recipe_confirm_screen.dart:211`

**Steps:**

- [ ] **Step 1: login_screen.dart の ScaffoldMessenger 直接呼び出しを特定**

行85付近の `ScaffoldMessenger.of(context).showSnackBar(...)` を確認。

- [ ] **Step 2: snackbar_utils の適切な関数に置換**

エラー表示なら `showErrorSnackBar(context, error)`、成功なら `showSuccessSnackBar(context, message)` に変更。

- [ ] **Step 3: recipe_confirm_screen.dart も同様に修正**

行211付近の `ScaffoldMessenger.of(context)` を `snackbar_utils` 経由に変更。

- [ ] **Step 4: flutter analyze && flutter test**

Run: `flutter analyze && flutter test`
Expected: エラー 0件、テスト全パス

- [ ] **Step 5: コミット**

```bash
git add lib/screens/login_screen.dart lib/screens/recipe_confirm_screen.dart
git commit -m "refactor(ui): ScaffoldMessenger直接構築をsnackbar_utils経由に統一"
```

---

### Issue #8: withAlpha() → withValues(alpha:) 移行

**優先度:** 中（独立実行可能）
**影響範囲:** 約30箇所、5ファイル
**推定規模:** 小〜中

**背景:** `withAlpha(int)` は int(0-255) を取る旧API。`withValues(alpha: double)` は 0.0-1.0 で Flutter 3.27+ 推奨。

**Files:**
- Modify: `lib/services/settings_theme.dart` (9箇所: 行412, 417, 428, 455, 563, 567, 573, 580, 597)
- Modify: `lib/screens/login_screen.dart` (6箇所: 行132, 133, 153, 224, 275, 279)
- Modify: `lib/screens/drawer/settings/account_screen.dart` (6箇所: 行54, 75, 123, 159, 182, 207)
- Modify: `lib/screens/drawer/settings/settings_font.dart` (7箇所: 行202, 207, 238, 338, 342, 348, 355)
- Modify: `lib/screens/main/widgets/main_app_bar.dart` (2箇所: 行91, 190)

**Steps:**

- [ ] **Step 1: 全 withAlpha 使用箇所を検索で確認**

Run: `grep -rn "\.withAlpha(" lib/`
変換表を作成: `withAlpha(N)` → `withValues(alpha: N/255)`

- [ ] **Step 2: settings_theme.dart の9箇所を変換**

例: `.withAlpha(200)` → `.withValues(alpha: 0.784)` (200/255)
例: `.withAlpha(128)` → `.withValues(alpha: 0.502)` (128/255)

- [ ] **Step 3: login_screen.dart の6箇所を変換**
- [ ] **Step 4: account_screen.dart の6箇所を変換**
- [ ] **Step 5: settings_font.dart の7箇所を変換**
- [ ] **Step 6: main_app_bar.dart の2箇所を変換**

- [ ] **Step 7: flutter analyze && flutter test**

Run: `flutter analyze && flutter test`
Expected: エラー 0件、テスト全パス

- [ ] **Step 8: コミット**

```bash
git add lib/services/settings_theme.dart lib/screens/login_screen.dart lib/screens/drawer/settings/account_screen.dart lib/screens/drawer/settings/settings_font.dart lib/screens/main/widgets/main_app_bar.dart
git commit -m "refactor(ui): withAlpha()をwithValues(alpha:)に統一移行"
```

---

### Issue #9: 重複コード・死コード整理

**優先度:** 低（独立実行可能）
**影響範囲:** 3ファイル
**推定規模:** 小

**Files:**
- Modify: `lib/services/app_info_service.dart:84-96` (_compareVersions 削除)
- Modify: `lib/models/release_history.dart:122-137` (compareVersions を公開APIとして維持)
- Modify: `lib/providers/data_provider.dart:111-114` (saveUserTaxRateOverride 空メソッド)

**Steps:**

- [ ] **Step 1: _compareVersions の呼び出し元を確認**

`app_info_service.dart` 内で `_compareVersions` がどこから呼ばれているか確認。

- [ ] **Step 2: _compareVersions を ReleaseHistory.compareVersions に置換**

`AppInfoService` 内の `_compareVersions(a, b)` 呼び出しを `ReleaseHistory.compareVersions(a, b)` に変更し、`_compareVersions` メソッドを削除。

- [ ] **Step 3: saveUserTaxRateOverride の呼び出し元を確認**

呼び出し元がなければ空メソッドを削除。呼び出し元があれば呼び出し元も含めて削除。

- [ ] **Step 4: flutter analyze && flutter test**

Run: `flutter analyze && flutter test`
Expected: エラー 0件、テスト全パス

- [ ] **Step 5: コミット**

```bash
git add lib/services/app_info_service.dart lib/models/release_history.dart lib/providers/data_provider.dart
git commit -m "refactor: 重複バージョン比較ロジック統合、死コード(空メソッド)削除"
```

---

## Chunk 2: ハードコード色の排除（CLAUDE.md規約準拠）

### Issue #2: ハードコード色排除 — メイン画面系

**優先度:** 高（Issue #1 完了後）
**影響範囲:** 3ファイル、約25箇所
**推定規模:** 中

**依存:** Issue #1（theme_utils.dart の subtextColor 修正が前提）

**Files:**
- Modify: `lib/screens/main/widgets/bottom_summary_widget.dart` (~15箇所、特に isDark 分岐7箇所)
- Modify: `lib/screens/main/widgets/main_app_bar.dart` (~8箇所)
- Modify: `lib/screens/main/utils/startup_helpers.dart` (3箇所: 行231, 247, 258)

**変換ルール（全Issue共通）:**

| 現在のパターン | 変換先 |
|---|---|
| `Colors.red` | `colorScheme.error` |
| `Colors.black87`, `Colors.black54` | `colorScheme.onSurface` |
| `Colors.white70` | `colorScheme.onSurface.withValues(alpha: 0.6)` |
| `Colors.white` (背景) | `theme.cardColor` or `colorScheme.surface` |
| `Colors.grey[800]` (背景) | `theme.cardColor` or `colorScheme.surfaceContainerHighest` |
| `Colors.grey.shade300` (区切り線) | `theme.dividerColor` |
| `Colors.orange` | `colorScheme.tertiary` or `colorScheme.secondaryContainer` |
| `Colors.green` | `colorScheme.primary`（成功の意味）or 適切なセマンティック色 |
| `Colors.blue` | `colorScheme.primary` |
| `isDark ? X : Y` (色分岐) | テーマ変数に統一（分岐不要に） |

**Steps:**

- [ ] **Step 1: bottom_summary_widget.dart の isDark 分岐パターンを列挙**

行609, 694, 702, 716, 724, 744, 752 の各パターンを確認し、対応するテーマ変数を決定。

- [ ] **Step 2: bottom_summary_widget.dart を修正**

各 `isDark ? Colors.xxx : Colors.yyy` を上記変換ルールに従い置換。

- [ ] **Step 3: main_app_bar.dart を修正**

行75, 89-90, 101-102, 109-110, 205, 207-208, 238 を修正。

- [ ] **Step 4: startup_helpers.dart を修正**

行231, 247, 258 の `Colors.white`, `Colors.black87`, `Colors.grey` を修正。

- [ ] **Step 5: ライトモード + ダークモードで目視確認**

Run: `flutter run -d chrome` で両モード確認。

- [ ] **Step 6: flutter analyze && flutter test**

Run: `flutter analyze && flutter test`
Expected: エラー 0件

- [ ] **Step 7: コミット**

```bash
git add lib/screens/main/widgets/bottom_summary_widget.dart lib/screens/main/widgets/main_app_bar.dart lib/screens/main/utils/startup_helpers.dart
git commit -m "refactor(ui): メイン画面系のハードコード色をテーマ変数に統一"
```

---

### Issue #3: ハードコード色排除 — Drawer画面系

**優先度:** 高（Issue #1 完了後）
**影響範囲:** 5ファイル、約30箇所
**推定規模:** 中

**依存:** Issue #1

**Files:**
- Modify: `lib/screens/drawer/settings/settings_screen.dart` (Colors.orange 5箇所)
- Modify: `lib/screens/drawer/calculator_screen.dart` (Colors.white 8箇所, Colors.black87 3箇所)
- Modify: `lib/screens/drawer/about_screen.dart` (Colors.orange 6箇所, Colors.black87/white 複数)
- Modify: `lib/screens/drawer/donation_screen.dart` (Colors.grey 3箇所)
- Modify: `lib/screens/drawer/maikago_premium.dart` (Colors.white 13箇所+, Colors.orange/purple/green)

**Steps:**

- [ ] **Step 1: 各ファイルのハードコード色を確認・変換計画を立てる**
- [ ] **Step 2: settings_screen.dart の Colors.orange を修正**
- [ ] **Step 3: calculator_screen.dart の Colors.white/black87 を修正**
- [ ] **Step 4: about_screen.dart の Colors.orange/black87/white を修正**
- [ ] **Step 5: donation_screen.dart の Colors.grey を修正**
- [ ] **Step 6: maikago_premium.dart の Colors.white 等を修正**

注: maikago_premium.dart はグラデーション背景上のテキストで Colors.white を使う意図がある箇所は `colorScheme.onPrimary` に変換。

- [ ] **Step 7: flutter analyze && flutter test**
- [ ] **Step 8: コミット**

```bash
git add lib/screens/drawer/
git commit -m "refactor(ui): Drawer画面系のハードコード色をテーマ変数に統一"
```

---

### Issue #4: ハードコード色排除 — ウィジェット・ダイアログ系

**優先度:** 高（Issue #1 完了後）
**影響範囲:** 7ファイル、約40箇所
**推定規模:** 中

**依存:** Issue #1

**Files:**
- Modify: `lib/widgets/list_edit.dart` (~12箇所: 行146, 162, 195, 228, 269, 278, 295, 306, 396, 513)
- Modify: `lib/widgets/welcome_dialog.dart` (Colors.white 6箇所, Colors.grey[800] 1箇所)
- Modify: `lib/widgets/upgrade_promotion_widget.dart` (Colors.white 10箇所+)
- Modify: `lib/widgets/recipe_import_bottom_sheet.dart` (Colors.grey 4箇所)
- Modify: `lib/widgets/image_analysis_progress_dialog.dart` (Colors.green 3箇所, Colors.white 1箇所)
- Modify: `lib/widgets/version_update_dialog.dart` (Colors.purple/red/green/orange/white)
- Modify: `lib/screens/release_history_screen.dart` (Colors.green/blue/orange)

**Steps:**

- [ ] **Step 1: list_edit.dart の ダークモード分岐を修正**
- [ ] **Step 2: welcome_dialog.dart の Colors.white/grey を修正**
- [ ] **Step 3: upgrade_promotion_widget.dart の Colors.white を修正**
- [ ] **Step 4: recipe_import_bottom_sheet.dart の Colors.grey を修正**
- [ ] **Step 5: image_analysis_progress_dialog.dart の Colors.green/white を修正**
- [ ] **Step 6: version_update_dialog.dart の複数ハードコード色を修正**

注: version_update_dialog のバージョンタイプ別色分け（major=purple, minor=green等）は意図的なセマンティック色。AppColors に定数として定義するか、colorScheme の拡張として管理。

- [ ] **Step 7: release_history_screen.dart の色を修正**
- [ ] **Step 8: flutter analyze && flutter test**
- [ ] **Step 9: コミット**

```bash
git add lib/widgets/ lib/screens/release_history_screen.dart
git commit -m "refactor(ui): ウィジェット・ダイアログ系のハードコード色をテーマ変数に統一"
```

---

### Issue #5: ハードコード色排除 — 課金画面系

**優先度:** 中（Issue #1 完了後）
**影響範囲:** 2ファイル、約20箇所
**推定規模:** 中

**依存:** Issue #1

**Files:**
- Modify: `lib/screens/subscription_screen_new.dart` (Colors.blue/green/purple/white70 約15箇所)
- Modify: `lib/screens/one_time_purchase_screen.dart` (類似パターン)

**Steps:**

- [ ] **Step 1: subscription_screen_new.dart のハードコード色を確認**

Colors.blue(39,131,211,315,370), Colors.green(204,227,349,370), Colors.purple(131), Colors.white70(153,161)

- [ ] **Step 2: subscription_screen_new.dart を修正**
- [ ] **Step 3: one_time_purchase_screen.dart も同様に修正**
- [ ] **Step 4: 両画面の重複UIパターンがあれば共通ウィジェット化を検討**

注: 共通化は大規模変更になるためこのIssueでは対象外。メモとして記録のみ。

- [ ] **Step 5: flutter analyze && flutter test**
- [ ] **Step 6: コミット**

```bash
git add lib/screens/subscription_screen_new.dart lib/screens/one_time_purchase_screen.dart
git commit -m "refactor(ui): 課金画面系のハードコード色をテーマ変数に統一"
```

---

## Chunk 3: 共通コンポーネント統一

### Issue #6: CommonDialog統一 — AlertDialog直接使用の排除

**優先度:** 中（独立実行可能）
**影響範囲:** 13ファイル、13箇所
**推定規模:** 中〜大

**Files:**
- Modify: `lib/screens/login_screen.dart:96`
- Modify: `lib/screens/recipe_confirm_screen.dart:100`
- Modify: `lib/screens/main/widgets/bottom_summary_widget.dart:276`
- Modify: `lib/screens/drawer/calculator_screen.dart:95`
- Modify: `lib/screens/drawer/donation_screen.dart:739`
- Modify: `lib/screens/drawer/settings/account_screen.dart:265`
- Modify: `lib/screens/drawer/settings/settings_font.dart:302`
- Modify: `lib/screens/subscription_screen_new.dart:455`
- Modify: `lib/widgets/list_edit.dart:95,125`
- Modify: `lib/widgets/existing_list_selector_dialog.dart:47`
- Modify: `lib/widgets/version_update_dialog.dart:27`
- Modify: `lib/widgets/update_confirm_dialog.dart:80`
- Modify: `lib/widgets/premium_upgrade_dialog.dart:26,38` (showConstrainedDialog未使用も修正)

**変換パターン:**

```dart
// Before:
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('タイトル'),
    content: Text('内容'),
    actions: [
      TextButton(onPressed: ..., child: Text('キャンセル')),
      ElevatedButton(onPressed: ..., child: Text('OK')),
    ],
  ),
);

// After:
CommonDialog.show(
  context: context,
  builder: (context) => CommonDialog(
    title: 'タイトル',
    content: Text('内容'),
    actions: [
      CommonDialog.cancelButton(context),
      CommonDialog.primaryButton(context, label: 'OK', onPressed: ...),
    ],
  ),
);
```

**Steps:**

- [ ] **Step 1: 各ファイルの AlertDialog 使用パターンを確認し変換計画を立てる**
- [ ] **Step 2: login_screen.dart のエラー詳細ダイアログを変換**
- [ ] **Step 3: recipe_confirm_screen.dart の材料編集ダイアログを変換**
- [ ] **Step 4: bottom_summary_widget.dart のログイン要求ダイアログを変換**
- [ ] **Step 5: calculator_screen.dart のヒントダイアログを変換**
- [ ] **Step 6: donation_screen.dart のダイアログを変換**
- [ ] **Step 7: account_screen.dart の削除確認ダイアログを変換**
- [ ] **Step 8: settings_font.dart のダイアログを変換**
- [ ] **Step 9: subscription_screen_new.dart のダイアログを変換**
- [ ] **Step 10: list_edit.dart の2箇所を変換**
- [ ] **Step 11: existing_list_selector_dialog.dart を変換**
- [ ] **Step 12: version_update_dialog.dart を変換**
- [ ] **Step 13: update_confirm_dialog.dart を変換**
- [ ] **Step 14: premium_upgrade_dialog.dart を変換（showConstrainedDialog化も含む）**
- [ ] **Step 15: flutter analyze && flutter test**
- [ ] **Step 16: コミット**

```bash
git add lib/screens/ lib/widgets/
git commit -m "refactor(ui): AlertDialog直接使用をCommonDialogに統一"
```

---

## Chunk 4: 大規模ファイルの責務分割

### Issue #10: donation_screen.dart の責務分割（952行）

**優先度:** 中（Issue #3 完了後）
**影響範囲:** 1ファイル → 3-4ファイル
**推定規模:** 大

**依存:** Issue #3（ハードコード色修正後に分割する方が効率的）

**分割方針:**
- `donation_screen.dart` — メイン画面（UI レイアウト、ナビゲーション）
- `donation_screen_widgets.dart` — 寄付アイテム表示ウィジェット群
- `donation_screen_dialogs.dart` — 寄付関連ダイアログ
- 課金ロジックは `DonationService` に既に分離済みか確認

**Steps:**

- [ ] **Step 1: donation_screen.dart の責務を分析**

ファイルを読み、以下を特定:
- UI構築部分（build メソッド、レイアウト）
- ウィジェット部分（繰り返し使われるUI部品）
- ダイアログ部分
- ビジネスロジック部分

- [ ] **Step 2: 分割計画を具体化**

責務ごとにファイル分割の境界を決定。

- [ ] **Step 3: ウィジェットを別ファイルに抽出**
- [ ] **Step 4: ダイアログを別ファイルに抽出**
- [ ] **Step 5: 元ファイルから import で参照**
- [ ] **Step 6: flutter analyze && flutter test**
- [ ] **Step 7: コミット**

```bash
git add lib/screens/drawer/
git commit -m "refactor(ui): donation_screen.dartの責務分割（952行→3ファイル）"
```

---

### Issue #11: その他大規模ファイルの責務分割

**優先度:** 低（Issue #2, #4 完了後）
**影響範囲:** 複数ファイル
**推定規模:** 大

**対象ファイル（500行超、優先度順）:**

| ファイル | 行数 | 分割方針 |
|---------|------|---------|
| `ocr_result_confirm_screen.dart` | 766 | UI + 確認ロジック + ウィジェット |
| `bottom_summary_widget.dart` | 759 | サマリー表示 + 操作ボタン + ダイアログ |
| `settings_screen.dart` | 718 | セクション別ウィジェット抽出 |
| `settings_theme.dart` | 705 | テーマ定義 + テーマ選択UI + ユーティリティ |
| `maikago_premium.dart` | 698 | プレミアム説明UI + 機能比較 + 購入フロー |
| `one_time_purchase_service.dart` | 680 | 購入ロジック + 復元ロジック + バリデーション |
| `usage_screen.dart` | 669 | セクション別ウィジェット抽出 |
| `about_screen.dart` | 655 | セクション別ウィジェット抽出 |
| `calculator_screen.dart` | 641 | 計算ロジック + UI + 履歴 |
| `settings_font.dart` | 627 | フォント選択UI + プレビュー + サイズ調整 |

注: 全ファイルを一度に分割するのではなく、変更頻度が高いファイルから段階的に実施。
各ファイルの分割は個別のサブIssueとして管理することを推奨。

**Steps:**

- [ ] **Step 1: 変更頻度の高いファイルを特定**

Run: `git log --oneline --follow lib/screens/ocr_result_confirm_screen.dart | wc -l` 等で変更頻度を確認。

- [ ] **Step 2-N: 各ファイルを個別に分割**

（各ファイルごとに Issue #10 と同様のプロセス）

---

## 実行順序サマリー

| 順序 | Issue | 内容 | 依存 | 並行可能 |
|------|-------|------|------|---------|
| 1 | #1 | テーマ基盤改善 | なし | - |
| 2 | #7 | SnackBar統一 | なし | #1と並行可 |
| 2 | #8 | withAlpha移行 | なし | #1と並行可 |
| 2 | #9 | 重複/死コード整理 | なし | #1と並行可 |
| 3 | #2 | 色: メイン画面 | #1 | #3,#4,#5と並行可 |
| 3 | #3 | 色: Drawer画面 | #1 | #2,#4,#5と並行可 |
| 3 | #4 | 色: ウィジェット | #1 | #2,#3,#5と並行可 |
| 3 | #5 | 色: 課金画面 | #1 | #2,#3,#4と並行可 |
| 3 | #6 | CommonDialog統一 | なし | #2-5と並行可 |
| 4 | #10 | 責務分割: donation | #3 | #11と並行可 |
| 4 | #11 | 責務分割: その他 | #2,#4 | #10と並行可 |

**推定総工数:** 約20-30時間（各Issueを /fix-issue で自動実行する場合）

---

## 検証チェックリスト（各Issue完了後）

- [ ] `flutter analyze` — 新規エラー 0件
- [ ] `flutter test` — 全テスト PASS
- [ ] ライトモード + ダークモード で UI 確認
- [ ] `grep -rn "Colors\." lib/` で残存ハードコード色を確認（settings_theme.dart のテーマ定義内は許容）
- [ ] `grep -rn "AlertDialog" lib/` で CommonDialog 未使用箇所を確認
- [ ] `grep -rn "ScaffoldMessenger" lib/` で snackbar_utils 未経由箇所を確認
