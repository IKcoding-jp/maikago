// 寄付状態（特典/広告非表示/テーマ解放）をアプリ全体に提供
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ad/interstitial_ad_service.dart';

/// 寄付状態を管理するクラス。
/// - 300円以上の寄付で特典有効（広告非表示/テーマ/フォント解放）
/// - Firebase と SharedPreferences による二重永続化
/// - 認証ユーザー単位で状態を管理
class DonationManager extends ChangeNotifier {
  static final DonationManager _instance = DonationManager._internal();
  factory DonationManager() => _instance;
  DonationManager._internal() {
    _loadDonationStatus();
  }

  static const String _isDonatedKey = 'isDonated';
  static const String _totalDonationAmountKey = 'totalDonationAmount';

  /// 特典の有無（寄付済みか）
  bool _isDonated = false;
  bool _isRestoring = false;
  int _totalDonationAmount = 0;
  String? _currentUserId;

  /// 寄付済みかどうか
  bool get isDonated => _isDonated;

  /// 総寄付金額
  int get totalDonationAmount => _totalDonationAmount;

  /// 寄付者称号を取得
  String get donorTitle {
    if (!_isDonated) return '';
    return 'サポーター';
  }

  /// 称号の色を取得
  Color get donorTitleColor {
    if (!_isDonated) return Colors.grey;
    return const Color(0xFF4CAF50); // グリーン
  }

  /// 称号アイコンを取得
  IconData get donorTitleIcon {
    if (!_isDonated) return Icons.person;
    return Icons.favorite;
  }

  /// 特典が有効かどうか（寄付済みの場合）
  bool get hasBenefits => _isDonated;

  /// 広告を非表示にするかどうか
  bool get shouldHideAds => _isDonated;

  /// テーマ変更機能が利用可能かどうか
  bool get canChangeTheme => _isDonated;

  /// フォント変更機能が利用可能かどうか
  bool get canChangeFont => _isDonated;

  /// 復元処理中かどうか
  bool get isRestoring => _isRestoring;

