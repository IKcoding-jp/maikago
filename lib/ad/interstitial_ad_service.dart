import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../services/subscription_integration_service.dart';
import '../config.dart';

class InterstitialAdService {
  static final InterstitialAdService _instance =
      InterstitialAdService._internal();
  factory InterstitialAdService() => _instance;
  InterstitialAdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isShowingAd = false;
  int _adShowCount = 0;
  int _operationCount = 0;
  static const int _showAdEveryOperations = 5;
  static const int _maxAdsPerSession = 2;

  /// 広告の読み込み（既に読み込み済みならスキップ）
  Future<void> loadAd() async {
    if (_isAdLoaded || _isShowingAd) return;

    // プレミアムユーザーの場合は広告読み込みをスキップ
    final subscriptionService = SubscriptionIntegrationService();
    if (subscriptionService.shouldHideAds) {
      if (configEnableDebugMode) {
        debugPrint('🔧 プレミアムユーザーのため、インタースティシャル広告の読み込みをスキップします');
      }
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 2000));

      // デバッグモード時の設定
      if (configEnableDebugMode) {
        debugPrint('🔧 デバッグモード: インタースティシャル広告IDを使用します');
        debugPrint('🔧 インタースティシャル広告ID: $adInterstitialUnitId');
      }

      await InterstitialAd.load(
        adUnitId: adInterstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isAdLoaded = true;

            _interstitialAd!.fullScreenContentCallback =
                FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                _isShowingAd = false;
                ad.dispose();
                _isAdLoaded = false;
                _adShowCount++;
                loadAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _isShowingAd = false;
                ad.dispose();
                _isAdLoaded = false;
                loadAd();
              },
              onAdShowedFullScreenContent: (ad) {
                _isShowingAd = true;
              },
            );
          },
          onAdFailedToLoad: (error) {
            _isAdLoaded = false;
            debugPrint('❌ インタースティシャル広告読み込み失敗: ${error.message}');
            debugPrint('🔍 エラーコード: ${error.code}');

            if (error.message.contains('JavascriptEngine') ||
                error.message.contains('WebView') ||
                error.message.contains('Renderer')) {
              debugPrint('🔄 WebViewエラーを検出、5秒後に再試行します');
              Future.delayed(const Duration(seconds: 5), () {
                loadAd();
              });
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ インタースティシャル広告読み込み例外: $e');
      _isAdLoaded = false;
    }
  }

  void incrementOperationCount() {
    _operationCount++;
    if (_operationCount == 1) {
      loadAd();
    }
  }

  bool shouldShowAd() {
    if (_isShowingAd) return false;

    final subscriptionService = SubscriptionIntegrationService();
    if (subscriptionService.shouldHideAds) return false;

    if (!_isAdLoaded || _interstitialAd == null) return false;

    if (_adShowCount >= _maxAdsPerSession) return false;

    return _operationCount % _showAdEveryOperations == 0;
  }

  Future<void> showAdIfReady() async {
    if (shouldShowAd()) {
      try {
        _isShowingAd = true;
        await _interstitialAd!.show();
      } catch (e) {
        _isShowingAd = false;
        _isAdLoaded = false;
        loadAd();
      }
    }
  }

  void resetSession() {
    _adShowCount = 0;
    _operationCount = 0;
    _isShowingAd = false;
    loadAd();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _isAdLoaded = false;
    _isShowingAd = false;
  }
}
