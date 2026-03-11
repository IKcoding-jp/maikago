---
name: issue-creator
description: GitHub Issue作成スキル。コードベース調査→影響範囲特定→gh issue create→Working Documents生成まで一気通貫。タスク規模に応じて調査深度とWorking生成を自動調整。「〜のIssueを作って」「〜を実装したい」時に使用。
argument-hint: "[作業内容]"
---

# Issue Creator

## ワークフロー

```
1. 作業内容理解+規模判定 → 2. コード調査(規模に応じて) → 3. Issue内容整理 → 4. ユーザー確認 → 5. Issue作成 → 6. Working Documents生成(規模に応じて)
```

このスキルではコード修正を行わない。調査とIssue作成とWorking生成のみ。

---

## Phase 1: 作業内容理解 + 規模判定

### タイプ判定

Issueタイプを判定: `bug` / `feat` / `refactor` / `docs` / `style` / `perf` / `chore` / `test`
不明点はユーザーに質問。

### 規模判定

タスクの規模を3段階で判定:

| 規模 | 基準 | 例 |
|------|------|-----|
| **小** | 1-2ファイル変更、単純な修正 | typo修正、設定変更、1関数の修正 |
| **中** | 3-5ファイル変更、機能の追加・修正 | Widget追加、既存機能の改善 |
| **大** | 6ファイル以上、新機能、複雑なリファクタ | 新画面作成、アーキテクチャ変更 |

規模判定に迷ったら「中」として扱う。

---

## Phase 2: コード調査（規模に応じて調整）

### 大規模タスク → 詳細調査

- `find_symbol` / `search_for_pattern` で関連コード特定
- `get_symbols_overview` で構造把握
- `find_referencing_symbols` で影響範囲確認

この調査結果はWorking Documents生成に流用されるため、しっかり行う。

### 中規模タスク → 標準調査

- `search_for_pattern` で関連コード特定
- `get_symbols_overview` で変更対象ファイルの構造把握

### 小規模タスク → 軽微調査 or 省略

- 対象ファイルが明確な場合は調査省略可
- 不明な場合のみ `search_for_pattern` で軽く確認

---

## Phase 3: Issue本文作成

```markdown
## 概要
[何をするか - 1-2文]

## 理由/背景
[なぜ必要か]

## 対象箇所
- `lib/path/to/file.dart:行番号` - クラス/関数名

## 作業内容
- [ ] タスク1
- [ ] タスク2

## 影響範囲
- 関連Widget・Provider・Service
```

小規模タスクでは「対象箇所」「影響範囲」は省略可。

---

## Phase 4: ユーザー確認 🔹確認ポイント

Issue本文を提示し、以下を確認:
- 内容が正しいか
- 規模判定が妥当か
- Working Documents生成の有無（AIの判断を提示）

---

## Phase 5: Issue作成

```bash
# 一時ファイルはリポジトリルートに作成（Windows互換）
cat > .tmp-issue-body.md <<'EOF'
[Issue本文]
EOF

gh issue create --title "[type]: タイトル" --body-file .tmp-issue-body.md --label "ラベル"
rm -f .tmp-issue-body.md
```

**ラベル対応**: bug→`bug`, feat→`enhancement`, refactor→`refactor`, docs→`documentation`, style→`design`, perf→`performance`, chore→`chore`, test→`testing`

---

## Phase 6: Working Documents生成（AIが規模に応じて判断）

### 生成判断基準

| 規模 | Working生成 | 理由 |
|------|:----------:|------|
| **大** | 必ず生成 | コンテキスト保持が必須 |
| **中** | 生成推奨 | /fix-issueでの作業効率化 |
| **小** | AIが判断 | 内容に応じて生成/スキップ |

### タスクタイプ別の生成内容

| タイプ | requirement.md | tasklist.md | design.md | testing.md |
|--------|:-------------:|:-----------:|:---------:|:----------:|
| bug    | o | o | o | o |
| feat   | o | o | o | o |
| refactor | o | o | o | 必要に応じて |
| test   | 軽量 | o | 軽量 | o |
| docs   | 軽量 | o | - | - |
| style  | 軽量 | o | 軽量 | - |
| chore  | - | o | - | - |

### ディレクトリ構成

```
docs/working/{YYYYMMDD}_{Issue番号}_{タイトル}/
├── requirement.md  # 要件定義
├── tasklist.md     # タスクリスト（必須）
├── design.md       # 設計書
└── testing.md      # テスト計画
```

### Working Documents テンプレート

#### requirement.md（要件定義）

```markdown
# 要件定義

**Issue**: #123
**作成日**: YYYY-MM-DD
**ラベル**: enhancement

## ユーザーストーリー
ユーザー「[セリフ形式]」
アプリ「[期待する動作]」

## 要件一覧
### 必須要件
- [ ] 要件1

### オプション要件
- [ ] 要件2

## 受け入れ基準
- [ ] 基準1
```

#### tasklist.md（タスクリスト）

```markdown
# タスクリスト

## フェーズ1: [フェーズ名]
- [ ] タスク1
- [ ] タスク2

## フェーズ2: [フェーズ名]
- [ ] タスク3

## 依存関係
- フェーズ1 → フェーズ2（順次実行）
```

#### design.md（設計書）

```markdown
# 設計書

## 実装方針

### 変更対象ファイル
- `lib/path/to/file.dart` - [変更内容]

### 新規作成ファイル
- `lib/path/to/new.dart` - [役割]

## 影響範囲
- [影響を受けるWidget・Provider・Service]

## Flutter固有の注意点
- Provider依存関係
- プラットフォーム分岐（kIsWeb）
- data_provider.dartへの影響
```

#### testing.md（テスト計画）

```markdown
# テスト計画

## テスト戦略

### ユニットテスト
- `test/path/to/file_test.dart`
  - テストケース1
  - テストケース2

### Widgetテスト
- `test/path/to/widget_test.dart`
  - UI操作シナリオ

## テスト実行コマンド
```bash
flutter test
```
```

---

## Phase 7: 完了

```
Issue #124 を作成しました
Working Documents を生成しました（or スキップしました）
   └── docs/working/20260214_124_タイトル/

次のステップ:
  /fix-issue 124
```

---

## 詳細パターン

実際のIssue作成例は以下を参照:

- **[issue-examples.md](references/issue-examples.md)** - バグ報告、機能追加、リファクタリング等の具体例
