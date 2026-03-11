---
name: project-maintenance
description: プロジェクトメンテナンス統合監査。複雑度（Lizard）・セキュリティ（Gitleaks）の監査を統合実行し、リファクタリング対象を優先順位付けして特定する。リファクタリング計画、コード品質チェック、PR作成前の包括的監査に使用。
allowed-tools: Bash, Read
---

# Project Maintenance Protocol

ユーザーからリファクタリング計画、コード品質チェック、または包括的な監査を求められた場合、以下の手順を実行せよ。

## 概要

このスキルは以下の監査を統合し、実行できます：

1. **複雑度解析（Lizard）** - 循環的複雑度（CCN）を測定し、リファクタリング対象を特定
2. **セキュリティ監査（Gitleaks）** - シークレット漏洩を検出

---

## 前提条件

以下のツールがインストールされていること：

| ツール | インストール | 用途 |
|--------|-------------|------|
| **Lizard** | `pip install lizard` | 複雑度解析 |
| **Gitleaks** | [公式サイト](https://github.com/zricethezav/gitleaks) | シークレット検出 |

> Windowsの場合、Gitleaksは `gitleaks.exe` として `C:\Users\kensa\bin` にインストール済み。

---

## 実行コマンド

### 統合監査（推奨）

すべての監査を一括実行：

```bash
uv run .claude/skills/project-maintenance/scripts/run-project-maintenance.py --output maintenance-report.md
```

### 個別監査

特定の監査のみ実行：

```bash
# 複雑度解析のみ
uv run .claude/skills/project-maintenance/scripts/run-project-maintenance.py --complexity --output complexity-report.md

# セキュリティ監査のみ
uv run .claude/skills/project-maintenance/scripts/run-project-maintenance.py --security --output security-report.md
```

### 閾値カスタマイズ

```bash
uv run .claude/skills/project-maintenance/scripts/run-project-maintenance.py --ccn-threshold 20 --nloc-threshold 60 --output report.md
```

---

## 閾値設定

### 複雑度（CCN）

| 指標 | 閾値 | 説明 |
|------|------|------|
| CCN（循環的複雑度） | **15** | 条件分岐・ループの複雑さ。15超は要リファクタリング |
| NLOC（論理行数） | **50** | 関数の長さ。50行超は分割を検討 |

#### CCN重症度レベル

| レベル | CCN範囲 | 対応 |
|--------|---------|------|
| 正常 | 1-10 | 問題なし |
| 注意 | 11-15 | モニタリング |
| 警告 | 16-25 | リファクタリング推奨 |
| 危険 | 26-50 | リファクタリング必須 |
| 即対応 | 51+ | 即座に分割すべき |

---

## 分析手順

### Step 1: 統合監査の実行

上記コマンドを実行し、監査結果を取得する。

### Step 2: 優先順位の判定

#### 優先度判定基準

1. **セキュリティ問題（最優先）**
   - シークレット漏洩

2. **複雑度が極めて高い関数（CCN 51+）**
   - 即座に分割すべき

3. **複雑度が高い関数（CCN 26-50）**
   - 計画的にリファクタリング

### Step 3: リファクタリング計画の策定

優先順位に基づいて、具体的なリファクタリング手法を提案。

### Step 4: リファクタリングIssue + Working Documents自動生成

統合監査の結果、リファクタリングが必要な場合、Issue作成とWorking Documents生成を連携します。

```
1. project-maintenance実行 → 2. 優先順位判定 → 3. Issue自動作成 → 4. Working自動生成
```

Issue作成後、`/create-spec [Issue番号]` で Working Documents生成。
`/fix-issue [Issue番号]` で実装開始可能。

### Step 5: リファクタリング手法の提案

#### 複雑度削減の手法

1. **ガード節の導入** - 早期リターンでネストを削減
2. **関数の抽出** - 一つの責務に分割
3. **ストラテジーパターン** - 条件分岐をポリモーフィズムで置換
4. **テーブル駆動** - switch/if-else チェーンをマップに変換
5. **Widget分割** - 巨大なWidgetを子Widgetに分離

#### セキュリティ問題の対応

- **シークレット漏洩**: `env.json` に移動、`.gitignore` に追加、Git履歴から削除
- **APIキー管理**: `lib/env.dart` の `Env` クラスで管理

---

## Flutter固有の注意点

### 複雑度が高くなりやすいファイル

- `lib/providers/data_provider.dart` - 1500行超の中心的状態管理
- `lib/screens/main_screen.dart` - メイン画面
- `lib/main.dart` - エントリーポイント

### スキャン対象ディレクトリ

```bash
# デフォルトのスキャン対象
--target lib test
```

### 検証コマンド

```bash
# リファクタリング後の検証
flutter analyze && flutter test
```

---

## 使用タイミング

### 定期実行（推奨）

- **週次**: 開発サイクルごとに実行
- **PR作成前**: 必ず実行して品質を確認
- **リリース前**: 大規模リリース前の総合チェック

### 特定シナリオ

- **リファクタリング計画**: 対象範囲の特定に使用
- **コードレビュー**: レビュー前の自己チェック
- **パフォーマンス改善**: ボトルネック特定の起点

---

## 注意事項

### 複雑度の妥当性

- **ビジネスロジックの複雑さ**: 本質的に複雑な処理は、無理に削減しない
- **テストカバレッジ**: リファクタリング前に十分なテストを書く
- **data_provider.dart**: 1500行超のファイル。段階的なリファクタリングを推奨

---

*このスキルは複雑度監査とセキュリティ監査を統合したものです。*
