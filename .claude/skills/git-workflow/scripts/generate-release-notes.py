#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "gitpython>=3.1.0",
# ]
# ///
"""
リリースノート自動生成スクリプト

git logから指定範囲のコミットを抽出し、コンベンショナルコミット形式でパースして
Markdown形式のリリースノートを生成します。

使用例:
    # 前回のタグから現在までの変更を抽出
    uv run generate-release-notes.py --from v1.3.1 --version v1.3.2 --output RELEASE_NOTES.md

    # pubspec.yamlのversionも更新
    uv run generate-release-notes.py --from v1.3.1 --version v1.3.2 --update-pubspec --output RELEASE_NOTES.md

    # 2つのタグ間の差分
    uv run generate-release-notes.py --from v1.3.0 --to v1.3.1 --output RELEASE_NOTES_1.3.1.md
"""

import argparse
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

try:
    from git import Repo, GitCommandError
except ImportError:
    print("[ERROR] エラー: GitPythonがインストールされていません。", file=sys.stderr)
    print("", file=sys.stderr)
    print("以下のコマンドでインストールしてください:", file=sys.stderr)
    print("  pip install gitpython", file=sys.stderr)
    print("", file=sys.stderr)
    sys.exit(1)


# コンベンショナルコミットの正規表現
COMMIT_PATTERN = re.compile(
    r'^(?P<type>feat|fix|refactor|docs|style|perf|test|chore|ci|revert|build)'
    r'(?:\((?P<scope>[^)]+)\))?'
    r':\s*(?P<description>.+)',
    re.IGNORECASE
)

# タイプごとのカテゴリマッピング
TYPE_CATEGORIES = {
    'feat': '追加',
    'fix': '修正',
    'refactor': '変更',
    'docs': '変更',
    'style': '変更',
    'perf': '変更',
    'test': '変更',
    'chore': '変更',
    'ci': '変更',
    'revert': '変更',
    'build': '変更',
}


def parse_commit_message(message: str) -> Optional[Tuple[str, Optional[str], str]]:
    """コミットメッセージをパースしてtype、scope、descriptionを抽出"""
    match = COMMIT_PATTERN.match(message)
    if match:
        return (
            match.group('type').lower(),
            match.group('scope'),
            match.group('description').strip()
        )
    return None


def get_commits_in_range(repo_path: Path, from_ref: str, to_ref: Optional[str] = None) -> List[Dict]:
    """指定範囲のコミットを取得"""
    try:
        repo = Repo(repo_path)
    except Exception as e:
        print(f"[ERROR] エラー: Gitリポジトリを開けませんでした: {e}", file=sys.stderr)
        sys.exit(1)

    if to_ref:
        commit_range = f"{from_ref}..{to_ref}"
    else:
        commit_range = f"{from_ref}..HEAD"

    try:
        commits = list(repo.iter_commits(commit_range))
    except GitCommandError as e:
        print(f"[ERROR] エラー: コミット範囲が無効です: {commit_range}", file=sys.stderr)
        print(f"詳細: {e}", file=sys.stderr)
        sys.exit(1)

    if not commits:
        print(f"[WARN] 警告: 指定範囲にコミットが見つかりませんでした: {commit_range}", file=sys.stderr)

    commit_list = []
    for commit in commits:
        message_lines = commit.message.strip().split('\n')
        first_line = message_lines[0]

        commit_list.append({
            'hash': commit.hexsha[:7],
            'message': first_line,
            'full_message': commit.message.strip(),
            'author': commit.author.name,
            'date': datetime.fromtimestamp(commit.committed_date)
        })

    return commit_list


def categorize_commits(commits: List[Dict]) -> Dict[str, List[Dict]]:
    """コミットをカテゴリ別に分類"""
    categorized = defaultdict(list)

    for commit in commits:
        parsed = parse_commit_message(commit['message'])

        if parsed:
            commit_type, scope, description = parsed
            category = TYPE_CATEGORIES.get(commit_type, 'その他')

            categorized[category].append({
                'type': commit_type,
                'scope': scope,
                'description': description,
                'hash': commit['hash'],
                'full_message': commit['full_message']
            })
        else:
            categorized['その他'].append({
                'type': 'other',
                'scope': None,
                'description': commit['message'],
                'hash': commit['hash'],
                'full_message': commit['full_message']
            })

    return categorized


def generate_release_notes(version: str, categorized_commits: Dict[str, List[Dict]], date: Optional[datetime] = None) -> str:
    """Markdown形式のリリースノートを生成"""
    if date is None:
        date = datetime.now()

    version_str = version.lstrip('v')

    lines = [
        f"# v{version_str} ({date.strftime('%Y-%m-%d')})",
        ""
    ]

    category_order = ['追加', '修正', '変更', 'その他']

    for category in category_order:
        if category not in categorized_commits:
            continue

        commits = categorized_commits[category]
        if not commits:
            continue

        lines.append(f"## {category}")
        lines.append("")

        for commit in commits:
            if commit['scope']:
                scope_str = f"**{commit['scope']}**: "
            else:
                scope_str = ""

            lines.append(f"- {scope_str}{commit['description']}")

        lines.append("")

    return '\n'.join(lines)


