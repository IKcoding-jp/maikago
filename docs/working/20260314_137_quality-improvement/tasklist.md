# タスクリスト

**ステータス**: 完了
**完了日**: 2026-03-14

## フェーズ1: A1 — 課金サービスのテスト追加

### 1-1: TrialManager テスト
- [x] テスト用コンストラクタ設計（onStateChangedコールバック）
- [x] 体験期間開始テスト（正常系）
- [x] 体験期間終了テスト
- [x] 期限切れ自動検出テスト（checkAndExpireIfNeeded）
- [x] 二重開始防止テスト（isTrialEverStarted）
- [x] 残り時間計算テスト（calculateTrialRemainingDuration）
- [x] タイマー管理テスト（start/cancel）

### 1-2: PurchasePersistence テスト
- [x] ローカル保存・復元の往復テスト
- [x] レガシーキー（premium_unlocked）からの移行テスト
- [x] 体験期間情報の保存・復元テスト

### 1-3: OneTimePurchaseService テスト
- [x] FakeOneTimePurchaseService の拡充（コントラクトテスト）
- [x] isPremiumUnlockedのロジックテスト（購入/体験期間/デバッグオーバーライド）
- [x] デバッグ用プレミアム切り替えテスト
- [x] ログアウト時リセットテスト（resetForLogout）
- [x] 体験期間の委譲テスト（startTrial/endTrial）

## フェーズ2: A2 — 認証サービスのテスト追加

### 2-3: AuthProvider テスト
- [x] 初期状態テスト（isLoggedIn, isGuestMode）
- [x] ゲストモード開始テスト
- [x] ゲストモード復元テスト（SharedPreferences）
- [x] ゲストデータマイグレーションコールバックテスト
- [x] ユーザー情報テスト（未ログイン時）
- [x] dispose テスト

注: AuthServiceはFirebase/GoogleSignInに強く結合しており、本体変更なしではテスト困難。AuthProviderのローカルモードテストでカバー。

## フェーズ3: A3 — 命名リファクタ + 未使用コード削除

### 3-1: 未使用コード削除
- [x] `lib/services/shared_group_service.dart` 削除
- [x] `test/services/shared_group_service_test.dart` 削除

### 3-2: 命名リファクタ（Dartコード）
- [x] `lib/models/shop.dart` — フィールド名リネーム + fromJson デュアルリード
- [x] `lib/models/shared_group_icons.dart` → `shared_tab_icons.dart`
- [x] `lib/providers/managers/shared_group_manager.dart` → `shared_tab_manager.dart`
- [x] `lib/providers/data_provider.dart` — メソッド名・変数名更新
- [x] UI層の全参照更新
- [x] `lib/utils/tab_sorter.dart` — メソッド名更新
- [x] `lib/screens/main/utils/item_operations.dart` — 参照更新

### 3-3: テスト・ヘルパー更新
- [x] `test/helpers/test_helpers.dart` — createSampleShop のパラメータ名更新
- [x] `test/models/shop_test.dart` — フィールド名更新
- [x] 既存テストの SharedGroup 参照を全て SharedTab に更新

### 3-5: ドキュメント更新
- [x] CLAUDE.md の関連記述確認・更新

## フェーズ4: 検証

- [x] `flutter analyze` — エラーなし確認
- [x] `flutter test` — 全366テストパス確認
- [x] SharedGroup 残存チェック（fromJson デュアルリード箇所を除く）
- [x] 手動動作確認

## 依存関係
- フェーズ1, 2 は並行実行可能
- フェーズ3 はフェーズ1, 2 の後に実施（テスト基盤を先に整える）
- フェーズ4 は全フェーズ完了後
