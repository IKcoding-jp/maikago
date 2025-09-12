/// 非消耗型アプリ内課金の種類
enum OneTimePurchaseType {
  premium, // まいかごプレミアム（全機能含む）
}

/// 非消耗型アプリ内課金モデル
class OneTimePurchase {
  final OneTimePurchaseType type;
  final String name;
  final String description;
  final int price;
  final String productId;
  final List<String> features;
  final int? trialDays; // 無料体験期間（日数）
  final String? trialDescription; // 体験期間の説明

  const OneTimePurchase({
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    required this.productId,
    required this.features,
    this.trialDays,
    this.trialDescription,
  });

  /// 利用可能な非消耗型商品一覧
  static List<OneTimePurchase> get availablePurchases => [
        OneTimePurchase.premium,
      ];

  /// まいかごプレミアム
  static const OneTimePurchase premium = OneTimePurchase(
    type: OneTimePurchaseType.premium,
    name: 'まいかごプレミアム',
    description: 'すべてのプレミアム機能を利用可能に',
    price: 280,
    productId: 'maikago_premium_unlock',
    features: [
      '全テーマ利用可能',
      '全フォント利用可能',
      '広告完全非表示',
    ],
    trialDays: 7, // 7日間の無料体験
    trialDescription: '7日間無料でお試し！いつでも解約OK',
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
