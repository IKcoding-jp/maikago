# 設計書: #36 build()内副作用除去 + #37 エラーハンドリング統一

## 修正対象ファイル

### Issue #36

| ファイル | 修正内容 |
|---------|---------|
| `lib/screens/main_screen.dart` | getCustomTheme()キャッシュ化、TabController移動、updateThemeAndFontIfNeeded移動 |
| `lib/widgets/list_edit.dart` | SharedPreferences個別読み込み廃止 → パラメータ受け取りに変更 |
| `lib/ad/ad_banner.dart` | busy-wait → Completerパターンに変更 |
| `lib/services/one_time_purchase_service.dart` | Completer追加（初期化完了通知用） |

### Issue #37

| ファイル | 修正内容 |
|---------|---------|
| `lib/utils/exceptions.dart` | **新規作成** カスタム例外クラス定義 |
| `lib/providers/repositories/item_repository.dart` | 文字列ベースエラー判定 → カスタム例外変換 |
| `lib/providers/repositories/shop_repository.dart` | 文字列ベースエラー判定 → カスタム例外変換 |
| `lib/services/data_service.dart` | 文字列ベースエラー判定 → カスタム例外変換 |
| `lib/services/item_service.dart` | 文字列ベースエラー判定 → カスタム例外変換 |
| `lib/services/shop_service.dart` | 文字列ベースエラー判定 → カスタム例外変換 |
| `lib/drawer/settings/settings_persistence.dart` | 空catchブロック修正 |
| `lib/providers/auth_provider.dart` | 5重ネスト整理、StreamSubscription管理 |

## 設計詳細

### #36-1: getCustomTheme()キャッシュ化

```dart
// Before: build()内で11回以上呼び出し
backgroundColor: getCustomTheme().scaffoldBackgroundColor,
// ...他の箇所でも繰り返し

// After: build()先頭で1回だけ取得
@override
Widget build(BuildContext context) {
  final theme = getCustomTheme();
  final luminance = theme.scaffoldBackgroundColor.computeLuminance();
  // 以降は theme 変数を使用
}
```

### #36-2: TabController更新のbuild()外移動

TabControllerの再生成ロジックをConsumer2のbuilder内から、`didChangeDependencies()`またはProviderのlistenで適切に処理する。

### #36-3: updateThemeAndFontIfNeeded()の移動

Consumer2のbuilder内での毎回呼び出しを廃止し、initStateまたはdidChangeDependenciesでの初期設定に変更。

### #36-4: 取り消し線設定のProvider化

```dart
// Before: 各ListEditがinitStateで個別にSharedPreferences読み込み
// After: 親ウィジェットまたはProviderから渡す
ListEdit(
  strikethroughEnabled: strikethroughEnabled, // パラメータとして受け取り
  // ...
)
```

### #36-5: AdBanner busy-wait → Completer

```dart
// OneTimePurchaseService に Completer 追加
final Completer<void> _initCompleter = Completer<void>();
Future<void> get initialized => _initCompleter.future;

// initialize() 完了時
_initCompleter.complete();

// AdBanner側
await purchaseService.initialized.timeout(const Duration(seconds: 3));
```

### #37-1: カスタム例外クラス

```dart
// lib/utils/exceptions.dart
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class NotFoundError extends AppException {
  const NotFoundError([String message = 'リソースが見つかりません'])
      : super(message, code: 'not-found');
}

class PermissionDeniedError extends AppException {
  const PermissionDeniedError([String message = '権限がありません'])
      : super(message, code: 'permission-denied');
}

class NetworkError extends AppException {
  const NetworkError([String message = 'ネットワークエラーが発生しました'])
      : super(message, code: 'network-error');
}
```

### #37-2: Firebase例外変換ヘルパー

```dart
// Service/Repository層でのFirebase例外変換
AppException convertFirebaseException(dynamic e) {
  if (e is FirebaseException) {
    switch (e.code) {
      case 'not-found':
        return NotFoundError(e.message ?? 'リソースが見つかりません');
      case 'permission-denied':
        return PermissionDeniedError(e.message ?? '権限がありません');
      default:
        return AppException(e.message ?? '不明なエラー', code: e.code, originalError: e);
    }
  }
  return AppException(e.toString(), originalError: e);
}
```

### #37-3: settings_persistence.dart 修正

全catchブロックで`DebugService().log()`を使ったログ出力を追加。save系はrethrowの一貫性を検討（saveThemeと同様にするか、ログのみにするか）。

### #37-4: AuthProvider StreamSubscription管理

```dart
StreamSubscription<User?>? _authStateSubscription;

// _init()内
_authStateSubscription = _authService.authStateChanges.listen(...);

// dispose()
@override
void dispose() {
  _authStateSubscription?.cancel();
  super.dispose();
}
```

### #37-5: AuthProvider 5重ネスト整理

ネストされたtry-catchを個別の初期化メソッドに分割する。
