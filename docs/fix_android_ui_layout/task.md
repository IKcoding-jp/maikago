# Android UI崩れ修正タスク

## 1. 現状の課題
- **タブとコンテンツの重なり**: `extendBodyBehindAppBar: true` が設定されているため、ボディのコンテンツ（「未購入」「購入済み」ラベル）がAppBar（タブ）と重なっている。
- **ボトムサマリーの重なり**: `BottomSummaryWidget` 内の3つのボタンと合計金額表示エリアが重なっている可能性がある。現在の実装では `Stack` を使用しているが、高さの確保が不明確。

## 2. 修正方針
- **トップの重なり解消**:
    - `extendBodyBehindAppBar` を `false` に変更し、ボディがAppBarの下から始まるようにする。
    - `AppBar` の `toolbarHeight` をタブの高さに合わせて動的に調整する。
    - ボディのパディングを調整し、不要な余白を削除する。
- **ボトムの重なり解消**:
    - `BottomSummaryWidget` 内のボタン群を `Stack` から `Row` に変更し、中央のボタンが常に中央に配置されるように `Expanded` と `Align` を活用する。
    - ボタン間の余白を適切に設定する。

## 3. タスクリスト
- [ ] `lib/screens/main_screen.dart` の `extendBodyBehindAppBar` を `false` に変更
- [ ] `lib/screens/main_screen.dart` の `AppBar` に `toolbarHeight` を設定
- [ ] `lib/screens/main_screen.dart` の `body` のパディングを調整
- [ ] `lib/screens/main/widgets/bottom_summary_widget.dart` の `Stack` を `Row` に変更
- [ ] 実装後の動作確認
