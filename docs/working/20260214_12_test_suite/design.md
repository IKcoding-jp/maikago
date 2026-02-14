# 設計書: テストスイート整備

**Issue**: #12
**作成日**: 2026-02-14
**バージョン**: 1.0

---

## 1. テストアーキテクチャ

### 1.1 テストレイヤー構成

```
まいカゴ テストスイート
├── Unit Tests (単体テスト)
│   ├── Providers
│   │   └── DataProvider
│   ├── Services
│   │   ├── ChatGptService
│   │   ├── AuthService
│   │   └── OneTimePurchaseService
│   └── Models
│       └── ListItem, Shop, etc.
├── Widget Tests (ウィジェットテスト)
│   └── Screens
│       └── MainScreen
└── Integration Tests (統合テスト) ※将来実装
    ├── Firebase連携テスト
    └── 認証フローテスト
```

### 1.2 テストディレクトリ構造

```
test/
├── mocks.dart                      # mockito アノテーション定義
├── mocks.mocks.dart                # 自動生成されたモック
├── helpers/
│   ├── test_helpers.dart           # テストヘルパー関数
│   ├── mock_data.dart              # サンプルデータ生成
│   └── firebase_mock_helpers.dart  # Firebase モックヘルパー
├── providers/
│   └── data_provider_test.dart
├── services/
│   ├── chatgpt_service_test.dart
│   ├── auth_service_test.dart
│   └── one_time_purchase_service_test.dart
├── screens/
│   └── main_screen_test.dart
└── models/
    └── list_test.dart
```

---

## 2. モック戦略

### 2.1 mockito 使用方針

**基本ポリシー**:
- 外部依存 (Firebase, HTTP, InAppPurchase) はすべてモック化
- mockito の `@GenerateMocks` アノテーションで自動生成
- 手動モックは最小限に抑える

**モック対象クラス一覧**:

```dart
// test/mocks.dart
import 'package:mockito/annotations.dart';
import 'package:maikago/services/data_service.dart';
import 'package:maikago/providers/auth_provider.dart';
import 'package:maikago/services/chatgpt_service.dart';
import 'package:maikago/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

@GenerateMocks([
  // Services
  DataService,
  ChatGptService,
  AuthService,

  // Providers
  AuthProvider,

  // Firebase
  FirebaseAuth,
  FirebaseFirestore,
  DocumentReference,
  CollectionReference,
  Query,
  DocumentSnapshot,
  QuerySnapshot,

  // Google Sign-In
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,

  // In-App Purchase
  InAppPurchase,
  PurchaseDetails,
  ProductDetails,

  // Storage
  SharedPreferences,

  // HTTP
  http.Client,
])
void main() {}
```

**生成コマンド**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2.2 Firebase モック戦略

Firebase依存のテストは以下の2つのアプローチを併用します。

#### アプローチ1: モックオブジェクト使用

```dart
// DataProvider テストでの例
test('addItem should save to Firestore', () async {
  // Arrange
  final mockDataService = MockDataService();
  final dataProvider = DataProvider(dataService: mockDataService);
  final item = ListItem(
    id: '1',
    name: 'テスト商品',
    shopId: '0',
    price: 100,
    createdAt: DateTime.now(),
  );

  when(mockDataService.saveItem(any, isAnonymous: anyNamed('isAnonymous')))
      .thenAnswer((_) async => {});

  // Act
  await dataProvider.addItem(item);

  // Assert
  verify(mockDataService.saveItem(item, isAnonymous: false)).called(1);
  expect(dataProvider.items, contains(item));
});
```

#### アプローチ2: Firebaseエミュレーター使用 (統合テスト)

将来的な統合テストでは、Firebaseエミュレーターを使用します。

```bash
# Firebase Emulator起動
firebase emulators:start --only firestore,auth

# テスト実行
flutter test integration_test/
```

### 2.3 HTTP モック戦略

ChatGptService のテストでは、`http.Client` をモック化します。

```dart
// ChatGptService テストでの例
test('extractProductInfo should return product info on success', () async {
  // Arrange
  final mockClient = MockClient();
  final service = ChatGptService(apiKey: 'test-key');

  when(mockClient.post(
    any,
    headers: anyNamed('headers'),
    body: anyNamed('body'),
  )).thenAnswer((_) async => http.Response(
    jsonEncode({
      'choices': [
        {
          'message': {
            'content': jsonEncode({
              'name': 'テスト商品',
              'price': 100,
            })
          }
        }
      ]
    }),
    200,
  ));

  // Act
  final result = await service.extractProductInfo('OCRテキスト');

  // Assert
  expect(result, isNotNull);
  expect(result!.name, 'テスト商品');
  expect(result.price, 100);
});
```

