# タスクリスト

## フェーズ1: A1 — 課金サービスのテスト追加

### 1-1: TrialManager テスト
- [ ] FakeTrialManager or テスト用コンストラクタ設計
- [ ] 体験期間開始テスト（正常系）
- [ ] 体験期間終了テスト
- [ ] 期限切れ自動検出テスト（checkAndExpireIfNeeded）
- [ ] 二重開始防止テスト（isTrialEverStarted）
- [ ] 残り時間計算テスト（calculateTrialRemainingDuration）
- [ ] タイマー管理テスト（start/cancel）

### 1-2: PurchasePersistence テスト
- [ ] ローカル保存・復元の往復テスト
- [ ] レガシーキー（premium_unlocked）からの移行テスト
- [ ] Firestore 保存・読み込みテスト（Fake Firestore使用）
- [ ] 体験期間履歴（trial_history）の保存テスト

### 1-3: OneTimePurchaseService テスト
- [ ] FakeOneTimePurchaseService の拡充（既存Fakeを参考）
- [ ] 初期化フローテスト（initialize）
- [ ] 購入成功時の状態遷移テスト
- [ ] 購入復元テスト（restorePurchases）
- [ ] デバッグ用プレミアム切り替えテスト
- [ ] ログアウト時リセットテスト（resetForLogout）
- [ ] isPremiumUnlocked の正確性テスト

## フェーズ2: A2 — 認証サービスのテスト追加

### 2-1: FakeAuthService 作成
- [ ] FakeAuthService クラス設計（Firebase/Google依存をFake化）
- [ ] signInWithGoogle / signOut / getUser のFake実装
- [ ] authStateChanges の Fake Stream 実装

### 2-2: AuthService テスト
- [ ] ログイン成功テスト
- [ ] ログイン失敗テスト（PlatformException等）
- [ ] ログアウトテスト
- [ ] プロフィール保存テスト（_saveUserProfile）
- [ ] Web/モバイル分岐テスト（kIsWeb）

### 2-3: AuthProvider テスト
- [ ] 初期状態テスト（isLoggedIn, isGuestMode）
- [ ] ゲストモード開始・終了テスト
- [ ] ログイン→サービス初期化テスト（_initializeServices）
- [ ] ログアウト→状態リセットテスト
- [ ] ゲストデータマイグレーションコールバックテスト
- [ ] dispose テスト（ストリーム購読解除）

## フェーズ3: A3 — 命名リファクタ + 未使用コード削除

### 3-1: 未使用コード削除
- [ ] `lib/services/shared_group_service.dart` 削除
- [ ] `test/services/shared_group_service_test.dart` 削除

### 3-2: 命名リファクタ（Dartコード）
- [ ] `lib/models/shop.dart` — `sharedGroupId` → `sharedTabGroupId`（仮）、`sharedGroupIcon` → `sharedTabGroupIcon`（仮）
- [ ] `lib/models/shop.dart` — fromJson でデュアルリード対応（旧キー→新キーフォールバック）
- [ ] `lib/models/shared_group_icons.dart` → `shared_tab_icons.dart`（ファイル名・クラス名）
- [ ] `lib/providers/managers/shared_group_manager.dart` → `shared_tab_manager.dart`
- [ ] `lib/providers/data_provider.dart` — メソッド名・変数名更新
- [ ] UI層の全参照更新（tab_edit_dialog, main_app_bar, bottom_summary_widget, budget_dialog）
- [ ] `lib/utils/tab_sorter.dart` — メソッド名更新
- [ ] `lib/screens/main/utils/item_operations.dart` — 参照更新

### 3-3: テスト・ヘルパー更新
- [ ] `test/helpers/test_helpers.dart` — createSampleShop のパラメータ名更新
- [ ] `test/models/shop_test.dart` — フィールド名更新
- [ ] 既存テストの SharedGroup 参照を全て SharedTab に更新

### 3-4: SharedTabManager テスト追加
- [ ] 合計金額計算テスト（getDisplayTotal, getSharedTabTotal）
- [ ] 予算取得テスト（getSharedTabBudget）
- [ ] 共有タブ更新テスト（updateSharedTab）
- [ ] 共有タブ解除テスト（removeFromSharedTab）
- [ ] 予算同期テスト（syncSharedTabBudget）

### 3-5: ドキュメント更新
- [ ] CLAUDE.md の関連記述確認・更新
- [ ] docs/ 内の SharedGroup 言及更新

## フェーズ4: 検証

- [ ] `flutter analyze` — エラーなし確認
- [ ] `flutter test` — 全テストパス確認
- [ ] SharedGroup 残存チェック（fromJson デュアルリード箇所を除く）
- [ ] 既存 Firestore データの読み込み動作確認

## 依存関係
- フェーズ1, 2 は並行実行可能
- フェーズ3 はフェーズ1, 2 の後に実施（テスト基盤を先に整える）
- フェーズ4 は全フェーズ完了後
