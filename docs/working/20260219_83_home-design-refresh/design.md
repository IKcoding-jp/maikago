# 設計書

## 実装方針

デザイン刷新は「見た目の変更」が主であり、ビジネスロジック・データフロー・Provider構造には手を加えない。
Widget層のUIコード（build メソッド内）とテーマ定義の変更に集中する。

### 変更対象ファイル
- `lib/screens/main/widgets/main_app_bar.dart` - AppBar・タブデザイン
- `lib/screens/main/widgets/item_list_section.dart` - リストレイアウト
- `lib/screens/main/widgets/bottom_summary_widget.dart` - 下部サマリーデザイン
- `lib/widgets/list_edit.dart` - リストアイテムカード
- `lib/services/settings_theme.dart` - テーマカラー・スタイル定義（必要に応じて）

### 新規作成ファイル
- `docs/working/20260219_83_home-design-refresh/mockups/pattern_a.html` - デザインモックA
- `docs/working/20260219_83_home-design-refresh/mockups/pattern_b.html` - デザインモックB
- `docs/working/20260219_83_home-design-refresh/mockups/pattern_c.html` - デザインモックC

## デザインモック方針

### 3パターンのコンセプト案

各パターンは以下の軸で差別化する：

| 軸 | パターンA | パターンB | パターンC |
|---|---------|---------|---------|
| **コンセプト** | モダンミニマル | グラスモーフィズム | カード重視・立体感 |
| **色使い** | 控えめ・ホワイトスペース重視 | 半透明・グラデーション | 影・深度で階層表現 |
| **タブ** | ピル型セグメント | フローティングチップ | アンダーライン強調 |
| **リストアイテム** | フラットリスト・区切り線 | すりガラスカード | 立体カード・影 |
| **サマリー** | インライン表示 | フローティングカード | 固定バー・グラデーション |

### 共通制約
- 現在の機能をすべて含むこと（タブ、2列リスト、予算、アクションボタン）
- モバイルファーストの縦型レイアウト
- テーマカラーは変数化し、16テーマ対応を前提とした設計

## 影響範囲
- MainScreen の Widget ツリー構造（UIのみ）
- SettingsTheme のカラー定義（新規スタイル追加の可能性）
- ResponsiveUtils との連携（既存の仕組みを維持）

## Flutter固有の注意点
- Provider依存関係: DataProvider, ThemeProvider への参照は変更なし
- プラットフォーム分岐（kIsWeb）: 800px制限は維持
- data_provider.dart への影響: なし（UI層のみの変更）
- テーマ適用: Theme.of(context) / colorScheme 経由のスタイル取得パターンを維持
- Material Design 3: useMaterial3: true を維持しつつ、カスタムスタイルで差別化
