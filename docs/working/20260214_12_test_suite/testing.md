# テスト仕様書: テストスイート整備

**Issue**: #12
**作成日**: 2026-02-14
**バージョン**: 1.0

---

## 1. テスト戦略

### 1.1 テストピラミッド

```
        /\
       /E2E\         統合テスト (将来実装)
      /------\       - 5%: ユーザーシナリオテスト
     /Widget \       ウィジェットテスト
    /----------\     - 15%: UI動作テスト
   /    Unit    \    単体テスト
  /--------------\   - 80%: ロジック・サービステスト
```

### 1.2 テストスコープ

| レイヤー | テスト対象 | テスト範囲 |
|---------|-----------|-----------|
| **単体テスト** | Providers, Services, Models | メソッド単位のロジック検証 |
| **ウィジェットテスト** | Screens, Widgets | UI表示・操作の検証 |
| **統合テスト** | Firebase連携, 認証フロー | エンドツーエンドの検証 (将来) |

---

## 2. DataProvider テスト仕様

### 2.1 テストファイル情報

- **ファイルパス**: `test/providers/data_provider_test.dart`
- **テスト対象**: `lib/providers/data_provider.dart`
- **依存モック**: `MockDataService`, `MockAuthProvider`, `MockSettingsPersistence`

### 2.2 テストケース一覧

#### 2.2.1 addItem() テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | アイテム追加成功 (楽観的更新) | アイテムがローカルリストに即座に追加される | 高 |
| 2 | アイテムのFirebase保存成功 | `DataService.saveItem()` が呼び出される | 高 |
| 3 | 重複アイテム追加時のupdateItem呼び出し | 既存アイテムが更新される | 高 |
| 4 | Firebase保存失敗時のロールバック | アイテムがローカルリストから削除される | 高 |
| 5 | ローカルモード時のFirebase非呼び出し | `DataService.saveItem()` が呼び出されない | 中 |
| 6 | notifyListeners() 呼び出し | UIリスナーが通知される | 中 |
| 7 | ショップへのアイテム追加 | 対応するショップのitemsリストに追加される | 中 |

**テストコード例**:

```dart
group('addItem', () {
  late DataProvider dataProvider;
  late MockDataService mockDataService;

  setUp(() {
    mockDataService = MockDataService();
    dataProvider = DataProvider(dataService: mockDataService);
  });

  test('should add item to local list immediately (optimistic update)', () async {
    // Arrange
    final item = ListItem(
      id: '',
      name: 'テスト商品',
      shopId: '0',
      price: 100,
      createdAt: DateTime.now(),
    );

    // Act
    await dataProvider.addItem(item);

    // Assert
    expect(dataProvider.items.length, 1);
    expect(dataProvider.items.first.name, 'テスト商品');
    expect(dataProvider.items.first.price, 100);
  });

  test('should save item to Firebase in background', () async {
    // Arrange
    final item = ListItem(
      id: '',
      name: 'テスト商品',
      shopId: '0',
      price: 100,
      createdAt: DateTime.now(),
    );

    when(mockDataService.saveItem(any, isAnonymous: anyNamed('isAnonymous')))
        .thenAnswer((_) async => {});

    // Act
    await dataProvider.addItem(item);
    await Future.delayed(Duration(milliseconds: 100)); // バックグラウンド処理待機

    // Assert
    verify(mockDataService.saveItem(any, isAnonymous: false)).called(1);
    expect(dataProvider.isSynced, true);
  });

  test('should rollback on Firebase save error', () async {
    // Arrange
    final item = ListItem(
      id: '',
      name: 'テスト商品',
      shopId: '0',
      price: 100,
      createdAt: DateTime.now(),
    );

    when(mockDataService.saveItem(any, isAnonymous: anyNamed('isAnonymous')))
        .thenThrow(Exception('Firebase error'));

    // Act & Assert
    try {
      await dataProvider.addItem(item);
      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
      // エラー想定内
    }

    expect(dataProvider.items.length, 0); // ロールバック確認
    expect(dataProvider.isSynced, false);
  });
});
```

