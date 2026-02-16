# 設計書: ナビゲーション管理の導入（go_router）

## ルート構造設計

### ルートパス一覧

| パス | 画面 | 種別 | 備考 |
|------|------|------|------|
| `/` | SplashScreen | 初期 | redirect で認証チェック |
| `/login` | LoginScreen | 認証 | 未認証時にリダイレクト |
| `/home` | MainScreen | メイン | 認証済みのデフォルト |
| `/about` | AboutScreen | ドロワー | |
| `/usage` | UsageScreen | ドロワー | |
| `/calculator` | CalculatorScreen | ドロワー | |
| `/subscription` | SubscriptionScreen | 課金 | 複数箇所から遷移 |
| `/feedback` | FeedbackScreen | ドロワー | |
| `/release-history` | ReleaseHistoryScreen | 情報 | |
| `/settings` | SettingsScreen | 設定親 | |
| `/settings/account` | AccountScreen | 設定子 | |
| `/settings/theme` | ThemeSelectScreen | 設定子 | |
| `/settings/font-size` | FontSizeSelectScreen | 設定子 | |
| `/settings/font` | FontSelectScreen | 設定子 | |
| `/settings/advanced` | AdvancedSettingsScreen | 設定子 | |
| `/settings/terms` | TermsOfServiceScreen | 設定子 | |
| `/settings/privacy` | PrivacyPolicyScreen | 設定子 | |
| `/camera` | EnhancedCameraScreen | フロー | 戻り値あり |
| `/ocr-confirm` | OcrResultConfirmScreen | フロー | 戻り値あり |
| `/recipe-confirm` | RecipeConfirmScreen | フロー | 戻り値あり |
| `/donation` | DonationScreen | 課金 | |
| `/one-time-purchase` | OneTimePurchaseScreen | 課金 | |

### 認証リダイレクト設計

```dart
redirect: (context, state) {
  final isLoggedIn = authProvider.isLoggedIn;
  final isLoggingIn = state.matchedLocation == '/login';

  if (!isLoggedIn && !isLoggingIn) return '/login';
  if (isLoggedIn && isLoggingIn) return '/home';
  return null; // リダイレクトなし
}
```

## ファイル構成

### 新規ファイル
- `lib/router.dart` - GoRouter 定義、ルート一覧、リダイレクトロジック

### 主な変更ファイル

#### 1. `lib/main.dart`
- `MaterialApp` → `MaterialApp.router` に変更
- `home`, `routes` プロパティを削除
- `routerConfig: router` を追加
- `SplashWrapper`, `AuthWrapper` を削除（go_router の redirect に統合）

#### 2. `lib/screens/main/widgets/main_drawer.dart`
- 7箇所の `Navigator.pop` + `Navigator.push` → `context.push()` に変更
- ドロワー内の遷移は `context.push()` で、ドロワーは自動的に閉じる（Scaffoldのdrawer動作）

#### 3. `lib/screens/drawer/settings/settings_screen.dart`
- 6+箇所の `Navigator.push` → `context.push()` に変更

#### 4. `lib/screens/main/widgets/bottom_summary_widget.dart`
- カメラ画面への遷移を `context.push()` に変更

#### 5. その他画面ファイル
- `Navigator.pop()` → `context.pop()` に統一
- 戻り値付きの `Navigator.pop(context, value)` → `context.pop(value)` に変更

## 設計方針

### go() vs push() の使い分け
- **`context.go()`**: トップレベルの画面切り替え（ナビゲーションスタックをリセット）
  - 例: ログイン後のホーム画面遷移
- **`context.push()`**: サブ画面への遷移（スタックに積む）
  - 例: ドロワーメニューからの画面遷移、設定画面からのサブ画面遷移

### ダイアログの扱い
- `showConstrainedDialog` はそのまま維持（go_router 対象外）
- ダイアログは画面遷移ではなくオーバーレイなので、Router の管轄外

### Web対応
- `MaterialApp.router` の `builder` で Web 横幅制限を維持
- go_router の URL がブラウザのアドレスバーに反映される
