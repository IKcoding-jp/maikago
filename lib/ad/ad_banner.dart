import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/subscription_integration_service.dart';
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

    // プレミアムになった場合：広告を破棄
    if (isPremium && _bannerAd != null) {
      debugPrint('🔧 プレミアムになったため、バナー広告を破棄します');
      _bannerAd?.dispose();
      _bannerAd = null;
      _isLoaded = false;
      _wasPremium = true;
      if (mounted) {
        setState(() {});
      }
    }
    // プレミアムが切れた場合：広告を再読み込み
    else if (!isPremium && !_isLoaded) {
      debugPrint('🔧 プレミアムが切れたため、バナー広告を再読み込みします');
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
    // プレミアムユーザーの場合は広告読み込みをスキップ
    final subscriptionService = SubscriptionIntegrationService();
    final bool forceShowAdsForDebug = configEnableDebugMode;

    // OneTimePurchaseServiceの初期化を待つ
    await Future.delayed(const Duration(milliseconds: 1500));

    debugPrint('🔧 広告読み込みチェック開始');
    debugPrint('🔧 サブスクリプションサービス状態:');
    debugPrint('🔧 isInitialized: ${subscriptionService.isInitialized}');
    debugPrint(
        '🔧 isPremiumUnlocked: ${subscriptionService.isPremiumUnlocked}');
    debugPrint(
        '🔧 isPremiumPurchased: ${subscriptionService.isPremiumPurchased}');
    debugPrint('🔧 isTrialActive: ${subscriptionService.isTrialActive}');
    debugPrint('🔧 shouldHideAds: ${subscriptionService.shouldHideAds}');
    debugPrint('🔧 shouldShowAds: ${subscriptionService.shouldShowAds()}');
    debugPrint('🔧 デバッグモード広告強制表示: $forceShowAdsForDebug');
    debugPrint('🔧 デバッグモード設定値: $configEnableDebugMode');

    if (subscriptionService.shouldHideAds && !forceShowAdsForDebug) {
      debugPrint('🔧 プレミアムユーザーのため、バナー広告の読み込みをスキップします');
      debugPrint('🔧 プレミアム状態の詳細:');
      debugPrint(
          '🔧   - isPremiumUnlocked: ${subscriptionService.isPremiumUnlocked}');
      debugPrint(
          '🔧   - isPremiumPurchased: ${subscriptionService.isPremiumPurchased}');
      debugPrint('🔧   - isTrialActive: ${subscriptionService.isTrialActive}');
      return;
    }

    // WebViewの初期化とGoogle Mobile Ads SDKの準備を待つ
    await Future.delayed(const Duration(milliseconds: 2000));

    debugPrint('🔧 バナー広告読み込み開始');
    debugPrint('🔧 広告ユニットID: $adBannerUnitId');
    debugPrint('🔧 広告サイズ: AdSize.banner');

    _bannerAd = BannerAd(
      // 秘匿情報をソースに埋め込まないため、dart-define から注入
      // セキュリティ根拠: リポジトリ上に本番用IDが残らない
      adUnitId: adBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ バナー広告読み込み成功');
          debugPrint('🔧 広告オブジェクト: ${ad.toString()}');
          if (!_hasDisposed && mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ バナー広告読み込み失敗: ${error.message}');
          debugPrint('🔍 エラーコード: ${error.code}');
          debugPrint('🔍 エラー詳細: $error');

          // WebViewエラーの場合は再試行（より長い間隔で）
          if (error.message.contains('JavascriptEngine') ||
              error.message.contains('WebView') ||
              error.message.contains('Renderer')) {
            debugPrint('🔄 WebViewエラーを検出、10秒後に再試行します');
            Future.delayed(const Duration(seconds: 10), () {
              if (!_hasDisposed && mounted) {
                _loadBannerAd();
              }
            });
          }

          ad.dispose();
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionIntegrationService>(
      builder: (context, subscriptionService, child) {
        // デバッグモードで広告強制表示テスト（一時的に有効化）
        final bool forceShowAdsForDebug = configEnableDebugMode;

        // サブスクリプションプランで広告非表示の場合は広告を非表示
        if (subscriptionService.shouldHideAds && !forceShowAdsForDebug) {
          debugPrint('🔧 広告が非表示: プレミアムユーザーまたはトライアル中');
          debugPrint(
              '🔧 isPremiumUnlocked: ${subscriptionService.isPremiumUnlocked}');
          debugPrint('🔧 isTrialActive: ${subscriptionService.isTrialActive}');
          debugPrint('🔧 デバッグモード広告強制表示: $forceShowAdsForDebug');
          return const SizedBox.shrink();
        }

        // 広告が読み込まれていない場合も非表示
        if (!_isLoaded || _bannerAd == null) {
          debugPrint(
              '🔧 広告が読み込まれていないため非表示: _isLoaded=$_isLoaded, _bannerAd=${_bannerAd != null}');
          debugPrint(
              '🔧 プレミアム状態確認: shouldHideAds=${subscriptionService.shouldHideAds}, forceShowAdsForDebug=$forceShowAdsForDebug');
          return const SizedBox.shrink();
        }

        debugPrint('✅ バナー広告を表示します');
        debugPrint(
            '🔧 広告サイズ: ${_bannerAd!.size.width.toDouble()} x ${_bannerAd!.size.height.toDouble()}');
        return RepaintBoundary(
          child: SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        );
      },
    );
  }
}
