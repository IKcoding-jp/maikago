/// 非消耗型アプリ内課金の種類
enum OneTimePurchaseType {
  premium, // まいかごプレミアム（全機能含む）
}

/// 非消耗型アプリ内課金モデル
class OneTimePurchase {
  const OneTimePurchase({
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    required this.productId,
    required this.features,
  });

  final OneTimePurchaseType type;
  final String name;
  final String description;
  final int price;
  final String productId;
  final List<String> features;

  /// 利用可能な非消耗型商品一覧
  static List<OneTimePurchase> get availablePurchases => [
        OneTimePurchase.premium,
      ];

  /// まいかごプレミアム
  static const OneTimePurchase premium = OneTimePurchase(
    type: OneTimePurchaseType.premium,
    name: 'まいかごプレミアム',
    description: 'すべてのプレミアム機能を利用可能に',
    price: 500,
    productId: 'maikago_premium_unlock',
    features: [
      'OCR（値札撮影）無制限 — 月5回の制限を解除',
      'ショップ（タブ）無制限 — 2つの制限を解除',
      'レシピ解析 — テキストから買い物リストを自動作成',
      '全テーマ・全フォント',
      '広告完全非表示',
    ],
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OneTimePurchase && other.type == type;
  }

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => 'OneTimePurchase(type: $type, name: $name)';
}
