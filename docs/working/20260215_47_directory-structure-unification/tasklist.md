# タスクリスト: Issue #47 ディレクトリ構成の統一

**ステータス**: 完了
**完了日**: 2026-02-15
**優先度**: Low

## Phase 1: ファイル移動

- [x] 1.1 `lib/drawer/settings/settings_persistence.dart` → `lib/services/settings_persistence.dart`
- [x] 1.2 `lib/drawer/settings/settings_theme.dart` → `lib/services/settings_theme.dart`
- [x] 1.3 `lib/drawer/` → `lib/screens/drawer/` （上記2ファイル除く全ファイル）
- [x] 1.4 `lib/ad/` → `lib/services/ad/`
- [x] 1.5 旧ディレクトリ（`lib/drawer/`, `lib/ad/`）の削除確認

## Phase 2: インポートパス更新

- [x] 2.1 `drawer/settings/settings_persistence.dart` → `services/settings_persistence.dart` のインポート更新（11+ファイル）
- [x] 2.2 `drawer/settings/settings_theme.dart` → `services/settings_theme.dart` のインポート更新（12+ファイル）
- [x] 2.3 `drawer/` → `screens/drawer/` のインポート更新（drawer画面ファイル参照）
- [x] 2.4 `ad/` → `services/ad/` のインポート更新（3ファイル）
- [x] 2.5 移動したファイル内部のインポートパス更新（相互参照の修正）

## Phase 3: 検証

- [x] 3.1 `flutter analyze` 通過
- [x] 3.2 `flutter test` 通過（180テスト全通過）

## Phase 4: ドキュメント更新

- [x] 4.1 CLAUDE.md のアーキテクチャセクション更新
