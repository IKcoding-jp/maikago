// ファミリー共有機能を管理するサービス
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/family_member.dart';
import '../models/shared_content.dart';
import '../models/shop.dart';
import 'subscription_manager.dart';

/// ファミリー共有機能を管理するサービス
/// - ファミリーメンバーの招待・管理
/// - リスト・タブの共有
/// - ファミリープラン権限の管理
class FamilySharingService extends ChangeNotifier {
  static final FamilySharingService _instance =
      FamilySharingService._internal();
  factory FamilySharingService() => _instance;
  FamilySharingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final Uuid _uuid = const Uuid();

  // ファミリー情報
  String? _familyId;
  List<FamilyMember> _familyMembers = [];
  FamilyMember? _currentUserMember;
  bool _isLoading = false;

  // 共有コンテンツ
  List<SharedContent> _sharedContents = [];
  List<SharedContent> _receivedContents = [];

  // Getters
  String? get familyId => _familyId;
  List<FamilyMember> get familyMembers => List.unmodifiable(_familyMembers);
  FamilyMember? get currentUserMember => _currentUserMember;
  bool get isLoading => _isLoading;
  List<SharedContent> get sharedContents => List.unmodifiable(_sharedContents);
  List<SharedContent> get receivedContents =>
      List.unmodifiable(_receivedContents);

  /// ファミリーオーナーかどうか
  bool get isFamilyOwner => _currentUserMember?.role == FamilyRole.owner;

  /// ファミリーメンバーかどうか
  bool get isFamilyMember => _currentUserMember != null;

  /// ファミリー共有が利用可能かどうか
  bool get canUseFamilySharing {
    return _subscriptionManager.familySharing &&
        _subscriptionManager.hasBenefits &&
        _subscriptionManager.currentPlan == SubscriptionPlan.family;
  }

