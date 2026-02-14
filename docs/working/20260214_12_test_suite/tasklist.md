# タスクリスト: テストスイート整備

**Issue**: #12
**作成日**: 2026-02-14
**更新日**: 2026-02-14
**ステータス**: 未着手

---

## Phase 1: テスト環境構築 (見積: 1日)

### 1.1 依存関係確認・追加

- [ ] `pubspec.yaml` のテスト関連依存関係確認
  - [x] `flutter_test` (SDK標準)
  - [x] `mockito: ^5.5.1` (既存)
  - [x] `build_runner: ^2.8.0` (既存)
  - [ ] 必要に応じて `fake_async`, `clock` を追加検討

### 1.2 テストディレクトリ構造作成

- [ ] `test/providers/` ディレクトリ作成
- [ ] `test/services/` ディレクトリ作成
- [ ] `test/screens/` ディレクトリ作成
- [ ] `test/models/` ディレクトリ作成 (必要に応じて)
- [ ] `test/helpers/` ディレクトリ作成 (テストヘルパー用)

### 1.3 mockito 自動生成設定

- [ ] `test/mocks.dart` ファイル作成
- [ ] モック対象クラスのアノテーション設定
  ```dart
  @GenerateMocks([
    DataService,
    AuthProvider,
    ChatGptService,
    // ... 他のモック対象
  ])
  ```
- [ ] `flutter pub run build_runner build` 実行
- [ ] 生成された `test/mocks.mocks.dart` の動作確認

### 1.4 テストヘルパー作成

- [ ] `test/helpers/test_helpers.dart` 作成
  - [ ] `createMockDataProvider()` ヘルパー
  - [ ] `createMockAuthProvider()` ヘルパー
  - [ ] `createMockFirestore()` ヘルパー
  - [ ] サンプルデータ生成関数

---

## Phase 2: DataProvider単体テスト (見積: 2-3日)

### 2.1 テストファイル作成

- [ ] `test/providers/data_provider_test.dart` 作成
- [ ] テストファイル基本構造設定 (setUp, tearDown)

### 2.2 addItem() テスト実装

- [ ] ✅ アイテム追加成功ケース
- [ ] ✅ 重複アイテム追加時のupdateItem呼び出し
- [ ] ✅ 楽観的更新の検証 (即座にUI反映)
- [ ] ✅ Firebase保存成功の検証
- [ ] ❌ Firebase保存失敗時のロールバック
- [ ] ✅ ローカルモード時のFirebase非呼び出し
- [ ] ✅ notifyListeners() 呼び出しの検証

**優先度**: 高

### 2.3 updateItem() テスト実装

- [ ] ✅ アイテム更新成功ケース
- [ ] ❌ 存在しないアイテム更新時のエラー
- [ ] ✅ バウンス抑止 (_pendingItemUpdates) の検証
- [ ] ✅ ショップ内アイテムの同期更新
- [ ] ✅ notifyListeners() 呼び出しの検証

**優先度**: 高

### 2.4 deleteItem() テスト実装

- [ ] ✅ アイテム削除成功ケース
- [ ] ❌ 存在しないアイテム削除時のエラー
- [ ] ✅ ショップ内アイテムの同期削除
- [ ] ✅ notifyListeners() 呼び出しの検証

**優先度**: 高

### 2.5 loadData() テスト実装

- [ ] ✅ 初回データロード成功
- [ ] ✅ キャッシュからのロード (_isDataLoaded フラグ)
- [ ] ✅ 認証状態変更時の再ロード
- [ ] ✅ ローカルモード時のFirebase非呼び出し
- [ ] ❌ タイムアウトエラーハンドリング

**優先度**: 高

### 2.6 認証連携テスト

- [ ] ✅ setAuthProvider() の正常動作
- [ ] ✅ 認証状態変更リスナーの動作
- [ ] ✅ ログイン時のデータリセット (_resetDataForLogin)
- [ ] ✅ ログアウト時のデータクリア

**優先度**: 中

### 2.7 ショップ管理テスト

- [ ] ✅ _ensureDefaultShop() の動作
- [ ] ✅ デフォルトショップ削除済みフラグの検証
- [ ] ✅ addShop() の動作
- [ ] ✅ updateShop() の動作
- [ ] ✅ deleteShop() の動作

**優先度**: 中

---

## Phase 3: ChatGptService単体テスト (見積: 2日)

### 3.1 テストファイル作成

- [ ] `test/services/chatgpt_service_test.dart` 作成
- [ ] HTTPクライアントモック設定

### 3.2 extractProductInfo() テスト実装

- [ ] ✅ OCRテキストから商品情報抽出成功
- [ ] ❌ APIキー未設定時のエラー
- [ ] ❌ HTTP 401エラー (認証失敗)
- [ ] ❌ HTTP 429エラー (レート制限)
- [ ] ❌ タイムアウトエラー
- [ ] ✅ JSONパースエラーハンドリング
- [ ] ✅ null/空レスポンスハンドリング

