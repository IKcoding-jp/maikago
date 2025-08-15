# RevenueCat 統合ガイド

RevenueCatは、アプリ内課金とサブスクリプションの管理を簡素化するサービスです。Google Play Billing の複雑な実装を抽象化し、より簡単にサブスクリプション機能を実装できます。

## 1. RevenueCat の利点

### 1.1 開発効率の向上
- **統一されたAPI**: iOS/Android/Web で同じAPIを使用
- **自動同期**: 購入状態の自動同期と管理
- **サーバー検証**: 購入の自動検証
- **分析機能**: 購入データの詳細分析

### 1.2 運用の簡素化
- **ダッシュボード**: 購入状態の一元管理
- **Webhook**: 購入イベントの自動通知
- **A/Bテスト**: 価格やプランのテスト
- **顧客サポート**: 購入履歴の確認

## 2. 導入手順

### 2.1 RevenueCat アカウント作成
1. [RevenueCat](https://www.revenuecat.com/) にアクセス
2. アカウントを作成
3. 新しいプロジェクトを作成

### 2.2 Flutter パッケージの追加
```yaml
dependencies:
  purchases_flutter: ^6.0.0
```

### 2.3 初期化コード
```dart
import 'package:purchases_flutter/purchases_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // RevenueCat の初期化
  await Purchases.setLogLevel(LogLevel.debug);
  await Purchases.configure(
    PurchasesConfiguration("your_api_key")
  );
  
  runApp(MyApp());
}
```

### 2.4 商品の設定
```dart
// 商品の取得
final offerings = await Purchases.getOfferings();
final current = offerings.current;

if (current != null) {
  // 利用可能な商品を表示
  for (final package in current.availablePackages) {
    print('商品: ${package.storeProduct.title}');
    print('価格: ${package.storeProduct.priceString}');
  }
}
```

### 2.5 購入処理
```dart
// 購入の実行
try {
  final customerInfo = await Purchases.purchasePackage(package);
  
  // 購入成功
  if (customerInfo.entitlements.active.isNotEmpty) {
    // サブスクリプションが有効
    print('購入成功: ${customerInfo.entitlements.active}');
  }
} catch (e) {
  // 購入失敗
  print('購入失敗: $e');
}
```

## 3. 現在の実装との比較

### 3.1 現在の実装（Google Play Billing 直接）
```dart
// 商品情報の取得
final ProductDetailsResponse response = await _inAppPurchase
    .queryProductDetails(_productIds);

// 購入処理
final PurchaseParam purchaseParam = PurchaseParam(
  productDetails: product,
);
await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

// 購入検証（手動実装が必要）
await _verifyPurchase(purchaseDetails);
```

### 3.2 RevenueCat を使用した場合
```dart
// 商品情報の取得
final offerings = await Purchases.getOfferings();

// 購入処理
final customerInfo = await Purchases.purchasePackage(package);

// 購入検証（自動）
if (customerInfo.entitlements.active.isNotEmpty) {
  // 有効なサブスクリプション
}
```

## 4. 移行計画

### 4.1 段階的移行
1. **Phase 1**: RevenueCat の導入と並行運用
2. **Phase 2**: 新規ユーザーは RevenueCat を使用
3. **Phase 3**: 既存ユーザーの移行
4. **Phase 4**: 旧実装の廃止

### 4.2 互換性の確保
```dart
class UnifiedPurchaseService {
  static const bool useRevenueCat = true;
  
  Future<void> purchaseProduct(String productId) async {
    if (useRevenueCat) {
      await _purchaseWithRevenueCat(productId);
    } else {
      await _purchaseWithGooglePlay(productId);
    }
  }
}
```

## 5. RevenueCat の設定

### 5.1 商品の設定
1. RevenueCat ダッシュボードで商品を設定
2. Google Play Console の商品IDと連携
3. エンティタイトメント（特典）を設定

### 5.2 エンティタイトメントの設定
```json
{
  "basic": {
    "name": "ベーシックプラン",
    "features": ["unlimited_lists", "no_ads", "themes_5"]
  },
  "premium": {
    "name": "プレミアムプラン", 
    "features": ["unlimited_lists", "no_ads", "all_themes", "family_sharing"]
  },
  "family": {
    "name": "ファミリープラン",
    "features": ["unlimited_lists", "no_ads", "all_themes", "family_sharing_10"]
  }
}
```

## 6. コスト比較

### 6.1 RevenueCat の料金
- **無料プラン**: 月間売上 $2,500 まで
- **有料プラン**: 月間売上の 1% + $99/月

### 6.2 開発コスト
- **現在の実装**: 開発・保守コストが高い
- **RevenueCat**: 開発コストを大幅削減

## 7. 推奨事項

### 7.1 導入タイミング
- **新規アプリ**: 最初から RevenueCat を使用
- **既存アプリ**: 段階的移行を推奨

### 7.2 実装方針
1. **並行運用**: 既存ユーザーへの影響を最小化
2. **段階移行**: リスクを分散
3. **テスト重視**: 十分なテスト期間を確保

## 8. 参考リンク

- [RevenueCat Flutter SDK](https://docs.revenuecat.com/docs/flutter)
- [RevenueCat ダッシュボード](https://app.revenuecat.com/)
- [Flutter 統合ガイド](https://docs.revenuecat.com/docs/flutter-quickstart)
- [エンティタイトメント設定](https://docs.revenuecat.com/docs/entitlements)
