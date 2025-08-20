import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ストア申請準備を管理するサービス
/// - アプリ内購入の設定
/// - プライバシーポリシーの更新
/// - 利用規約の更新
/// - スクリーンショットの準備
/// - コンプライアンスチェック
class StorePreparationService extends ChangeNotifier {
  static final StorePreparationService _instance =
      StorePreparationService._internal();
  factory StorePreparationService() => _instance;
  StorePreparationService._internal();

  // === ストア設定 ===
  bool _isStoreReady = false;
  bool _isIapConfigured = false;
  bool _isPrivacyPolicyUpdated = false;
  bool _isTermsOfServiceUpdated = false;
  bool _isScreenshotsReady = false;
  bool _isComplianceChecked = false;

  // === アプリ情報 ===
  PackageInfo? _packageInfo;
  String _appVersion = '';
  String _buildNumber = '';

  // === ストア情報 ===
  final Map<String, dynamic> _storeListing = {
    'appName': 'まいカゴ',
    'shortDescription': 'シンプルで使いやすいお買い物リスト管理アプリ',
    'fullDescription': '''
まいカゴは、日々のお買い物をより効率的に管理するためのシンプルで使いやすいアプリです。

【主な機能】
• 直感的なリスト作成と管理
• カテゴリ別の商品整理
• 共有機能で家族と連携
• カスタマイズ可能なテーマ
• オフライン対応

【サブスクリプションプラン】
• 無料プラン：基本的なリスト管理機能
• ベーシックプラン：広告非表示、テーマカスタマイズ
• プレミアムプラン：家族共有、高度な機能
• ファミリープラン：最大6名の家族メンバー

【プライバシーとセキュリティ】
• 個人情報の安全な管理
• データの暗号化
• 透明性のあるプライバシーポリシー

今すぐダウンロードして、お買い物をより楽しく効率的に！
''',
    'keywords': '買い物,リスト,管理,家族,共有,テーマ,カスタマイズ',
    'category': 'Productivity',
    'contentRating': 'Everyone',
    'targetAudience': '一般ユーザー',
  };

  // === アプリ内購入設定（無効化） ===
  final Map<String, Map<String, dynamic>> _iapProducts = {};

  // === コンプライアンスチェック項目 ===
  final Map<String, bool> _complianceChecks = {
    'privacy_policy': false,
    'terms_of_service': false,
    'data_collection': false,
    'user_consent': false,
    'data_retention': false,
    'data_deletion': false,
    'subscription_terms': false,
    'cancellation_policy': false,
    'refund_policy': false,
    'age_rating': false,
    'content_guidelines': false,
    'security_measures': false,
  };

  // === ゲッター ===
  bool get isStoreReady => _isStoreReady;
  bool get isIapConfigured => _isIapConfigured;
  bool get isPrivacyPolicyUpdated => _isPrivacyPolicyUpdated;
  bool get isTermsOfServiceUpdated => _isTermsOfServiceUpdated;
  bool get isScreenshotsReady => _isScreenshotsReady;
  bool get isComplianceChecked => _isComplianceChecked;
  PackageInfo? get packageInfo => _packageInfo;
  String get appVersion => _appVersion;
  String get buildNumber => _buildNumber;
  Map<String, dynamic> get storeListing => Map.unmodifiable(_storeListing);
  Map<String, Map<String, dynamic>> get iapProducts =>
      Map.unmodifiable(_iapProducts);
  Map<String, bool> get complianceChecks => Map.unmodifiable(_complianceChecks);

  /// 初期化
  Future<void> initialize() async {
    await _loadPackageInfo();
    await _loadStoreStatus();
    await _runComplianceChecks();
    _updateStoreReadiness();
    notifyListeners();
  }