---

## 3. DataProvider テスト設計

### 3.1 テスト対象メソッド

| メソッド | テストケース数 | 優先度 |
|---------|--------------|-------|
| `addItem()` | 7 | 高 |
| `updateItem()` | 5 | 高 |
| `deleteItem()` | 4 | 高 |
| `loadData()` | 5 | 高 |
| `setAuthProvider()` | 4 | 中 |
| `_ensureDefaultShop()` | 3 | 中 |

### 3.2 テストケース詳細

#### 3.2.1 addItem() テストケース

```dart
group('addItem', () {
  late DataProvider dataProvider;
  late MockDataService mockDataService;

  setUp(() {
    mockDataService = MockDataService();
    dataProvider = DataProvider(dataService: mockDataService);
  });

  test('should add item to local list immediately (optimistic update)', () async {
    // 楽観的更新の検証
    final item = ListItem(id: '', name: 'テスト', shopId: '0', price: 100, createdAt: DateTime.now());

    await dataProvider.addItem(item);

    expect(dataProvider.items.length, 1);
    expect(dataProvider.items.first.name, 'テスト');
  });

  test('should save item to Firebase in background', () async {
    // Firebase保存の検証
    final item = ListItem(id: '', name: 'テスト', shopId: '0', price: 100, createdAt: DateTime.now());

    when(mockDataService.saveItem(any, isAnonymous: anyNamed('isAnonymous')))
        .thenAnswer((_) async => {});

    await dataProvider.addItem(item);
    await Future.delayed(Duration(milliseconds: 100)); // バックグラウンド処理待機

    verify(mockDataService.saveItem(any, isAnonymous: false)).called(1);
  });

  test('should rollback on Firebase save error', () async {
    // エラー時のロールバック検証
    final item = ListItem(id: '', name: 'テスト', shopId: '0', price: 100, createdAt: DateTime.now());

    when(mockDataService.saveItem(any, isAnonymous: anyNamed('isAnonymous')))
        .thenThrow(Exception('Firebase error'));

    try {
      await dataProvider.addItem(item);
      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
      // エラー想定内
    }

    expect(dataProvider.items.length, 0); // ロールバック確認
  });

  test('should call updateItem if item with same id already exists', () async {
    // 重複チェックの検証
    final item = ListItem(id: '1', name: 'テスト', shopId: '0', price: 100, createdAt: DateTime.now());

    when(mockDataService.saveItem(any, isAnonymous: anyNamed('isAnonymous')))
        .thenAnswer((_) async => {});

    await dataProvider.addItem(item);
    await dataProvider.addItem(item.copyWith(name: '更新テスト'));

    expect(dataProvider.items.length, 1);
    expect(dataProvider.items.first.name, '更新テスト');
  });

  test('should not call Firebase in local mode', () async {
    // ローカルモードの検証
    dataProvider.setLocalMode(true);
    final item = ListItem(id: '', name: 'テスト', shopId: '0', price: 100, createdAt: DateTime.now());

    await dataProvider.addItem(item);

    verifyNever(mockDataService.saveItem(any, isAnonymous: anyNamed('isAnonymous')));
  });

  test('should call notifyListeners', () async {
    // UI通知の検証
    var notified = false;
    dataProvider.addListener(() {
      notified = true;
    });

    final item = ListItem(id: '', name: 'テスト', shopId: '0', price: 100, createdAt: DateTime.now());
    await dataProvider.addItem(item);

    expect(notified, true);
  });

  test('should add item to corresponding shop', () async {
    // ショップへの追加検証
    final shop = Shop(id: '0', name: 'デフォルト', items: [], createdAt: DateTime.now());
    dataProvider.shops.add(shop);

    final item = ListItem(id: '', name: 'テスト', shopId: '0', price: 100, createdAt: DateTime.now());

    when(mockDataService.saveItem(any, isAnonymous: anyNamed('isAnonymous')))
        .thenAnswer((_) async => {});

    await dataProvider.addItem(item);

    expect(dataProvider.shops.first.items.length, 1);
  });
});
```

#### 3.2.2 updateItem() テストケース

```dart
group('updateItem', () {
  // 省略 (同様のパターンで実装)

  test('should update item in local list immediately');
  test('should update item in Firebase');
  test('should add to pending updates for bounce prevention');
  test('should update item in corresponding shop');
  test('should call notifyListeners');
});
```