**優先度**: 高

### 3.3 extractProductInfoFromImage() テスト実装

- [ ] ✅ 画像から商品情報抽出成功
- [ ] ✅ Base64エンコード処理の検証
- [ ] ❌ APIエラーハンドリング
- [ ] ✅ Vision APIレスポンスパース

**優先度**: 高

### 3.4 extractPriceCandidates() テスト実装

- [ ] ✅ 価格候補一覧抽出成功
- [ ] ✅ 税込/税抜/税率の正しい抽出
- [ ] ✅ リトライ処理の検証 (最大3回)
- [ ] ❌ リトライ後も失敗時の空配列返却

**優先度**: 中

### 3.5 extractNameAndPrice() テスト実装

- [ ] ✅ 商品名と価格抽出成功
- [ ] ✅ 小数点誤認識修正の検証
- [ ] ✅ 税込/税抜判定ロジック
- [ ] ✅ 複数価格候補からの最高価格選択
- [ ] ✅ confidence スコア計算

**優先度**: 高

### 3.6 エッジケーステスト

- [ ] ✅ 空文字列入力
- [ ] ✅ 異常に長いテキスト入力
- [ ] ✅ 特殊文字を含む入力
- [ ] ❌ ネットワークエラー

**優先度**: 低

---

## Phase 4: AuthService単体テスト (見積: 1-2日)

### 4.1 テストファイル作成

- [ ] `test/services/auth_service_test.dart` 作成
- [ ] Firebase/GoogleSignInモック設定

### 4.2 signInWithGoogle() テスト実装

- [ ] ✅ サインイン成功 (ネイティブ)
- [ ] ✅ サインイン成功 (Webポップアップ)
- [ ] ✅ サインイン成功 (Webリダイレクト)
- [ ] ❌ サインインキャンセル
- [ ] ❌ ID Token取得失敗
- [ ] ❌ Firebase認証失敗
- [ ] ❌ PlatformException各種エラーコード
- [ ] ✅ ユーザープロフィール保存の呼び出し

**優先度**: 高

### 4.3 signOut() テスト実装

- [ ] ✅ サインアウト成功
- [ ] ❌ サインアウト失敗時のエラーハンドリング
- [ ] ✅ Firebase/GoogleSignIn両方のサインアウト

**優先度**: 高

### 4.4 認証状態監視テスト

- [ ] ✅ authStateChanges ストリームの動作
- [ ] ✅ currentUser 取得
- [ ] ❌ Firebase未初期化時のエラーハンドリング

**優先度**: 中

### 4.5 Webリダイレクト認証テスト

- [ ] ✅ checkRedirectResult() 成功ケース
- [ ] ✅ リダイレクト結果がnullの場合
- [ ] ❌ リダイレクトエラーハンドリング

**優先度**: 中

### 4.6 ユーザープロフィール保存テスト

- [ ] ✅ _saveUserProfile() 成功
- [ ] ❌ Firestore保存失敗

**優先度**: 低

---

## Phase 5: OneTimePurchaseService単体テスト (見積: 1-2日)

### 5.1 テストファイル作成

- [ ] `test/services/one_time_purchase_service_test.dart` 作成
- [ ] InAppPurchase/Firebaseモック設定

### 5.2 initialize() テスト実装

- [ ] ✅ 初回初期化成功
- [ ] ✅ 複数回初期化時のスキップ
- [ ] ✅ ユーザーID変更時の再ロード
- [ ] ✅ デバイスフィンガープリント生成
- [ ] ❌ Firebase未初期化時のエラーハンドリング

**優先度**: 高

### 5.3 プレミアム状態取得テスト

- [ ] ✅ isPremiumUnlocked getter (購入済み)
- [ ] ✅ isPremiumUnlocked getter (体験期間中)
- [ ] ✅ isPremiumUnlocked getter (未購入)
- [ ] ✅ isPremiumPurchased getter

**優先度**: 高

### 5.4 体験期間ロジックテスト

- [ ] ✅ 体験期間開始処理
- [ ] ✅ 体験期間終了判定
- [ ] ✅ trialRemainingDuration 計算
- [ ] ✅ 体験期間タイマーの動作

**優先度**: 高

### 5.5 デバイスフィンガープリント生成テスト

- [ ] ✅ Android デバイスフィンガープリント生成
- [ ] ✅ iOS デバイスフィンガープリント生成
- [ ] ✅ Web デバイスフィンガープリント生成
- [ ] ✅ フォールバックロジックの検証

**優先度**: 中

### 5.6 LocalStorage連携テスト

- [ ] ✅ SharedPreferencesからの状態ロード
- [ ] ✅ SharedPreferencesへの状態保存
- [ ] ✅ ユーザーごとの状態分離

**優先度**: 中

---

## Phase 6: MainScreen ウィジェットテスト (見積: 1日)

### 6.1 テストファイル作成

- [ ] `test/screens/main_screen_test.dart` 作成
- [ ] Provider モック設定

### 6.2 基本レンダリングテスト

