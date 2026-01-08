# Android 3ボタンナビゲーション重なり修正タスク

## 1. 現状の課題
- `MainScreen` の `bottomNavigationBar` に配置された `BottomSummaryWidget` が、Android固有の3ボタンナビゲーション（Back, Home, Recents）と重なっている。
- 前回の修正で `Stack` から `Row` に変更したが、垂直方向のSafe Areaが適切に考慮されていないため、ナビゲーションバーがUIの上に乗ってしまっている。

## 2. 修正方針
- **Safe Areaの考慮**: `BottomSummaryWidget` の最下部にシステムの `viewPadding.bottom` を追加し、ナビゲーションバーの領域を避けるようにする。
- **ボトムパディングの調整**: 現在 `padding: const EdgeInsets.fromLTRB(18, 12, 18, 16)` となっている箇所を、`SafeArea` または `MediaQuery` を用いて動的に調整する。

## 3. タスクリスト
- [ ] `lib/screens/main/widgets/bottom_summary_widget.dart` に `SafeArea` を導入、または `MediaQuery.of(context).padding.bottom` をパディングに追加する。
- [ ] `MainScreen` の `bottomNavigationBar` のパディング設定を確認し、不要なマージンを整理する。
- [ ] 実装後の動作確認（特にAndroidエミュレータ/実機の3ボタンモード）