#### 2.2.2 updateItem() テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | アイテム更新成功 (楽観的更新) | アイテムがローカルリストで即座に更新される | 高 |
| 2 | アイテムのFirebase更新成功 | `DataService.updateItem()` が呼び出される | 高 |
| 3 | バウンス抑止 (_pendingItemUpdates) | 更新IDがpendingMapに追加される | 中 |
| 4 | ショップ内アイテムの同期更新 | ショップのitemsリストも更新される | 中 |
| 5 | notifyListeners() 呼び出し | UIリスナーが通知される | 中 |

#### 2.2.3 deleteItem() テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | アイテム削除成功 | アイテムがローカルリストから削除される | 高 |
| 2 | アイテムのFirebase削除成功 | `DataService.deleteItem()` が呼び出される | 高 |
| 3 | ショップ内アイテムの同期削除 | ショップのitemsリストからも削除される | 中 |
| 4 | notifyListeners() 呼び出し | UIリスナーが通知される | 中 |

#### 2.2.4 loadData() テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | 初回データロード成功 | Firebaseからアイテムとショップがロードされる | 高 |
| 2 | キャッシュからのロード | `_isDataLoaded` フラグが true の場合、Firebase呼び出しをスキップ | 中 |
| 3 | 認証状態変更時の再ロード | ログイン/ログアウト時にデータが再ロードされる | 高 |
| 4 | ローカルモード時のFirebase非呼び出し | `_isLocalMode` が true の場合、Firebase呼び出しをスキップ | 中 |
| 5 | タイムアウトエラーハンドリング | タイムアウト時にエラーメッセージを表示 | 低 |

#### 2.2.5 認証連携テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | setAuthProvider() 正常動作 | AuthProviderが設定され、リスナーが登録される | 中 |
| 2 | 認証状態変更リスナーの動作 | ログイン/ログアウト時にコールバックが呼ばれる | 中 |
| 3 | ログイン時のデータリセット | `_resetDataForLogin()` が呼び出される | 中 |
| 4 | ログアウト時のデータクリア | `clearData()` が呼び出される | 中 |

---

## 3. ChatGptService テスト仕様

### 3.1 テストファイル情報

- **ファイルパス**: `test/services/chatgpt_service_test.dart`
- **テスト対象**: `lib/services/chatgpt_service.dart`
- **依存モック**: `MockClient` (http)

### 3.2 テストケース一覧

#### 3.2.1 extractProductInfo() テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | OCRテキストから商品情報抽出成功 | `OcrItemResult` が返される | 高 |
| 2 | APIキー未設定時のnull返却 | `null` が返される | 高 |
| 3 | HTTP 401エラー (認証失敗) | `null` が返される | 中 |
| 4 | HTTP 429エラー (レート制限) | `null` が返される | 中 |
| 5 | タイムアウトエラー | `null` が返される | 中 |
| 6 | JSONパースエラー | `null` が返される | 低 |
| 7 | 空レスポンス | `null` が返される | 低 |

**テストコード例**:

```dart
group('extractProductInfo', () {
  late ChatGptService service;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    service = ChatGptService(apiKey: 'test-api-key');
  });

  test('should return product info on successful API call', () async {
    // Arrange
    final mockResponse = jsonEncode({
      'choices': [
        {
          'message': {
            'content': jsonEncode({
              'name': 'やわらかパイ',
              'price': 138,
            })
          }
        }
      ]
    });

    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(mockResponse, 200));

    // Act
    final result = await service.extractProductInfo('やわらかパイ 税込138円');

    // Assert
    expect(result, isNotNull);
    expect(result!.name, 'やわらかパイ');
    expect(result.price, 138);
  });

  test('should return null when API key is empty', () async {
    // Arrange
    final serviceWithoutKey = ChatGptService(apiKey: '');

    // Act
    final result = await serviceWithoutKey.extractProductInfo('テスト');

    // Assert
    expect(result, isNull);
  });

  test('should return null on HTTP 401 error', () async {
    // Arrange
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response('Unauthorized', 401));

    // Act
    final result = await service.extractProductInfo('テスト');

    // Assert
    expect(result, isNull);
  });
});
```

#### 3.2.2 extractProductInfoFromImage() テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | 画像から商品情報抽出成功 | `OcrItemResult` が返される | 高 |
| 2 | Base64エンコード処理 | 画像が正しくBase64エンコードされる | 中 |
| 3 | APIエラーハンドリング | エラー時に `null` が返される | 中 |
| 4 | Vision APIレスポンスパース | JSONが正しくパースされる | 低 |

