import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../services/one_time_purchase_service.dart';
import '../config.dart';

class InterstitialAdService {
  static final InterstitialAdService _instance =
      InterstitialAdService._internal();
  factory InterstitialAdService() => _instance;
  InterstitialAdService._internal() {
    // OneTimePurchaseServiceの状態変化を監視
    _wasPremium = OneTimePurchaseService().isPremiumUnlocked;
    OneTimePurchaseService().addListener(_onPremiumStatusChanged);
  }

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isShowingAd = false;
  int _operationCount = 0;
  static const int _showAdEveryOperations = 3;
  bool _wasPremium = false; // 前回のプレミアム状態を保持

  void _onPremiumStatusChanged() {
    final isPremium = OneTimePurchaseService().isPremiumUnlocked;

    // プレミアム状態に変化がない場合はスキップ
    if (_wasPremium == isPremium) {
      return;
    }

    // プレミアムになった場合：広告を破棄
    if (isPremium && _interstitialAd != null) {
      debugPrint('🔧 プレミアムになったため、インタースティシャル広告を破棄します');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isAdLoaded = false;
      _wasPremium = true;
    }
    // プレミアムが切れた場合：広告を再読み込みし、プレミアム解除時の広告を表示する機会を増やす
    else if (!isPremium && !_isAdLoaded && !_isShowingAd) {
      debugPrint('🔧 プレミアムが切れたため、インタースティシャル広告を再読み込みします');
      _wasPremium = false;
      // オペレーションカウントを調整して広告表示の機会を増やす
      if (_operationCount % _showAdEveryOperations != 0) {
        _operationCount = _operationCount +
            (_showAdEveryOperations -
                (_operationCount % _showAdEveryOperations));
      }
      loadAd();

      // プレミアム解除直後に広告を表示する機会を増やす（少し遅延させてから）
      Future.delayed(const Duration(seconds: 2), () {
        showAdOnPremiumChange();
      });
    }
  }

  /// プレミアム状態変化時のインタースティシャル広告表示
  Future<void> showAdOnPremiumChange() async {
    if (_isShowingAd) return;

    final purchaseService = OneTimePurchaseService();
    if (!purchaseService.isInitialized || purchaseService.isPremiumUnlocked) {
      return;
    }

    if (_isAdLoaded && _interstitialAd != null) {
      debugPrint('🎯 プレミアム状態変化時にインタースティシャル広告を表示します');
      try {
        _isShowingAd = true;
        await _interstitialAd!.show();
      } catch (e) {
        debugPrint('❌ プレミアム状態変化時のインタースティシャル広告表示失敗: $e');
        _isShowingAd = false;
        _isAdLoaded = false;
        loadAd();
      }
    }
  }

