import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // テスト用のインタースティシャル広告ユニットID
  final String _adUnitId = 'ca-app-pub-3940256099942544/1033173712';

  // シングルトンパターンで実装
  static final InterstitialAdManager _instance =
      InterstitialAdManager._internal();
  factory InterstitialAdManager() => _instance;
  InterstitialAdManager._internal();

  bool get isAdLoaded => _isAdLoaded;

  Future<void> loadAd() async {
    try {
      await InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isAdLoaded = true;
            print('インタースティシャル広告が読み込まれました');
          },
          onAdFailedToLoad: (error) {
            _interstitialAd = null;
            _isAdLoaded = false;
            print('インタースティシャル広告の読み込みに失敗しました: $error');
          },
        ),
      );
    } catch (e) {
      print('インタースティシャル広告の読み込み中にエラーが発生しました: $e');
    }
  }

  Future<void> showAd() async {
    if (_interstitialAd != null && _isAdLoaded) {
      try {
        await _interstitialAd!.show();
        _isAdLoaded = false;
        _interstitialAd = null;
        // 広告表示後に新しい広告を読み込む
        loadAd();
      } catch (e) {
        print('インタースティシャル広告の表示中にエラーが発生しました: $e');
      }
    } else {
      print('インタースティシャル広告が読み込まれていません');
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
  }
}
