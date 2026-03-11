---
name: create-spec
description: 【手動用】既存IssueからWorking Documentsを生成。通常は /issue-creator で自動生成されるため、手動実行が必要な場合（古いIssue、外部で作成されたIssue等）に使用。「/create-spec 123」のように使用。
argument-hint: "[Issue番号]"
---

# Working Documents手動生成スキル

## 概要

**通常は `/issue-creator` でIssue作成と同時にWorking Documentsが生成されます。**

このスキルは以下の場合に手動で使用します:
- 古いIssue（Working Documentsがない）
- 外部で作成されたIssue（GitHub Web等）
- `/issue-creator` を使わずに作成されたIssue

## Working Documentsの役割

- **永続的な設計メモ**: 実装中のコンテキストを保持、セッション間で引き継ぐ
- **EnterPlanModeとの違い**: Working = 永続化、Plan = 一時的詳細計画（併用推奨）
- **Git保管**: PR完了後も削除せず、過去の設計判断の記録として保管

## ワークフロー

```
1. Issue取得 → 2. Serena MCP調査 → 3. Working生成 → 4. ユーザー確認
```

---

## Phase 1: Issue情報取得

```bash
gh issue view $ARGUMENTS --json title,body,labels,number,assignees
```

以下の情報を抽出:
- Issue番号
- タイトル
- 本文（要件、背景、作業内容）
- ラベル（bug, enhancement, refactor 等）

---

## Phase 2: Serena MCP調査

関連コードをSerena MCPで調査します（探索のみ、編集禁止）:

### 調査手順

1. **パターン検索**: `search_for_pattern` でキーワード検索
   - Issueのタイトル・本文からキーワード抽出

2. **シンボル構造把握**: `get_symbols_overview` でファイル構造確認
   - 関連ファイルのクラス・メソッド・関数を把握

3. **シンボル詳細確認**: `find_symbol` で具体的な実装確認
   - 修正対象のWidget・Provider・Serviceを特定

4. **影響範囲確認**: `find_referencing_symbols` で依存関係追跡
   - 修正による影響範囲を特定

### 調査深度の判断

| Issueタイプ | 調査深度 | 理由 |
|------------|---------|------|
| bug | 詳細 | 根本原因特定が必須 |
| refactor | 詳細 | 影響範囲の完全把握が必須 |
| enhancement | 中程度 | 既存パターンの参照が主 |
| docs | 軽微 | コード調査は最小限 |

### Serena MCPの使い方

- **探索のみ**: `search_for_pattern`, `get_symbols_overview`, `find_symbol`, `find_referencing_symbols`
- **編集禁止**: `replace_symbol_body`, `insert_*`, `rename_symbol` は使用しない
- **理由**: 編集はClaude Code標準ツール（Edit/Write）の方が安定

---

## Phase 3: Working Documents生成

`docs/working/{YYYYMMDD}_{Issue番号}_{タイトル}/` ディレクトリを作成し、以下の4ファイルを生成します。

### ディレクトリ命名規則

```
docs/working/20260214_123_買い物リスト共有機能/
```

- `YYYYMMDD`: 生成日（ソート用）
- `Issue番号`: GitHub Issue番号
- `タイトル`: Issueタイトル（日本語可、50文字以内）

---

### 1. requirement.md（要件定義）

```markdown
# 要件定義

**Issue**: #123
**作成日**: YYYY-MM-DD
**ラベル**: enhancement

## ユーザーストーリー

ユーザー「[セリフ形式で記述]」
アプリ「[期待する動作]」

## 要件一覧

### 必須要件
- [ ] 要件1 - 具体的な動作
- [ ] 要件2 - 具体的な動作

### オプション要件
- [ ] 要件3 - あれば望ましい動作

## 非機能要件
- パフォーマンス: [目標値]
- 対応プラットフォーム: iOS, Android, Web, Windows

## 受け入れ基準
- [ ] 基準1
- [ ] 基準2
```

---

### 2. design.md（設計書）

```markdown
# 設計書

## アーキテクチャ概要

[Provider → Service → Firestore の層構造に沿った設計]

## 実装方針

### 変更対象ファイル
- `lib/providers/data_provider.dart` - [変更内容]
- `lib/screens/main_screen.dart` - [変更内容]

### 新規作成ファイル
- `lib/services/new_service.dart` - [役割]

## データモデル

### Firestoreスキーマ
```dart
class NewModel {
  final String id;
  final String name;
  // ...
}
```

## Widget構成
- `ExistingWidget` (既存) → [変更内容]
- `NewWidget` (新規) → [役割]

## 依存関係

### 影響範囲
- Provider依存関係
- data_provider.dartへの影響有無

## Flutter固有の注意点
- kIsWebでのプラットフォーム分岐
- Web時の横幅制限（800px）
- テーマ対応（SettingsTheme.generateTheme()）

## 禁止事項チェック
- env.jsonへのAPIキー直書き禁止
- data_provider.dartの大規模変更は慎重に
```

---

### 3. tasklist.md（タスクリスト）

```markdown
# タスクリスト

## フェーズ1: データモデル・Service実装
- [ ] モデルクラス作成
- [ ] Serviceクラス作成
- [ ] Firestoreとの連携

## フェーズ2: Provider拡張
- [ ] DataProviderに新機能を追加
- [ ] 状態管理ロジック実装

## フェーズ3: UI実装
- [ ] 新画面/Widget作成
- [ ] 既存画面への組み込み

## フェーズ4: テスト
- [ ] ユニットテスト
- [ ] Widgetテスト

## 依存関係
- フェーズ1 → フェーズ2 → フェーズ3 → フェーズ4（順次実行）
```

---

### 4. testing.md（テスト計画）

```markdown
# テスト計画

## テスト戦略

### ユニットテスト
- `test/services/new_service_test.dart`
  - 正常系テスト
  - 異常系テスト
  - 境界値テスト

### Widgetテスト
- `test/screens/new_screen_test.dart`
  - UI表示の正確性
  - ユーザー操作シナリオ

### 手動テスト
- iOS / Android / Web / Windows での動作確認
- プラットフォーム固有の問題がないか確認

## テスト実行コマンド
```bash
flutter test
flutter test test/specific_test.dart
```
```

---

## Phase 4: ユーザー確認

生成されたWorking Documentsをユーザーに提示し、以下を確認します:

### 確認内容
1. **requirement.md**: 要件が正しく理解されているか
2. **design.md**: 実装方針が適切か
3. **tasklist.md**: タスク分割が妥当か
4. **testing.md**: テスト計画が十分か

### フィードバック対応
- **修正依頼**: AIが該当ファイルを修正 → 再度確認
- **OK**: /fix-issue で実装開始

---

## 注意事項

### Working Documentsの更新
- 実装中に逐次更新（設計変更、タスク完了）
- PR完了後も削除しない（Git保管で過去の設計判断を記録）

### EnterPlanModeとの使い分け
- **Working Documents**: 永続的な設計メモ、Issueスコープ
- **EnterPlanMode**: 一時的な詳細計画、複雑な実装の事前検討
- 併用推奨: Working生成後、EnterPlanModeで詳細計画

---

## 実行例

```bash
# 1. Issue作成
gh issue create --title "feat: 買い物リスト共有機能を追加" --label "enhancement"

# 2. Working Documents自動生成
/create-spec 123

# 3. 生成されたドキュメントを確認
ls docs/working/20260214_123_買い物リスト共有機能/
# → requirement.md, design.md, tasklist.md, testing.md

# 4. /fix-issue で実装開始
/fix-issue 123
```
