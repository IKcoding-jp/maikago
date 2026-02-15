import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:maikago/services/one_time_purchase_service.dart';
import 'package:maikago/config.dart';
import 'package:maikago/services/debug_service.dart';

/// アプリ起動広告（App Open Ads）管理マネージャー
/// Googleドキュメントのベストプラクティスに基づく実装
class AppOpenAdManager {
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal() {
    // OneTimePurchaseServiceの状態変化を監視
    _wasPremium = OneTimePurchaseService().isPremiumUnlocked;
    OneTimePurchaseService().addListener(_onPremiumStatusChanged);
  }

  static final AppOpenAdManager _instance = AppOpenAdManager._internal();

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

  /// 広告ユニットID（常に本番IDを利用）
  String get _adUnitId => adAppOpenUnitId;

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
    try {
      if (isAdAvailable || _isShowingAd) {
        DebugService().log('🔧 アプリ起動広告: 既に読み込み済みまたは表示中のためスキップ');
        return;
      }

      final purchaseService = OneTimePurchaseService();
      // 初期化完了を待つ
      if (!purchaseService.isInitialized) {
        DebugService().log('🔧 アプリ起動広告: OneTimePurchaseServiceの初期化待機中');
        return;
      }

      if (purchaseService.isPremiumUnlocked) {
        DebugService().log('🔧 アプリ起動広告: プレミアムユーザーのため広告読み込みをスキップ');
        return;
      }

      DebugService().log(
          '🔧 アプリ起動広告: 広告読み込み開始（試行回数: ${_loadAttempts + 1}/$_maxLoadAttempts）');

      AppOpenAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            DebugService().log('✅ アプリ起動広告: 読み込み成功');
            _appOpenAd = ad;
            _appOpenAdLoadTime = DateTime.now();
            _loadAttempts = 0; // 成功時はリセット

            _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                DebugService().log('🔧 アプリ起動広告: 表示開始');
                _isShowingAd = true;
              },
              onAdDismissedFullScreenContent: (ad) {
                DebugService().log('🔧 アプリ起動広告: 表示終了');
                _isShowingAd = false;
                ad.dispose();
                _appOpenAd = null;
                _appOpenAdLoadTime = null;
                // 次の広告を読み込み
                Future.delayed(const Duration(seconds: 1), () {
                  loadAd();
                });
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                DebugService().log('❌ アプリ起動広告: 表示失敗 - $error');
                _isShowingAd = false;
                ad.dispose();
                _appOpenAd = null;
                _appOpenAdLoadTime = null;
                // エラー後は少し待ってから再読み込み
                Future.delayed(const Duration(seconds: 3), () {
                  loadAd();
                });
              },
            );
          },
          onAdFailedToLoad: (error) {
            DebugService().log('❌ アプリ起動広告: 読み込み失敗 - $error');
            _appOpenAd = null;
            _appOpenAdLoadTime = null;
            _loadAttempts++;

            if (_loadAttempts < _maxLoadAttempts) {
              DebugService().log(
                  '🔧 アプリ起動広告: リトライします（$_loadAttempts/$_maxLoadAttempts）');
              Future.delayed(Duration(seconds: 2 + _loadAttempts), () {
                loadAd();
              });
            } else {
              DebugService().log('❌ アプリ起動広告: 最大試行回数に達したため読み込みを停止');
              _loadAttempts = 0;
            }
          },
        ),
      );
    } catch (e, stackTrace) {
      DebugService().log('❌ アプリ起動広告読み込みエラー: $e');
      DebugService().log('❌ スタックトレース: $stackTrace');
      _appOpenAd = null;
      _appOpenAdLoadTime = null;
    }
  }

  /// アプリ起動広告を表示する（読み込み済みの場合のみ）
  /// Googleドキュメントのベストプラクティスに基づく実装
  void showAdIfAvailable() {
    try {
      final purchaseService = OneTimePurchaseService();

      // 初期化完了を待つ
      if (!purchaseService.isInitialized) {
        DebugService().log('🔧 アプリ起動広告: OneTimePurchaseServiceの初期化待機中');
        return;
      }

      if (purchaseService.isPremiumUnlocked) {
        DebugService().log('🔧 アプリ起動広告: プレミアムユーザーのため広告表示をスキップ');
        return;
      }

      // 広告が利用可能かチェック
      if (!isAdAvailable) {
        DebugService().log('🔧 アプリ起動広告: 広告が読み込まれていないため読み込みを開始');
        loadAd();
        return;
      }

      // 既に表示中の場合はスキップ
      if (_isShowingAd) {
        DebugService().log('🔧 アプリ起動広告: 既に表示中のためスキップ');
        return;
      }

      // 広告の有効期限チェック
      if (_appOpenAdLoadTime != null &&
          DateTime.now()
              .subtract(maxCacheDuration)
              .isAfter(_appOpenAdLoadTime!)) {
        DebugService().log('🔧 アプリ起動広告: 広告の有効期限切れのため再読み込み');
        _appOpenAd!.dispose();
        _appOpenAd = null;
        _appOpenAdLoadTime = null;
        loadAd();
        return;
      }

      // 使用回数チェック
      if (_appUsageCount < _minUsageCountBeforeAd) {
        DebugService().log(
            '🔧 アプリ起動広告: 使用回数不足（$_appUsageCount/$_minUsageCountBeforeAd）');
        return;
      }

      // 広告表示前の最終チェック
      if (_appOpenAd == null) {
        DebugService().log('🔧 アプリ起動広告: 広告オブジェクトがnullのため表示をスキップ');
        return;
      }

      DebugService().log('🔧 アプリ起動広告: 広告表示を開始');
      _isShowingAd = true;
      _appOpenAd!.show();
    } catch (e, stackTrace) {
      DebugService().log('❌ アプリ起動広告表示エラー: $e');
      DebugService().log('❌ スタックトレース: $stackTrace');
      _isShowingAd = false;

      // エラー発生時は広告を破棄して再読み込み
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _appOpenAdLoadTime = null;

      // 少し待ってから再読み込みを試行
      Future.delayed(const Duration(seconds: 2), () {
        loadAd();
      });
    }
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
