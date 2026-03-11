---
name: git-workflow
description: Git操作とリリースの自動化。コンベンショナルコミット形式(日本語)でのコミットメッセージ生成、セマンティックバージョニング、変更履歴生成。commit、version、changelog、git、コミットメッセージ、release時に使用。
---

# Git Workflow スキル

## コミットメッセージ形式

```
<type>(<scope>): <日本語で50文字以内の説明>

<body: 変更点を箇条書き>

<footer: Closes #番号 等>

Co-Authored-By: Claude <noreply@anthropic.com>
```

**タイプ:**

| タイプ | 用途 | 例 |
|--------|------|-----|
| `feat` | 新機能 | feat(list): 買い物リスト共有機能を追加 |
| `fix` | バグ修正 | fix(ocr): OCR認識精度の改善 |
| `refactor` | リファクタリング | refactor(provider): DataProviderを整理 |
| `docs` | ドキュメント | docs(readme): セットアップ手順を追加 |
| `style` | コードスタイル | style: フォーマットを統一 |
| `perf` | パフォーマンス | perf(list): リスト描画速度を最適化 |
| `test` | テスト | test(service): Serviceテストを追加 |
| `chore` | ビルド・設定 | chore(deps): 依存関係を更新 |
| `ci` | CI/CD | ci(codemagic): ワークフローを追加 |

**スコープ例:** 機能名(`list`, `ocr`, `recipe`)、レイヤー名(`provider`, `service`, `screen`)、画面名(`main`, `settings`)

## Working Documents参照によるスコープ自動決定

コミット作成時、Working Documentsが存在する場合は自動参照します。

### スコープの自動抽出

1. 現在のブランチからIssue番号を抽出（例: `fix/#123-xxx` → `123`）
2. `docs/working/` ディレクトリで該当Issue番号のWorking Documentsを検索
3. `design.md` の「変更対象ファイル」セクションから主要な変更箇所を抽出
4. スコープを自動決定:
   - 単一機能の場合: 機能名をスコープに使用（例: `list`, `ocr`）
   - 複数機能の場合: 最も影響が大きい機能をスコープに使用
   - 共通UIの場合: `ui` をスコープに使用

### フォールバック

Working Documentsが存在しない、またはスコープが自動決定できない場合は、従来通りファイルパスから判断します。

## コミット手順

```bash
# 1. 変更確認
git diff --staged --stat && git diff --staged

# 2. コミット（複数行はHEREDOC使用）
git commit -m "$(cat <<'EOF'
fix(list): 買い物リストの並び順問題を修正

- ソート条件が正しく適用されない問題を修正
- テストケースを追加

Closes #123

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

## セマンティックバージョニング

`MAJOR.MINOR.PATCH+BUILD` — `pubspec.yaml` の `version` フィールドを更新。

| 変更種別 | バージョン | 例 |
|----------|-----------|-----|
| 破壊的変更 | MAJOR | 2.0.0+55 |
| 新機能 | MINOR | 1.4.0+55 |
| バグ修正 | PATCH | 1.3.2+55 |

```bash
# pubspec.yaml のバージョンを手動で更新
# version: 1.3.1+54 → version: 1.3.2+55
```

## リリースノート形式

```markdown
# v1.3.2 (2026-02-14)

## 追加
- 新機能の説明

## 修正
- バグ修正の説明

## 変更
- 既存機能の変更
```

## リリースノート自動生成

Git logからコンベンショナルコミット形式のコミットを抽出し、Markdown形式のリリースノートを自動生成します。

```bash
# 前回のタグから現在までの変更を抽出
uv run scripts/generate-release-notes.py --from v1.3.1 --version v1.3.2 --output RELEASE_NOTES.md
```

## デプロイ

**デプロイ前チェック:**
```bash
flutter analyze && flutter test
```

**Android:** `flutter build appbundle --release`
**iOS:** Codemagic経由（TestFlight配信）
**Web:** `flutter build web` → GitHub Actions で Firebase Hosting にデプロイ
**Windows:** `flutter build windows`

## ルール

- コミットメッセージは**日本語**
- 1コミット = 1つの論理的変更
- mainブランチへの直接コミット禁止
- デプロイ前に必ずテスト実行
