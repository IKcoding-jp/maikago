# 要件定義

**Issue**: #145
**作成日**: 2026-03-14
**ラベル**: refactor

## 背景

CLAUDE.md 規約「1ファイル500行を超えたら責務分割を検討」に該当するファイルが2件存在する:

| ファイル | 現在の行数 | 超過 |
|---------|-----------|------|
| `lib/screens/release_history_screen.dart` | 517行 | +17行 |
| `lib/screens/main_screen.dart` | 505行 | +5行 |

## ユーザーストーリー

開発者「500行超のファイルを開くと、どこに何があるか把握しづらい」
リファクタ後「責務ごとにファイルが分かれ、変更箇所の特定が容易になる」

## 要件一覧

### 必須要件
- [ ] B1: `release_history_screen.dart`（517行）を責務ごとに分割し、本体を500行以下にする
- [ ] B2: `main_screen.dart`（505行）を責務ごとに分割し、本体を500行以下にする

### 制約事項
- ロジック変更は行わない（純粋なファイル分割のみ）
- 既存の `lib/screens/main/` ディレクトリ構成（dialogs / widgets / utils）を踏襲する
- 分割先ファイルの命名は既存パターンに合わせる
- `flutter analyze` / `flutter test` がパスすること

### オプション要件
- なし（将来のリファクタは別 Issue で対応）

## 受け入れ基準
- [ ] `release_history_screen.dart` が500行以下
- [ ] `main_screen.dart` が500行以下
- [ ] `flutter analyze` がエラーなし
- [ ] `flutter test` が全パス
- [ ] 外部からの import パス変更なし（`router.dart` 等からの参照が壊れない）
- [ ] アプリの見た目・動作に変更なし
