// サブスクリプション状態（プラン/特典/広告非表示/テーマ解放）をアプリ全体に提供
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../config.dart';
import '../config/subscription_ids.dart';
import 'debug_service.dart';

/// サブスクリプションプランの種類
enum SubscriptionPlan {
  free, // フリープラン
  basic, // ベーシックプラン
  premium, // プレミアムプラン
  family, // ファミリープラン
}

/// サブスクリプション状態を管理するクラス。
/// - 4つのプラン（フリー、ベーシック、プレミアム、ファミリー）
/// - Firebase と SharedPreferences による二重永続化
/// - 認証ユーザー単位で状態を管理
/// - DonationManagerとの互換性を保持
/// - デバッグ・最適化機能を統合
class SubscriptionManager extends ChangeNotifier {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal() {
    _loadSubscriptionStatus();
    _startTrialCheckTimer();
  }

  // デバッグサービス
  final DebugService _debugService = DebugService();

  // 永続化キー
  static const String _currentPlanKey = 'currentPlan';
  static const String _subscriptionExpiryKey = 'subscriptionExpiry';
  static const String _familyMembersKey = 'familyMembers';
  static const String _isActiveKey = 'isActive';
  static const String _trialStartDateKey = 'trialStartDate';
  static const String _trialUsedKey = 'trialUsed';

  // サブスクリプション状態
  SubscriptionPlan _currentPlan = SubscriptionPlan.free;
  DateTime? _subscriptionExpiry;
  List<String> _familyMembers = [];
  bool _isActive = false;
  bool _isRestoring = false;
  String? _currentUserId;

  // 無料トライアル状態
  DateTime? _trialStartDate;
  bool _trialUsed = false;

  // タイマー
  Timer? _trialCheckTimer;

  // プラン定義
  static const Map<SubscriptionPlan, Map<String, dynamic>> _planDefinitions = {
    SubscriptionPlan.free: {
      'name': 'フリープラン',
      'price': 0,
      'maxLists': 3,
      'maxItemsPerList': 10, // 各リスト内の商品アイテム数制限
      'showAds': true,
      'themes': 1,
      'fonts': 1,
      'familySharing': false,
      'maxFamilyMembers': 0,
      'productId': null,
    },
    SubscriptionPlan.basic: {
      'name': 'ベーシックプラン',
      'price': 120,
      'maxLists': -1, // 無制限
      'maxItemsPerList': 50, // 各リスト内の商品アイテム数制限
      'showAds': false,
      'themes': 5,
      'fonts': 3,
      'familySharing': false,
      'maxFamilyMembers': 0,
      'productId': SubscriptionIds.basicMonthly,
      'yearlyProductId': SubscriptionIds.basicYearly,
    },
    SubscriptionPlan.premium: {
      'name': 'プレミアムプラン',
      'price': 240,
      'maxLists': -1, // 無制限
      'maxItemsPerList': -1, // 無制限
      'showAds': false,
      'themes': -1, // 全テーマ
      'fonts': -1, // 全フォント
      'familySharing': true,
      'maxFamilyMembers': 5,
      'productId': SubscriptionIds.premiumMonthly,
      'yearlyProductId': SubscriptionIds.premiumYearly,
    },
    SubscriptionPlan.family: {
      'name': 'ファミリープラン',
      'price': 360,
      'maxLists': -1, // 無制限
      'maxItemsPerList': -1, // 無制限
      'showAds': false,
      'themes': -1, // 全テーマ
      'fonts': -1, // 全フォント
      'familySharing': true,
      'maxFamilyMembers': 10,
      'productId': SubscriptionIds.familyMonthly,
      'yearlyProductId': SubscriptionIds.familyYearly,
    },
  };

  // Getters
  SubscriptionPlan get currentPlan => _currentPlan;
  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  List<String> get familyMembers => List.unmodifiable(_familyMembers);
  bool get isActive => _isActive;
  bool get isRestoring => _isRestoring;

  // 無料トライアル関連
  DateTime? get trialStartDate => _trialStartDate;
  bool get trialUsed => _trialUsed;

  /// 無料トライアルが利用可能かどうか
  bool get canUseTrial => !_trialUsed;

  /// 無料トライアルが有効かどうか
  bool get isTrialActive {
    if (_trialStartDate == null) return false;
    final trialEndDate = _trialStartDate!.add(const Duration(days: 7));
    return DateTime.now().isBefore(trialEndDate);
  }

