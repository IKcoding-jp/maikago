# テスト計画: Issue #35 テーマ色分岐・SnackBar等のコード重複解消

## ユニットテスト

### snackbar_utils_test.dart

- [ ] `showErrorSnackBar` が SnackBar を表示すること
- [ ] `showErrorSnackBar` の背景色が `colorScheme.error` であること
- [ ] `showErrorSnackBar` が Exception prefix を除去すること
- [ ] `showSuccessSnackBar` が SnackBar を表示すること
- [ ] `showSuccessSnackBar` の背景色が `colorScheme.primary` であること
- [ ] `showInfoSnackBar` が SnackBar を表示すること

### theme_utils_test.dart

- [ ] Dark テーマで `cardShadowColor` が alpha: 0.3 であること
- [ ] Light テーマで `cardShadowColor` が alpha: 0.1 であること

## 統合テスト（手動）

- [ ] 各テーマ（dark, light, pink 等）で画面表示が変わらないこと
- [ ] エラー発生時の SnackBar 表示が正常であること
- [ ] 成功メッセージの SnackBar 表示が正常であること

## 回帰テスト

- [ ] `flutter analyze` — Lint エラーなし
- [ ] `flutter test` — 全テスト通過
