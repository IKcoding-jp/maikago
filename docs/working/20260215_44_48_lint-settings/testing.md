# テスト計画: Lint設定の強化（#44 + #48）

## テスト方針
lintルール変更のため、主にstatic analysis（`flutter analyze`）による検証。

## テスト項目

### 1. 静的解析
- `flutter analyze` が警告・エラーなしで通過すること

### 2. 既存テスト
- `flutter test` が全て通過すること（動作変更なし）

### 3. 回帰確認
- mounted チェック追加による既存動作への影響がないこと
- lint修正がロジックを変更していないこと
