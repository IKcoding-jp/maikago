# 要件定義: Issue #47 ディレクトリ構成の統一（layer-first/feature-first混在）

## 概要

`lib/` のディレクトリ構成がlayer-first（`models/`, `providers/`, `services/`, `screens/`）とfeature-first（`drawer/`, `ad/`）で混在しているため、layer-firstに統一する。

## 現状の問題

- 基本はlayer-first構成だが、`drawer/` と `ad/` がfeature-first的に独立している
- `drawer/settings/` にUI（画面ウィジェット）とロジック（`settings_persistence.dart`, `settings_theme.dart`）が混在

## 要件

### R1: `drawer/` を `screens/drawer/` に移動
- ドロワー内の全画面ファイルを `screens/drawer/` 配下に配置
- `settings/` サブディレクトリもそのまま移動（`settings_persistence.dart`, `settings_theme.dart` を除く）

### R2: ロジックファイルを `services/` に移動
- `drawer/settings/settings_persistence.dart` → `services/settings_persistence.dart`
- `drawer/settings/settings_theme.dart` → `services/settings_theme.dart`

### R3: `ad/` を `services/ad/` に移動
- 広告関連の3ファイルを `services/ad/` 配下に配置

### R4: 全インポートパスの更新
- 移動に伴い、全ファイルのインポートパスを更新
- ビルドエラー・Lintエラーが発生しないこと

## 非機能要件

- 機能的な変更は一切行わない（純粋なリファクタリング）
- テストが全て通ること
- `flutter analyze` でエラーがないこと