#### 3.2.3 loadData() テストケース

```dart
group('loadData', () {
  test('should load items and shops from Firebase on first load', () async {
    final mockItems = [
      ListItem(id: '1', name: 'テスト1', shopId: '0', price: 100, createdAt: DateTime.now()),
    ];
    final mockShops = [
      Shop(id: '0', name: 'デフォルト', items: [], createdAt: DateTime.now()),
    ];

    when(mockDataService.getItems(isAnonymous: anyNamed('isAnonymous')))
        .thenAnswer((_) async => mockItems);
    when(mockDataService.getShops(isAnonymous: anyNamed('isAnonymous')))
        .thenAnswer((_) async => mockShops);

    await dataProvider.loadData();

    expect(dataProvider.items, mockItems);
    expect(dataProvider.shops, mockShops);
  });

  test('should use cache on subsequent loads');
  test('should reload data when auth state changes');
  test('should not call Firebase in local mode');
  test('should handle timeout errors gracefully');
});
```

---

## 4. ChatGptService テスト設計

### 4.1 テスト対象メソッド

| メソッド | テストケース数 | 優先度 |
|---------|--------------|-------|
| `extractProductInfo()` | 7 | 高 |
| `extractProductInfoFromImage()` | 4 | 高 |
| `extractPriceCandidates()` | 4 | 中 |
| `extractNameAndPrice()` | 5 | 高 |

### 4.2 テストケース詳細

#### 4.2.1 extractProductInfo() テストケース

```dart
group('extractProductInfo', () {
  late ChatGptService service;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    service = ChatGptService(apiKey: 'test-api-key');
  });

  test('should return product info on successful API call', () async {
    // 成功ケース
    when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(
          jsonEncode({
            'choices': [
              {'message': {'content': jsonEncode({'name': 'テスト商品', 'price': 100})}}
            ]
          }),
          200,
        ));

    final result = await service.extractProductInfo('やわらかパイ 税込138円');

    expect(result, isNotNull);
    expect(result!.name, 'テスト商品');
    expect(result.price, 100);
  });

  test('should return null when API key is empty', () async {
    final serviceWithoutKey = ChatGptService(apiKey: '');
    final result = await serviceWithoutKey.extractProductInfo('テスト');
    expect(result, isNull);
  });

  test('should return null on HTTP 401 error', () async {
    when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response('Unauthorized', 401));

    final result = await service.extractProductInfo('テスト');
    expect(result, isNull);
  });

  test('should return null on HTTP 429 error (rate limit)', () async {
    when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response('Rate limit', 429));

    final result = await service.extractProductInfo('テスト');
    expect(result, isNull);
  });

  test('should return null on timeout', () async {
    when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenThrow(TimeoutException('Timeout'));

    final result = await service.extractProductInfo('テスト');
    expect(result, isNull);
  });

  test('should handle JSON parse error gracefully', () async {
    when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response('invalid json', 200));

    final result = await service.extractProductInfo('テスト');
    expect(result, isNull);
  });

  test('should handle empty response', () async {
    when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(
          jsonEncode({'choices': []}),
          200,
        ));

    final result = await service.extractProductInfo('テスト');
    expect(result, isNull);
  });
});
```

---

## 5. AuthService テスト設計

### 5.1 テスト対象メソッド

| メソッド | テストケース数 | 優先度 |
|---------|--------------|-------|
| `signInWithGoogle()` | 8 | 高 |
| `signOut()` | 2 | 高 |
| `authStateChanges` | 2 | 中 |
| `checkRedirectResult()` | 3 | 中 |

### 5.2 テストケース詳細

#### 5.2.1 signInWithGoogle() テストケース