  /// 現在のユーザーIDを設定（切り替え時に状態を再読込/リセット）
  void setCurrentUserId(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      if (userId != null) {
        _loadDonationStatus();
      } else {
        // ログアウト時は状態をリセット
        _resetDonationStatus();
      }
    }
  }

  /// 寄付状態をリセット（ログアウト時用）
  void _resetDonationStatus() {
    _isDonated = false;
    _totalDonationAmount = 0;
    notifyListeners();
  }

  /// 寄付状態を永続化から読み込み
  Future<void> _loadDonationStatus() async {
    try {
      // ユーザーがログインしていない場合は何もしない
      if (_currentUserId == null) {
        _resetDonationStatus();
        return;
      }

      // Firebaseからユーザー固有の寄付状態を読み込み
      await _loadDonationStatusFromFirebase();

      // ローカルに保存されていない場合は購入履歴を確認
      if (!_isDonated) {
        await _restoreDonationStatus();
      }

      // 特定のメールアドレスに寄付状態を付与
      await _checkSpecialDonorStatus();

      notifyListeners();
    } catch (e) {
      debugPrint('寄付状態の読み込みエラー: $e');
    }
  }

  /// Firebaseからユーザー固有の寄付状態を読み込み
  Future<void> _loadDonationStatusFromFirebase() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('donations')
          .doc('status');

      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        _isDonated = data['isDonated'] ?? false;
        _totalDonationAmount = data['totalAmount'] ?? 0;
        debugPrint(
          'Firebaseから寄付状態を読み込みました: 寄付済み=$_isDonated, 総額=$_totalDonationAmount',
        );
      } else {
        // ドキュメントが存在しない場合は初期状態
        _isDonated = false;
        _totalDonationAmount = 0;
      }
    } catch (e) {
      debugPrint('Firebaseからの寄付状態読み込みエラー: $e');
      // エラー時は初期状態に設定
      _isDonated = false;
      _totalDonationAmount = 0;
    }
  }

  /// 特定のメールアドレスに寄付状態を付与（開発者向けの特別付与）
  Future<void> _checkSpecialDonorStatus() async {
    try {
      // 現在のユーザーのメールアドレスを取得
      final currentUser = FirebaseAuth.instance.currentUser;
      final userEmail = currentUser?.email;

      if (userEmail != null && userEmail == 'kensaku.ikeda04@gmail.com') {
        if (!_isDonated) {
          _isDonated = true;
          _totalDonationAmount = 1000; // 1000円の寄付として設定
          await _saveDonationStatus();
          debugPrint('特別寄付者として寄付状態を付与しました: $userEmail');
        }
      }
    } catch (e) {
      debugPrint('特別寄付者チェックエラー: $e');
    }
  }

  /// 購入履歴から寄付状態を復元（IAPの restorePurchases を起動）
  Future<void> _restoreDonationStatus() async {
    try {
      _isRestoring = true;
      notifyListeners();

      final InAppPurchase inAppPurchase = InAppPurchase.instance;

      // アプリ内購入が利用可能かチェック
      final bool available = await inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('アプリ内購入が利用できません');
        return;
      }

      // 購入履歴を復元
      await inAppPurchase.restorePurchases();

      // 購入ストリームで復元された購入を監視
      // 実際の復元処理は購入ストリームで行われるため、
      // ここでは復元処理の開始のみを行う
      debugPrint('購入履歴の復元を開始しました');
    } catch (e) {
      debugPrint('寄付状態の復元エラー: $e');
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// 寄付状態を永続化に保存（Firebase/SharedPreferences）
  Future<void> _saveDonationStatus() async {
    try {
      // Firebaseにユーザー固有の寄付状態を保存
      await _saveDonationStatusToFirebase();

      // ローカルにも保存（バックアップ用）
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${_currentUserId}_$_isDonatedKey', _isDonated);
      await prefs.setInt(
        '${_currentUserId}_$_totalDonationAmountKey',
        _totalDonationAmount,
      );
    } catch (e) {
      debugPrint('寄付状態の保存エラー: $e');
    }
  }

  /// Firebaseにユーザー固有の寄付状態を保存
  Future<void> _saveDonationStatusToFirebase() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('donations')
          .doc('status');

      await docRef.set({
        'isDonated': _isDonated,
        'totalAmount': _totalDonationAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        'Firebaseに寄付状態を保存しました: 寄付済み=$_isDonated, 総額=$_totalDonationAmount',
      );
    } catch (e) {
      debugPrint('Firebaseへの寄付状態保存エラー: $e');
    }
  }

  /// 寄付処理を実行。300円以上の場合は特典を有効にする。
  Future<void> processDonation(int amount) async {
    if (amount >= 300) {
      _isDonated = true;
      _totalDonationAmount += amount;
      await _saveDonationStatus();
      notifyListeners();

      // インタースティシャル広告サービスをリセットして広告表示を停止
      try {
        InterstitialAdService().resetSession();
      } catch (e) {
        debugPrint('インタースティシャル広告サービスのリセットエラー: $e');
      }

      debugPrint('寄付特典が有効になりました: ¥$amount (総額: ¥$_totalDonationAmount)');
    }
  }

  /// 購入履歴から寄付状態を手動で復元
  Future<void> restoreDonationStatus() async {
    await _restoreDonationStatus();
  }

  /// 寄付状態をリセット（テスト用）
  Future<void> resetDonationStatus() async {
    _isDonated = false;
    _totalDonationAmount = 0;
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

  /// 寄付を追加する（テスト用）
  Future<void> addDonation(int amount) async {
    _isDonated = true;
    _totalDonationAmount += amount;
    await _saveDonationStatus();
    notifyListeners();
    debugPrint('寄付を追加しました: ¥$amount (総額: ¥$_totalDonationAmount)');
  }

  /// 寄付状態を強制有効化する（テスト用）
  Future<void> forceEnableDonation() async {
    _isDonated = true;
    _totalDonationAmount = 1000; // デフォルトで1000円設定
    await _saveDonationStatus();
    notifyListeners();
    debugPrint('寄付状態を強制有効化しました');
  }
}
