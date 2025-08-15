# Google Play Billing 設定ガイド

このドキュメントでは、まいカゴアプリでのGoogle Play定期購入（サブスクリプション）の設定手順を説明します。

## 1. Google Play Console での商品登録

### 1.1 アプリの選択
1. [Google Play Console](https://play.google.com/console) にログイン
2. 対象のアプリ「まいカゴ」を選択

### 1.2 サブスクリプション商品の作成
1. **「収益化」** → **「商品」** → **「サブスクリプション」** に移動
2. **「サブスクリプションを作成」** をクリック

### 1.3 商品IDの設定
以下の商品IDを正確に入力してください：

#### ベーシックプラン
- **商品ID**: `maikago_basic`
- **Base Plan ID**: 
  - 月額: `maikago-basic-monthly`
  - 年額: `maikago-basic-yearly`

#### プレミアムプラン
- **商品ID**: `maikago_premium`
- **Base Plan ID**:
  - 月額: `maikago-premium-monthly`
  - 年額: `maikago-premium-yearly`

#### ファミリープラン
- **商品ID**: `maikago_family`
- **Base Plan ID**:
  - 月額: `maikago-family-monthly`
  - 年額: `maikago-family-yearly`

### 1.4 価格設定
推奨価格（日本円）：

| プラン | 月額 | 年額（20%割引） |
|--------|------|-----------------|
| ベーシック | ¥120 | ¥1,200 |
| プレミアム | ¥240 | ¥2,400 |
| ファミリー | ¥480 | ¥4,800 |

### 1.5 商品説明
各プランの説明を入力：

#### ベーシックプラン
```
• リスト数: 無制限
• アイテム数: 各リスト50個まで
• 広告非表示
• テーマ: 5種類
• フォント: 3種類
```

#### プレミアムプラン
```
• リスト数: 無制限
• アイテム数: 無制限
• 広告非表示
• テーマ: 全種類
• フォント: 全種類
• ファミリー共有: 最大5人
```

#### ファミリープラン
```
• プレミアムプランの全機能
• ファミリー共有: 最大10人
• 家族向け特典機能
```

## 2. テスト設定

### 2.1 ライセンステスト
1. **「設定」** → **「ライセンステスト」**
2. テスト用Gmailアカウントを追加
3. テスト用アカウントでアプリをインストール

### 2.2 テスト用アカウントの追加
```
テスト用Gmailアカウント例:
- test1@gmail.com
- test2@gmail.com
- developer@gmail.com
```

## 3. アプリの設定

### 3.1 AndroidManifest.xml
既に設定済み：
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

### 3.2 pubspec.yaml
既に設定済み：
```yaml
dependencies:
  in_app_purchase: ^3.3.0
```

## 4. 実装済み機能

### 4.1 サブスクリプション管理
- ✅ `SubscriptionManager` - サブスクリプション状態管理
- ✅ `InAppPurchaseService` - 購入処理
- ✅ `PaymentService` - 決済システム統合

### 4.2 商品ID定義
- ✅ `SubscriptionIds` - 商品IDの一元管理
- ✅ プラン定義（ベーシック、プレミアム、ファミリー）

### 4.3 UI実装
- ✅ `SubscriptionScreen` - サブスクリプション選択画面
- ✅ プラン比較表
- ✅ 無料トライアル機能

## 5. テスト手順

### 5.1 開発環境でのテスト
1. テスト用アカウントでアプリをインストール
2. サブスクリプション画面に移動
3. 各プランを選択して購入テスト
4. 購入履歴の復元テスト

### 5.2 本番環境でのテスト
1. 内部テスト版をリリース
2. テスト用アカウントで本番版をテスト
3. 実際の決済処理をテスト

## 6. トラブルシューティング

### 6.1 よくある問題

#### 商品が見つからない
- 商品IDが正確に一致しているか確認
- Google Play Consoleで商品が公開されているか確認
- アプリのバージョンが正しいか確認

#### 購入が失敗する
- テスト用アカウントが正しく設定されているか確認
- ネットワーク接続を確認
- アプリの権限設定を確認

#### サブスクリプションが反映されない
- 購入完了処理が正しく実行されているか確認
- Firebaseとの同期を確認
- アプリの再起動を試行

### 6.2 デバッグ方法
```dart
// デバッグモードを有効化
enableDebugMode = true;

// ログの確認
debugPrint('購入処理: $productId');
```

## 7. 本番リリース前のチェックリスト

- [ ] Google Play Consoleで商品が正しく設定されている
- [ ] テスト用アカウントで購入テストが完了している
- [ ] 購入履歴の復元が正常に動作している
- [ ] サブスクリプションの期限管理が正しく動作している
- [ ] エラーハンドリングが適切に実装されている
- [ ] プライバシーポリシーと利用規約が更新されている

## 8. 参考リンク

- [Google Play Billing Library](https://developer.android.com/google/play/billing)
- [Flutter in_app_purchase](https://pub.dev/packages/in_app_purchase)
- [Google Play Console](https://play.google.com/console)
- [サブスクリプション設計ドキュメント](./SUBSCRIPTION_DESIGN.md)