#### 3.2.3 extractPriceCandidates() テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | 価格候補一覧抽出成功 | 複数の価格候補が返される | 高 |
| 2 | 税込/税抜/税率の正しい抽出 | 各フィールドが正しく抽出される | 高 |
| 3 | リトライ処理の検証 | 最大3回リトライされる | 中 |
| 4 | リトライ後も失敗時の空配列返却 | 空配列が返される | 低 |

#### 3.2.4 extractNameAndPrice() テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | 商品名と価格抽出成功 | `ChatGptItemResult` が返される | 高 |
| 2 | 小数点誤認識修正 | 27864円 → 278円 に修正される | 高 |
| 3 | 税込/税抜判定ロジック | 正しく税込/税抜が判定される | 高 |
| 4 | 複数価格候補からの最高価格選択 | 最も高い価格が選択される | 中 |
| 5 | confidence スコア計算 | 信頼度スコアが0.0-1.0の範囲 | 低 |

---

## 4. AuthService テスト仕様

### 4.1 テストファイル情報

- **ファイルパス**: `test/services/auth_service_test.dart`
- **テスト対象**: `lib/services/auth_service.dart`
- **依存モック**: `MockFirebaseAuth`, `MockGoogleSignIn`, `MockFirebaseFirestore`

### 4.2 テストケース一覧

#### 4.2.1 signInWithGoogle() テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | サインイン成功 (ネイティブ) | 'success' が返される | 高 |
| 2 | サインイン成功 (Webポップアップ) | 'success' が返される | 高 |
| 3 | サインイン成功 (Webリダイレクト) | 'redirect' が返される | 中 |
| 4 | サインインキャンセル | 'sign_in_canceled' が返される | 中 |
| 5 | ID Token取得失敗 | 例外がスローされる | 中 |
| 6 | Firebase認証失敗 | エラーコードが返される | 中 |
| 7 | PlatformException各種エラーコード | 対応するエラーコードが返される | 低 |
| 8 | ユーザープロフィール保存 | `_saveUserProfile()` が呼び出される | 低 |

**テストコード例**:

```dart
group('signInWithGoogle', () {
  late AuthService service;
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    service = AuthService(); // 依存性注入の実装が必要
  });

  test('should return success on successful sign-in (native)', () async {
    // Arrange
    final mockGoogleUser = MockGoogleSignInAccount();
    final mockGoogleAuth = MockGoogleSignInAuthentication();
    final mockUserCredential = MockUserCredential();

    when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
    when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
    when(mockGoogleUser.authentication).thenAnswer((_) async => mockGoogleAuth);
    when(mockGoogleAuth.idToken).thenReturn('test-id-token');
    when(mockAuth.signInWithCredential(any)).thenAnswer((_) async => mockUserCredential);

    // Act
    final result = await service.signInWithGoogle();

    // Assert
    expect(result, 'success');
  });

  test('should return sign_in_canceled when user cancels', () async {
    // Arrange
    when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
    when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

    // Act
    final result = await service.signInWithGoogle();

    // Assert
    expect(result, 'sign_in_canceled');
  });
});
```

#### 4.2.2 signOut() テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | サインアウト成功 | Firebase/GoogleSignIn両方からサインアウト | 高 |
| 2 | サインアウト失敗時のエラーハンドリング | エラーがログ出力される | 低 |

#### 4.2.3 認証状態監視テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | authStateChanges ストリームの動作 | ユーザー状態変更が通知される | 中 |
| 2 | currentUser 取得 | 現在のユーザーが返される | 中 |
| 3 | Firebase未初期化時のエラーハンドリング | null が返される | 低 |

---

## 5. OneTimePurchaseService テスト仕様

### 5.1 テストファイル情報

- **ファイルパス**: `test/services/one_time_purchase_service_test.dart`
- **テスト対象**: `lib/services/one_time_purchase_service.dart`
- **依存モック**: `MockInAppPurchase`, `MockFirebaseAuth`, `MockFirebaseFirestore`, `MockSharedPreferences`

### 5.2 テストケース一覧

#### 5.2.1 initialize() テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | 初回初期化成功 | `isInitialized` が true になる | 高 |
| 2 | 複数回初期化時のスキップ | 2回目以降はスキップされる | 中 |
| 3 | ユーザーID変更時の再ロード | Firestoreから状態が再ロードされる | 高 |
| 4 | デバイスフィンガープリント生成 | フィンガープリントが生成される | 中 |
| 5 | Firebase未初期化時のエラーハンドリング | エラーがログ出力される | 低 |

