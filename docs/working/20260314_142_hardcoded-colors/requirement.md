# 要件定義: ハードコード色をテーマ変数に置換

## Issue

- **Issue番号**: #142
- **タイトル**: refactor: ハードコード色をテーマ変数に置換（76箇所）
- **作成日**: 2026-03-14

## 背景

`lib/` 配下の76箇所で `Colors.white`, `Colors.black`, `Colors.blue` 等のハードコード色が使用されている。CLAUDE.md およびプロジェクトの Dart コーディング規約（`.claude/rules/dart-style.md`）にて「ハードコード色は原則禁止」と定められており、テーマ変数への置換が必要である。

現状ではダークモードとライトモードの切り替え時に、ハードコードされた色が適切に対応できず、視認性の問題が発生し得る。

## 目的

1. **テーマ一貫性の確保**: 全画面でテーマカラーシステムに準拠し、テーマ切り替え時に自然な表示を実現する
2. **保守性の向上**: 色の定義を一元管理し、将来のテーマ追加・変更を容易にする
3. **コーディング規約の遵守**: CLAUDE.md で定められた色規約に全コードを準拠させる

## スコープ

### 対象

- `lib/` 配下の Dart ファイルにおけるハードコード色の使用箇所（76箇所）
- `Colors.white`, `Colors.black`, `Colors.grey`, `Colors.blue`, `Colors.red`, `Colors.green` 等の Material Colors 直接使用

### 対象外

- `lib/services/settings_theme.dart` の `AppColors` クラス定義自体（色定数の定義元）
- `lib/services/settings_theme.dart` の `generateTheme()` 内での `Colors` 使用（テーマ生成ロジック内での使用は許容）
- テスト用コード
- `Colors.transparent` の使用（透明色はテーマに依存しないため）

## 色置換マッピング規約

| 用途 | 使うべき変数 | 禁止パターン |
|------|------------|------------|
| エラー/削除 | `colorScheme.error` | `Colors.red` |
| テキスト | `colorScheme.onSurface` | `Colors.black87`, `Colors.black54` |
| サブテキスト | `colorScheme.onSurface.withValues(alpha: 0.6)` | `Colors.white70` |
| 背景 | `theme.cardColor` or `colorScheme.surface` | `Colors.white`, `Colors.grey[800]` |
| 区切り線 | `theme.dividerColor` | `Colors.grey.shade300` |
| プライマリ上テキスト | `colorScheme.onPrimary` | プライマリ背景上の `Colors.white` |
| 影色 | `theme.cardShadowColor`（ThemeUtils拡張） | `Colors.black.withValues(alpha: ...)` |
| ダーク/ライト分岐色 | テーマ側で吸収 | `isDark ? Colors.white : Colors.black87` |

## 制約事項

- カメラUI（`camera_screen.dart`, `camera_top_bar.dart`, `camera_bottom_controls.dart`）は暗い背景が前提のため、固定の白色/黒色の使用が意味的に正しい場合がある。この場合は `AppColors` に専用定数を定義するか、コメントで意図を明記する
- スプラッシュ画面（`splash_screen.dart`）はプライマリカラー背景上の白文字であり、`colorScheme.onPrimary` に置換する
- `upcoming_features_screen.dart` の機能アイコン色（13色）は装飾目的であり、`AppColors` に `featureXxx` 定数として定義する

## 受入基準

1. `lib/` 配下で `Colors.white`, `Colors.black`, `Colors.blue`, `Colors.red`, `Colors.green`, `Colors.grey`, `Colors.orange`, `Colors.purple`, `Colors.cyan`, `Colors.pink`, `Colors.amber`, `Colors.indigo`, `Colors.teal`, `Colors.deepPurple`, `Colors.deepOrange`, `Colors.lightBlue`, `Colors.lightGreen` の直接使用が、テーマ生成ロジック・`AppColors` 定義・`Colors.transparent` を除いて存在しないこと
2. `flutter analyze` がエラーなしで通ること
3. `flutter test` が全テスト通過すること
4. ライトモード・ダークモードの両方で全画面の表示が適切であること
5. 14種のテーマすべてで主要画面の表示に問題がないこと
