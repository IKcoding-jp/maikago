# テスト計画

## テスト戦略

### 全体方針
- Fake実装パターンを採用（Firebase/IAP依存のため）
- SharedPreferences.setMockInitialValues({}) でローカルストレージをモック
- 既存テスト（feature_access_control_test.dart: 657行）のパターンに準拠

## A1: 課金サービスのテスト

### test/services/purchase/trial_manager_test.dart
- 体験期間開始（正常系: isTrialActive, startDate, endDate の検証）
- 体験期間終了（isTrialActive == false）
- 期限切れ自動検出（checkAndExpireIfNeeded で期限過ぎたら終了）
- 二重開始防止（isTrialEverStarted == true の場合に開始拒否）
- 残り時間計算（calculateTrialRemainingDuration の正確性）
- タイマー管理（startTrialTimer / cancelTrialTimer）
- コールバック呼び出し確認（onStateChanged が呼ばれるか）

### test/services/purchase/purchase_persistence_test.dart
- ローカル保存→復元の往復テスト
- レガシーキー（premium_unlocked）からの移行
- JSON形式の premium_status_map 保存・復元
- 体験期間情報の保存・復元
- Firestore 保存（FakeFirestore使用）
- Firestore 読み込み（ユーザー単位 + デバイスフィンガープリント）
- Firebase未初期化時のエラーハンドリング

### test/services/one_time_purchase_service_test.dart
- 初期化フロー（initialize → isInitialized == true）
- isPremiumUnlocked の正確性（通常 / デバッグオーバーライド）
- isPremiumPurchased（体験期間除外の判定）
- デバッグ用プレミアム切り替え（debugSetPremiumOverride）
- ログアウト時リセット（resetForLogout → 状態クリア確認）
- エラー状態管理（setError / clearError）
- ローディング状態管理

## A2: 認証サービスのテスト

### test/services/auth_service_test.dart
- Googleログイン成功（signInWithGoogle → User 返却）
- Googleログイン失敗（PlatformException 発生時のハンドリング）
- ログアウト（signOut → currentUser == null）
- プロフィール保存（_saveUserProfile → Firestore書き込み確認）
- authStateChanges ストリームの動作確認

### test/providers/auth_provider_test.dart
- 初期状態（isLoggedIn == false, isGuestMode == false, canUseApp == false）
- ゲストモード開始（enterGuestMode → isGuestMode == true, canUseApp == true）
- ログイン成功（signInWithGoogle → isLoggedIn == true, user != null）
- ログイン時サービス初期化（_initializeServices 呼び出し確認）
- ログアウト（signOut → isLoggedIn == false, user == null）
- ゲストデータマイグレーション（コールバック実行確認）
- ユーザー情報取得（userDisplayName, userEmail, userPhotoURL）
- dispose（ストリーム購読解除の確認）
- notifyListeners の呼び出し確認

## A3: SharedTabManager のテスト

### test/providers/managers/shared_tab_manager_test.dart
- getDisplayTotal — チェック済みアイテムの合計（価格×個数×割引率）
- getSharedTabTotal — グループ内全タブの合計集計
- getSharedTabBudget — グループの予算取得（最初のショップの予算）
- updateSharedTab — 新規共有設定（2-5タブ、クロスリファレンス正確性）
- updateSharedTab — 共有解除（参照除去の正確性）
- removeFromSharedTab — グループからの離脱
- syncSharedTabBudget — 全メンバーへの予算同期
- 楽観的更新パターン（キャッシュ即座更新 → Firestore書き込み）

※ 旧 shared_group_service_test.dart (916行) のテストケースを参考に移行

## テスト実行コマンド
```bash
# 全テスト
flutter test

# A1 のみ
flutter test test/services/purchase/
flutter test test/services/one_time_purchase_service_test.dart

# A2 のみ
flutter test test/services/auth_service_test.dart
flutter test test/providers/auth_provider_test.dart

# A3 のみ
flutter test test/providers/managers/shared_tab_manager_test.dart

# 静的分析
flutter analyze
```

## 検証チェックリスト
- [ ] 全テストがパスする
- [ ] flutter analyze エラーなし
- [ ] 既存テスト（feature_access_control_test 等）が壊れていない
- [ ] SharedGroup の命名がコードベースに残っていない（fromJson デュアルリード除く）