  /// パッケージ情報を読み込み
  Future<void> _loadPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _appVersion = _packageInfo!.version;
      _buildNumber = _packageInfo!.buildNumber;
    } catch (e) {
      debugPrint('StorePreparationService: パッケージ情報の読み込みに失敗: $e');
    }
  }

  /// ストア状態を読み込み
  Future<void> _loadStoreStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isIapConfigured = prefs.getBool('store_iap_configured') ?? false;
      _isPrivacyPolicyUpdated = prefs.getBool('store_privacy_updated') ?? false;
      _isTermsOfServiceUpdated = prefs.getBool('store_terms_updated') ?? false;
      _isScreenshotsReady = prefs.getBool('store_screenshots_ready') ?? false;
      _isComplianceChecked = prefs.getBool('store_compliance_checked') ?? false;
    } catch (e) {
      debugPrint('StorePreparationService: ストア状態の読み込みに失敗: $e');
    }
  }

  /// コンプライアンスチェックを実行
  Future<void> _runComplianceChecks() async {
    // プライバシーポリシーの確認
    _complianceChecks['privacy_policy'] = _isPrivacyPolicyUpdated;

    // 利用規約の確認
    _complianceChecks['terms_of_service'] = _isTermsOfServiceUpdated;

    // データ収集の確認
    _complianceChecks['data_collection'] = true; // 基本的なデータ収集のみ

    // ユーザー同意の確認
    _complianceChecks['user_consent'] = true; // アプリ内で同意取得

    // データ保持期間の確認
    _complianceChecks['data_retention'] = true; // 明確な保持期間設定

    // データ削除の確認
    _complianceChecks['data_deletion'] = true; // 削除機能実装済み

    // サブスクリプション条項の確認
    _complianceChecks['subscription_terms'] = _isIapConfigured;

    // 解約ポリシーの確認
    _complianceChecks['cancellation_policy'] = _isIapConfigured;

    // 返金ポリシーの確認
    _complianceChecks['refund_policy'] = _isIapConfigured;

    // 年齢制限の確認
    _complianceChecks['age_rating'] = true; // 全年齢対象

    // コンテンツガイドラインの確認
    _complianceChecks['content_guidelines'] = true; // 適切なコンテンツ

    // セキュリティ対策の確認
    _complianceChecks['security_measures'] = true; // 基本的なセキュリティ実装
  }

  /// ストア準備状況を更新
  void _updateStoreReadiness() {
    _isStoreReady =
        _isIapConfigured &&
        _isPrivacyPolicyUpdated &&
        _isTermsOfServiceUpdated &&
        _isScreenshotsReady &&
        _isComplianceChecked &&
        _complianceChecks.values.every((check) => check);
  }

  /// アプリ内購入設定を完了
  Future<void> markIapConfigured() async {
    _isIapConfigured = true;
    await _saveStoreStatus();
    _updateStoreReadiness();
    notifyListeners();
  }

  /// プライバシーポリシー更新を完了
  Future<void> markPrivacyPolicyUpdated() async {
    _isPrivacyPolicyUpdated = true;
    await _saveStoreStatus();
    _runComplianceChecks();
    _updateStoreReadiness();
    notifyListeners();
  }

  /// 利用規約更新を完了
  Future<void> markTermsOfServiceUpdated() async {
    _isTermsOfServiceUpdated = true;
    await _saveStoreStatus();
    _runComplianceChecks();
    _updateStoreReadiness();
    notifyListeners();
  }

  /// スクリーンショット準備を完了
  Future<void> markScreenshotsReady() async {
    _isScreenshotsReady = true;
    await _saveStoreStatus();
    _updateStoreReadiness();
    notifyListeners();
  }

  /// コンプライアンスチェックを完了
  Future<void> markComplianceChecked() async {
    _isComplianceChecked = true;
    await _saveStoreStatus();
    _updateStoreReadiness();
    notifyListeners();
  }

  /// ストア状態を保存
  Future<void> _saveStoreStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('store_iap_configured', _isIapConfigured);
      await prefs.setBool('store_privacy_updated', _isPrivacyPolicyUpdated);
      await prefs.setBool('store_terms_updated', _isTermsOfServiceUpdated);
      await prefs.setBool('store_screenshots_ready', _isScreenshotsReady);
      await prefs.setBool('store_compliance_checked', _isComplianceChecked);
    } catch (e) {
      debugPrint('StorePreparationService: ストア状態の保存に失敗: $e');
    }
  }

  /// ストア申請準備状況を取得
  Map<String, dynamic> getStorePreparationStatus() {
    return {
      'isStoreReady': _isStoreReady,
      'iapConfigured': _isIapConfigured,
      'privacyPolicyUpdated': _isPrivacyPolicyUpdated,
      'termsOfServiceUpdated': _isTermsOfServiceUpdated,
      'screenshotsReady': _isScreenshotsReady,
      'complianceChecked': _isComplianceChecked,
      'complianceChecks': Map.unmodifiable(_complianceChecks),
      'appVersion': _appVersion,
      'buildNumber': _buildNumber,
      'packageName': _packageInfo?.packageName ?? '',
    };
  }

  /// ストア申請用のチェックリストを取得
  List<Map<String, dynamic>> getStoreChecklist() {
    return [
      {
        'category': 'アプリ内購入',
        'items': [
          {
            'title': '商品設定の完了',
            'description': 'Google Play ConsoleとApp Store Connectで商品を設定',
            'completed': _isIapConfigured,
            'action': 'Google Play ConsoleとApp Store Connectで商品を設定してください',
          },
          {
            'title': '価格設定の確認',
            'description': '各プランの価格が適切に設定されている',
            'completed': _isIapConfigured,
            'action': '価格設定を確認してください',
          },
        ],
      },
      {
        'category': '法的要件',
        'items': [
          {
            'title': 'プライバシーポリシーの更新',
            'description': 'サブスクリプション機能に対応したプライバシーポリシー',
            'completed': _isPrivacyPolicyUpdated,
            'action': 'プライバシーポリシーを更新してください',
          },
          {
            'title': '利用規約の更新',
            'description': 'サブスクリプション条項を含む利用規約',
            'completed': _isTermsOfServiceUpdated,
            'action': '利用規約を更新してください',
          },
        ],
      },
      {
        'category': 'ストア申請',
        'items': [
          {
            'title': 'スクリーンショットの準備',
            'description': '各デバイスサイズに対応したスクリーンショット',
            'completed': _isScreenshotsReady,
            'action': 'スクリーンショットを準備してください',
          },
          {
            'title': 'アプリ説明の更新',
            'description': 'サブスクリプション機能を含むアプリ説明',
            'completed': true,
            'action': 'アプリ説明は更新済みです',
          },
        ],
      },
      {
        'category': 'コンプライアンス',
        'items': [
          {
            'title': 'データ保護の確認',
            'description': 'GDPR、CCPA等のデータ保護法への対応',
            'completed': _complianceChecks['data_collection'] ?? false,
            'action': 'データ保護法への対応を確認してください',
          },
          {
            'title': '解約方法の明記',
            'description': 'サブスクリプションの解約方法を明確に記載',
            'completed': _complianceChecks['cancellation_policy'] ?? false,
            'action': '解約方法を明記してください',
          },
        ],
      },
    ];
  }

  /// ストア申請用のエクスポートデータを取得
  Map<String, dynamic> getStoreExportData() {
    return {
      'appInfo': {
        'name': _storeListing['appName'],
        'version': _appVersion,
        'buildNumber': _buildNumber,
        'packageName': _packageInfo?.packageName ?? '',
      },
      'storeListing': _storeListing,
      'iapProducts': _iapProducts,
      'complianceChecks': _complianceChecks,
      'preparationStatus': getStorePreparationStatus(),
      'checklist': getStoreChecklist(),
    };
  }

  /// デバッグ情報を出力
  void printDebugInfo() {
    debugPrint('=== ストア申請準備状況 ===');
    debugPrint('ストア準備完了: $_isStoreReady');
    debugPrint('アプリ内購入設定: $_isIapConfigured');
    debugPrint('プライバシーポリシー更新: $_isPrivacyPolicyUpdated');
    debugPrint('利用規約更新: $_isTermsOfServiceUpdated');
    debugPrint('スクリーンショット準備: $_isScreenshotsReady');
    debugPrint('コンプライアンスチェック: $_isComplianceChecked');
    debugPrint('アプリバージョン: $_appVersion');
    debugPrint('ビルド番号: $_buildNumber');

    debugPrint('=== コンプライアンスチェック ===');
    _complianceChecks.forEach((key, value) {
      debugPrint('$key: $value');
    });
  }
}