#### 5.2.2 プレミアム状態取得テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | isPremiumUnlocked (購入済み) | true が返される | 高 |
| 2 | isPremiumUnlocked (体験期間中) | true が返される | 高 |
| 3 | isPremiumUnlocked (未購入) | false が返される | 高 |
| 4 | isPremiumPurchased getter | 実際の購入状態が返される | 中 |

#### 5.2.3 体験期間ロジックテスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | 体験期間開始処理 | `_isTrialActive` が true になる | 高 |
| 2 | 体験期間終了判定 | 終了時刻を過ぎると false になる | 高 |
| 3 | trialRemainingDuration 計算 | 正しい残り時間が返される | 中 |
| 4 | 体験期間タイマーの動作 | タイマーが正しく動作する | 中 |

---

## 6. MainScreen ウィジェットテスト仕様

### 6.1 テストファイル情報

- **ファイルパス**: `test/screens/main_screen_test.dart`
- **テスト対象**: `lib/screens/main_screen.dart`
- **依存モック**: `MockDataProvider`, `MockAuthProvider`, `MockOneTimePurchaseService`

### 6.2 テストケース一覧

#### 6.2.1 基本レンダリングテスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | MainScreen ウィジェット表示 | ウィジェットが正しくレンダリングされる | 中 |
| 2 | AppBar レンダリング | AppBarが表示される | 中 |
| 3 | TabBar レンダリング | TabBarが表示される | 中 |
| 4 | FloatingActionButton レンダリング | FABが表示される | 低 |

#### 6.2.2 タブ操作テスト

| # | テストケース名 | 期待結果 | 優先度 |
|---|---------------|---------|-------|
| 1 | タブ切り替え動作 | タブをタップすると内容が切り替わる | 中 |
| 2 | タブ追加ボタンタップ | ダイアログが表示される | 低 |
| 3 | タブ編集ダイアログ表示 | 編集ダイアログが表示される | 低 |

---

## 7. テスト実行手順

### 7.1 ローカルでのテスト実行

```bash
# 1. モック生成
flutter pub run build_runner build --delete-conflicting-outputs

# 2. 全テスト実行
flutter test

# 3. カバレッジ付きテスト実行
flutter test --coverage

# 4. 特定ファイルのテスト実行
flutter test test/providers/data_provider_test.dart

# 5. 特定テストケースのみ実行
flutter test test/providers/data_provider_test.dart --name "addItem"
```

### 7.2 CI/CDでのテスト実行

#### GitHub Actions

```bash
# .github/workflows/test.yml で自動実行
# PRマージ前に自動でテストが実行される
```

#### Codemagic

```bash
# codemagic.yaml で自動実行
# ビルド前に自動でテストが実行される
```

---

## 8. テスト結果の判定基準

### 8.1 成功基準

- ✅ すべてのテストケースがパス
- ✅ カバレッジ目標達成 (全体60%以上)
- ✅ テスト実行時間が制限内 (単体テスト5秒以内)

### 8.2 失敗時の対応

| 失敗理由 | 対応 |
|---------|-----|
| テストケース失敗 | コード修正またはテストケース修正 |
| カバレッジ不足 | テストケース追加 |
| テストタイムアウト | 非同期処理の最適化、モック化の改善 |

---

## 9. テストデータ

### 9.1 サンプルデータ

#### ListItem サンプル

```dart
final sampleItem = ListItem(
  id: '1',
  name: 'やわらかパイ',
  shopId: '0',
  price: 138,
  isCompleted: false,
  createdAt: DateTime(2026, 2, 14, 12, 0, 0),
  updatedAt: DateTime(2026, 2, 14, 12, 0, 0),
);
```

#### Shop サンプル

```dart
final sampleShop = Shop(
  id: '0',
  name: 'デフォルト',
  items: [],
  createdAt: DateTime(2026, 2, 14, 12, 0, 0),
  budget: 5000,
);
```

#### OCRテキスト サンプル

```dart
final sampleOcrText = '''
やわらかパイ
税込138円
税抜128円
''';
```

### 9.2 エッジケースデータ

