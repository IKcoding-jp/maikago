# タスクリスト — Issue #89: コード品質改善

**ステータス**: 未着手
**作成日**: 2026-02-20

## Phase 1: カメラ画面統合（H-1）

- [ ] `camera_screen.dart` のテストコード参照を確認
- [ ] `camera_screen.dart` を削除（未使用）
- [ ] `enhanced_camera_screen.dart` を `camera_screen.dart` にリネーム
- [ ] クラス名を `EnhancedCameraScreen` → `CameraScreen` に変更
- [ ] 全インポート参照を更新（router.dart 等）
- [ ] カメラ機能の動作確認

## Phase 2: ハードコードバージョン修正（H-2）

- [ ] `version_notification_service.dart:46` — `'1.2.0'` → 定数化
- [ ] `release_history_screen.dart:43` — `'1.1.6'` → 定数化
- [ ] フォールバックバージョンを `pubspec.yaml` の現行バージョンと同期

## Phase 3: settings_persistence 共通化（M-1）

- [ ] ジェネリックヘルパー `_save<T>()` / `_load<T>()` を実装
- [ ] シンプル保存メソッド（4個）をヘルパーに移行
- [ ] シンプル読み込みメソッド（6個）をヘルパーに移行
- [ ] タブ別操作メソッド（4個）をヘルパーに移行
- [ ] 空catchブロック（192-194行）を修正

## Phase 4: エラーハンドリング修正（M-2）

- [ ] `main_screen.dart:178` — 空catch → DebugServiceログ追加
- [ ] `main_screen.dart:248` — 空catch → DebugServiceログ追加
- [ ] `data_service.dart:603` — 空catch → DebugServiceログ追加
- [ ] `shared_group_icons.dart:80-82` — `firstWhere` + `orElse` に改善
- [ ] `version_notification_service.dart:62` — 空catch → ログ追加

## Phase 5: donation_screen switch文統一（M-3）

- [ ] `donationProductIdToAmount` / `donationAmountToProductId` のMap定義を追加
- [ ] `_getAmountFromProductId()` をMap参照に置換
- [ ] `_getProductIdFromAmount()` をMap参照に置換

## Phase 6: 検証

- [ ] `flutter analyze` 通過
- [ ] `flutter test` 全テスト通過
