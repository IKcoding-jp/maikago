// ファミリー共有機能を管理するサービス
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/family_member.dart';
import '../models/shared_content.dart';
import '../models/shop.dart';

/// ファミリー共有機能を管理するサービス
/// - ファミリーメンバーの招待・管理
/// - タブ・リストの共有
/// - ファミリープラン権限の管理
class FamilySharingService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  /// ファミリー共有が利用可能かどうか（一時的に常にtrueを返す）
  bool get canUseFamilySharing {
    // TODO: SubscriptionServiceとの連携を後で実装
    return true;
  }

  /// QRコード招待トークンを生成
  Future<String?> generateQRCodeInviteToken() async {
    if (!canUseFamilySharing || !isFamilyOwner) return null;
    if (_familyId == null) return null;

    try {
      final inviteToken = _uuid.v4();

      // 招待トークンをFirestoreに保存
      await _firestore.collection('familyInviteTokens').doc(inviteToken).set({
        'token': inviteToken,
        'familyId': _familyId,
        'createdBy': _auth.currentUser?.uid,
        'createdByName': _auth.currentUser?.displayName ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        'isUsed': false,
      });

      return inviteToken;
    } catch (e) {
      debugPrint('QRコード招待トークン生成エラー: $e');
      return null;
    }
  }

  /// QRコードデータを取得
  Future<Map<String, dynamic>?> getQRCodeData() async {
    if (!canUseFamilySharing || !isFamilyOwner) return null;
    if (_familyId == null) return null;

    try {
      final inviteToken = await generateQRCodeInviteToken();
      if (inviteToken == null) return null;

      return {
        'type': 'family_invite',
        'familyId': _familyId,
        'inviteToken': inviteToken,
        'expiresAt': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        'createdBy': _auth.currentUser?.uid,
        'createdByName': _auth.currentUser?.displayName ?? '',
        'appVersion': '0.5.6', // アプリバージョン
      };
    } catch (e) {
      debugPrint('QRコードデータ取得エラー: $e');
      return null;
    }
  }

  /// QRコード招待トークンを検証
  Future<bool> validateQRCodeInviteToken(String token) async {
    try {
      final tokenDoc = await _firestore
          .collection('familyInviteTokens')
          .doc(token)
          .get();

      if (!tokenDoc.exists) return false;

      final tokenData = tokenDoc.data()!;
      final expiresAt = DateTime.parse(tokenData['expiresAt']);
      final isUsed = tokenData['isUsed'] ?? false;

      // 有効期限チェック
      if (DateTime.now().isAfter(expiresAt)) return false;

      // 使用済みチェック
      if (isUsed) return false;

      return true;
    } catch (e) {
      debugPrint('QRコード招待トークン検証エラー: $e');
      return false;
    }
  }

  /// QRコード招待トークンを使用済みにマーク
  Future<bool> markQRCodeInviteTokenAsUsed(String token) async {
    try {
      await _firestore.collection('familyInviteTokens').doc(token).update({
        'isUsed': true,
        'usedAt': DateTime.now().toIso8601String(),
        'usedBy': _auth.currentUser?.uid,
      });
      return true;
    } catch (e) {
      debugPrint('QRコード招待トークン使用済みマークエラー: $e');
      return false;
    }
  }

  /// QRコード招待でファミリーに参加
  Future<bool> joinFamilyByQRCode(String inviteToken) async {
    if (!canUseFamilySharing) return false;

    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    try {
      // 招待トークンの詳細情報を取得
      final tokenDoc = await _firestore
          .collection('familyInviteTokens')
          .doc(inviteToken)
          .get();

      if (!tokenDoc.exists) return false;

      final tokenData = tokenDoc.data()!;
      final familyId = tokenData['familyId'] as String;
      final createdBy = tokenData['createdBy'] as String;

      // 既にファミリーに所属しているかチェック
      if (_familyId != null) {
        debugPrint('既にファミリーに所属しています');
        return false;
      }

      // ファミリー情報の存在確認はスキップ（権限の問題を回避）
      // 招待トークンが有効であれば、ファミリーは存在するはず

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
        'members.${user.uid}': member.toMap(),
      });

      // ユーザー情報にファミリーIDを設定
      await _firestore.collection('users').doc(user.uid).set({
        'familyId': familyId,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // ローカル情報を更新
      _familyId = familyId;
      await _loadFamilyInfo(user.uid);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('QRコード招待によるファミリー参加エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ファミリー情報を初期化
  Future<void> initialize() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _setLoading(true);

      // 基本的なファミリー情報を読み込み（権限チェックなし）
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
    try {
      // ユーザーが所属するファミリーを検索
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('ユーザードキュメントが存在しません: $userId');
        // ユーザードキュメントが存在しない場合は、基本的なユーザー情報を作成
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(userId).set({
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
        return;
      }

      final userData = userDoc.data();
      _familyId = userData?['familyId'];

      if (_familyId == null) {
        debugPrint('ユーザーはファミリーに所属していません: $userId');
        return;
      }

      // ファミリーメンバー情報を取得
      final familyDoc = await _firestore
          .collection('families')
          .doc(_familyId)
          .get();
      if (!familyDoc.exists) {
        debugPrint('ファミリードキュメントが存在しません: $_familyId');
        return;
      }

      final familyData = familyDoc.data();
      final membersData = familyData?['members'] as Map<String, dynamic>? ?? {};

      _familyMembers = membersData.values
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
    } catch (e) {
      debugPrint('ファミリー情報読み込みエラー: $e');
      // エラーが発生した場合は空の状態を設定
      _familyMembers = [];
      _currentUserMember = null;
      notifyListeners();
    }
  }

  /// 共有コンテンツを読み込み
  Future<void> _loadSharedContents(String userId) async {
    try {
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
    } catch (e) {
      debugPrint('共有コンテンツ読み込みエラー: $e');
      // エラーが発生した場合は空のタブを設定
      _sharedContents = [];
      _receivedContents = [];
      notifyListeners();
    }
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

      // ファミリー情報を保存（membersはマップ形式で保存）
      await _firestore.collection('families').doc(familyId).set({
        'id': familyId,
        'ownerId': user.uid,
        'createdAt': DateTime.now().toIso8601String(),
        'members': {user.uid: owner.toMap()},
      });

      // ユーザー情報にファミリーIDを設定
      await _firestore.collection('users').doc(user.uid).set({
        'familyId': familyId,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

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

    // メンバー数制限チェック（一時的に無効化）
    // final currentPlan = _subscriptionService.currentPlan;
    // final maxMembers = currentPlan?.maxFamilyMembers ?? 0;
    // if (_familyMembers.length >= maxMembers) {
    //   return false;
    // }

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

  /// コンテンツを共有
  Future<bool> shareContent({
    required Shop shop,
    required String title,
    required String description,
    required List<String> memberIds,
  }) async {
    if (!canUseFamilySharing || !isFamilyMember) return false;
    if (_familyId == null) return false;

    _setLoading(true);
    try {
      final contentId = _uuid.v4();
      final now = DateTime.now();

      // 共有コンテンツを作成
      final sharedContent = SharedContent(
        id: contentId,
        title: title,
        description: description,
        type: SharedContentType.list, // デフォルトでタブとして扱う
        contentId: shop.id,
        content: shop,
        sharedBy: _auth.currentUser?.uid ?? '',
        sharedByName: _auth.currentUser?.displayName ?? 'Unknown',
        sharedAt: now,
        sharedWith: memberIds,
        isActive: true,
      );

      // Firestoreに保存
      await _firestore.collection('sharedContents').doc(contentId).set({
        'id': contentId,
        'title': title,
        'description': description,
        'shopId': shop.id,
        'shopName': shop.name,
        'shopData': shop.toMap(),
        'sharedBy': sharedContent.sharedBy,
        'sharedByName': sharedContent.sharedByName,
        'sharedAt': now.toIso8601String(),
        'memberIds': memberIds,
        'isActive': true,
        'familyId': _familyId,
      });

      // 共有したコンテンツタブに追加
      _sharedContents.add(sharedContent);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('コンテンツ共有エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 共有コンテンツを削除
  Future<bool> removeSharedContent(String contentId) async {
    if (!canUseFamilySharing || !isFamilyMember) return false;

    _setLoading(true);
    try {
      // Firestoreから削除
      await _firestore.collection('sharedContents').doc(contentId).delete();

      // ローカルタブから削除
      _sharedContents.removeWhere((content) => content.id == contentId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('共有コンテンツ削除エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 共有コンテンツを読み込み
  Future<void> loadSharedContents() async {
    if (!canUseFamilySharing || !isFamilyMember) return;
    if (_familyId == null) return;

    _setLoading(true);
    try {
      // 共有したコンテンツを読み込み
      final sharedQuery = await _firestore
          .collection('sharedContents')
          .where('sharedBy', isEqualTo: _auth.currentUser?.uid)
          .where('familyId', isEqualTo: _familyId)
          .where('isActive', isEqualTo: true)
          .get();

      _sharedContents = sharedQuery.docs.map((doc) {
        final data = doc.data();
        return SharedContent(
          id: data['id'],
          title: data['title'],
          description: data['description'],
          type: SharedContentType.values.firstWhere(
            (type) => type.name == (data['type'] ?? 'list'),
            orElse: () => SharedContentType.list,
          ),
          contentId: data['contentId'] ?? data['shopId'] ?? '',
          content: data['shopData'] != null
              ? Shop.fromMap(data['shopData'])
              : null,
          sharedBy: data['sharedBy'],
          sharedByName: data['sharedByName'],
          sharedAt: DateTime.parse(data['sharedAt']),
          sharedWith: List<String>.from(
            data['sharedWith'] ?? data['memberIds'] ?? [],
          ),
          isActive: data['isActive'] ?? true,
        );
      }).toList();

      // 共有されたコンテンツを読み込み
      final receivedQuery = await _firestore
          .collection('sharedContents')
          .where('sharedWith', arrayContains: _auth.currentUser?.uid)
          .where('familyId', isEqualTo: _familyId)
          .where('isActive', isEqualTo: true)
          .get();

      _receivedContents = receivedQuery.docs.map((doc) {
        final data = doc.data();
        return SharedContent(
          id: data['id'],
          title: data['title'],
          description: data['description'],
          type: SharedContentType.values.firstWhere(
            (type) => type.name == (data['type'] ?? 'list'),
            orElse: () => SharedContentType.list,
          ),
          contentId: data['contentId'] ?? data['shopId'] ?? '',
          content: data['shopData'] != null
              ? Shop.fromMap(data['shopData'])
              : null,
          sharedBy: data['sharedBy'],
          sharedByName: data['sharedByName'],
          sharedAt: DateTime.parse(data['sharedAt']),
          sharedWith: List<String>.from(
            data['sharedWith'] ?? data['memberIds'] ?? [],
          ),
          isActive: data['isActive'] ?? true,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('共有コンテンツ読み込みエラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
