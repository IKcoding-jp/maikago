# ヘッダー背景色の統一

`MainScreen`のヘッダー（AppBar）の背景色が透明に設定されており、他の画面（「アプリについて」や「使い方」など）のヘッダー色（テーマのプライマリカラー）と異なっている問題を修正します。

## 提案される変更

### [Component] UI/Screens

#### [MODIFY] [main_screen.dart](file:///d:/Dev/maikago/lib/screens/main_screen.dart)

- `AppBar`の`backgroundColor`を `Colors.transparent` から `getCustomTheme().colorScheme.primary` に変更します。
- `foregroundColor` を `getCustomTheme().colorScheme.onPrimary` に変更し、アイコンやテキストの視認性を確保します。
- `systemOverlayStyle` を更新し、ステータスバーのアイコン色が背景色に対して適切になるようにします。
- 画面右上の「+」アイコン（タブ追加ボタン）の色を `onPrimary` に合わせて調整します。

## 検証計画

### 手動確認
- `MainScreen`を表示し、ヘッダーの背景色が「アプリについて」などの他の画面と同じ色（デフォルトではピンク、テーマ変更時はそのプライマリカラー）になっていることを確認します。
- テーマを「ライト」「ダーク」「オレンジ」などに変更し、それぞれのテーマにおいてヘッダーの色が正しく追従し、文字やアイコンが見やすいことを確認します。
- ステータスバーのアイコン（時計、バッテリーなど）が背景色と被って見えにくくなっていないか確認します。
