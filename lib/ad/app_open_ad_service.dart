import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/one_time_purchase_service.dart';
import '../config.dart';

/// アプリ起動広告（App Open Ads）管理マネージャー
/// Googleドキュメントのベストプラクティスに基づく実装
class AppOpenAdManager {
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal() {
    // OneTimePurchaseServiceの状態変化を監視
    _wasPremium = OneTimePurchaseService().isPremiumUnlocked;
    OneTimePurchaseService().addListener(_onPremiumStatusChanged);
  }

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _appOpenAdLoadTime;
  bool _wasPremium = false; // 前回のプレミアム状態を保持
  int _loadAttempts = 0; // 読み込み試行回数
  static const int _maxLoadAttempts = 3; // 最大読み込み試行回数

  // 広告の最大キャッシュ時間（4時間）
  static const Duration maxCacheDuration = Duration(hours: 4);

  // アプリ使用回数の追跡（ユーザーがアプリを数回使用した後に広告を表示するため）
  static int _appUsageCount = 0;
  static const int _minUsageCountBeforeAd = 3; // 3回目以降から広告を表示

  /// プラットフォーム別の広告ユニットIDを取得
  String get _adUnitId {
    if (configEnableDebugMode) {
      return 'ca-app-pub-3940256099942544/3419836394'; // Google公式テスト広告ID
    }

    final unitId = adAppOpenUnitId;
    if (unitId.contains('1234567890') ||
        unitId == 'ca-app-pub-3940256099942544/3419836394') {
      return 'ca-app-pub-3940256099942544/3419836394'; // フォールバックとしてテスト広告IDを使用
    }

    return unitId;
  }

  /// アプリ起動広告の読み込み状態
  bool get isAdAvailable {
    return _appOpenAd != null;
  }

  /// アプリ起動広告の表示状態
  bool get isShowingAd => _isShowingAd;

  /// デバッグ用：現在の状態を取得
  Map<String, dynamic> getDebugInfo() {
    return {
      'isAdAvailable': isAdAvailable,
      'isShowingAd': _isShowingAd,
      'wasPremium': _wasPremium,
      'appOpenAd': _appOpenAd != null,
      'loadTime': _appOpenAdLoadTime,
      'usageCount': _appUsageCount,
    };
  }

  /// プレミアム状態変化時の処理
  void _onPremiumStatusChanged() {
    final isPremium = OneTimePurchaseService().isPremiumUnlocked;

    // プレミアム状態に変化がない場合はスキップ
    if (_wasPremium == isPremium) {
      return;
    }

    if (isPremium && _appOpenAd != null) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _appOpenAdLoadTime = null;
      _wasPremium = true;
    } else if (!isPremium && !isAdAvailable && !_isShowingAd) {
      _wasPremium = false;
      loadAd();
    }
  }

  /// アプリ起動広告を読み込む
  void loadAd() {
    if (isAdAvailable || _isShowingAd) {
      return;
    }

    _loadAttempts = 0;

    final purchaseService = OneTimePurchaseService();
    // 初期化完了を待つ
    if (!purchaseService.isInitialized) {
      debugPrint('🔧 アプリ起動広告: OneTimePurchaseServiceの初期化待機中');
      return;
    }

    if (purchaseService.isPremiumUnlocked) {
      debugPrint('🔧 アプリ起動広告: プレミアムユーザーのため広告読み込みをスキップ');
      return;
    }

    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenAdLoadTime = DateTime.now();

          _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _isShowingAd = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              _isShowingAd = false;
              ad.dispose();
              _appOpenAd = null;
              _appOpenAdLoadTime = null;
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isShowingAd = false;
              ad.dispose();
              _appOpenAd = null;
              _appOpenAdLoadTime = null;
              loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _appOpenAdLoadTime = null;
          _loadAttempts++;

          if (_loadAttempts < _maxLoadAttempts) {
            Future.delayed(const Duration(seconds: 2), () {
              loadAd();
            });
          } else {
            _loadAttempts = 0;
          }
        },
      ),
    );
  }

  /// アプリ起動広告を表示する（読み込み済みの場合のみ）
  /// Googleドキュメントのベストプラクティスに基づく実装
  void showAdIfAvailable() {
    final purchaseService = OneTimePurchaseService();
    // 初期化完了を待つ
    if (!purchaseService.isInitialized) {
      debugPrint('🔧 アプリ起動広告: OneTimePurchaseServiceの初期化待機中');
      return;
    }

    if (purchaseService.isPremiumUnlocked) {
      debugPrint('🔧 アプリ起動広告: プレミアムユーザーのため広告表示をスキップ');
      return;
    }

    if (!isAdAvailable) {
      loadAd();
      return;
    }

    if (_isShowingAd) {
      return;
    }

    if (DateTime.now()
        .subtract(maxCacheDuration)
        .isAfter(_appOpenAdLoadTime!)) {
      _appOpenAd!.dispose();
      _appOpenAd = null;
      _appOpenAdLoadTime = null;
      loadAd();
      return;
    }

    if (_appUsageCount < _minUsageCountBeforeAd) {
      return;
    }

    _isShowingAd = true;
    _appOpenAd!.show();
  }

  /// アプリ使用回数を記録（広告表示タイミングの制御用）
  void recordAppUsage() {
    _appUsageCount++;

    if (_appUsageCount >= _minUsageCountBeforeAd &&
        !isAdAvailable &&
        !_isShowingAd) {
      final purchaseService = OneTimePurchaseService();
      if (purchaseService.isInitialized && !purchaseService.isPremiumUnlocked) {
        loadAd();
      }
    }
  }

  /// リソースを解放
  void dispose() {
    OneTimePurchaseService().removeListener(_onPremiumStatusChanged);
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _appOpenAdLoadTime = null;
    _isShowingAd = false;
  }
}
