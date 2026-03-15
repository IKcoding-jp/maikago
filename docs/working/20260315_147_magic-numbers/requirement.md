# 要件定義

**Issue**: #147
**作成日**: 2026-03-15
**ラベル**: refactor

## 背景

SizedBox / EdgeInsets / BorderRadius 等の数値リテラルが定数化されずに繰り返し使用されている。値変更時に修正漏れのリスクがある。

## 要件一覧

### 必須要件
- [ ] B1: `item_repository.dart` の `batchSize = 5` 重複（3箇所）をクラスレベル定数に統一
- [ ] B2: `calculator_screen.dart` 関連の `isSmallScreen` レスポンシブ間隔定数を定義
- [ ] B3: アプリ共通のBorderRadius定数クラスを作成（CLAUDE.md定義: ダイアログ20px, カード14px, TextField12px, ボタン20px）

### 制約事項
- ロジック変更は行わない（定数の定義と参照のみ）
- `flutter analyze` / `flutter test` がパスすること

## 受け入れ基準
- [ ] `item_repository.dart` に `batchSize` のローカル重複定義がない
- [ ] `calculator_screen.dart` 関連ファイルでレスポンシブ間隔が定数化されている
- [ ] 共通BorderRadius定数が定義されている
- [ ] `flutter analyze` エラーなし
- [ ] `flutter test` 全パス
