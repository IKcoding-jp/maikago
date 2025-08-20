/// サブスクリプションプランの種類
enum SubscriptionPlanType { free, basic, premium, family }

/// サブスクリプション期間
enum SubscriptionPeriod { monthly, yearly }

/// サブスクリプションプランモデル
class SubscriptionPlan {
  final SubscriptionPlanType type;
  final String name;
  final String description;
  final int? monthlyPrice;
  final int? yearlyPrice;
  final int maxLists;
  final int maxTabs;
  final bool hasListLimit;
  final bool hasTabLimit;
  final bool showAds;
  final bool canCustomizeTheme;
  final bool canCustomizeFont;
  final bool hasEarlyAccess;
  final bool isFamilyPlan;
  final int maxFamilyMembers;

  const SubscriptionPlan({
    required this.type,
    required this.name,
    required this.description,
    this.monthlyPrice,
    this.yearlyPrice,
    required this.maxLists,
    required this.maxTabs,
    required this.hasListLimit,
    required this.hasTabLimit,
    required this.showAds,
    required this.canCustomizeTheme,
    required this.canCustomizeFont,
    required this.hasEarlyAccess,
    required this.isFamilyPlan,
    required this.maxFamilyMembers,
  });

  /// 利用可能なプラン一覧
  static List<SubscriptionPlan> get availablePlans => [
    SubscriptionPlan.free,
    SubscriptionPlan.basic,
    SubscriptionPlan.premium,
    SubscriptionPlan.family,
  ];

  /// フリープラン
  static const SubscriptionPlan free = SubscriptionPlan(
    type: SubscriptionPlanType.free,
    name: 'まいカゴフリー',
    description: '基本的な機能を無料で利用',
    monthlyPrice: 0,
    yearlyPrice: 0,
    maxLists: 10, // 各タブ内のリスト数制限
    maxTabs: 3, // 画面上部のタブ数制限
    hasListLimit: true,
    hasTabLimit: true,
    showAds: true,
    canCustomizeTheme: false,
    canCustomizeFont: false,
    hasEarlyAccess: false,
    isFamilyPlan: false,
    maxFamilyMembers: 0,
  );

  /// ベーシックプラン
  static const SubscriptionPlan basic = SubscriptionPlan(
    type: SubscriptionPlanType.basic,
    name: 'まいカゴベーシック',
    description: '無駄な機能はいらない人向け',
    monthlyPrice: 240,
    yearlyPrice: 2200,
    maxLists: 30,
    maxTabs: 10,
    hasListLimit: true,
    hasTabLimit: true,
    showAds: false,
    canCustomizeTheme: false,
    canCustomizeFont: false,
    hasEarlyAccess: false,
    isFamilyPlan: false,
    maxFamilyMembers: 0,
  );

  /// プレミアムプラン
  static const SubscriptionPlan premium = SubscriptionPlan(
    type: SubscriptionPlanType.premium,
    name: 'まいカゴプレミアム',
    description: '追加機能を利用したいユーザー',
    monthlyPrice: 480,
    yearlyPrice: 4800,
    maxLists: -1,
    maxTabs: -1,
    hasListLimit: false,
    hasTabLimit: false,
    showAds: false,
    canCustomizeTheme: true,
    canCustomizeFont: true,
    hasEarlyAccess: true,
    isFamilyPlan: false,
    maxFamilyMembers: 0,
  );

  /// ファミリープラン
  static const SubscriptionPlan family = SubscriptionPlan(
    type: SubscriptionPlanType.family,
    name: 'まいカゴファミリー',
    description: '家族・グループで利用したいユーザー（参加メンバーは特典のみ利用）',
    monthlyPrice: 720,
    yearlyPrice: 6000,
    maxLists: -1,
    maxTabs: -1,
    hasListLimit: false,
    hasTabLimit: false,
    showAds: false,
    canCustomizeTheme: true,
    canCustomizeFont: true,
    hasEarlyAccess: true,
    isFamilyPlan: true,
    maxFamilyMembers: 6,
  );

  /// 有料プランかどうか
  bool get isPaidPlan => type != SubscriptionPlanType.free;

  /// フリープランかどうか
  bool get isFreePlan => type == SubscriptionPlanType.free;

  /// 指定された期間の料金を取得
  int getPrice(SubscriptionPeriod period) {
    switch (period) {
      case SubscriptionPeriod.monthly:
        return monthlyPrice ?? 0;
      case SubscriptionPeriod.yearly:
        return yearlyPrice ?? 0;
    }
  }

  /// 商品IDを取得
  String? getProductId(SubscriptionPeriod period) {
    if (isFreePlan) return null;

    switch (type) {
      case SubscriptionPlanType.basic:
        return period == SubscriptionPeriod.monthly
            ? 'maikago_basic_monthly'
            : 'maikago_basic_yearly';
      case SubscriptionPlanType.premium:
        return period == SubscriptionPeriod.monthly
            ? 'maikago_premium_monthly'
            : 'maikago_premium_yearly';
      case SubscriptionPlanType.family:
        return period == SubscriptionPeriod.monthly
            ? 'maikago_family_monthly'
            : 'maikago_family_yearly';
      case SubscriptionPlanType.free:
        return null;
    }
  }

  /// プランの特徴を取得
  List<String> getFeatures() {
    final features = <String>[];

    if (!hasListLimit) features.add('タブ無制限');
    if (!hasTabLimit) features.add('タブ無制限');
    if (!showAds) features.add('広告非表示');
    if (canCustomizeTheme) features.add('テーマカスタマイズ');
    if (canCustomizeFont) features.add('フォントカスタマイズ');
    if (hasEarlyAccess) features.add('新機能早期アクセス');
    if (isFamilyPlan) features.add('ファミリー共有機能');

    return features;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionPlan && other.type == type;
  }

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => 'SubscriptionPlan(type: $type, name: $name)';
}