- [ ] ✅ MainScreen ウィジェット表示
- [ ] ✅ AppBar レンダリング
- [ ] ✅ TabBar レンダリング
- [ ] ✅ FloatingActionButton レンダリング

**優先度**: 中

### 6.3 タブ操作テスト

- [ ] ✅ タブ切り替え動作
- [ ] ✅ タブ追加ボタンタップ
- [ ] ✅ タブ編集ダイアログ表示

**優先度**: 中

### 6.4 ダイアログ表示テスト

- [ ] ✅ AddTabDialog 表示
- [ ] ✅ ItemEditDialog 表示
- [ ] ✅ SortDialog 表示
- [ ] ✅ BudgetDialog 表示

**優先度**: 低

### 6.5 Provider連携テスト

- [ ] ✅ DataProvider からのデータ取得
- [ ] ✅ AuthProvider からの認証状態取得
- [ ] ✅ OneTimePurchaseService からのプレミアム状態取得

**優先度**: 中

---

## Phase 7: CI/CD統合・ドキュメント作成 (見積: 1日)

### 7.1 GitHub Actions設定

- [ ] `.github/workflows/test.yml` 作成
- [ ] PRマージ前のテスト自動実行設定
- [ ] テストカバレッジレポート生成
- [ ] テスト失敗時のPRブロック設定

### 7.2 Codemagic統合

- [ ] `codemagic.yaml` にテスト実行追加
- [ ] ビルド前のテスト実行設定
- [ ] テスト失敗時のビルド中断設定

### 7.3 テストドキュメント作成

- [ ] `docs/testing/test_guide.md` 作成
  - [ ] テスト実装ガイドライン
  - [ ] テストコード規約
  - [ ] モック作成手順
  - [ ] テスト実行方法

- [ ] `docs/testing/test_coverage.md` 作成
  - [ ] カバレッジ目標
  - [ ] カバレッジレポート参照方法

### 7.4 READMEにテスト情報追加

- [ ] `README.md` にテスト実行コマンド追加
- [ ] テストカバレッジバッジ追加 (オプション)

---

## Phase 8: レビュー・改善 (見積: 0.5日)

### 8.1 コードレビュー

- [ ] テストコードのレビュー
- [ ] カバレッジ目標達成確認
- [ ] テスト実行時間計測

### 8.2 改善・修正

- [ ] レビュー指摘事項の修正
- [ ] テスト失敗の修正
- [ ] ドキュメント誤字脱字修正

### 8.3 最終確認

- [ ] 全テスト実行 (`flutter test`)
- [ ] CI/CDパイプライン動作確認
- [ ] Issue #12 クローズ

---

## 進捗トラッキング

### 全体進捗

- **完了タスク数**: 0 / 120
- **進捗率**: 0%
- **ステータス**: 未着手

### Phase別進捗

| Phase | タスク数 | 完了数 | 進捗率 | ステータス |
|-------|---------|-------|-------|-----------|
| Phase 1 | 12 | 0 | 0% | 未着手 |
| Phase 2 | 30 | 0 | 0% | 未着手 |
| Phase 3 | 25 | 0 | 0% | 未着手 |
| Phase 4 | 18 | 0 | 0% | 未着手 |
| Phase 5 | 18 | 0 | 0% | 未着手 |
| Phase 6 | 12 | 0 | 0% | 未着手 |
| Phase 7 | 9 | 0 | 0% | 未着手 |
| Phase 8 | 6 | 0 | 0% | 未着手 |

---

## 優先度マトリクス

### 高優先度 (Phase 2, 3, 4, 5の一部)

1. DataProvider: addItem, updateItem, deleteItem, loadData
2. ChatGptService: extractProductInfo, extractProductInfoFromImage, extractNameAndPrice
3. AuthService: signInWithGoogle, signOut
4. OneTimePurchaseService: initialize, isPremiumUnlocked, 体験期間ロジック

### 中優先度 (Phase 2, 3, 4, 5, 6の一部)

1. DataProvider: 認証連携、ショップ管理
2. ChatGptService: extractPriceCandidates
3. AuthService: 認証状態監視、Webリダイレクト
4. OneTimePurchaseService: デバイスフィンガープリント、LocalStorage
5. MainScreen: 基本レンダリング、タブ操作、Provider連携

### 低優先度 (Phase 3, 4, 5, 6の一部)

1. ChatGptService: エッジケース
2. AuthService: ユーザープロフィール保存
3. MainScreen: ダイアログ表示

---

## ブロッカー・依存関係

### 依存関係

- Phase 2-5は並列実行可能
- Phase 6はPhase 1完了後に実施
- Phase 7はPhase 2-6完了後に実施
- Phase 8はPhase 7完了後に実施

### ブロッカー

- なし (現時点)

---

## 備考

- 各タスクの✅は成功ケース、❌は失敗ケースを示す
- テスト実装は段階的に進め、CI/CDで継続的に検証する
- カバレッジ目標未達の場合は、優先度を見直して追加実装を検討
