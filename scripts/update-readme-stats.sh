#!/bin/bash
# README.md の動的メトリクスを最新値に更新するスクリプト
# Claude Code の Stop hook から自動実行される

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
README="$REPO_ROOT/README.md"

if [ ! -f "$README" ]; then
  exit 0
fi

# --- メトリクス収集 ---

# バージョン（pubspec.yaml から）
VERSION=$(grep '^version:' "$REPO_ROOT/pubspec.yaml" | sed 's/version: *//;s/+.*//')

# Dart ファイル数
DART_FILES=$(find "$REPO_ROOT/lib" -name "*.dart" 2>/dev/null | wc -l | tr -d ' ')

# 総コード行数（空行除外、千単位で丸め）
TOTAL_LINES=$(find "$REPO_ROOT/lib" -name "*.dart" -exec cat {} + 2>/dev/null | grep -c '[^ ]' || echo 0)
LOC_DISPLAY="~$(( (TOTAL_LINES + 500) / 1000 * 1000 ))行"

# コミット数
COMMITS=$(git -C "$REPO_ROOT" rev-list --count HEAD 2>/dev/null || echo 0)

# リリース数（タグ数）
RELEASES=$(git -C "$REPO_ROOT" tag -l 2>/dev/null | wc -l | tr -d ' ')

# テストファイル数
TEST_FILES=$(find "$REPO_ROOT/test" -name "*_test.dart" 2>/dev/null | wc -l | tr -d ' ')

# 開発期間（最初のコミットから現在まで）
FIRST_COMMIT_DATE=$(git -C "$REPO_ROOT" log --format="%ai" --reverse 2>/dev/null | head -1 | cut -d'-' -f1-2 || true)
if [ -n "$FIRST_COMMIT_DATE" ]; then
  FIRST_YEAR=$(echo "$FIRST_COMMIT_DATE" | cut -d'-' -f1)
  FIRST_MONTH=$(echo "$FIRST_COMMIT_DATE" | cut -d'-' -f2 | sed 's/^0//')
  NOW_YEAR=$(date +%Y)
  NOW_MONTH=$(date +%-m)
  MONTHS=$(( (NOW_YEAR - FIRST_YEAR) * 12 + NOW_MONTH - FIRST_MONTH ))
  if [ "$MONTHS" -lt 12 ]; then
    DEV_PERIOD="約${MONTHS}ヶ月"
  else
    YEARS=$(( MONTHS / 12 ))
    REM_MONTHS=$(( MONTHS % 12 ))
    if [ "$REM_MONTHS" -eq 0 ]; then
      DEV_PERIOD="約${YEARS}年"
    else
      DEV_PERIOD="約${YEARS}年${REM_MONTHS}ヶ月"
    fi
  fi
else
  DEV_PERIOD="不明"
fi

# 最初のタグ
FIRST_TAG=$(git -C "$REPO_ROOT" tag -l --sort=version:refname 2>/dev/null | head -1)
FIRST_TAG="${FIRST_TAG:-v0.1.0}"

# --- README 更新 ---
# マーカー間のテキストを置換: <!-- key -->OLD<!-- /key --> → <!-- key -->NEW<!-- /key -->

update_marker() {
  local key="$1"
  local value="$2"
  local file="$3"
  # sed でマーカー間を置換（改行なしの単一行マッチ）
  sed -i "s|<!-- ${key} -->.*<!-- /${key} -->|<!-- ${key} -->${value}<!-- /${key} -->|g" "$file"
}

update_marker "v" "$VERSION" "$README"
update_marker "latest-v" "v${VERSION}" "$README"
update_marker "dart-files" "$DART_FILES" "$README"
update_marker "loc" "$LOC_DISPLAY" "$README"
update_marker "commits" "${COMMITS}+" "$README"
update_marker "releases" "${RELEASES}+ (${FIRST_TAG} → v${VERSION})" "$README"
update_marker "test-files" "$TEST_FILES" "$README"
update_marker "dev-period" "$DEV_PERIOD" "$README"
update_marker "dev-period2" "$DEV_PERIOD" "$README"
update_marker "release-count" "${RELEASES}以上" "$README"
