# 要件定義: Issue #46 Color/fontSize定数の集約

## 概要

カラーコードとフォントサイズのマジックナンバーがプロジェクト全体に散在している問題を解消する。

## 背景

- `Color(0xFFFFB6C1)` のような直接的なカラーコードが **166箇所** に散在
- `fontSize: 22` 等のマジックナンバーが **200+箇所/23ファイル** に存在
- `AppColors` クラスは定義済みだが **1ファイル（login_screen.dart）でしか使用されていない**
- AdMob 本番広告 ID が `config.dart` にハードコード（フォールバック値が本番ID）

## 要件

### R1: Color定数の集約

- `AppColors` クラスをテーマ対応に拡張するか、`colorScheme` セマンティックカラーに統一
- `settings_theme.dart` のテーマ定義内カラーコードは許容（テーマ定義の一次ソース）
- その他のファイルでの直接カラーコード使用を定数参照に置換

### R2: fontSize定数の集約

- `Theme.of(context).textTheme` の活用を推進
- テーマの textTheme にマッピングできないサイズは定数クラスで管理
- 各ファイルでのハードコードを textTheme 参照または定数参照に置換

### R3: AdMob IDの環境変数移行

- `config.dart` のフォールバック値をテスト用 ID に変更
- 本番 ID は `env.json` / `--dart-define` のみで提供

## 対象外

- テーマ色分岐パターンの解消 → Issue #35 で対応
- SnackBar パターンの統一 → Issue #35 で対応
- テーマ自体の追加・変更
