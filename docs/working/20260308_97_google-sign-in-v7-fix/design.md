# 設計書

## 実装方針

### google_sign_in v7 API の正しい使用パターン

v7公式では以下の2つのアプローチが存在:

#### A. ストリームベース（推奨）
```dart
final signIn = GoogleSignIn.instance;
signIn.initialize(clientId: clientId, serverClientId: serverClientId);
signIn.authenticationEvents.listen((event) {
  switch (event) {
    case GoogleSignInAuthenticationEventSignIn():
      // event.user でユーザー情報取得
    case GoogleSignInAuthenticationEventSignOut():
      // サインアウト処理
  }
});
signIn.attemptLightweightAuthentication(); // 自動サインイン試行
```

#### B. authenticate() 直接呼び出し
```dart
final signIn = GoogleSignIn.instance;
await signIn.initialize(clientId: clientId, serverClientId: serverClientId);
final GoogleSignInAccount user = await signIn.authenticate();
```

### 現在のコードの問題点

1. **`initialize()` パラメータ不足**: `clientId` 未指定
2. **`authenticate()` の動作**: v7で戻り値・例外の仕様が変わった可能性
3. **`googleUser.authentication`（sync）**: v7でのidToken取得方法が異なる可能性
4. **google_sign_in_web retracted**: Web依存パッケージが撤回済み

### 変更対象ファイル
- `lib/services/auth_service.dart` - signInWithGoogle() / _ensureGoogleSignInInitialized() / signOut() を v7 正式APIに修正
- `pubspec.yaml` - 必要に応じてバージョン制約調整
- `pubspec.lock` - google_sign_in_web 更新

### 修正方針

**最小限の修正で動作復旧を優先**:
1. v7 APIのauthenticate()が使える場合はそのまま活用（ストリームベースへの全面書き換えは避ける）
2. `initialize()` パラメータの修正
3. idToken取得方法の修正
4. retracted パッケージの更新

## 影響範囲
- `AuthService` → `AuthProvider` → `LoginScreen` / `AccountScreen`
- ログイン/ログアウトフロー全体
- Firebase Firestore/Functions へのアクセス（認証トークン依存）

## Flutter固有の注意点
- Web版は `kIsWeb` 分岐で Firebase Auth 直接使用（google_sign_in不使用）
- Android: google-services.json から clientId 自動取得
- iOS: GoogleService-Info.plist から設定取得
- `data_provider.dart` への直接的な影響はなし（認証後のデータロードは既存のまま）
