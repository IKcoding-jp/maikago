# 要件定義書: テストスイート整備

**Issue**: #12
**作成日**: 2026-02-14
**ラベル**: testing, critical
**担当**: Claude Code

---

## 1. 背景と目的

### 1.1 背景

まいカゴプロジェクトは現在、ほぼテストが存在しない状態です。`test/`ディレクトリには実質的なテストコードが無く、以下の問題が顕在化しています。

- `lib/providers/data_provider.dart` (1500行超) の大規模なロジックが未検証
- `lib/services/chatgpt_service.dart` のOCR/AI連携ロジックが手動テストのみ
- `lib/services/auth_service.dart` の認証フローが複雑かつ未テスト
- `lib/services/one_time_purchase_service.dart` の課金ロジックが未検証
- リグレッションの早期発見が困難
- CI/CDパイプラインでの自動テストが機能していない

### 1.2 目的

本Issue #12では、プロジェクトの品質保証基盤を構築し、以下を実現します。

1. **重要コンポーネントの単体テストカバレッジ確保**
   - DataProvider: 状態管理・同期ロジックの検証
   - ChatGptService: OCR/AI解析ロジックの検証
   - AuthService: 認証フローの検証
   - OneTimePurchaseService: 課金ロジックの検証

2. **統合テスト・E2Eテストの基盤構築**
   - ユーザーシナリオベースのテスト
   - Firebase連携のモック化とテスト

3. **CI/CDパイプラインでの自動テスト実行**
   - GitHub Actions / Codemagic での自動テスト
   - PRマージ前の品質ゲート

4. **テストベストプラクティスの確立**
   - テストコード規約の策定
   - テスト実装ガイドラインの作成

---

## 2. 機能要件

### 2.1 単体テスト (Unit Tests)

#### 2.1.1 DataProvider テスト (`test/providers/data_provider_test.dart`)

**対象メソッド (優先度順)**:

| メソッド名 | テストケース例 | 優先度 |
|-----------|--------------|-------|
| `addItem()` | アイテム追加成功、重複チェック、楽観的更新、エラーハンドリング | 高 |
| `updateItem()` | アイテム更新成功、存在しないアイテム更新、バウンス抑止 | 高 |
| `deleteItem()` | アイテム削除成功、存在しないアイテム削除 | 高 |
| `loadData()` | 初回ロード、キャッシュロード、認証状態変更時のロード | 高 |
| `setAuthProvider()` | 認証プロバイダー設定、認証状態変更リスナー | 中 |
| `_resetDataForLogin()` | ログイン時のデータリセット | 中 |
| `_ensureDefaultShop()` | デフォルトショップ作成、削除済みショップの再作成抑制 | 中 |

**モック対象**:
- `DataService` (Firebase Firestore操作)
- `AuthProvider` (認証状態)
- `SettingsPersistence` (SharedPreferences)

#### 2.1.2 ChatGptService テスト (`test/services/chatgpt_service_test.dart`)

**対象メソッド**:

| メソッド名 | テストケース例 | 優先度 |
|-----------|--------------|-------|
| `extractProductInfo()` | OCRテキストから商品情報抽出成功、失敗、タイムアウト | 高 |
| `extractProductInfoFromImage()` | 画像から商品情報抽出成功、失敗 | 高 |
| `extractPriceCandidates()` | 価格候補抽出成功、リトライ処理、エラーハンドリング | 中 |
| `extractNameAndPrice()` | 商品名と価格抽出、小数点誤認識修正、税込/税抜判定 | 高 |

**モック対象**:
- `http.Client` (OpenAI API呼び出し)
- レスポンスデータ (JSONモック)

#### 2.1.3 AuthService テスト (`test/services/auth_service_test.dart`)

**対象メソッド**:

| メソッド名 | テストケース例 | 優先度 |
|-----------|--------------|-------|
| `signInWithGoogle()` | サインイン成功、キャンセル、エラー、Web/モバイル分岐 | 高 |
| `signOut()` | サインアウト成功、エラー | 高 |
| `checkRedirectResult()` | Webリダイレクト認証結果確認 | 中 |
| `_saveUserProfile()` | ユーザープロフィール保存成功、失敗 | 中 |

**モック対象**:
- `FirebaseAuth`
- `GoogleSignIn`
- `FirebaseFirestore`

#### 2.1.4 OneTimePurchaseService テスト (`test/services/one_time_purchase_service_test.dart`)

**対象メソッド**:

| メソッド名 | テストケース例 | 優先度 |
|-----------|--------------|-------|
| `initialize()` | 初期化成功、複数回初期化、ユーザーID変更 | 高 |
| `isPremiumUnlocked` | プレミアム状態取得、体験期間判定 | 高 |
| `_generateDeviceFingerprint()` | デバイスフィンガープリント生成 | 中 |
| 体験期間ロジック | 体験期間開始、終了、残り時間計算 | 高 |

