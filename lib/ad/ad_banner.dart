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
    debugPrint('📺 バナー広告の読み込み開始');
    debugPrint('📺 広告ユニットID: $adBannerUnitId');

    // WebViewの初期化を待つ（より長い時間）
    await Future.delayed(const Duration(milliseconds: 2000));

    // Google Mobile Adsの初期化状態を確認
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ['TEST_DEVICE_ID'], // テスト用
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        ),
      );
      debugPrint('📺 リクエスト設定を更新しました');
    } catch (e) {
      debugPrint('❌ リクエスト設定の更新に失敗: $e');
    }

    _bannerAd = BannerAd(
      // 秘匿情報をソースに埋め込まないため、dart-define から注入
      // セキュリティ根拠: リポジトリ上に本番用IDが残らない
      adUnitId: adBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ バナー広告の読み込み成功');
          if (!_hasDisposed && mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ バナー広告の読み込みに失敗: $error');
          debugPrint('❌ エラーコード: ${error.code}');
          debugPrint('❌ エラーメッセージ: ${error.message}');
          debugPrint('❌ エラードメイン: ${error.domain}');
          debugPrint('❌ トラブルシューティング:');
          debugPrint('   1. ネットワーク接続を確認');
          debugPrint('   2. Google Mobile Adsの初期化状態を確認');
          debugPrint('   3. 広告ユニットIDが正しいか確認');
          debugPrint('   4. AdMobアカウントの設定を確認');
          debugPrint('   5. WebViewの初期化状態を確認');

          // WebViewエラーの場合は再試行
          if (error.message.contains('JavascriptEngine')) {
            debugPrint('🔄 WebViewエラーを検出 - 3秒後に再試行します');
            Future.delayed(const Duration(seconds: 3), () {
              if (!_hasDisposed && mounted) {
                debugPrint('🔄 バナー広告の再読み込みを開始');
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
        // デバッグ情報を出力
        debugPrint('=== バナー広告表示判定 ===');
        debugPrint('サブスクリプションによる広告非表示: ${subscriptionService.shouldHideAds}');
        debugPrint('広告読み込み状態: $_isLoaded');
        debugPrint('広告オブジェクト存在: ${_bannerAd != null}');
        debugPrint(
            '現在のプラン: ${subscriptionService.currentPlan?.name ?? 'フリープラン'}');
        debugPrint(
            'プランのshowAds設定: ${subscriptionService.currentPlan?.showAds}');

        // サブスクリプションプランで広告非表示の場合は広告を非表示
        if (subscriptionService.shouldHideAds) {
          debugPrint('サブスクリプションによりバナー広告を非表示');
          return const SizedBox.shrink();
        }

        // 広告が読み込まれていない場合も非表示
        if (!_isLoaded || _bannerAd == null) {
          debugPrint('広告が読み込まれていないためバナー広告を非表示');
          return const SizedBox.shrink();
        }

        debugPrint('バナー広告を表示');
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
