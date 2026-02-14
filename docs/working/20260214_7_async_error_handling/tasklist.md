# タスクリスト

**ステータス**: 完了
**完了日**: 2026-02-15

## フェーズ1: 調査
- [x] `void.*async`パターンの全箇所をGrepで検索（10箇所特定）
- [x] `catch (_)`パターンの全箇所をGrepで検索（6箇所特定）
- [x] `catch (e)`でログのみの箇所を洗い出し

## フェーズ2: 修正
- [x] `lib/main.dart` - `_checkForUpdatesInBackground`を`Future<void>`に変更
- [x] `lib/main.dart` - `_initializeVersionNotification`を`Future<void>`に変更
- [x] `lib/main.dart` - `_showAppOpenAdOnResume`を`Future<void>`に変更
- [x] `lib/widgets/welcome_dialog.dart` - `_completeWelcome`を`Future<void>`に変更
- [x] `lib/ad/ad_banner.dart` - `_loadBannerAd`を`Future<void>`に変更
- [x] `lib/providers/auth_provider.dart` - `_init`を`Future<void>`に変更
- [x] `lib/screens/recipe_confirm_screen.dart` - `_editIngredient`を`Future<void>`に変更
- [x] `lib/drawer/settings/settings_screen.dart` - 3メソッドを`Future<void>`に変更
- [x] `lib/screens/main/widgets/bottom_summary_widget.dart` - `catch (_)` 2箇所にログ追加
- [x] `lib/services/vision_ocr_service.dart` - `catch (_)` 1箇所にログ追加
- [x] `main.dart`の`late final`関連`catch (_)` 3箇所は#6対象のためスキップ

## フェーズ3: 確認
- [x] `flutter analyze`でエラーがないこと
- [x] `flutter test` 65テスト全通過

## 依存関係
- フェーズ1 → フェーズ2 → フェーズ3（順次実行）
