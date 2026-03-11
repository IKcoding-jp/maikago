# よくあるエラーパターンと解決方法

まいカゴ（Flutter）で頻繁に遭遇するエラーパターンと、その原因・解決方法・予防策をまとめています。

## 目次

1. [Firestore権限エラー](#1-firestore権限エラー)
2. [Provider未検出エラー](#2-provider未検出エラー)
3. [BuildContext非同期使用エラー](#3-buildcontext非同期使用エラー)
4. [プラットフォーム分岐エラー](#4-プラットフォーム分岐エラー)
5. [Widget State管理エラー](#5-widget-state管理エラー)

---

## 1. Firestore権限エラー

### エラーメッセージ

```
FirebaseException: [cloud_firestore/permission-denied] Missing or insufficient permissions.
```

### 原因

- Firestoreセキュリティルールが適切に設定されていない
- 認証トークンが期限切れ
- クライアント側の `uid` とルールの `request.auth.uid` が不一致

### 解決方法

#### ステップ1: セキュリティルールを確認

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### ステップ2: 認証状態を確認

```dart
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  // ログイン画面へ遷移
  return;
}
// 認証済みの場合のみFirestore操作を実行
```

### 予防策

1. **セキュリティルールを必ず設定**: デフォルトは `allow read, write: if false;`
2. **認証状態をチェック**: Firestore操作前に必ず `currentUser` の存在を確認
3. **最小権限の原則**: 必要最小限の権限のみを許可

---

## 2. Provider未検出エラー

### エラーメッセージ

```
ProviderNotFoundException: Error: Could not find the correct Provider<DataProvider> above this Widget.
```

### 原因

- `MultiProvider` の設定でProviderが登録されていない
- Widgetツリーの上位にProviderが配置されていない
- `context` のスコープ外でProviderを参照

### 解決方法

```dart
// main.dart で MultiProvider に正しく登録されているか確認
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProxyProvider<AuthProvider, DataProvider>(
      create: (_) => DataProvider(),
      update: (_, auth, data) => data!..updateAuth(auth),
    ),
  ],
  child: MyApp(),
)
```

### 予防策

1. **MultiProviderに全Providerを登録**: `main.dart`の設定を確認
2. **Providerの依存関係順序**: 依存先を先に登録
3. **contextのスコープ確認**: `Builder` でcontextを分離

---

## 3. BuildContext非同期使用エラー

### エラーメッセージ

```
Warning: Do not use BuildContexts across async gaps.
```

### 原因

- `async`メソッド内で`await`の後に`context`を使用
- `analysis_options.yaml`で`use_build_context_synchronously`はignore設定だが注意が必要

### 解決方法

```dart
// NG
Future<void> _submit() async {
  await someAsyncOperation();
  Navigator.of(context).pop(); // contextが無効な可能性
}

// OK: mountedチェック
Future<void> _submit() async {
  await someAsyncOperation();
  if (!mounted) return;
  Navigator.of(context).pop();
}
```

### 予防策

1. **mounted チェック**: async操作後は必ず `mounted` を確認
2. **コールバック前にcontextを保存**: NavigatorState等を事前に取得

---

## 4. プラットフォーム分岐エラー

### エラーメッセージ

```
Unsupported operation: Platform._operatingSystem
```

### 原因

- Web環境で `dart:io` の `Platform` クラスを使用
- `kIsWeb` での分岐が不足

### 解決方法

```dart
// NG
import 'dart:io';
if (Platform.isAndroid) { ... }

// OK: Web対応
import 'package:flutter/foundation.dart' show kIsWeb;
if (kIsWeb) {
  // Web用処理
} else if (Platform.isAndroid) {
  // Android用処理
}
```

### 予防策

1. **kIsWeb を先にチェック**: Web判定を最初に行う
2. **条件付きimport**: `dart:io` は条件付きでimport

---

## 5. Widget State管理エラー

### エラーメッセージ

```
setState() called after dispose()
```

### 原因

- Widgetが破棄された後に `setState()` が呼ばれている
- 非同期処理完了時にWidgetが既に破棄されている

### 解決方法

```dart
// NG
Future<void> _loadData() async {
  final data = await fetchData();
  setState(() {
    _data = data; // Widgetが破棄済みの可能性
  });
}

// OK: mountedチェック
Future<void> _loadData() async {
  final data = await fetchData();
  if (!mounted) return;
  setState(() {
    _data = data;
  });
}
```

### 予防策

1. **mounted チェック**: 非同期処理後は必ず確認
2. **StreamSubscriptionのキャンセル**: `dispose()`でキャンセル
3. **CancelableOperation**: 必要に応じて非同期処理をキャンセル可能にする

---

## エラー対応のベストプラクティス

### 1. エラーメッセージを正確に読む

- エラーメッセージの最初の1行に原因が書かれていることが多い
- スタックトレースから発生箇所を特定

### 2. flutter analyzeを活用

- `flutter analyze` で静的解析エラーを事前検出
- Lintルールに従ってコードを修正

### 3. 段階的にデバッグ

- `debugPrint()` でログ挿入
- Flutter DevToolsでWidgetツリーを確認
- 問題箇所を特定してから修正

### 4. 修正後にテスト

- 同じエラーが再発しないか確認
- 関連機能に影響がないか確認
