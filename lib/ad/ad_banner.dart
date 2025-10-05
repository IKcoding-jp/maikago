import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/one_time_purchase_service.dart';
import '../config.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _hasDisposed = false;
  bool _wasPremium = false; // 前回のプレミアム状態を保持

  @override
  void initState() {
    super.initState();
    // OneTimePurchaseServiceの状態変化を監視
    _wasPremium = OneTimePurchaseService().isPremiumUnlocked;
    OneTimePurchaseService().addListener(_onPremiumStatusChanged);
    _loadBannerAd();
  }

  void _onPremiumStatusChanged() {
    final isPremium = OneTimePurchaseService().isPremiumUnlocked;

    // プレミアム状態に変化がない場合はスキップ
    if (_wasPremium == isPremium) {
      return;
    }

    if (isPremium && _bannerAd != null) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isLoaded = false;
      _wasPremium = true;
      if (mounted) {
        setState(() {});
      }
    } else if (!isPremium && !_isLoaded) {
      _wasPremium = false;
      _loadBannerAd();
    }
  }

  @override
  void dispose() {
    _hasDisposed = true;
    OneTimePurchaseService().removeListener(_onPremiumStatusChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() async {
    if (_hasDisposed || !mounted) {
      return;
    }
    final bool forceShowAdsForDebug = configEnableDebugMode;

    // OneTimePurchaseServiceの初期化を待つ
    final purchaseService = OneTimePurchaseService();
    int waitCount = 0;
    while (!purchaseService.isInitialized && waitCount < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      waitCount++;
    }

    if (_hasDisposed || !mounted) {
      return;
    }

    // プレミアム状態をより確実にチェック
    if (purchaseService.isPremiumUnlocked && !forceShowAdsForDebug) {
      debugPrint('🔧 バナー広告: プレミアムユーザーのため広告読み込みをスキップ');
      return;
    }

    // WebViewの初期化とGoogle Mobile Ads SDKの準備を待つ
    await Future.delayed(const Duration(milliseconds: 2000));
    if (_hasDisposed || !mounted) {
      return;
    }

    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;

    final bannerAd = BannerAd(
      adUnitId: adBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!_hasDisposed && mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          if (error.message.contains('JavascriptEngine') ||
              error.message.contains('WebView') ||
              error.message.contains('Renderer')) {
            Future.delayed(const Duration(seconds: 10), () {
              if (!_hasDisposed && mounted) {
                _loadBannerAd();
              }
            });
          }

          ad.dispose();
          _bannerAd = null;
          _isLoaded = false;
        },
      ),
    );

    if (_hasDisposed || !mounted) {
      bannerAd.dispose();
      return;
    }

    _bannerAd = bannerAd;
    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    final bool forceShowAdsForDebug = configEnableDebugMode;

    // プレミアム機能で広告非表示の場合は広告を非表示
    final purchaseService = OneTimePurchaseService();
    if (purchaseService.isPremiumUnlocked && !forceShowAdsForDebug) {
      debugPrint('🔧 バナー広告: プレミアムユーザーのため広告を非表示');
      return const SizedBox.shrink();
    }

    // 広告が読み込まれていない場合も非表示
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