```dart
group('signInWithGoogle', () {
  late AuthService service;
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockFirestore = MockFirebaseFirestore();
    service = AuthService(); // 依存性注入の実装が必要
  });

  test('should return success on successful sign-in (native)', () async {
    final mockGoogleUser = MockGoogleSignInAccount();
    final mockGoogleAuth = MockGoogleSignInAuthentication();
    final mockUserCredential = MockUserCredential();
    final mockUser = MockUser();

    when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
    when(mockGoogleUser.authentication).thenAnswer((_) async => mockGoogleAuth);
    when(mockGoogleAuth.idToken).thenReturn('test-id-token');
    when(mockAuth.signInWithCredential(any)).thenAnswer((_) async => mockUserCredential);
    when(mockUserCredential.user).thenReturn(mockUser);

    final result = await service.signInWithGoogle();

    expect(result, 'success');
  });

  test('should return sign_in_canceled when user cancels', () async {
    when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

    final result = await service.signInWithGoogle();

    expect(result, 'sign_in_canceled');
  });

  test('should handle ID token null error', () async {
    final mockGoogleUser = MockGoogleSignInAccount();
    final mockGoogleAuth = MockGoogleSignInAuthentication();

    when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
    when(mockGoogleUser.authentication).thenAnswer((_) async => mockGoogleAuth);
    when(mockGoogleAuth.idToken).thenReturn(null);

    expect(
      () => service.signInWithGoogle(),
      throwsException,
    );
  });

  // 他のテストケース省略
});
```

---

## 6. OneTimePurchaseService テスト設計

### 6.1 テスト対象メソッド

| メソッド | テストケース数 | 優先度 |
|---------|--------------|-------|
| `initialize()` | 5 | 高 |
| `isPremiumUnlocked` | 3 | 高 |
| 体験期間ロジック | 4 | 高 |
| `_generateDeviceFingerprint()` | 4 | 中 |

### 6.2 テストケース詳細

```dart
group('OneTimePurchaseService', () {
  late OneTimePurchaseService service;
  late MockInAppPurchase mockInAppPurchase;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockInAppPurchase = MockInAppPurchase();
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockPrefs = MockSharedPreferences();
    service = OneTimePurchaseService();
  });

  test('should initialize successfully', () async {
    when(mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);
    when(mockAuth.currentUser).thenReturn(null);
    when(mockPrefs.getString(any)).thenReturn(null);

    await service.initialize();

    expect(service.isInitialized, true);
  });

  test('should return premium unlocked when purchased', () async {
    // プレミアム購入済み状態のテスト
  });

  test('should return premium unlocked when trial is active', () async {
    // 体験期間中のテスト
  });

  // 他のテストケース省略
});
```

---

## 7. MainScreen ウィジェットテスト設計

### 7.1 テスト戦略

ウィジェットテストでは、以下の点を検証します。

1. **レンダリング検証**: ウィジェットが正しく表示される
2. **操作検証**: ユーザー操作が正しく動作する
3. **Provider連携検証**: Providerからのデータが正しく反映される

### 7.2 テストケース例

```dart
group('MainScreen Widget Tests', () {
  late MockDataProvider mockDataProvider;
  late MockAuthProvider mockAuthProvider;
  late MockOneTimePurchaseService mockPurchaseService;

  setUp(() {
    mockDataProvider = MockDataProvider();
    mockAuthProvider = MockAuthProvider();
    mockPurchaseService = MockOneTimePurchaseService();

    when(mockDataProvider.items).thenReturn([]);
    when(mockDataProvider.shops).thenReturn([
      Shop(id: '0', name: 'デフォルト', items: [], createdAt: DateTime.now()),
    ]);
    when(mockAuthProvider.isLoggedIn).thenReturn(false);
    when(mockPurchaseService.isPremiumUnlocked).thenReturn(false);
  });

  testWidgets('should render MainScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DataProvider>.value(value: mockDataProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<OneTimePurchaseService>.value(value: mockPurchaseService),
        ],
        child: MaterialApp(home: MainScreen()),
      ),
    );

    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('should switch tabs when tapped', (WidgetTester tester) async {
    // タブ切り替えテスト
  });

  // 他のテストケース省略
});
```

---

## 8. テストヘルパー設計

### 8.1 test_helpers.dart

```dart
import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';

/// サンプルアイテム生成
ListItem createSampleItem({
  String? id,
  String? name,
  String? shopId,
  int? price,
}) {
  return ListItem(
    id: id ?? '1',
    name: name ?? 'サンプル商品',
    shopId: shopId ?? '0',
    price: price ?? 100,
    createdAt: DateTime.now(),
  );
}

/// サンプルショップ生成
Shop createSampleShop({
  String? id,
  String? name,
  List<ListItem>? items,
}) {
  return Shop(
    id: id ?? '0',
    name: name ?? 'デフォルト',
    items: items ?? [],
    createdAt: DateTime.now(),
  );
}

/// 複数アイテム生成
List<ListItem> createSampleItems(int count) {
  return List.generate(
    count,
    (index) => createSampleItem(
      id: index.toString(),
      name: 'サンプル商品$index',
      price: (index + 1) * 100,
    ),
  );
}
```

