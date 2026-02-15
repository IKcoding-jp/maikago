# 要件定義: Issue #35 テーマ色分岐・SnackBar等のコード重複解消

## 概要

テーマ色判定の条件分岐パターンと SnackBar エラー表示パターンがプロジェクト全体で大量にコピペされている問題を解消する。

## 背景

- `currentTheme == 'dark' ? Colors.white : ...` のような3重条件分岐が **134箇所** に散在
- `ScaffoldMessenger.of(context).showSnackBar(...)` のパターンが **48箇所/16ファイル** に重複
- SnackBar の背景色が統一されていない（`colorScheme.error`, `Colors.red`, `Colors.orange`, `Colors.grey` が混在）

## 要件

### R1: テーマユーティリティヘルパーの作成

- テーマ色分岐を集約するヘルパー関数/Extension を作成
- 既存の `SettingsTheme.getContrastColor()` を活用・拡張
- `Theme.of(context).colorScheme` のセマンティックカラーを活用する方向で統一

### R2: SnackBar ユーティリティ関数の作成

- `showErrorSnackBar(BuildContext context, dynamic error)` を作成
- `showSuccessSnackBar(BuildContext context, String message)` を作成
- 背景色は `Theme.of(context).colorScheme` から取得し統一

### R3: 既存コードの置換

- テーマ色分岐のハードコードを新ヘルパーに置換
- SnackBar 表示コードを新ユーティリティに置換
- 全ファイルで動作が変わらないこと

## 対象外

- テーマ定義そのもの（`settings_theme.dart` の switch 文）の変更 → Issue #46 で対応
- 新テーマの追加
- UI デザインの変更
