import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:maikago/models/donation.dart';
import 'package:maikago/services/debug_service.dart';

/// 寄付機能を管理するサービス
class DonationService extends ChangeNotifier {
  factory DonationService() => _instance;
  DonationService._internal();

  static final DonationService _instance = DonationService._internal();

  // Firebase 依存は遅延取得
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // 状態管理
  List<Donation> _donations = [];
  final bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  String? _currentUserId;

  // Getters
  List<Donation> get donations => _donations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasDonated => _donations.isNotEmpty;

  /// 合計寄付金額
  int get totalDonationAmount =>
      _donations.fold(0, (total, donation) => total + donation.amount);

  /// 寄付回数
  int get donationCount => _donations.length;

  /// 初回寄付日時
  DateTime? get firstDonationDate => _donations.isNotEmpty
      ? _donations
          .map((d) => d.dateTime)
          .reduce((a, b) => a.isBefore(b) ? a : b)
      : null;

  /// 最終寄付日時
  DateTime? get lastDonationDate => _donations.isNotEmpty
      ? _donations.map((d) => d.dateTime).reduce((a, b) => a.isAfter(b) ? a : b)
      : null;

  /// 寄付統計情報
  DonationStats get donationStats => DonationStats(
        totalAmount: totalDonationAmount,
        totalCount: donationCount,
        firstDonationDate: firstDonationDate,
        lastDonationDate: lastDonationDate,
        donations: _donations,
      );

  /// 初期化
  Future<void> initialize() async {
    if (_isInitialized) {
      DebugService().log('寄付サービスは既に初期化済みです。');
      return;
    }

    try {
      DebugService().log('寄付サービス初期化開始');

      // 現在のユーザーIDを取得して設定
      final user = _auth.currentUser;
      _currentUserId = user?.uid;

      await _loadFromLocalStorage();
      await _loadFromFirestore();
      _isInitialized = true;
      DebugService().log('寄付サービス初期化完了');
    } catch (e) {
      DebugService().log('寄付サービス初期化エラー: $e');
      _setError('初期化に失敗しました: $e');
    }
  }

  /// 新しい寄付を追加
  void addDonation({
    required int amount,
    required String productId,
    String? transactionId,
  }) {
    final donation = Donation(
      id: const Uuid().v4(),
      amount: amount,
      dateTime: DateTime.now(),
      productId: productId,
      transactionId: transactionId,
    );

    _donations.add(donation);
    _donations.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // 新しい順にソート

    _saveToLocalStorage();
    _saveToFirestore();
    notifyListeners();

    DebugService().log('寄付を追加しました: ¥$amount (${donation.id})');
  }

  /// 寄付履歴をクリア（デバッグ用）
  void clearDonations() {
    _donations.clear();
    _saveToLocalStorage();
    _saveToFirestore();
    notifyListeners();

    DebugService().log('寄付履歴をクリアしました');
  }

  /// 特定の寄付を削除（デバッグ用）
  void removeDonation(String donationId) {
    _donations.removeWhere((donation) => donation.id == donationId);
    _saveToLocalStorage();
    _saveToFirestore();
    notifyListeners();

    DebugService().log('寄付を削除しました: $donationId');
  }

  /// ローカルストレージから読み込み
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final donationsJson = prefs.getStringList('donations') ?? [];

      _donations = donationsJson
          .map((jsonString) {
            try {
              return Donation.fromJson(Map<String, dynamic>.from(
                  Map<String, dynamic>.from({'data': jsonString})
                      .map((key, value) => MapEntry(key, value))));
            } catch (e) {
              DebugService().log('寄付データのJSONパースエラー: $e');
              return null;
            }
          })
          .where((donation) => donation != null)
          .cast<Donation>()
          .toList();

      DebugService().log('寄付データをローカルストレージから読み込み完了: ${_donations.length}件');
    } catch (e) {
      DebugService().log('寄付データローカルストレージ読み込みエラー: $e');
    }
  }

  /// ローカルストレージに保存
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final donationsJson = _donations
          .map((d) => d.toJson())
          .map((json) => json.toString())
          .toList();
      await prefs.setStringList('donations', donationsJson);

      DebugService().log('寄付データをローカルストレージに保存完了: ${_donations.length}件');
    } catch (e) {
      DebugService().log('寄付データローカルストレージ保存エラー: $e');
    }
  }

  /// Firestoreから読み込み
  Future<void> _loadFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 現在のユーザーIDを更新
      _currentUserId = user.uid;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('donations')
          .doc('donation_history')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final donationsData = data['donations'] as List<dynamic>? ?? [];

        final firestoreDonations = donationsData
            .map((json) => Donation.fromJson(json as Map<String, dynamic>))
            .toList();

        // Firestoreのデータを優先し、重複を避けるためにマージ
        _mergeDonations(firestoreDonations);

        DebugService().log(
            '寄付データをFirestoreから読み込み完了: ${_donations.length}件 (ユーザー: $user.uid)');
      } else {
        DebugService().log('寄付データなし (ユーザー: $user.uid)');
      }
    } catch (e) {
      DebugService().log('寄付データFirestore読み込みエラー: $e');
    }
  }

  /// Firestoreに保存
  Future<void> _saveToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 現在のユーザーIDを更新
      _currentUserId = user.uid;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('donations')
          .doc('donation_history')
          .set({
        'donations': _donations.map((d) => d.toJson()).toList(),
        'totalAmount': totalDonationAmount,
        'totalCount': donationCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      DebugService().log('寄付データをFirestoreに保存完了 (ユーザー: $user.uid)');
    } catch (e) {
      DebugService().log('寄付データFirestore保存エラー: $e');
    }
  }

  /// 寄付データをマージ（重複を避ける）
  void _mergeDonations(List<Donation> newDonations) {
    final existingIds = _donations.map((d) => d.id).toSet();

    for (final donation in newDonations) {
      if (!existingIds.contains(donation.id)) {
        _donations.add(donation);
      }
    }

    _donations.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// エラーをクリア
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// エラーを設定
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// アカウント切り替え時の処理
  void handleAccountSwitch(String newUserId) {
    DebugService().log('アカウント切り替え検知: $_currentUserId → $newUserId');

    // ユーザーIDが変更された場合のみ処理を実行
    if (_currentUserId != newUserId) {
      DebugService().log('アカウントが変更されました。寄付データをリセットします。');

      // 状態をリセット
      _donations.clear();
      _error = null;
      _currentUserId = newUserId;

      // 新しいユーザーのデータを読み込み
      if (newUserId.isNotEmpty) {
        _loadFromFirestore();
      }

      notifyListeners();
      DebugService().log('寄付データのリセット完了。新ユーザーID: $newUserId');
    } else {
      DebugService().log('同じユーザーIDのため、寄付データの変更は不要です。');
    }
  }

  /// デバッグ情報を取得
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'currentUserId': _currentUserId,
      'donationCount': donationCount,
      'totalAmount': totalDonationAmount,
      'hasDonated': hasDonated,
      'firstDonationDate': firstDonationDate?.toIso8601String(),
      'lastDonationDate': lastDonationDate?.toIso8601String(),
      'donations': _donations.map((d) => d.toJson()).toList(),
      'error': _error,
      'isLoading': _isLoading,
    };
  }
}
