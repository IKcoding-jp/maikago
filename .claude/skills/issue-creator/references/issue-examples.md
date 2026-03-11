# GitHub Issue 作成例集

まいカゴでのIssue作成の具体例。Serena MCPでの調査結果からIssue本文作成、ラベル付け、gh CLIコマンド実行までの流れをまとめています。

## 目次

1. [バグ報告Issue（Provider状態管理問題）](#1-バグ報告issueprovider状態管理問題)
2. [機能追加Issue（新機能）](#2-機能追加issue新機能)
3. [リファクタリングIssue](#3-リファクタリングissue)

---

## 1. バグ報告Issue（Provider状態管理問題）

### Serena MCP調査結果

```
# 問題の特定
search_for_pattern: "notifyListeners"
→ 検出: lib/providers/data_provider.dart に多数

# 構造把握
get_symbols_overview: lib/providers/data_provider.dart
→ DataProvider クラス（1500行超）

# 参照箇所確認
find_referencing_symbols: DataProvider
→ 参照元: 多数のScreen/Widget
```

### Issue本文

```markdown
## 概要

DataProviderで特定の操作後にUIが更新されない問題を修正する。

## 再現手順

1. 買い物リストに商品を追加
2. 別の画面に遷移
3. 戻ると追加した商品が表示されない

## 原因

`DataProvider` 内で `notifyListeners()` の呼び出しが不足している箇所がある。

## 対象箇所

- `lib/providers/data_provider.dart:行番号` - 対象メソッド

## 作業内容

- [ ] 該当メソッドに `notifyListeners()` を追加
- [ ] テストケース追加

## 影響範囲

- DataProviderを参照している全画面
```

### ラベル

- `bug`

### 実際のコマンド

```bash
cat > .tmp-issue-body.md <<'EOF'
[Issue本文]
EOF

gh issue create \
  --title "fix(provider): DataProviderの状態通知不足を修正" \
  --body-file .tmp-issue-body.md \
  --label "bug"

rm -f .tmp-issue-body.md
```

---

## 2. 機能追加Issue（新機能）

### Issue本文テンプレート

```markdown
## 概要

[機能の概要]

## 理由/背景

[なぜこの機能が必要か]

## 対象箇所

### 新規作成
- `lib/services/new_service.dart` - サービス層
- `lib/screens/new_screen.dart` - UI画面

### 既存修正
- `lib/providers/data_provider.dart` - 新機能のデータ管理追加

## 作業内容

- [ ] サービス層実装
- [ ] Provider拡張
- [ ] UI画面作成
- [ ] テスト追加

## 影響範囲

- [影響を受ける既存機能]
```

### ラベル

- `enhancement`

---

## 3. リファクタリングIssue

### Issue本文テンプレート

```markdown
## 概要

[リファクタリングの概要]

## 理由/背景

- 複雑度が高い / 保守性が低い
- [具体的な問題点]

## 対象箇所

- `lib/path/to/file.dart` - [変更内容]

## 作業内容

- [ ] [具体的なリファクタリング作業]
- [ ] テストカバレッジ確保

## 影響範囲

- [影響を受ける機能]
```

### ラベル

- `refactor`

---

## Issue作成のベストプラクティス

### 1. 調査フェーズ

Serena MCPで以下を確認：
- `search_for_pattern`: 関連コードの検索
- `get_symbols_overview`: ファイル構造の把握
- `find_referencing_symbols`: 影響範囲の特定

### 2. Issue本文の構成

必須セクション:
- **概要**: 何をするか（1-2文）
- **理由/背景**: なぜ必要か
- **対象箇所**: 修正・追加するファイルと行番号
- **作業内容**: チェックリスト形式
- **影響範囲**: 関連Widget・Provider・Service

### 3. gh CLIコマンド

必ず `--body-file` を使用（バッククォート問題回避）。
一時ファイルはリポジトリルートに作成（Windows互換: `/tmp/` は使用禁止）:

```bash
cat > .tmp-issue-body.md <<'EOF'
[Issue本文]
EOF

gh issue create \
  --title "[type]: タイトル" \
  --body-file .tmp-issue-body.md \
  --label "label1,label2"

rm -f .tmp-issue-body.md
```
