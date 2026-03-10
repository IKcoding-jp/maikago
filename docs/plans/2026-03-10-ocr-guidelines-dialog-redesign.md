# OCR撮影注意ダイアログ リデザイン

## 概要
`camera_guidelines_dialog.dart`のUIをモダンカード風にリデザインし、AppColorsのテーマカラーに統一する。

## 変更方針
- `AlertDialog` → `Dialog` + カスタムレイアウト
- ハードコードされた色 → `AppColors`のパステルカラーに統一
- 各セクションにshadow付きカード風デザイン
- 撮影マナー2項目を1カードに統合
- タイトル中央寄せ、余白・角丸を大きめに
- `SingleChildScrollView`でスクロール対応

## カラーマッピング
| セクション | 変更後 |
|---|---|
| 撮影のコツ | `AppColors.secondary` (#B5EAD7) |
| 撮影マナー | `AppColors.accent` (#FFDAC1) |
| 読み取り精度 | `AppColors.primary` (#FFB6C1) |
| プライバシー | `AppColors.tertiary` (#C7CEEA) |
| ボタン | `AppColors.primary` |

## 変更ファイル
- `lib/widgets/camera_guidelines_dialog.dart`（単一ファイル）

## 変更しないもの
- 機能・戻り値・テキスト内容・パラメータ
