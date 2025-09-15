import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/subscription_integration_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _hasDisposed = true;
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() async {
    // WebViewの初期化を待つ（より長い時間）
    await Future.delayed(const Duration(milliseconds: 2000));

    // Google Mobile Adsの初期化状態を確認
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ['4A1374DD02BA1DF5AA510337859580DB'], // テスト用
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        ),
      );
    } catch (e) {
      // リクエスト設定の更新に失敗
    }

    _bannerAd = BannerAd(
      // 秘匿情報をソースに埋め込まないため、dart-define から注入
      // セキュリティ根拠: リポジトリ上に本番用IDが残らない
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
          debugPrint('❌ バナー広告読み込み失敗: ${error.message}');
          debugPrint('🔍 エラーコード: ${error.code}');

          // WebViewエラーの場合は再試行
          if (error.message.contains('JavascriptEngine') ||
              error.message.contains('WebView') ||
              error.message.contains('Renderer')) {
            debugPrint('🔄 WebViewエラーを検出、3秒後に再試行します');
            Future.delayed(const Duration(seconds: 3), () {
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
        // サブスクリプションプランで広告非表示の場合は広告を非表示
        if (subscriptionService.shouldHideAds) {
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
      },
    );
  }
}