**モック対象**:
- `InAppPurchase`
- `FirebaseFirestore`
- `FirebaseAuth`
- `SharedPreferences`

### 2.2 ウィジェットテスト (Widget Tests)

#### 2.2.1 MainScreen テスト (`test/screens/main_screen_test.dart`)

**テストケース**:
- ウィジェットの初期レンダリング
- タブ切り替え動作
- ダイアログ表示 (AddTabDialog, ItemEditDialog, etc.)
- Provider連携の検証

**モック対象**:
- `DataProvider`
- `AuthProvider`
- `OneTimePurchaseService`

### 2.3 統合テスト (Integration Tests)

**優先度**: 中 (単体テスト完了後に実施)

- Firebase連携テスト (エミュレーター使用)
- 認証フローの統合テスト
- データ同期フローの統合テスト

---

## 3. 非機能要件

### 3.1 テストカバレッジ目標

| コンポーネント | 目標カバレッジ |
|--------------|--------------|
| `DataProvider` | 80%以上 |
| `ChatGptService` | 70%以上 |
| `AuthService` | 75%以上 |
| `OneTimePurchaseService` | 75%以上 |
| 全体 | 60%以上 |

### 3.2 テスト実行時間

- 単体テスト全体: 5秒以内
- ウィジェットテスト: 10秒以内
- 統合テスト: 30秒以内

### 3.3 CI/CD統合

- GitHub Actions: PRマージ前にテスト自動実行
- Codemagic: iOS/Androidビルド前にテスト実行
- テスト失敗時のビルド中断

---

## 4. 制約事項

### 4.1 技術的制約

- Flutter SDK: >=3.0.0 <4.0.0
- テストフレームワーク: `flutter_test` (標準)
- モックライブラリ: `mockito` (既存依存関係)
- ビルドランナー: `build_runner` (既存依存関係)

### 4.2 リソース制約

- 既存コードへの影響を最小限にする (コード変更なし原則)
- テストコードのみを追加 (リファクタリングは別Issue)
- 段階的な実装 (全テストを一度に実装しない)

### 4.3 スコープ外

- 既存コードのリファクタリング (Issue #3, #4, #5 で実施)
- パフォーマンステスト
- セキュリティテスト (別途実施)
- E2Eテスト (後続フェーズで実施)

---

## 5. 成功基準

以下の条件をすべて満たすことで、Issue #12を完了とします。

1. **単体テスト実装完了**
   - `DataProvider`: 主要メソッドの80%カバレッジ
   - `ChatGptService`: 主要メソッドの70%カバレッジ
   - `AuthService`: 主要メソッドの75%カバレッジ
   - `OneTimePurchaseService`: 主要メソッドの75%カバレッジ

2. **ウィジェットテスト実装完了**
   - `MainScreen`: 基本的なレンダリング・操作のテスト

3. **CI/CD統合完了**
   - GitHub Actions でのテスト自動実行設定
   - Codemagic でのテスト統合

4. **ドキュメント整備完了**
   - テスト実装ガイドライン作成
   - テストコード規約策定

5. **全テスト成功**
   - `flutter test` ですべてのテストがパス

---

## 6. リスクと対策

| リスク | 影響度 | 発生確率 | 対策 |
|-------|-------|---------|-----|
| モック化が複雑でテスト実装が困難 | 高 | 中 | シンプルなテストから開始、段階的に複雑化 |
| Firebase依存のテストが不安定 | 中 | 高 | Firebaseエミュレーター使用、モック化徹底 |
| テスト実行時間が長すぎる | 中 | 低 | 並列実行、不要なセットアップ削減 |
| 既存コードのテスタビリティ不足 | 高 | 高 | 最小限のリファクタリング許可、別Issueで対応 |

---

## 7. スケジュール (目安)

| フェーズ | 作業内容 | 期間 |
|---------|---------|-----|
| Phase 1 | テスト環境構築、mockito生成設定 | 1日 |
| Phase 2 | DataProvider単体テスト実装 | 2-3日 |
| Phase 3 | ChatGptService単体テスト実装 | 2日 |
| Phase 4 | AuthService単体テスト実装 | 1-2日 |
| Phase 5 | OneTimePurchaseService単体テスト実装 | 1-2日 |
| Phase 6 | MainScreen ウィジェットテスト実装 | 1日 |
| Phase 7 | CI/CD統合、ドキュメント作成 | 1日 |

**合計見積もり**: 9-12日

---

## 8. 関連Issue

- Issue #3: DataProvider分割 (テスタビリティ向上)
- Issue #4: ChatGptService分割 (テスタビリティ向上)
- Issue #5: MainScreen分割 (テスタビリティ向上)
- Issue #7: 非同期エラーハンドリング改善 (テストケース参考)

---

## 9. 承認

- **レビュー担当**: プロジェクトオーナー
- **承認日**: TBD
- **承認者署名**: TBD