  /// 広告の読み込み（既に読み込み済みならスキップ）
  Future<void> loadAd() async {
    if (_isAdLoaded || _isShowingAd) return;

    // OneTimePurchaseServiceの初期化を待つ
    final purchaseService = OneTimePurchaseService();
    int waitCount = 0;
    while (!purchaseService.isInitialized && waitCount < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      waitCount++;
    }

    debugPrint('🔧 インタースティシャル広告読み込みチェック開始');
    debugPrint('🔧 OneTimePurchaseService状態:');
    debugPrint('🔧 isInitialized: ${purchaseService.isInitialized}');
    debugPrint('🔧 isPremiumUnlocked: ${purchaseService.isPremiumUnlocked}');
    debugPrint('🔧 isPremiumPurchased: ${purchaseService.isPremiumPurchased}');
    debugPrint('🔧 isTrialActive: ${purchaseService.isTrialActive}');
    debugPrint('🔧 デバッグモード設定値: $configEnableDebugMode');

    if (purchaseService.isPremiumUnlocked) {
      debugPrint('🔧 プレミアムユーザーのため、インタースティシャル広告の読み込みをスキップします');
      debugPrint('🔧 プレミアム状態の詳細:');
      debugPrint(
          '🔧   - isPremiumUnlocked: ${purchaseService.isPremiumUnlocked}');
      debugPrint(
          '🔧   - isPremiumPurchased: ${purchaseService.isPremiumPurchased}');
      debugPrint('🔧   - isTrialActive: ${purchaseService.isTrialActive}');
      return;
    }

    try {
      // バナー広告の後に読み込むため待機
      await Future.delayed(const Duration(milliseconds: 5000));

      // デバッグモード時の設定
      debugPrint('🔧 インタースティシャル広告読み込み開始');
      debugPrint('🔧 インタースティシャル広告ID: $adInterstitialUnitId');
      debugPrint(
          '🔧 現在の広告状態: _isAdLoaded=$_isAdLoaded, _isShowingAd=$_isShowingAd');

      await InterstitialAd.load(
        adUnitId: adInterstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('✅ インタースティシャル広告読み込み成功');
            debugPrint('🔧 インタースティシャル広告オブジェクト: ${ad.toString()}');
            _interstitialAd = ad;
            _isAdLoaded = true;

            _interstitialAd!.fullScreenContentCallback =
                FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                _isShowingAd = false;
                ad.dispose();
                _isAdLoaded = false;
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
            debugPrint('🔍 エラー詳細: $error');

            if (error.message.contains('JavascriptEngine') ||
                error.message.contains('WebView') ||
                error.message.contains('Renderer')) {
              debugPrint('🔄 WebViewエラーを検出、15秒後に再試行します');
              Future.delayed(const Duration(seconds: 15), () {
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
    // 最初の操作後、さらに遅延させてから広告を読み込む
    if (_operationCount == 1) {
      Future.delayed(const Duration(seconds: 5), () {
        loadAd();
      });
    }
  }

  bool shouldShowAd() {
    if (_isShowingAd) {
      debugPrint('🔧 インタースティシャル広告表示条件チェック: 既に広告表示中');
      return false;
    }

    final purchaseService = OneTimePurchaseService();
    if (!purchaseService.isInitialized) {
      debugPrint('🔧 インタースティシャル広告表示条件チェック: OneTimePurchaseServiceの初期化待機中');
      return false;
    }

    if (purchaseService.isPremiumUnlocked) {
      debugPrint('🔧 インタースティシャル広告表示条件チェック: プレミアムユーザー（広告非表示）');
      return false;
    }

    if (!_isAdLoaded || _interstitialAd == null) {
      debugPrint('🔧 インタースティシャル広告表示条件チェック: 広告が読み込まれていない');
      debugPrint('🔧   - _isAdLoaded: $_isAdLoaded');
      debugPrint('🔧   - _interstitialAd: ${_interstitialAd != null}');
      return false;
    }

    final shouldShow = _operationCount % _showAdEveryOperations == 0;
    debugPrint('🔧 インタースティシャル広告表示条件チェック:');
    debugPrint('🔧   - _operationCount: $_operationCount');
    debugPrint('🔧   - _showAdEveryOperations: $_showAdEveryOperations');
    debugPrint(
        '🔧   - 計算結果: $_operationCount % $_showAdEveryOperations == 0 = $shouldShow');

    return shouldShow;
  }

  Future<void> showAdIfReady() async {
    if (shouldShowAd()) {
      debugPrint('✅ インタースティシャル広告を表示します');
      try {
        _isShowingAd = true;
        await _interstitialAd!.show();
      } catch (e) {
        debugPrint('❌ インタースティシャル広告表示失敗: $e');
        _isShowingAd = false;
        _isAdLoaded = false;
        loadAd();
      }
    } else {
      debugPrint('🔧 インタースティシャル広告表示条件を満たしていません');
    }
  }

  void resetSession() {
    _operationCount = 0;
    _isShowingAd = false;
    loadAd();
  }

  void dispose() {
    OneTimePurchaseService().removeListener(_onPremiumStatusChanged);
    _interstitialAd?.dispose();
    _isAdLoaded = false;
    _isShowingAd = false;
  }
}