### 8.2 firebase_mock_helpers.dart

```dart
import 'package:mockito/mockito.dart';
import '../mocks.mocks.dart';

/// Firestore モック設定ヘルパー
void setupFirestoreMock(MockFirebaseFirestore mockFirestore) {
  final mockCollection = MockCollectionReference();
  final mockDoc = MockDocumentReference();

  when(mockFirestore.collection(any)).thenReturn(mockCollection);
  when(mockCollection.doc(any)).thenReturn(mockDoc);
}

/// Auth モック設定ヘルパー
void setupAuthMock(MockFirebaseAuth mockAuth, {bool isLoggedIn = false}) {
  if (isLoggedIn) {
    final mockUser = MockUser();
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-user-id');
  } else {
    when(mockAuth.currentUser).thenReturn(null);
  }
}
```

---

## 9. CI/CD統合設計

### 9.1 GitHub Actions設定

`.github/workflows/test.yml`:

```yaml
name: Flutter Tests

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Generate mocks
        run: flutter pub run build_runner build --delete-conflicting-outputs

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          fail_ci_if_error: false

      - name: Check test results
        run: |
          if [ $? -ne 0 ]; then
            echo "Tests failed!"
            exit 1
          fi
```

### 9.2 Codemagic統合

`codemagic.yaml` への追加:

```yaml
workflows:
  ios-workflow:
    # ... 既存設定 ...
    scripts:
      - name: Generate mocks
        script: flutter pub run build_runner build --delete-conflicting-outputs
      - name: Run tests
        script: flutter test
        test_report: test/*.xml
```

---

## 10. カバレッジ測定

### 10.1 カバレッジ取得コマンド

```bash
# カバレッジ付きでテスト実行
flutter test --coverage

# LCOVレポート生成
genhtml coverage/lcov.info -o coverage/html

# ブラウザで確認
open coverage/html/index.html
```

### 10.2 カバレッジ目標

| ファイル | 目標カバレッジ |
|---------|--------------|
| `data_provider.dart` | 80% |
| `chatgpt_service.dart` | 70% |
| `auth_service.dart` | 75% |
| `one_time_purchase_service.dart` | 75% |
| **全体** | **60%** |

---

## 11. テストコード規約

### 11.1 命名規則

- テストグループ: `group('メソッド名', () { ... })`
- テストケース: `test('should [期待される動作] when [条件]', () { ... })`
- モック変数: `mock[クラス名]` (例: `mockDataService`)

### 11.2 テスト構造

AAA (Arrange-Act-Assert) パターンを使用:

```dart
test('should add item successfully', () async {
  // Arrange (準備)
  final mockDataService = MockDataService();
  final dataProvider = DataProvider(dataService: mockDataService);
  final item = createSampleItem();

  when(mockDataService.saveItem(any, isAnonymous: anyNamed('isAnonymous')))
      .thenAnswer((_) async => {});

  // Act (実行)
  await dataProvider.addItem(item);

  // Assert (検証)
  expect(dataProvider.items, contains(item));
  verify(mockDataService.saveItem(item, isAnonymous: false)).called(1);
});
```

### 11.3 非同期テストのベストプラクティス

```dart
test('should handle async operations correctly', () async {
  // 非同期処理は必ず await
  await dataProvider.loadData();

  // バックグラウンド処理の完了を待つ
  await Future.delayed(Duration(milliseconds: 100));

  // 検証
  expect(dataProvider.isLoading, false);
});
```

---

## 12. トラブルシューティング

### 12.1 よくある問題と解決策

| 問題 | 原因 | 解決策 |
|-----|------|-------|
| モックが生成されない | `build_runner` 未実行 | `flutter pub run build_runner build` を実行 |
| テストがタイムアウトする | 非同期処理の待機不足 | `await` や `Future.delayed()` で待機 |
| Firebaseエラーが発生する | Firebase未初期化 | モックを使用するか、`Firebase.initializeApp()` を呼び出す |
| カバレッジが低い | テストケース不足 | 優先度の高いメソッドから順にテスト追加 |

---

## 13. 今後の拡張

- **E2Eテスト**: `integration_test` パッケージで実装
- **パフォーマンステスト**: ベンチマークテスト追加
- **ビジュアルリグレッションテスト**: Golden Testsの導入検討

---

## 14. 参考資料

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [mockito Package Documentation](https://pub.dev/packages/mockito)
- [Firebase Test Lab](https://firebase.google.com/docs/test-lab)
