# タスクリスト: Issue #35 テーマ色分岐・SnackBar等のコード重複解消

**ステータス**: 実装完了（検証は #46 と合わせて実施）

## Phase 1: ユーティリティ作成

- [x] 1.1 `lib/utils/snackbar_utils.dart` を作成（showErrorSnackBar, showSuccessSnackBar, showInfoSnackBar, showWarningSnackBar）
- [x] 1.2 `lib/utils/theme_utils.dart` を作成（ThemeData Extension: cardShadowColor, subtextColor）
- [ ] 1.3 ユニットテスト作成 → 検証フェーズで実施

## Phase 2: SnackBar 置換

- [x] 2.1 エラー系 SnackBar を `showErrorSnackBar()` に置換（16ファイル）
- [x] 2.2 成功系 SnackBar を `showSuccessSnackBar()` に置換
- [x] 2.3 情報系 SnackBar を `showInfoSnackBar()` に置換
- [x] 2.4 警告系 SnackBar を `showWarningSnackBar()` に置換

## Phase 3: テーマ色分岐の置換

- [x] 3.1 `currentTheme == 'dark' ? Colors.white : Colors.black87` → `colorScheme.onSurface` に置換
- [x] 3.2 ドロワーメニュー色を `_drawerItemColor` / `_drawerTextColor` ゲッターに集約
- [x] 3.3 影色分岐を `ThemeUtils.cardShadowColor` に置換
- [x] 3.4 サブテキスト色を `ThemeUtils.subtextColor` に置換
- [x] 3.5 `currentTheme` 文字列比較を `theme.brightness` チェックに置換

## Phase 4: 検証

- [x] 4.1 `flutter analyze` 通過
- [ ] 4.2 `flutter test` 通過 → #46 完了後に実施
