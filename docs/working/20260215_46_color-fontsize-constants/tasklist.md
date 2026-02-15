# タスクリスト: Issue #46 Color/fontSize定数の集約

**ステータス**: 実装完了

## Phase 1: 定数・ユーティリティ整備

- [x] 1.1 `AppColors` クラスを整理（装飾色・ブランド色・ダークテーマ色を追加）
- [x] 1.2 AdMob ID のフォールバック値をテスト用 ID に変更（`config.dart`）
- [x] 1.3 広告サービスを `Env` 経由に変更（env.json → --dart-define → テスト用ID）

## Phase 2: Color定数の置換

- [x] 2.1 `maikago_premium.dart` のハードコードカラーを `AppColors` 定数に置換（11箇所）
- [x] 2.2 `welcome_dialog.dart` のパステル色を `AppColors` に置換（3箇所）
- [x] 2.3 `main_screen.dart` の `customColors` マップを `AppColors` に置換
- [x] 2.4 `about_screen.dart` のハードコードカラーを置換（4箇所）
- [x] 2.5 `usage_screen.dart` の装飾色を `AppColors` に置換（8箇所）
- [x] 2.6 `upgrade_promotion_widget.dart` のプロモーション色を置換
- [x] 2.7 `calculator_screen.dart` のダークテーマ色を置換（3箇所）
- [x] 2.8 `release_history_screen.dart` のダークテーマ色を置換（2箇所）
- [x] 2.9 `version_update_dialog.dart` のダークカード色を置換
- [x] 2.10 settings系ファイル群のダークテーマ色を置換（4ファイル）
- [x] 2.11 `settings_font.dart` の背景色を置換

## Phase 3: fontSize定数の置換

- [x] 3.1 `maikago_premium.dart` の fontSize を textTheme 参照に置換（24箇所）
- [x] 3.2 `calculator_screen.dart` の fontSize を置換（5箇所）
- [x] 3.3 screens系ファイル群の fontSize を置換
- [x] 3.4 widgets系ファイル群の fontSize を置換
- [x] 3.5 dialogs系ファイル群の fontSize を置換

## Phase 4: 検証

- [x] 4.1 `flutter analyze` 通過
- [ ] 4.2 `flutter test` 通過
