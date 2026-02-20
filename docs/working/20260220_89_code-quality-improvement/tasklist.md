# タスクリスト — Issue #89: コード品質改善

**ステータス**: 完了
**作成日**: 2026-02-20
**完了日**: 2026-02-20

## Phase 1: カメラ画面統合（H-1）

- [x] `camera_screen.dart` のテストコード参照を確認
- [x] `camera_screen.dart` を削除（未使用）
- [x] `enhanced_camera_screen.dart` を `camera_screen.dart` にリネーム
- [x] クラス名を `EnhancedCameraScreen` → `CameraScreen` に変更
- [x] 全インポート参照を更新（router.dart 等）
- [x] カメラ機能の動作確認

## Phase 2: ハードコードバージョン修正（H-2）

- [x] `version_notification_service.dart:46` — `'1.2.0'` → `'1.3.1'`
- [x] `release_history_screen.dart:43` — `'1.1.6'` → `'1.3.1'`
- [x] フォールバックバージョンを `pubspec.yaml` の現行バージョンと同期

## Phase 3: settings_persistence 共通化（M-1）

- [x] ジェネリックヘルパー `_save()` / `_load<T>()` を実装
- [x] シンプル保存メソッド（6個）をヘルパーに移行
- [x] シンプル読み込みメソッド（8個）をヘルパーに移行
- [x] タブ別操作メソッド（2個）をヘルパーに移行
- [x] 空catchブロック（192-194行）を修正

## Phase 4: エラーハンドリング修正（M-2）

- [x] `main_screen.dart:178` — 空catch → DebugServiceログ追加
- [x] `main_screen.dart:248` — 空catch → DebugServiceログ追加
- [x] `data_service.dart:603` — 空catch → DebugServiceログ追加
- [x] `shared_group_icons.dart:80-82` — `firstWhere` + `orElse` に改善
- [x] `version_notification_service.dart:62` — 空catch → ログ追加

## Phase 5: donation_screen switch文統一（M-3）

- [x] `_productIdToAmount` / `_amountToProductId` のMap定義を追加
- [x] `_getAmountFromProductId()` をMap参照に置換
- [x] `_getProductIdFromAmount()` をMap参照に置換

## Phase 6: 検証

- [x] `flutter analyze` 通過
- [x] `flutter test` 全テスト通過（137テスト）
