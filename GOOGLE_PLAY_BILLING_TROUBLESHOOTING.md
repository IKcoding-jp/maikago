# Google Play Billing トラブルシューティングガイド

## 問題: 商品が見つからない

### エラーメッセージ
```
PaymentService: Product not found: maikago-premium-monthly
```

## 1. Google Play Console での商品ID確認

### 1.1 商品IDの確認手順
1. [Google Play Console](https://play.google.com/console) にログイン
2. 対象のアプリ「まいカゴ」を選択
3. **「収益化」** → **「商品」** → **「サブスクリプション」**
4. 各サブスクリプション商品をクリック
5. **「Base Plan」** タブで実際の商品IDを確認

### 1.2 確認すべき項目
- **Product ID**: 例 `maikago_premium`
- **Base Plan ID**: 例 `maikago-premium-monthly`
- **Status**: Active（有効）になっているか
- **Pricing**: 価格が設定されているか

## 2. よくある問題と解決方法

### 2.1 商品IDの不一致
**問題**: アプリのコードとGoogle Play Consoleの商品IDが異なる

**解決方法**:
1. Google Play Consoleで実際の商品IDを確認
2. `lib/config/subscription_ids.dart` の商品IDを修正

```dart
// 例: Google Play Consoleで maikago_premium_monthly と設定されている場合
static const String premiumMonthly = 'maikago_premium_monthly'; // アンダースコアに変更
```

### 2.2 商品が非アクティブ
**問題**: 商品が作成されているが有効になっていない

**解決方法**:
1. Google Play Consoleで商品のステータスを確認
2. 「Active」に設定
3. 変更を保存

### 2.3 アプリのバージョン不一致
**問題**: テスト用アプリのバージョンが古い

**解決方法**:
1. 最新のAPKをアップロード
2. テスト用アカウントで最新版をインストール

### 2.4 テスト用アカウントの設定
**問題**: テスト用アカウントが正しく設定されていない

**解決方法**:
1. **「設定」** → **「ライセンステスト」**
2. テスト用Gmailアカウントを追加
3. そのアカウントでアプリをインストール

## 3. デバッグ手順

### 3.1 詳細ログの確認
アプリを実行して以下のログを確認：

```
PaymentService: Requested product IDs:
  - maikago-basic-monthly
  - maikago-basic-yearly
  - maikago-premium-monthly
  - maikago-premium-yearly
  - maikago-family-monthly
  - maikago-family-yearly

PaymentService: Found product details:
  - ID: [実際に見つかった商品ID]
  - Title: [商品タイトル]
  - Price: [価格]

PaymentService: Not found product IDs:
  - [見つからなかった商品ID]
```

### 3.2 商品IDの修正
Google Play Consoleの実際の商品IDに合わせて修正：

```dart
// lib/config/subscription_ids.dart
class SubscriptionIds {
  // Google Play Consoleの実際の商品IDに合わせて修正
  static const String premiumMonthly = '実際の商品ID'; // 例: maikago_premium_monthly
}
```

## 4. テスト用商品IDの設定

### 4.1 テスト用商品IDの作成
Google Play Consoleでテスト用の商品IDを作成：

```
テスト用商品ID例:
- test_maikago_premium_monthly
- test_maikago_premium_yearly
```

### 4.2 テスト用商品IDの使用
```dart
// テスト環境でのみ使用
static const String premiumMonthly = 'test_maikago_premium_monthly';
```

## 5. 段階的デバッグ

### 5.1 Step 1: 基本的な商品ID確認
```dart
// 1つの商品IDでテスト
static const Set<String> _productIds = {
  'maikago-premium-monthly', // この商品IDが正しいか確認
};
```

### 5.2 Step 2: 商品情報の詳細確認
```dart
// 商品情報の詳細をログ出力
for (final product in response.productDetails) {
  debugPrint('商品詳細:');
  debugPrint('  ID: ${product.id}');
  debugPrint('  Title: ${product.title}');
  debugPrint('  Description: ${product.description}');
  debugPrint('  Price: ${product.price}');
  debugPrint('  Raw Price: ${product.rawPrice}');
}
```

### 5.3 Step 3: エラーの詳細確認
```dart
if (response.error != null) {
  debugPrint('商品取得エラー: ${response.error}');
  debugPrint('エラーコード: ${response.error!.code}');
  debugPrint('エラーメッセージ: ${response.error!.message}');
}
```

## 6. よくある商品IDパターン

### 6.1 ハイフン区切り
```
maikago-premium-monthly
maikago-premium-yearly
```

### 6.2 アンダースコア区切り
```
maikago_premium_monthly
maikago_premium_yearly
```

### 6.3 ドット区切り
```
maikago.premium.monthly
maikago.premium.yearly
```

## 7. 解決チェックリスト

- [ ] Google Play Consoleで商品IDを確認
- [ ] アプリのコードの商品IDを修正
- [ ] 商品が「Active」状態になっているか確認
- [ ] テスト用アカウントが正しく設定されているか確認
- [ ] 最新のAPKがアップロードされているか確認
- [ ] アプリを再起動してテスト
- [ ] 詳細ログで商品情報を確認

## 8. サポート情報

### 8.1 必要な情報
問題解決のために以下の情報を準備してください：

1. **Google Play Consoleの商品ID一覧**
2. **アプリのコードの商品ID一覧**
3. **詳細ログの出力**
4. **エラーメッセージの詳細**

### 8.2 参考リンク
- [Google Play Billing Library](https://developer.android.com/google/play/billing)
- [Flutter in_app_purchase](https://pub.dev/packages/in_app_purchase)
- [Google Play Console](https://play.google.com/console)