  /// 無料トライアルの残り日数を取得
  int get trialRemainingDays {
    if (_trialStartDate == null) return 0;
    final trialEndDate = _trialStartDate!.add(const Duration(days: 7));
    final remaining = trialEndDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// 無料トライアルの終了日
  DateTime? get trialEndDate {
    if (_trialStartDate == null) return null;
    return _trialStartDate!.add(const Duration(days: 7));
  }

  /// 現在のプラン名を取得
  String get currentPlanName => _planDefinitions[_currentPlan]!['name'];

  /// 現在のプラン価格を取得
  int get currentPlanPrice => _planDefinitions[_currentPlan]!['price'];

  /// 現在のプランの最大リスト数を取得
  int get maxLists => _planDefinitions[_currentPlan]!['maxLists'];

  /// 現在のプランの各リスト内の最大商品アイテム数を取得
  int get maxItemsPerList => _planDefinitions[_currentPlan]!['maxItemsPerList'];

  /// 現在のプランの広告表示設定を取得
  bool get showAds => _planDefinitions[_currentPlan]!['showAds'];

  /// 現在のプランのテーマ数を取得
  int get themes => _planDefinitions[_currentPlan]!['themes'];

  /// 現在のプランのフォント数を取得
  int get fonts => _planDefinitions[_currentPlan]!['fonts'];

  /// 現在のプランの家族共有設定を取得
  bool get familySharing => _planDefinitions[_currentPlan]!['familySharing'];

  /// 現在のプランの最大家族メンバー数を取得
  int get maxFamilyMembers =>
      _planDefinitions[_currentPlan]!['maxFamilyMembers'];

  /// 現在のプランの商品IDを取得（月額）
  String? get productId => _planDefinitions[_currentPlan]!['productId'];

  /// 現在のプランの年額商品IDを取得
  String? get yearlyProductId =>
      _planDefinitions[_currentPlan]!['yearlyProductId'];

  /// サブスクリプションが有効かどうか（期限切れでない）
  bool get hasBenefits => (_isActive && !_isExpired) || isTrialActive;

  /// サブスクリプションが期限切れかどうか
  bool get _isExpired {
    if (_subscriptionExpiry == null) return true;
    return DateTime.now().isAfter(_subscriptionExpiry!);
  }

  /// 広告を非表示にするかどうか
  bool get shouldHideAds => !showAds && hasBenefits;

  /// テーマ変更機能が利用可能かどうか
  bool get canChangeTheme => themes > 1 && hasBenefits;

  /// フォント変更機能が利用可能かどうか
  bool get canChangeFont => fonts > 1 && hasBenefits;

  /// サブスクリプション状態を読み込み
  Future<void> _loadSubscriptionStatus() async {
    _debugService.startPerformanceTimer('loadSubscriptionStatus');

    try {
      if (enableDebugMode) {
        debugPrint('SubscriptionManager: サブスクリプション状態の読み込みを開始');
      }

      // ローカルから読み込み
      await _loadSubscriptionStatusFromLocal();

      // Firebaseから読み込み（認証済みの場合）
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _currentUserId = currentUser.uid;
        if (enableDebugMode) {
          debugPrint('SubscriptionManager: 認証ユーザーを検出: ${currentUser.uid}');
        }
        await _loadSubscriptionStatusFromFirebase();
      }

      // 期限切れチェック
      if (_isActive && _isExpired) {
        if (enableDebugMode) {
          debugPrint('SubscriptionManager: サブスクリプションが期限切れです');
        }
        await _handleExpiredSubscription();
      }

      // 無料トライアル期限切れチェック
      if (isTrialActive && trialRemainingDays == 0) {
        if (enableDebugMode) {
          debugPrint('SubscriptionManager: 無料トライアルが期限切れです');
        }
        await _handleExpiredTrial();
      }

      if (enableDebugMode) {
        debugPrint(
          'SubscriptionManager: 読み込み完了 - プラン: $_currentPlan, 有効: $_isActive, 期限: $_subscriptionExpiry',
        );
      }

      // デバッグ情報を記録
      _debugService.recordFeatureUsage('subscription_load');

      notifyListeners();
    } catch (e, stackTrace) {
      _debugService.logError('サブスクリプション状態の読み込みエラー', e, stackTrace);
      if (enableDebugMode) {
        debugPrint('サブスクリプション状態の読み込みエラー: $e');
      }
    } finally {
      _debugService.stopPerformanceTimer('loadSubscriptionStatus');
    }
  }