  /// ファミリー情報を初期化
  Future<void> initialize() async {
    if (!canUseFamilySharing) return;

    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    try {
      await _loadFamilyInfo(user.uid);
      await _loadSharedContents(user.uid);
    } catch (e) {
      debugPrint('ファミリー共有初期化エラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// ファミリー情報を読み込み
  Future<void> _loadFamilyInfo(String userId) async {
    // ユーザーが所属するファミリーを検索
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data();
    _familyId = userData?['familyId'];

    if (_familyId == null) return;

    // ファミリーメンバー情報を取得
    final familyDoc = await _firestore
        .collection('families')
        .doc(_familyId)
        .get();
    if (!familyDoc.exists) return;

    final familyData = familyDoc.data();
    final membersData = familyData?['members'] as List<dynamic>? ?? [];

    _familyMembers = membersData
        .map((member) => FamilyMember.fromMap(member))
        .where((member) => member.isActive)
        .toList();

    // 現在のユーザーのメンバー情報を設定
    _currentUserMember = _familyMembers.firstWhere(
      (member) => member.id == userId,
      orElse: () => FamilyMember(
        id: userId,
        email: _auth.currentUser?.email ?? '',
        displayName: _auth.currentUser?.displayName ?? '',
        photoUrl: _auth.currentUser?.photoURL,
        role: FamilyRole.member,
        joinedAt: DateTime.now(),
      ),
    );

    notifyListeners();
  }

  /// 共有コンテンツを読み込み
  Future<void> _loadSharedContents(String userId) async {
    if (_familyId == null) return;

    // 共有したコンテンツ
    final sharedQuery = await _firestore
        .collection('sharedContents')
        .where('sharedBy', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    _sharedContents = sharedQuery.docs
        .map((doc) => SharedContent.fromMap(doc.data()))
        .toList();

    // 共有されたコンテンツ
    final receivedQuery = await _firestore
        .collection('sharedContents')
        .where('sharedWith', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .get();

    _receivedContents = receivedQuery.docs
        .map((doc) => SharedContent.fromMap(doc.data()))
        .toList();

    notifyListeners();
  }

  /// ファミリーを作成（ファミリープラン契約者が実行）
  Future<bool> createFamily() async {
    if (!canUseFamilySharing) return false;

    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    try {
      final familyId = _uuid.v4();

      // ファミリーオーナーとしてメンバーを作成
      final owner = FamilyMember(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        role: FamilyRole.owner,
        joinedAt: DateTime.now(),
      );

      // ファミリー情報を保存
      await _firestore.collection('families').doc(familyId).set({
        'id': familyId,
        'ownerId': user.uid,
        'createdAt': DateTime.now().toIso8601String(),
        'members': [owner.toMap()],
      });

      // ユーザー情報にファミリーIDを設定
      await _firestore.collection('users').doc(user.uid).update({
        'familyId': familyId,
      });

      _familyId = familyId;
      _familyMembers = [owner];
      _currentUserMember = owner;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ファミリー作成エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ファミリーメンバーを招待
  Future<bool> inviteMember(String email) async {
    if (!canUseFamilySharing || !isFamilyOwner) return false;
    if (_familyId == null) return false;

    // メンバー数制限チェック
    if (_familyMembers.length >= _subscriptionManager.maxFamilyMembers) {
      return false;
    }

    _setLoading(true);
    try {
      // 招待情報を作成
      final inviteId = _uuid.v4();
      await _firestore.collection('familyInvites').doc(inviteId).set({
        'id': inviteId,
        'familyId': _familyId,
        'email': email,
        'invitedBy': _auth.currentUser?.uid,
        'invitedByName': _auth.currentUser?.displayName ?? '',
        'invitedAt': DateTime.now().toIso8601String(),
        'status': 'pending',
        'expiresAt': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
      });

      // TODO: メール送信機能を実装（Firebase Functions等を使用）

      return true;
    } catch (e) {
      debugPrint('メンバー招待エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 招待を承認
  Future<bool> acceptInvite(String inviteId) async {
    if (!canUseFamilySharing) return false;

    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    try {
      // 招待情報を取得
      final inviteDoc = await _firestore
          .collection('familyInvites')
          .doc(inviteId)
          .get();
      if (!inviteDoc.exists) return false;

      final inviteData = inviteDoc.data()!;
      final familyId = inviteData['familyId'] as String;

      // メンバーを作成
      final member = FamilyMember(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        role: FamilyRole.member,
        joinedAt: DateTime.now(),
      );

      // ファミリーにメンバーを追加
      await _firestore.collection('families').doc(familyId).update({
        'members': FieldValue.arrayUnion([member.toMap()]),
      });

      // ユーザー情報にファミリーIDを設定
      await _firestore.collection('users').doc(user.uid).update({
        'familyId': familyId,
      });

      // 招待を削除
      await _firestore.collection('familyInvites').doc(inviteId).delete();

      // ローカル情報を更新
      await _loadFamilyInfo(user.uid);

      return true;
    } catch (e) {
      debugPrint('招待承認エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// メンバーを削除
  Future<bool> removeMember(String memberId) async {
    if (!canUseFamilySharing || !isFamilyOwner) return false;
    if (_familyId == null) return false;

    _setLoading(true);
    try {
      // メンバーを非アクティブにする
      final updatedMembers = _familyMembers.map((member) {
        if (member.id == memberId) {
          return member.copyWith(isActive: false);
        }
        return member;
      }).toList();

      await _firestore.collection('families').doc(_familyId).update({
        'members': updatedMembers.map((m) => m.toMap()).toList(),
      });

      // ユーザー情報からファミリーIDを削除
      await _firestore.collection('users').doc(memberId).update({
        'familyId': null,
      });

      // ローカル情報を更新
      await _loadFamilyInfo(_auth.currentUser!.uid);

      return true;
    } catch (e) {
      debugPrint('メンバー削除エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// リスト・タブを共有
  Future<bool> shareContent({
    required Shop shop,
    required String title,
    required String description,
    required List<String> memberIds,
  }) async {
    if (!canUseFamilySharing || !isFamilyMember) return false;

    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    try {
      final sharedContent = SharedContent(
        id: _uuid.v4(),
        title: title,
        description: description,
        type: SharedContentType.list,
        contentId: shop.id,
        content: shop,
        sharedBy: user.uid,
        sharedByName: user.displayName ?? '',
        sharedAt: DateTime.now(),
        sharedWith: memberIds,
      );

      // 共有コンテンツを保存
      await _firestore
          .collection('sharedContents')
          .doc(sharedContent.id)
          .set(sharedContent.toMap());

      // ローカル情報を更新
      await _loadSharedContents(user.uid);

      return true;
    } catch (e) {
      debugPrint('コンテンツ共有エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 共有コンテンツを取得
  Future<Shop?> getSharedContent(String contentId) async {
    try {
      final doc = await _firestore
          .collection('sharedContents')
          .doc(contentId)
          .get();
      if (!doc.exists) return null;

      final sharedContent = SharedContent.fromMap(doc.data()!);
      return sharedContent.content;
    } catch (e) {
      debugPrint('共有コンテンツ取得エラー: $e');
      return null;
    }
  }

  /// 共有を削除
  Future<bool> removeSharedContent(String contentId) async {
    if (!canUseFamilySharing) return false;

    _setLoading(true);
    try {
      await _firestore.collection('sharedContents').doc(contentId).update({
        'isActive': false,
      });

      // ローカル情報を更新
      await _loadSharedContents(_auth.currentUser!.uid);

      return true;
    } catch (e) {
      debugPrint('共有削除エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ファミリーを離脱
  Future<bool> leaveFamily() async {
    if (!canUseFamilySharing || !isFamilyMember) return false;
    if (isFamilyOwner) return false; // オーナーは離脱できない

    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    try {
      // メンバーを非アクティブにする
      final updatedMembers = _familyMembers.map((member) {
        if (member.id == user.uid) {
          return member.copyWith(isActive: false);
        }
        return member;
      }).toList();

      await _firestore.collection('families').doc(_familyId).update({
        'members': updatedMembers.map((m) => m.toMap()).toList(),
      });

      // ユーザー情報からファミリーIDを削除
      await _firestore.collection('users').doc(user.uid).update({
        'familyId': null,
      });

      // ローカル情報をクリア
      _familyId = null;
      _familyMembers = [];
      _currentUserMember = null;
      _sharedContents = [];
      _receivedContents = [];

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ファミリー離脱エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ファミリーを解散（オーナーのみ）
  Future<bool> dissolveFamily() async {
    if (!canUseFamilySharing || !isFamilyOwner) return false;
    if (_familyId == null) return false;

    _setLoading(true);
    try {
      // 全メンバーを非アクティブにする
      final updatedMembers = _familyMembers.map((member) {
        return member.copyWith(isActive: false);
      }).toList();

      await _firestore.collection('families').doc(_familyId).update({
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'dissolvedAt': DateTime.now().toIso8601String(),
      });

      // 全メンバーのユーザー情報からファミリーIDを削除
      final batch = _firestore.batch();
      for (final member in _familyMembers) {
        final userRef = _firestore.collection('users').doc(member.id);
        batch.update(userRef, {'familyId': null});
      }
      await batch.commit();

      // ローカル情報をクリア
      _familyId = null;
      _familyMembers = [];
      _currentUserMember = null;
      _sharedContents = [];
      _receivedContents = [];

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ファミリー解散エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