```dart
// 空文字列
final emptyString = '';

// 異常に長いテキスト
final longText = 'a' * 10000;

// 特殊文字
final specialChars = '!@#\$%^&*()_+-=[]{}|;:\'",.<>?/~`';

// null値 (Dart 3.0以降はnull safetyで基本的に不要)
```

---

## 10. テストカバレッジレポート

### 10.1 カバレッジ確認方法

```bash
# カバレッジ取得
flutter test --coverage

# HTMLレポート生成
genhtml coverage/lcov.info -o coverage/html

# ブラウザで確認
open coverage/html/index.html
```

### 10.2 カバレッジ目標

| コンポーネント | 目標 | 現在 | ステータス |
|--------------|------|------|-----------|
| DataProvider | 80% | 0% | ❌ 未達成 |
| ChatGptService | 70% | 0% | ❌ 未達成 |
| AuthService | 75% | 0% | ❌ 未達成 |
| OneTimePurchaseService | 75% | 0% | ❌ 未達成 |
| **全体** | **60%** | **0%** | **❌ 未達成** |

---

## 11. テスト環境

### 11.1 ローカル環境

- **Flutter SDK**: >=3.0.0 <4.0.0
- **Dart SDK**: >=3.0.0 <4.0.0
- **OS**: Windows 11, macOS, Linux

### 11.2 CI/CD環境

- **GitHub Actions**: ubuntu-latest, Flutter 3.19.0
- **Codemagic**: Xcode 15.0, Flutter 3.19.0

---

## 12. トラブルシューティング

### 12.1 よくあるエラーと解決策

#### エラー1: モッククラスが見つからない

```
Error: 'MockDataService' isn't a type.
```

**解決策**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### エラー2: テストがタイムアウトする

```
Test timed out after 30 seconds.
```

**解決策**:
```dart
// 非同期処理を適切にawaitする
await dataProvider.loadData();
await Future.delayed(Duration(milliseconds: 100));
```

#### エラー3: Firebaseが初期化されていない

```
Error: [core/no-app] No Firebase App '[DEFAULT]' has been created
```

**解決策**:
```dart
// モックを使用する
final mockFirestore = MockFirebaseFirestore();
when(mockFirestore.collection(any)).thenReturn(mockCollection);
```

---

## 13. テストレビューチェックリスト

### 13.1 コードレビュー時の確認項目

- [ ] すべてのテストケースがパスしている
- [ ] AAA (Arrange-Act-Assert) パターンが守られている
- [ ] テストケース名が明確 (should [期待される動作] when [条件])
- [ ] モックの使用が適切 (外部依存はすべてモック化)
- [ ] 非同期処理が適切にawaitされている
- [ ] テスト実行時間が制限内 (5秒以内)
- [ ] カバレッジ目標が達成されている
- [ ] エッジケースがカバーされている
- [ ] テストコードに重複がない (ヘルパー関数活用)

### 13.2 テストコード品質チェック

- [ ] テストコードの可読性が高い
- [ ] テストケースが独立している (他のテストに依存しない)
- [ ] セットアップとクリーンアップが適切
- [ ] エラーメッセージが分かりやすい
- [ ] 不要なコメントがない (コードで説明)

---

## 14. 今後の改善計画

### Phase 1 (Issue #12 完了後)
- [ ] カバレッジ60%達成確認
- [ ] CI/CD統合完了
- [ ] テストドキュメント整備

### Phase 2 (将来)
- [ ] 統合テスト実装 (Firebaseエミュレーター使用)
- [ ] E2Eテスト実装 (`integration_test` パッケージ)
- [ ] パフォーマンステスト追加
- [ ] ビジュアルリグレッションテスト (Golden Tests)

### Phase 3 (将来)
- [ ] テストカバレッジ80%達成
- [ ] テスト自動生成ツール導入検討
- [ ] テストデータ管理の最適化

---

## 15. 参考資料

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [mockito Package](https://pub.dev/packages/mockito)
- [build_runner Package](https://pub.dev/packages/build_runner)
- [test Package](https://pub.dev/packages/test)
- [AAA Pattern](https://automationpanda.com/2020/07/07/arrange-act-assert-a-pattern-for-writing-good-tests/)

---

## 16. 承認

- **テスト仕様書作成者**: Claude Code
- **レビュー担当**: プロジェクトオーナー
- **承認日**: TBD
- **承認者署名**: TBD
