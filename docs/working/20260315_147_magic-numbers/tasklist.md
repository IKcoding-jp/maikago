# タスクリスト

**ステータス**: 完了
**完了日**: 2026-03-15
**作成日**: 2026-03-15

## フェーズ1: item_repository.dart の batchSize 統一

- [ ] `const batchSize = 5` のローカル定義3箇所を削除（195行, 258行, 378行）
- [ ] クラスレベルに `static const int _batchSize = 5;` を定義
- [ ] 3箇所の参照を `_batchSize` に更新

## フェーズ2: 電卓画面のレスポンシブ間隔定数化

- [ ] `lib/screens/drawer/calculator_screen.dart` に間隔定数を定義
- [ ] `calculator_display.dart`, `calculator_button.dart` の共通パターンも定数化
- [ ] 定数参照に置換

## フェーズ3: 共通BorderRadius定数クラス作成

- [ ] `lib/utils/design_constants.dart` を作成
- [ ] CLAUDE.md定義に基づくBorderRadius定数を定義
- [ ] calculator関連ファイルで使用

## フェーズ4: 検証

- [ ] `flutter analyze` エラーなし
- [ ] `flutter test` 全パス
