// インタースティシャル広告の読込/表示管理と寄付状態による抑制ロジック
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/donation_manager.dart';

class InterstitialAdService {
  static final InterstitialAdService _instance =
      InterstitialAdService._internal();
  factory InterstitialAdService() => _instance;
  InterstitialAdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  int _adShowCount = 0;
  int _operationCount = 0;
  static const int _showAdEveryOperations = 5; // 5回の操作ごとに広告を表示
  static const int _maxAdsPerSession = 2; // セッションあたり最大2回（より緩和）
  static const bool _isDebugMode = true; // デバッグモードフラグ

  /// 広告の読み込み（既に読み込み済みならスキップ）
  Future<void> loadAd() async {
    if (_isAdLoaded) return;

    try {
      await InterstitialAd.load(
        adUnitId:
            'ca-app-pub-3940256099942544/1033173712', // テスト用インタースティシャル広告ユニットID
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
                    ad.dispose();
                    _isAdLoaded = false;
                    _adShowCount++;
                    // 次の広告を事前に読み込み
                    loadAd();
                  },
                  onAdFailedToShowFullScreenContent: (ad, error) {
                    ad.dispose();
                    _isAdLoaded = false;
                    debugPrint('インタースティシャル広告の表示に失敗: $error');
                    // 次の広告を事前に読み込み
                    loadAd();
                  },
                );
          },
          onAdFailedToLoad: (error) {
            _isAdLoaded = false;
            debugPrint('インタースティシャル広告の読み込みに失敗: $error');
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

  /// 広告表示の判定（寄付済なら常に非表示、セッション内上限・間隔で制御）
  bool shouldShowAd() {
    // 寄付済みの場合は広告を表示しない
    // DonationManagerのシングルトンインスタンスを使用
    final donationManager = DonationManager();
    if (donationManager.shouldHideAds) {
      if (_isDebugMode) {
        debugPrint(
          '寄付済みのため、広告を表示しません (shouldHideAds: ${donationManager.shouldHideAds})',
        );
      }
      return false;
    }

    // 広告が読み込まれていない場合は表示しない
    if (!_isAdLoaded || _interstitialAd == null) {
      if (_isDebugMode) {
        debugPrint(
          '広告が読み込まれていません: isLoaded=$_isAdLoaded, ad=${_interstitialAd != null}',
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
        '広告表示判定: 操作$_operationCount回目, 表示間隔$_showAdEveryOperations回, 表示するか: $shouldShow',
      );
    }
    return shouldShow;
  }

  /// 条件を満たしていれば広告を表示
  Future<void> showAdIfReady() async {
    if (shouldShowAd()) {
      if (_isDebugMode) {
        debugPrint('インタースティシャル広告を表示します');
      }
      try {
        await _interstitialAd!.show();
      } catch (e) {
        debugPrint('インタースティシャル広告の表示中にエラーが発生: $e');
        _isAdLoaded = false;
        loadAd(); // 次の広告を読み込み
      }
    } else {
      if (_isDebugMode) {
        debugPrint('インタースティシャル広告の表示条件を満たしていません');
      }
    }
  }

  /// セッションリセット（アプリ起動時など）
  void resetSession() {
    _adShowCount = 0;
    _operationCount = 0;
    loadAd(); // 新しいセッション用の広告を読み込み
  }

  /// 広告の破棄
  void dispose() {
    _interstitialAd?.dispose();
    _isAdLoaded = false;
  }

  /// デバッグ用：現在の状態を取得
  Map<String, dynamic> getDebugInfo() {
    return {
      'isAdLoaded': _isAdLoaded,
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
    if (_isAdLoaded && _interstitialAd != null) {
      debugPrint('デバッグ用：強制的にインタースティシャル広告を表示します');
      try {
        await _interstitialAd!.show();
      } catch (e) {
        debugPrint('強制表示中にエラーが発生: $e');
      }
    } else {
      debugPrint('デバッグ用：広告が読み込まれていないため、強制表示できません');
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
    loadAd();
  }
}
