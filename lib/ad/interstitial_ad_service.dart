// インタースティシャル広告の読込/表示管理とサブスクリプションプランによる抑制ロジック
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/subscription_integration_service.dart';
import '../config.dart';

class InterstitialAdService {
  static final InterstitialAdService _instance =
      InterstitialAdService._internal();
  factory InterstitialAdService() => _instance;
  InterstitialAdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isShowingAd = false; // 広告表示中フラグを追加
  int _adShowCount = 0;
  int _operationCount = 0;
  static const int _showAdEveryOperations = 5; // 5回の操作ごとに広告を表示
  static const int _maxAdsPerSession = 2; // セッションあたり最大2回（より緩和）
  static const bool _isDebugMode = true; // デバッグモードフラグ

  /// 広告の読み込み（既に読み込み済みならスキップ）
  Future<void> loadAd() async {
    if (_isAdLoaded || _isShowingAd) return; // 表示中は読み込みをスキップ

    try {
      // WebViewの初期化を待つ（より長い時間）
      await Future.delayed(const Duration(milliseconds: 2000));

      await InterstitialAd.load(
        // 秘匿情報をソースに埋め込まないため、dart-define から注入
        // セキュリティ根拠: リポジトリ上に本番用IDが残らない
        adUnitId: adInterstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isAdLoaded = true;
            debugPrint('インタースティシャル広告が読み込まれました');

            // 広告が閉じられた時の処理
            _interstitialAd!.fullScreenContentCallback =
                FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('🎬 インタースティシャル広告が閉じられました');
                _isShowingAd = false; // 表示中フラグをリセット
                ad.dispose();
                _isAdLoaded = false;
                _adShowCount++;
                debugPrint('📊 広告表示回数更新: $_adShowCount');
                // 次の広告を事前に読み込み
                loadAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('❌ インタースティシャル広告の表示に失敗: $error');
                _isShowingAd = false; // 表示中フラグをリセット
                ad.dispose();
                _isAdLoaded = false;
                // 次の広告を事前に読み込み
                loadAd();
              },
              onAdShowedFullScreenContent: (ad) {
                debugPrint('🎬 インタースティシャル広告が表示されました');
                _isShowingAd = true; // 表示中フラグを設定
              },
            );
          },
          onAdFailedToLoad: (error) {
            _isAdLoaded = false;
            debugPrint('インタースティシャル広告の読み込みに失敗: $error');

            // WebViewエラーの場合は再試行
            if (error.message.contains('JavascriptEngine')) {
              debugPrint('🔄 インタースティシャル広告のWebViewエラーを検出 - 5秒後に再試行します');
              Future.delayed(const Duration(seconds: 5), () {
                loadAd();
              });
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('インタースティシャル広告の読み込み中にエラーが発生: $e');
    }
  }

  /// 操作回数をカウント（一定回数ごとに広告表示を検討）
  void incrementOperationCount() {
    _operationCount++;

    if (_isDebugMode) {
      debugPrint('操作カウント: $_operationCount, 広告表示回数: $_adShowCount');
    }

    // セッション開始時に広告を読み込み
    if (_operationCount == 1) {
      loadAd();
    }
  }

  /// 広告表示の判定（サブスクリプションプランなら常に非表示、セッション内上限・間隔で制御）
  bool shouldShowAd() {
    if (_isDebugMode) {
      debugPrint('=== インタースティシャル広告表示判定 ===');
    }

    // 既に広告を表示中の場合は表示しない
    if (_isShowingAd) {
      if (_isDebugMode) {
        debugPrint('インタースティシャル広告が既に表示中のため、表示しません');
      }
      return false;
    }

    // サブスクリプションプランで広告非表示の場合は広告を表示しない
    final subscriptionService = SubscriptionIntegrationService();
    if (subscriptionService.shouldHideAds) {
      if (_isDebugMode) {
        debugPrint(
          'サブスクリプションプランで広告非表示のため、インタースティシャル広告を表示しません (shouldHideAds: ${subscriptionService.shouldHideAds})',
        );
        debugPrint(
          '現在のプラン: ${subscriptionService.currentPlan?.name ?? 'フリープラン'}',
        );
        debugPrint(
          'プランのshowAds設定: ${subscriptionService.currentPlan?.showAds}',
        );
      }
      return false;
    }

    // 広告が読み込まれていない場合は表示しない
    if (!_isAdLoaded || _interstitialAd == null) {
      if (_isDebugMode) {
        debugPrint(
          'インタースティシャル広告が読み込まれていません: isLoaded=$_isAdLoaded, ad=${_interstitialAd != null}',
        );
      }
      return false;
    }

    // セッションあたりの最大表示回数を超えている場合は表示しない
    if (_adShowCount >= _maxAdsPerSession) {
      if (_isDebugMode) {
        debugPrint('最大表示回数に達しました: $_adShowCount/$_maxAdsPerSession');
      }
      return false;
    }

    // 一定回数の操作ごとに広告を表示
    final shouldShow = _operationCount % _showAdEveryOperations == 0;
    if (_isDebugMode) {
      debugPrint(
        'インタースティシャル広告表示判定: 操作$_operationCount回目, 表示間隔$_showAdEveryOperations回, 表示するか: $shouldShow',
      );
      if (shouldShow) {
        debugPrint('インタースティシャル広告を表示します');
      }
    }
    return shouldShow;
  }

