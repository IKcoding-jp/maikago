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
    // サブスクリプション状態を確認してから広告を読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final subscriptionService =
            Provider.of<SubscriptionIntegrationService>(context, listen: false);
        if (subscriptionService.shouldHideAds) {
          debugPrint('サブスクリプションによりバナー広告の読み込みもスキップ');
          return;
        }
        _loadBannerAd();
      } catch (_) {
        // Provider 未構築タイミングの保険
        _loadBannerAd();
      }
    });
  }

  @override
  void dispose() {
    _hasDisposed = true;
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
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

        // サブスクリプションプランで広告非表示の場合は広告を非表示（ロード済みなら破棄）
        if (subscriptionService.shouldHideAds) {
          debugPrint('サブスクリプションによりバナー広告を非表示');
          if (_bannerAd != null) {
            _bannerAd?.dispose();
            _bannerAd = null;
            _isLoaded = false;
          }
          return const SizedBox.shrink();
        }

        // これまで非表示で読み込んでいなかった場合、ここでロードを開始
        if (_bannerAd == null && !_isLoaded) {
          _loadBannerAd();
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
