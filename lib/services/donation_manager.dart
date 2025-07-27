import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 寄付状態を管理するクラス
/// 300円以上の寄付をしたユーザーの特典状態を管理
class DonationManager extends ChangeNotifier {
  static const String _isDonatedKey = 'isDonated';

  bool _isDonated = false;

  /// 寄付済みかどうか
  bool get isDonated => _isDonated;

  /// 特典が有効かどうか（寄付済みの場合）
  bool get hasBenefits => _isDonated;

  /// 広告を非表示にするかどうか
  bool get shouldHideAds => _isDonated;

  /// テーマ変更機能が利用可能かどうか
  bool get canChangeTheme => _isDonated;

  /// フォント変更機能が利用可能かどうか
  bool get canChangeFont => _isDonated;

  DonationManager() {
    _loadDonationStatus();
  }

  /// 寄付状態を永続化から読み込み
  Future<void> _loadDonationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDonated = prefs.getBool(_isDonatedKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('寄付状態の読み込みエラー: $e');
    }
  }

  /// 寄付状態を永続化に保存
  Future<void> _saveDonationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isDonatedKey, _isDonated);
    } catch (e) {
      debugPrint('寄付状態の保存エラー: $e');
    }
  }

  /// 寄付処理を実行
  /// 300円以上の場合は特典を有効にする
  Future<void> processDonation(int amount) async {
    if (amount >= 300 && !_isDonated) {
      _isDonated = true;
      await _saveDonationStatus();
      notifyListeners();
      debugPrint('寄付特典が有効になりました: ¥$amount');
    }
  }

  /// 寄付状態をリセット（テスト用）
  Future<void> resetDonationStatus() async {
    _isDonated = false;
    await _saveDonationStatus();
    notifyListeners();
    debugPrint('寄付状態をリセットしました');
  }

  /// 寄付状態を強制的に有効にする（テスト用）
  Future<void> enableDonationBenefits() async {
    _isDonated = true;
    await _saveDonationStatus();
    notifyListeners();
    debugPrint('寄付特典を強制的に有効にしました');
  }
}