  /// 条件を満たしていれば広告を表示
  Future<void> showAdIfReady() async {
    if (shouldShowAd()) {
      if (_isDebugMode) {
        debugPrint('🎬 インタースティシャル広告を表示します');
        debugPrint(
            '📊 広告状態: isLoaded=$_isAdLoaded, isShowing=$_isShowingAd, ad=${_interstitialAd != null}');
      }
      try {
        _isShowingAd = true; // 表示開始前にフラグを設定
        await _interstitialAd!.show();
        if (_isDebugMode) {
          debugPrint('✅ インタースティシャル広告表示リクエスト完了');
        }
      } catch (e) {
        debugPrint('❌ インタースティシャル広告の表示中にエラーが発生: $e');
        _isShowingAd = false; // エラー時はフラグをリセット
        _isAdLoaded = false;
        loadAd(); // 次の広告を読み込み
      }
    } else {
      if (_isDebugMode) {
        debugPrint('⏭️ インタースティシャル広告の表示条件を満たしていません');
        debugPrint(
            '📊 現在の状態: isLoaded=$_isAdLoaded, isShowing=$_isShowingAd, ad=${_interstitialAd != null}');
      }
    }
  }

  /// セッションリセット（アプリ起動時など）
  void resetSession() {
    _adShowCount = 0;
    _operationCount = 0;
    _isShowingAd = false; // 表示中フラグもリセット
    loadAd(); // 新しいセッション用の広告を読み込み
  }

  /// 広告の破棄
  void dispose() {
    _interstitialAd?.dispose();
    _isAdLoaded = false;
    _isShowingAd = false; // 表示中フラグもリセット
  }

  /// デバッグ用：現在の状態を取得
  Map<String, dynamic> getDebugInfo() {
    return {
      'isAdLoaded': _isAdLoaded,
      'isShowingAd': _isShowingAd, // 表示中フラグも含める
      'adShowCount': _adShowCount,
      'operationCount': _operationCount,
      'shouldShowAd': shouldShowAd(),
      'isDebugMode': _isDebugMode,
      'showAdEveryOperations': _showAdEveryOperations,
      'maxAdsPerSession': _maxAdsPerSession,
    };
  }

  /// デバッグ用：強制で広告を表示（テスト用）
  Future<void> forceShowAd() async {
    if (_isAdLoaded && _interstitialAd != null && !_isShowingAd) {
      debugPrint('デバッグ用：強制的にインタースティシャル広告を表示します');
      try {
        _isShowingAd = true;
        await _interstitialAd!.show();
      } catch (e) {
        debugPrint('強制表示中にエラーが発生: $e');
        _isShowingAd = false;
      }
    } else {
      debugPrint('デバッグ用：広告が読み込まれていないか、既に表示中のため、強制表示できません');
      loadAd(); // 広告を読み込み直す
    }
  }

  /// デバッグ用：即座に広告を表示（テスト用）
  Future<void> showAdImmediately() async {
    debugPrint('デバッグ用：即座にインタースティシャル広告を表示します');
    _operationCount = _showAdEveryOperations; // 表示条件を満たすように設定
    await showAdIfReady();
  }

  /// デバッグ用：セッションをリセット
  void resetForDebug() {
    debugPrint('デバッグ用：セッションをリセットします');
    _adShowCount = 0;
    _operationCount = 0;
    _isShowingAd = false; // 表示中フラグもリセット
    loadAd();
  }
}