  /// ローカルからサブスクリプション状態を読み込み
  Future<void> _loadSubscriptionStatusFromLocal() async {
    _debugService.startPerformanceTimer('loadFromLocal');

    try {
      final prefs = await SharedPreferences.getInstance();
      final planIndex = prefs.getInt('${_currentUserId}_$_currentPlanKey') ?? 0;
      final expiryTimestamp = prefs.getInt(
        '${_currentUserId}_$_subscriptionExpiryKey',
      );
      final familyMembersJson =
          prefs.getStringList('${_currentUserId}_$_familyMembersKey') ?? [];
      final isActive =
          prefs.getBool('${_currentUserId}_$_isActiveKey') ?? false;
      final trialStartTimestamp = prefs.getInt(
        '${_currentUserId}_$_trialStartDateKey',
      );
      final trialUsed =
          prefs.getBool('${_currentUserId}_$_trialUsedKey') ?? false;

      _currentPlan = SubscriptionPlan.values[planIndex];
      _subscriptionExpiry = expiryTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(expiryTimestamp)
          : null;
      _familyMembers = familyMembersJson;
      _isActive = isActive;
      _trialStartDate = trialStartTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(trialStartTimestamp)
          : null;
      _trialUsed = trialUsed;

      if (enableDebugMode) {
        debugPrint(
          'ローカルからサブスクリプション状態を読み込みました: プラン=$_currentPlan, 有効=$_isActive, 期限=$_subscriptionExpiry',
        );
      }
    } catch (e, stackTrace) {
      _debugService.logError('ローカルからのサブスクリプション状態読み込みエラー', e, stackTrace);
      if (enableDebugMode) {
        debugPrint('ローカルからのサブスクリプション状態読み込みエラー: $e');
      }
      // エラー時は初期状態のまま
    } finally {
      _debugService.stopPerformanceTimer('loadFromLocal');
    }
  }

