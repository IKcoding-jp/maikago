/// ストア申請準備の設定ファイル
/// - ストアURL
/// - 商品ID
/// - コンプライアンス要件
/// - 申請手順

class StorePreparationConfig {
  // === ストアURL ===
  static const String googlePlayConsoleUrl = 'https://play.google.com/console';
  static const String appStoreConnectUrl = 'https://appstoreconnect.apple.com';
  static const String googlePlayDeveloperUrl =
      'https://developer.android.com/guide/play/billing';
  static const String appStoreDeveloperUrl =
      'https://developer.apple.com/in-app-purchase/';

  // === 商品ID設定 ===
  static const Map<String, String> productIds = {
    'basic_monthly': 'maikago-basic-monthly',
    'basic_yearly': 'maikago-basic-yearly',
    'premium_monthly': 'maikago-premium-monthly',
    'premium_yearly': 'maikago-premium-yearly',
    'family_monthly': 'maikago-family-monthly',
    'family_yearly': 'maikago-family-yearly',
  };

  // === 価格設定（日本円） ===
  static const Map<String, int> prices = {
    'basic_monthly': 120,
    'basic_yearly': 1200,
    'premium_monthly': 240,
    'premium_yearly': 2400,
    'family_monthly': 360,
    'family_yearly': 3600,
  };

  // === ストア申請要件 ===
  static const List<String> requiredItems = [
    'アプリ内購入設定',
    'プライバシーポリシー更新',
    '利用規約更新',
    'スクリーンショット準備',
    'コンプライアンスチェック',
  ];

  // === コンプライアンス要件 ===
  static const Map<String, List<String>> complianceRequirements = {
    'privacy_policy': [
      '個人情報の収集目的の明記',
      'データの使用目的の明記',
      '第三者提供の制限',
      'データ削除権利の明記',
      'サブスクリプション関連の情報収集',
    ],
    'terms_of_service': [
      'サブスクリプションサービスの説明',
      '解約方法の明記',
      '自動更新の説明',
      '家族共有機能の説明',
      '返金ポリシーの明記',
    ],
    'data_protection': ['GDPR対応', 'CCPA対応', 'データ暗号化', 'セキュアな通信', 'アクセス制御'],
    'subscription_management': [
      '解約方法の明確な説明',
      '自動更新の事前通知',
      '価格変更の事前通知',
      '無料トライアルの説明',
      '返金条件の明記',
    ],
  };

  // === スクリーンショット要件 ===
  static const Map<String, List<String>> screenshotRequirements = {
    'android': [
      '16:9 アスペクト比',
      '最小解像度: 320x320px',
      '最大解像度: 3840x3840px',
      'PNGまたはJPEG形式',
      '最大ファイルサイズ: 8MB',
    ],
    'ios': [
      '6.7インチ (iPhone 14 Pro Max)',
      '6.5インチ (iPhone 14 Plus)',
      '5.5インチ (iPhone 8 Plus)',
      '12.9インチ (iPad Pro)',
      '11インチ (iPad Pro)',
    ],
  };

  // === 申請手順 ===
  static const Map<String, List<String>> applicationSteps = {
    'google_play': [
      'Google Play Consoleにログイン',
      'アプリを作成',
      'ストア情報を入力',
      'アプリ内購入商品を設定',
      'プライバシーポリシーをアップロード',
      'スクリーンショットをアップロード',
      'アプリをアップロード',
      '審査を待つ',
    ],
    'app_store': [
      'App Store Connectにログイン',
      'アプリを作成',
      'アプリ情報を入力',
      'アプリ内購入商品を設定',
      'プライバシーポリシーをアップロード',
      'スクリーンショットをアップロード',
      'アプリをアップロード',
      '審査を待つ',
    ],
  };

  // === 審査ガイドライン ===
  static const Map<String, List<String>> reviewGuidelines = {
    'content': ['不適切なコンテンツの排除', '年齢制限の適切な設定', '著作権の遵守', '商標権の遵守'],
    'functionality': ['アプリの安定性', 'クラッシュの防止', '適切なエラーハンドリング', 'パフォーマンスの最適化'],
    'subscription': ['解約方法の明確な表示', '自動更新の事前通知', '価格の明確な表示', '無料トライアルの説明'],
    'privacy': ['プライバシーポリシーの適切な内容', 'データ収集の透明性', 'ユーザー同意の取得', 'データ削除機能の提供'],
  };

  // === エラーハンドリング ===
  static const Map<String, String> errorMessages = {
    'iap_not_configured': 'アプリ内購入が設定されていません',
    'privacy_not_updated': 'プライバシーポリシーが更新されていません',
    'terms_not_updated': '利用規約が更新されていません',
    'screenshots_not_ready': 'スクリーンショットが準備されていません',
    'compliance_not_checked': 'コンプライアンスチェックが完了していません',
  };

  // === 成功メッセージ ===
  static const Map<String, String> successMessages = {
    'store_ready': 'ストア申請の準備が完了しました！',
    'iap_configured': 'アプリ内購入の設定が完了しました',
    'privacy_updated': 'プライバシーポリシーの更新が完了しました',
    'terms_updated': '利用規約の更新が完了しました',
    'screenshots_ready': 'スクリーンショットの準備が完了しました',
    'compliance_checked': 'コンプライアンスチェックが完了しました',
  };

  // === ヘルプ情報 ===
  static const Map<String, String> helpInfo = {
    'iap_setup': 'Google Play ConsoleとApp Store Connectで商品を設定してください',
    'privacy_policy': 'サブスクリプション機能に対応したプライバシーポリシーを作成してください',
    'terms_of_service': 'サブスクリプション条項を含む利用規約を作成してください',
    'screenshots': '各デバイスサイズに対応したスクリーンショットを準備してください',
    'compliance': 'データ保護法とストアガイドラインへの対応を確認してください',
  };

  /// 商品IDを取得
  static String getProductId(String plan) {
    return productIds[plan] ?? '';
  }

  /// 価格を取得
  static int getPrice(String plan) {
    return prices[plan] ?? 0;
  }

  /// エラーメッセージを取得
  static String getErrorMessage(String key) {
    return errorMessages[key] ?? '不明なエラー';
  }

  /// 成功メッセージを取得
  static String getSuccessMessage(String key) {
    return successMessages[key] ?? '完了しました';
  }

  /// ヘルプ情報を取得
  static String getHelpInfo(String key) {
    return helpInfo[key] ?? '詳細情報がありません';
  }

  /// コンプライアンス要件を取得
  static List<String> getComplianceRequirements(String category) {
    return complianceRequirements[category] ?? [];
  }

  /// 申請手順を取得
  static List<String> getApplicationSteps(String platform) {
    return applicationSteps[platform] ?? [];
  }

  /// 審査ガイドラインを取得
  static List<String> getReviewGuidelines(String category) {
    return reviewGuidelines[category] ?? [];
  }
}
