/// サブスクリプション商品IDの定数定義
/// Google Play Billing/App Store Connect用の商品IDを一元管理
class SubscriptionIds {
  // === サブスクリプション商品ID（Product IDs） ===

  /// ベーシックプラン商品ID
  static const String basicProduct = 'maikago_basic';

  /// プレミアムプラン商品ID
  static const String premiumProduct = 'maikago_premium';

  /// ファミリープラン商品ID
  static const String familyProduct = 'maikago_family';

  // === Base Plan / 個別ID（購買時に参照するID） ===
  // Google Play Consoleの実際のBase Plan IDに合わせて修正

  /// ベーシックプラン月額
  static const String basicMonthly = 'maikago-basic-monthly';

  /// ベーシックプラン年額
  static const String basicYearly = 'maikago-basic-yearly';

  /// プレミアムプラン月額
  static const String premiumMonthly = 'maikago-premium-monthly';

  /// プレミアムプラン年額
  static const String premiumYearly = 'maikago-premium-yearly';

  /// ファミリープラン月額
  static const String familyMonthly = 'maikago-family-monthly';

  /// ファミリープラン年額
  static const String familyYearly = 'maikago-family-yearly';

  // === 商品ID一覧 ===

  /// 全サブスクリプション商品ID（Product IDs）
  static const Set<String> allProducts = {
    basicProduct,
    premiumProduct,
    familyProduct,
  };

  /// 全Base Plan ID（購買処理用）
  static const Set<String> allBasePlans = {
    basicMonthly,
    basicYearly,
    premiumMonthly,
    premiumYearly,
    familyMonthly,
    familyYearly,
  };

  /// 月額プランID
  static const Set<String> monthlyPlans = {
    basicMonthly,
    premiumMonthly,
    familyMonthly,
  };

  /// 年額プランID
  static const Set<String> yearlyPlans = {
    basicYearly,
    premiumYearly,
    familyYearly,
  };

  // === ヘルパーメソッド ===

  /// IDが月額プランかどうかを判定
  static bool isMonthlyPlan(String id) {
    return monthlyPlans.contains(id);
  }

  /// IDが年額プランかどうかを判定
  static bool isYearlyPlan(String id) {
    return yearlyPlans.contains(id);
  }

  /// IDがベーシックプランかどうかを判定
  static bool isBasicPlan(String id) {
    return id == basicMonthly || id == basicYearly;
  }

  /// IDがプレミアムプランかどうかを判定
  static bool isPremiumPlan(String id) {
    return id == premiumMonthly || id == premiumYearly;
  }

  /// IDがファミリープランかどうかを判定
  static bool isFamilyPlan(String id) {
    return id == familyMonthly || id == familyYearly;
  }

  /// 対応するプラン名を取得
  static String getPlanName(String id) {
    switch (id) {
      case basicMonthly:
        return 'ベーシック（月額）';
      case basicYearly:
        return 'ベーシック（年額）';
      case premiumMonthly:
        return 'プレミアム（月額）';
      case premiumYearly:
        return 'プレミアム（年額）';
      case familyMonthly:
        return 'ファミリー（月額）';
      case familyYearly:
        return 'ファミリー（年額）';
      default:
        return '不明なプラン';
    }
  }

  /// 月額プランから年額プランのIDを取得
  static String? getYearlyPlanId(String monthlyId) {
    switch (monthlyId) {
      case basicMonthly:
        return basicYearly;
      case premiumMonthly:
        return premiumYearly;
      case familyMonthly:
        return familyYearly;
      default:
        return null;
    }
  }

  /// 年額プランから月額プランのIDを取得
  static String? getMonthlyPlanId(String yearlyId) {
    switch (yearlyId) {
      case basicYearly:
        return basicMonthly;
      case premiumYearly:
        return premiumMonthly;
      case familyYearly:
        return familyMonthly;
      default:
        return null;
    }
  }
}