  /// Firebaseからユーザー固有のサブスクリプション状態を読み込み
  Future<void> _loadSubscriptionStatusFromFirebase() async {
    _debugService.startPerformanceTimer('loadFromFirebase');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('subscriptions')
          .doc('status');

      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final planIndex = data['currentPlan'] ?? 0;
        final expiryTimestamp = data['subscriptionExpiry'];
        final familyMembers = List<String>.from(data['familyMembers'] ?? []);
        final isActive = data['isActive'] ?? false;
        final trialStartTimestamp = data['trialStartDate'];
        final trialUsed = data['trialUsed'] ?? false;

        _currentPlan = SubscriptionPlan.values[planIndex];
        _subscriptionExpiry = expiryTimestamp != null
            ? (expiryTimestamp as Timestamp).toDate()
            : null;
        _familyMembers = familyMembers;
        _isActive = isActive;
        _trialStartDate = trialStartTimestamp != null
            ? (trialStartTimestamp as Timestamp).toDate()
            : null;
        _trialUsed = trialUsed;

        if (enableDebugMode) {
          debugPrint(
            'Firebaseからサブスクリプション状態を読み込みました: プラン=$_currentPlan, 有効=$_isActive, 期限=$_subscriptionExpiry',
          );
        }
      } else {
        // ドキュメントが存在しない場合は初期状態
        _currentPlan = SubscriptionPlan.free;
        _subscriptionExpiry = null;
        _familyMembers.clear();
        _isActive = false;
        if (enableDebugMode) {
          debugPrint('Firebaseにサブスクリプション状態ドキュメントが存在しません');
        }
      }
    } catch (e, stackTrace) {
      _debugService.logError('Firebaseからのサブスクリプション状態読み込みエラー', e, stackTrace);
      if (enableDebugMode) {
        debugPrint('Firebaseからのサブスクリプション状態読み込みエラー: $e');
        debugPrint('ローカル保存のみで継続します');
      }
    } finally {
      _debugService.stopPerformanceTimer('loadFromFirebase');
    }
  }

  /// 期限切れサブスクリプションの処理
  Future<void> _handleExpiredSubscription() async {
    _debugService.startPerformanceTimer('handleExpiredSubscription');

    try {
      _isActive = false;
      _currentPlan = SubscriptionPlan.free;
      _subscriptionExpiry = null;
      _familyMembers.clear();

      await _saveSubscriptionStatus();

      if (enableDebugMode) {
        debugPrint('サブスクリプションが期限切れのため、フリープランに戻しました');
      }
    } catch (e, stackTrace) {
      _debugService.logError('期限切れサブスクリプション処理エラー', e, stackTrace);
    } finally {
      _debugService.stopPerformanceTimer('handleExpiredSubscription');
    }
  }

  /// 期限切れ無料トライアルの処理
  Future<void> _handleExpiredTrial() async {
    _debugService.startPerformanceTimer('handleExpiredTrial');

    try {
      _currentPlan = SubscriptionPlan.free;
      _trialUsed = true;

      await _saveSubscriptionStatus();

      if (enableDebugMode) {
        debugPrint('無料トライアルが期限切れのため、フリープランに戻しました');
      }
    } catch (e, stackTrace) {
      _debugService.logError('期限切れ無料トライアル処理エラー', e, stackTrace);
    } finally {
      _debugService.stopPerformanceTimer('handleExpiredTrial');
    }
  }

  /// サブスクリプション状態を永続化に保存
  Future<void> _saveSubscriptionStatus() async {
    _debugService.startPerformanceTimer('saveSubscriptionStatus');

    try {
      // まずローカルに保存（確実に保存するため）
      await _saveSubscriptionStatusToLocal();

      // Firebaseにユーザー固有のサブスクリプション状態を保存（オプション）
      await _saveSubscriptionStatusToFirebase();
    } catch (e, stackTrace) {
      _debugService.logError('サブスクリプション状態の保存エラー', e, stackTrace);
      if (enableDebugMode) {
        debugPrint('サブスクリプション状態の保存エラー: $e');
      }
    } finally {
      _debugService.stopPerformanceTimer('saveSubscriptionStatus');
    }
  }

  /// ローカルにサブスクリプション状態を保存
  Future<void> _saveSubscriptionStatusToLocal() async {
    _debugService.startPerformanceTimer('saveToLocal');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        '${_currentUserId}_$_currentPlanKey',
        _currentPlan.index,
      );
      await prefs.setInt(
        '${_currentUserId}_$_subscriptionExpiryKey',
        _subscriptionExpiry?.millisecondsSinceEpoch ?? 0,
      );
      await prefs.setStringList(
        '${_currentUserId}_$_familyMembersKey',
        _familyMembers,
      );
      await prefs.setBool('${_currentUserId}_$_isActiveKey', _isActive);
      await prefs.setInt(
        '${_currentUserId}_$_trialStartDateKey',
        _trialStartDate?.millisecondsSinceEpoch ?? 0,
      );
      await prefs.setBool('${_currentUserId}_$_trialUsedKey', _trialUsed);

      if (enableDebugMode) {
        debugPrint(
          'ローカルにサブスクリプション状態を保存しました: プラン=$_currentPlan, 有効=$_isActive, 期限=$_subscriptionExpiry',
        );
      }
    } catch (e, stackTrace) {
      _debugService.logError('ローカルへのサブスクリプション状態保存エラー', e, stackTrace);
      if (enableDebugMode) {
        debugPrint('ローカルへのサブスクリプション状態保存エラー: $e');
      }
      rethrow;
    } finally {
      _debugService.stopPerformanceTimer('saveToLocal');
    }
  }

  /// Firebaseにユーザー固有のサブスクリプション状態を保存
  Future<void> _saveSubscriptionStatusToFirebase() async {
    _debugService.startPerformanceTimer('saveToFirebase');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('subscriptions')
          .doc('status');

      // クライアントからのサブスクリプション状態書き込みは既定で禁止
      if (!allowClientSubscriptionWrite) {
        if (enableDebugMode) {
          debugPrint('subscriptions書き込みはクライアントから無効化されています');
        }
        return;
      }

      await docRef.set({
        'currentPlan': _currentPlan.index,
        'subscriptionExpiry': _subscriptionExpiry != null
            ? Timestamp.fromDate(_subscriptionExpiry!)
            : null,
        'familyMembers': _familyMembers,
        'isActive': _isActive,
        'trialStartDate': _trialStartDate != null
            ? Timestamp.fromDate(_trialStartDate!)
            : null,
        'trialUsed': _trialUsed,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (enableDebugMode) {
        debugPrint(
          'Firebaseにサブスクリプション状態を保存しました: プラン=$_currentPlan, 有効=$_isActive, 期限=$_subscriptionExpiry',
        );
      }
    } catch (e, stackTrace) {
      _debugService.logError('Firebaseへのサブスクリプション状態保存エラー', e, stackTrace);
      if (enableDebugMode) {
        debugPrint('Firebaseへのサブスクリプション状態保存エラー: $e');
        debugPrint('ローカル保存のみで継続します');
      }
    } finally {
      _debugService.stopPerformanceTimer('saveToFirebase');
    }
  }

  /// サブスクリプション処理を実行
  Future<void> processSubscription(
    SubscriptionPlan plan, {
    DateTime? expiry,
  }) async {
    _debugService.startPerformanceTimer('processSubscription');

    try {
      _currentPlan = plan;
      _subscriptionExpiry = expiry;
      _isActive = expiry != null && !_isExpired;

      if (enableDebugMode) {
        debugPrint('サブスクリプション処理: プラン=$plan, 期限=$expiry, 有効=$_isActive');
      }

      await _saveSubscriptionStatus();

      // デバッグ情報を記録
      _debugService.recordFeatureUsage('subscription_process');
      _debugService.recordFeatureUsage('subscription_plan_${plan.name}');

      notifyListeners();
    } catch (e, stackTrace) {
      _debugService.logError('サブスクリプション処理エラー', e, stackTrace);
      rethrow;
    } finally {
      _debugService.stopPerformanceTimer('processSubscription');
    }
  }

  /// 無料トライアルを開始
  Future<void> startFreeTrial() async {
    _debugService.startPerformanceTimer('startFreeTrial');

    try {
      if (_trialUsed) {
        throw Exception('無料トライアルは既に使用済みです');
      }

      _trialStartDate = DateTime.now();
      _currentPlan = SubscriptionPlan.premium; // プレミアムプランでトライアル開始

      if (enableDebugMode) {
        debugPrint('無料トライアルを開始しました: $_trialStartDate');
      }

      await _saveSubscriptionStatus();

      // デバッグ情報を記録
      _debugService.recordFeatureUsage('free_trial_start');

      notifyListeners();
    } catch (e, stackTrace) {
      _debugService.logError('無料トライアル開始エラー', e, stackTrace);
      rethrow;
    } finally {
      _debugService.stopPerformanceTimer('startFreeTrial');
    }
  }

  /// 家族メンバーを追加
  Future<void> addFamilyMember(String memberEmail) async {
    _debugService.startPerformanceTimer('addFamilyMember');

    try {
      if (memberEmail.isEmpty) {
        throw ArgumentError('メールアドレスが指定されていません');
      }

      // 家族共有が有効でない場合は追加できない
      if (!familySharing) {
        if (enableDebugMode) {
          debugPrint('家族共有が有効でないため、メンバーを追加できません');
        }
        return;
      }

      // 既に存在する場合は追加しない
      if (_familyMembers.contains(memberEmail)) {
        if (enableDebugMode) {
          debugPrint('既に存在するメールアドレスです: $memberEmail');
        }
        return;
      }

      // 制限チェック
      if (_familyMembers.length >= maxFamilyMembers) {
        if (enableDebugMode) {
          debugPrint(
            '家族メンバー数の制限に達しました: ${_familyMembers.length}/$maxFamilyMembers',
          );
        }
        return;
      }

      _familyMembers.add(memberEmail);

      if (enableDebugMode) {
        debugPrint(
          '家族メンバーを追加しました: $memberEmail (${_familyMembers.length}/$maxFamilyMembers)',
        );
      }

      await _saveSubscriptionStatus();

      // デバッグ情報を記録
      _debugService.recordFeatureUsage('family_member_add');

      notifyListeners();
    } catch (e, stackTrace) {
      _debugService.logError('家族メンバー追加エラー', e, stackTrace);
      rethrow;
    } finally {
      _debugService.stopPerformanceTimer('addFamilyMember');
    }
  }

  /// 家族メンバーを削除
  Future<void> removeFamilyMember(String memberEmail) async {
    _debugService.startPerformanceTimer('removeFamilyMember');

    try {
      if (memberEmail.isEmpty) {
        throw ArgumentError('メールアドレスが指定されていません');
      }

      final removed = _familyMembers.remove(memberEmail);

      if (removed) {
        if (enableDebugMode) {
          debugPrint('家族メンバーを削除しました: $memberEmail');
        }

        await _saveSubscriptionStatus();

        // デバッグ情報を記録
        _debugService.recordFeatureUsage('family_member_remove');

        notifyListeners();
      } else {
        if (enableDebugMode) {
          debugPrint('削除対象のメールアドレスが見つかりません: $memberEmail');
        }
      }
    } catch (e, stackTrace) {
      _debugService.logError('家族メンバー削除エラー', e, stackTrace);
      rethrow;
    } finally {
      _debugService.stopPerformanceTimer('removeFamilyMember');
    }
  }

  /// 現在のユーザーIDを設定
  void setCurrentUserId(String? userId) {
    _debugService.startPerformanceTimer('setCurrentUserId');

    try {
      if (_currentUserId != userId) {
        _currentUserId = userId;

        if (enableDebugMode) {
          debugPrint('ユーザーIDを設定しました: $userId');
        }

        // ユーザーIDが変更された場合は状態を再読み込み
        if (userId != null) {
          _loadSubscriptionStatus();
        }

        // デバッグ情報を記録
        _debugService.recordFeatureUsage('user_id_set');
      }
    } catch (e, stackTrace) {
      _debugService.logError('ユーザーID設定エラー', e, stackTrace);
    } finally {
      _debugService.stopPerformanceTimer('setCurrentUserId');
    }
  }

  /// サブスクリプション状態を復元
  Future<void> _restoreSubscriptionStatus() async {
    _debugService.startPerformanceTimer('restoreSubscriptionStatus');

    try {
      _isRestoring = true;
      notifyListeners();

      // 復元処理を実装（IAPの復元など）
      if (enableDebugMode) {
        debugPrint('サブスクリプション状態の復元を開始');
      }

      // 復元処理が完了したら状態を更新
      await Future.delayed(const Duration(seconds: 1)); // 仮の処理

      if (enableDebugMode) {
        debugPrint('サブスクリプション状態の復元が完了');
      }

      // デバッグ情報を記録
      _debugService.recordFeatureUsage('subscription_restore');
    } catch (e, stackTrace) {
      _debugService.logError('サブスクリプション状態復元エラー', e, stackTrace);
    } finally {
      _isRestoring = false;
      notifyListeners();
      _debugService.stopPerformanceTimer('restoreSubscriptionStatus');
    }
  }

  /// 無料トライアルチェックタイマーを開始
  void _startTrialCheckTimer() {
    _trialCheckTimer?.cancel();
    _trialCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkTrialExpiry();
    });
  }

  /// 無料トライアル期限切れチェック
  void _checkTrialExpiry() {
    if (isTrialActive && trialRemainingDays == 0) {
      if (enableDebugMode) {
        debugPrint('SubscriptionManager: タイマーで無料トライアル期限切れを検出');
      }
      _handleExpiredTrial();
    }
  }

  // ===== デバッグ用メソッド =====
  // リリースビルドでは使用しない

  /// デバッグ用: プランを変更
  Future<void> setDebugPlan(SubscriptionPlan plan) async {
    if (kReleaseMode) return; // リリースビルドでは実行しない

    _currentPlan = plan;
    _subscriptionExpiry = DateTime.now().add(const Duration(days: 30));
    _isActive = true;

    // ローカルストレージに保存
    await _saveSubscriptionStatus();

    if (enableDebugMode) {
      debugPrint('デバッグ: プランを${_planDefinitions[plan]!['name']}に変更');
    }

    notifyListeners();
  }

  /// デバッグ用: サブスクリプションの有効/無効を切り替え
  Future<void> setDebugSubscriptionActive(bool active) async {
    if (kReleaseMode) return; // リリースビルドでは実行しない

    _isActive = active;
    if (active) {
      _subscriptionExpiry = DateTime.now().add(const Duration(days: 30));
    } else {
      _subscriptionExpiry = DateTime.now().subtract(const Duration(days: 1));
    }

    // ローカルストレージに保存
    await _saveSubscriptionStatus();

    if (enableDebugMode) {
      debugPrint('デバッグ: サブスクリプションを${active ? '有効' : '無効'}に変更');
    }

    notifyListeners();
  }

  /// デバッグ用: トライアルをリセット
  Future<void> resetDebugTrial() async {
    if (kReleaseMode) return; // リリースビルドでは実行しない

    _trialStartDate = null;
    _trialUsed = false;

    // ローカルストレージに保存
    await _saveSubscriptionStatus();

    if (enableDebugMode) {
      debugPrint('デバッグ: トライアルをリセット');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _trialCheckTimer?.cancel();
    super.dispose();
  }
}