def update_pubspec_version(repo_path: Path, version: str) -> bool:
    """pubspec.yamlのversionフィールドを更新"""
    pubspec_path = repo_path / 'pubspec.yaml'

    if not pubspec_path.exists():
        print(f"[ERROR] エラー: pubspec.yamlが見つかりません: {pubspec_path}", file=sys.stderr)
        return False

    try:
        content = pubspec_path.read_text(encoding='utf-8')
    except Exception as e:
        print(f"[ERROR] エラー: pubspec.yamlの読み込みに失敗しました: {e}", file=sys.stderr)
        return False

    version_str = version.lstrip('v')

    # version: X.Y.Z+BUILD のパターンを検索・置換
    version_pattern = re.compile(r'^version:\s*\S+', re.MULTILINE)
    match = version_pattern.search(content)

    if not match:
        print("[ERROR] エラー: pubspec.yamlにversionフィールドが見つかりません", file=sys.stderr)
        return False

    old_version = match.group()

    # ビルド番号を保持または自動インクリメント
    if '+' in version_str:
        new_version_line = f"version: {version_str}"
    else:
        # 既存のビルド番号を取得してインクリメント
        old_build = 0
        if '+' in old_version:
            try:
                old_build = int(old_version.split('+')[1])
            except (ValueError, IndexError):
                pass
        new_version_line = f"version: {version_str}+{old_build + 1}"

    new_content = version_pattern.sub(new_version_line, content)

    try:
        pubspec_path.write_text(new_content, encoding='utf-8')
    except Exception as e:
        print(f"[ERROR] エラー: pubspec.yamlの書き込みに失敗しました: {e}", file=sys.stderr)
        return False

    print(f"[OK] pubspec.yamlのバージョンを更新: {old_version} → {new_version_line}")
    return True


def main():
    parser = argparse.ArgumentParser(
        description='Git logからリリースノートを自動生成します。',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用例:
  # 前回のタグから現在までの変更を抽出
  uv run generate-release-notes.py --from v1.3.1 --version v1.3.2 --output RELEASE_NOTES.md

  # pubspec.yamlのversionも更新
  uv run generate-release-notes.py --from v1.3.1 --version v1.3.2 --update-pubspec --output RELEASE_NOTES.md

  # 2つのタグ間の差分
  uv run generate-release-notes.py --from v1.3.0 --to v1.3.1 --output RELEASE_NOTES_1.3.1.md
        """
    )

    parser.add_argument(
        '--from',
        dest='from_ref',
        required=True,
        help='開始リファレンス（タグ、ブランチ、コミットハッシュ）'
    )

    parser.add_argument(
        '--to',
        dest='to_ref',
        help='終了リファレンス（省略時はHEAD）'
    )

    parser.add_argument(
        '--version',
        help='リリースバージョン（vプレフィックス付きでもOK）'
    )

    parser.add_argument(
        '--output',
        default='RELEASE_NOTES.md',
        help='出力ファイル名（デフォルト: RELEASE_NOTES.md）'
    )

    parser.add_argument(
        '--update-pubspec',
        action='store_true',
        help='pubspec.yamlのversionフィールドを更新する'
    )

    args = parser.parse_args()

    if not args.version:
        if args.to_ref:
            args.version = args.to_ref
        else:
            print("[ERROR] エラー: --versionまたは--toを指定してください。", file=sys.stderr)
            sys.exit(1)

    repo_path = Path.cwd()

    print(f"[INFO] リリースノート生成開始...")
    print(f"   バージョン: {args.version}")
    print(f"   範囲: {args.from_ref} → {args.to_ref or 'HEAD'}")
    print()

    commits = get_commits_in_range(repo_path, args.from_ref, args.to_ref)

    if not commits:
        print("[WARN] 警告: コミットがないため、リリースノートは生成されません。", file=sys.stderr)
        sys.exit(0)

    print(f"[OK] {len(commits)}件のコミットを取得しました。")

    categorized = categorize_commits(commits)

    for category, category_commits in categorized.items():
        print(f"   {category}: {len(category_commits)}件")

    print()

    release_notes = generate_release_notes(args.version, categorized)

    output_path = Path(args.output)
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(release_notes)
        print(f"[OK] リリースノートを生成しました: {output_path}")
    except Exception as e:
        print(f"[ERROR] エラー: ファイルの書き込みに失敗しました: {e}", file=sys.stderr)
        sys.exit(1)

    if args.update_pubspec:
        print()
        if update_pubspec_version(repo_path, args.version):
            print("[OK] pubspec.yamlの更新が完了しました。")
        else:
            print("[WARN] 警告: pubspec.yamlの更新に失敗しました。", file=sys.stderr)

    print()
    print("[SUCCESS] リリースノート生成が完了しました！")


if __name__ == '__main__':
    main()
