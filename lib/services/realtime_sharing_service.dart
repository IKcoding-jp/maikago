import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/family_member.dart';
import '../models/shared_content.dart';
import '../models/shop.dart';
import '../models/item.dart';
import '../models/sync_data.dart';

/// リアルタイム共有機能を管理するサービス
/// Cloud Firestoreのリアルタイムリスナーを使用してリアルタイム同期を実現
class RealtimeSharingService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // リアルタイムリスナー
  StreamSubscription<DocumentSnapshot>? _familyListener;
  StreamSubscription<QuerySnapshot>? _transmissionsListener;
  StreamSubscription<QuerySnapshot>? _syncDataListener;
  StreamSubscription<QuerySnapshot>? _notificationsListener;

  // データ
  List<SharedContent> _receivedContents = [];
  List<SyncData> _syncDataList = [];
  List<FamilyMember> _familyMembers = [];
  List<Map<String, dynamic>> _notifications = [];
  String? _familyId;
  bool _isConnected = false;

  // Getters
  List<SharedContent> get receivedContents =>
      List.unmodifiable(_receivedContents);
  List<SyncData> get syncDataList => List.unmodifiable(_syncDataList);
  List<FamilyMember> get familyMembers => List.unmodifiable(_familyMembers);
  List<Map<String, dynamic>> get notifications =>
      List.unmodifiable(_notifications);
  String? get familyId => _familyId;
  bool get isConnected => _isConnected;

  /// リアルタイム共有サービスを初期化
  Future<void> initialize() async {
    try {
      debugPrint('🔧 RealtimeSharingService: 初期化開始');
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ RealtimeSharingService: ユーザーが認証されていません');
        return;
      }

      debugPrint('👤 RealtimeSharingService: ユーザーID: ${user.uid}');
      await _loadFamilyInfo(user.uid);

      if (_familyId != null) {
        debugPrint('👨‍👩‍👧‍👦 RealtimeSharingService: ファミリーID: $_familyId');
        await _setupRealtimeListeners();
      } else {
        debugPrint('ℹ️ RealtimeSharingService: ファミリーIDが設定されていません');
      }

      _isConnected = true;
      debugPrint('✅ RealtimeSharingService: 初期化完了');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ RealtimeSharingService初期化エラー: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  /// ファミリー情報を読み込み
  Future<void> _loadFamilyInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _familyId = userData['familyId'] as String?;

        if (_familyId != null) {
          await _loadFamilyMembers();
        }
      }
    } catch (e) {
      debugPrint('ファミリー情報読み込みエラー: $e');
    }
  }

  /// ファミリーメンバーを読み込み
  Future<void> _loadFamilyMembers() async {
    try {
      if (_familyId == null) return;

      debugPrint('👨‍👩‍👧‍👦 RealtimeSharingService: ファミリーメンバー読み込み開始');
      final familyDoc = await _firestore
          .collection('families')
          .doc(_familyId)
          .get();

      if (familyDoc.exists) {
        final familyData = familyDoc.data()!;
        final membersData = familyData['members'] as List<dynamic>? ?? [];
        final ownerIdInDoc = familyData['ownerId']?.toString();

        _familyMembers = membersData
            .whereType<Map<String, dynamic>>()
            .map((memberData) => FamilyMember.fromMap(memberData))
            .where((member) => member.isActive)
            .toList();

        // フォールバック: メンバーが空で、ownerId が自分なら最低限自分を反映
        if (_familyMembers.isEmpty && ownerIdInDoc != null) {
          final currentUserId = _auth.currentUser?.uid;
          if (currentUserId != null && currentUserId == ownerIdInDoc) {
            final fallbackOwner = FamilyMember(
              id: currentUserId,
              email: _auth.currentUser?.email ?? '',
              displayName: _auth.currentUser?.displayName ?? 'Owner',
              photoUrl: _auth.currentUser?.photoURL,
              role: FamilyRole.owner,
              joinedAt: DateTime.now(),
              isActive: true,
            );
            _familyMembers = [fallbackOwner];
          }
        }

        debugPrint(
          '✅ RealtimeSharingService: ファミリーメンバー読み込み完了 (${_familyMembers.length}人)',
        );
      } else {
        debugPrint('ℹ️ RealtimeSharingService: ファミリードキュメントが存在しません');
        _familyMembers = [];
      }
    } catch (e) {
      debugPrint('❌ RealtimeSharingService: ファミリーメンバー読み込みエラー: $e');
      _familyMembers = [];

      // 権限エラーの場合は、ファミリーIDをリセット
      if (e.toString().contains('permission-denied')) {
        debugPrint(
          '🔒 RealtimeSharingService: ファミリーアクセス権限がありません。ファミリーIDをリセットします。',
        );
        await _resetFamilyId();
      }
    }
  }

  /// リアルタイムリスナーを設定
  Future<void> _setupRealtimeListeners() async {
    try {
      debugPrint('🔧 RealtimeSharingService: リアルタイムリスナー設定開始');
      final user = _auth.currentUser;
      if (user == null || _familyId == null) {
        debugPrint('❌ RealtimeSharingService: ユーザーまたはファミリーIDが無効');
        return;
      }

      // ファミリー情報のリアルタイム監視（ファミリーIDが有効な場合のみ）
      if (_familyId != null && _familyId!.isNotEmpty) {
        debugPrint('👨‍👩‍👧‍👦 RealtimeSharingService: ファミリーリスナー設定中...');
        try {
          _familyListener = _firestore
              .collection('families')
              .doc(_familyId)
              .snapshots()
              .listen(
                _onFamilyDataChanged,
                onError: (error) {
                  debugPrint('❌ RealtimeSharingService: ファミリーリスナーエラー: $error');
                },
              );
        } catch (e) {
          debugPrint('❌ RealtimeSharingService: ファミリーリスナー設定エラー: $e');
        }
      } else {
        debugPrint('ℹ️ RealtimeSharingService: ファミリーIDが無効なため、ファミリーリスナーをスキップ');
      }

      // 受信コンテンツのリアルタイム監視
      debugPrint('📨 RealtimeSharingService: 受信コンテンツリスナー設定中...');
      try {
        _transmissionsListener = _firestore
            .collection('transmissions')
            .where('sharedWith', arrayContains: user.uid)
            .where('isActive', isEqualTo: true)
            .orderBy('sharedAt', descending: true)
            .snapshots()
            .listen(
              _onTransmissionsChanged,
              onError: (error) {
                debugPrint('❌ RealtimeSharingService: 受信コンテンツリスナーエラー: $error');
              },
            );

        // 補助: orderBy を使わないワンオフクエリで該当件数を確認
        try {
          final oneOff = await _firestore
              .collection('transmissions')
              .where('sharedWith', arrayContains: user.uid)
              .where('isActive', isEqualTo: true)
              .get();
          debugPrint(
            '🛰️ RealtimeSharingService: oneOffQuery transmissions count=${oneOff.docs.length}',
          );
          if (oneOff.docs.isNotEmpty) {
            final ids = oneOff.docs.map((d) => d.id).join(',');
            debugPrint('🛰️ RealtimeSharingService: oneOffQuery ids=[$ids]');
          }
        } catch (oneOffError) {
          debugPrint(
            '🛰️ RealtimeSharingService: oneOffQuery error: $oneOffError',
          );
        }
      } catch (e) {
        debugPrint('❌ RealtimeSharingService: 受信コンテンツリスナー設定エラー: $e');
      }

      // 同期データのリアルタイム監視
      debugPrint('🔄 RealtimeSharingService: 同期データリスナー設定中...');
      try {
        _syncDataListener = _firestore
            .collection('syncData')
            .where('sharedWith', arrayContains: user.uid)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen(
              _onSyncDataChanged,
              onError: (error) {
                debugPrint('❌ RealtimeSharingService: 同期データリスナーエラー: $error');
              },
            );
      } catch (e) {
        debugPrint('❌ RealtimeSharingService: 同期データリスナー設定エラー: $e');
      }

      // 通知のリアルタイム監視
      debugPrint('🔔 RealtimeSharingService: 通知リスナー設定中...');
      try {
        _notificationsListener = _firestore
            .collection('notifications')
            .doc(user.uid)
            .collection('items')
            .where('isRead', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen(
              _onNotificationsChanged,
              onError: (error) {
                debugPrint('❌ RealtimeSharingService: 通知リスナーエラー: $error');
              },
            );
      } catch (e) {
        debugPrint('❌ RealtimeSharingService: 通知リスナー設定エラー: $e');
      }

      debugPrint('✅ RealtimeSharingService: リアルタイムリスナー設定完了');
    } catch (e) {
      debugPrint('❌ RealtimeSharingService: リアルタイムリスナー設定エラー: $e');
    }
  }

  /// ファミリーデータ変更時の処理
  void _onFamilyDataChanged(DocumentSnapshot snapshot) {
    try {
      if (snapshot.exists) {
        final familyData = snapshot.data() as Map<String, dynamic>;
        final membersData = familyData['members'] as List<dynamic>? ?? [];
        final ownerIdInDoc = familyData['ownerId']?.toString();

        _familyMembers = membersData
            .whereType<Map<String, dynamic>>()
            .map((memberData) => FamilyMember.fromMap(memberData))
            .where((member) => member.isActive)
            .toList();

        // フォールバック: メンバーが空で、ownerId が自分なら最低限自分を反映
        if (_familyMembers.isEmpty && ownerIdInDoc != null) {
          final currentUserId = _auth.currentUser?.uid;
          if (currentUserId != null && currentUserId == ownerIdInDoc) {
            final fallbackOwner = FamilyMember(
              id: currentUserId,
              email: _auth.currentUser?.email ?? '',
              displayName: _auth.currentUser?.displayName ?? 'Owner',
              photoUrl: _auth.currentUser?.photoURL,
              role: FamilyRole.owner,
              joinedAt: DateTime.now(),
              isActive: true,
            );
            _familyMembers = [fallbackOwner];
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('ファミリーデータ変更処理エラー: $e');
    }
  }

  /// 受信コンテンツ変更時の処理
  Future<void> _onTransmissionsChanged(QuerySnapshot snapshot) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      debugPrint(
        '🛰️ RealtimeSharingService: _onTransmissionsChanged snapshot docs=${snapshot.docs.length}',
      );
      if (snapshot.docs.isNotEmpty) {
        final ids = snapshot.docs.map((d) => d.id).join(',');
        debugPrint(
          '🛰️ RealtimeSharingService: _onTransmissionsChanged ids=[$ids]',
        );
      }
      // 自動追加: 受信対象のショップがあればユーザーの shops コレクションへ保存
      if (currentUserId != null) {
        // ユーザードキュメントから削除マーカーを取得（復元防止用）
        List<String> deletedShopIds = [];
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(currentUserId)
              .get();
          if (userDoc.exists) {
            final ud = userDoc.data();
            deletedShopIds =
                (ud?['deletedShopIds'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
          }
        } catch (e) {
          debugPrint('🛰️ RealtimeSharingService: deletedShopIds取得エラー: $e');
        }

        for (final doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final sharedWith = (data['sharedWith'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList();
            final sharedBy = data['sharedBy']?.toString();
            final type = data['type'] as String? ?? data['type'];

            if (sharedWith != null &&
                sharedWith.contains(currentUserId) &&
                sharedBy != currentUserId &&
                (type == null ||
                    type == SharedContentType.tab.name ||
                    type == 'tab')) {
              final shopData = data['shopData'] as Map<String, dynamic>?;
              if (shopData != null) {
                // sync送信では transmissions.contentId に syncId を格納しているため、
                // 受信側では contentId を優先して使って user shops へ保存する。
                final shopIdCandidate =
                    (data['contentId']?.toString() ??
                    shopData['id']?.toString() ??
                    doc.id);
                // 受信側が直前にこのタブを削除している場合は自動追加を抑止
                if (deletedShopIds.contains(shopIdCandidate)) {
                  debugPrint(
                    '⚠️ RealtimeSharingService: 自動追加抑止 - ユーザーが削除済 shopId=$shopIdCandidate',
                  );
                  continue;
                }
                final itemsFromItemsData = data['itemsData'] as List<dynamic>?;

                // merge items if needed
                final mergedShopData = Map<String, dynamic>.from(shopData);
                if ((mergedShopData['items'] == null ||
                        (mergedShopData['items'] as List).isEmpty) &&
                    (itemsFromItemsData != null &&
                        itemsFromItemsData.isNotEmpty)) {
                  mergedShopData['items'] = itemsFromItemsData;
                }

                // ここで候補IDを優先して user shops のドキュメントID とする
                final shopId = shopIdCandidate;
                // 自動追加ロジックは無効化しました（送信モデルに変更）。
                // ここでは受信通知のみ扱い、ユーザーが明示的に受け取り操作を実行したときに
                // TransmissionService.applyReceivedTab を呼んでローカル保存を行ってください。
                debugPrint(
                  'ℹ️ RealtimeSharingService: 自動追加は無効化されています shopId=$shopId',
                );
              }
            }
          } catch (e) {
            debugPrint('🔍 RealtimeSharingService: 自動追加処理中のエラー: $e');
          }
        }
      }
      _receivedContents = snapshot.docs
          .map(
            (doc) => SharedContent.fromMap(doc.data() as Map<String, dynamic>),
          )
          .map((content) {
            // 受信側のユーザーが送信対象に含まれており、送信者自身ではない場合は
            // ストア上のステータスが'sent'でも受信側では'received'として扱う
            if (currentUserId != null &&
                content.sharedWith.contains(currentUserId) &&
                content.sharedBy != currentUserId &&
                content.status == TransmissionStatus.sent) {
              return content.copyWith(status: TransmissionStatus.received);
            }
            return content;
          })
          .where((content) => content.isActive)
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('受信コンテンツ変更処理エラー: $e');
    }
  }

  /// 同期データ変更時の処理
  void _onSyncDataChanged(QuerySnapshot snapshot) {
    try {
      _syncDataList = snapshot.docs
          .map((doc) => SyncData.fromMap(doc.data() as Map<String, dynamic>))
          .where((syncData) => syncData.isActive)
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('同期データ変更処理エラー: $e');
    }
  }

  /// 通知変更時の処理
  void _onNotificationsChanged(QuerySnapshot snapshot) {
    try {
      _notifications = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('通知変更処理エラー: $e');
    }
  }

  /// リアルタイムでコンテンツを送信
  Future<bool> sendContentRealtime({
    required Shop shop,
    required String title,
    required String description,
    required List<FamilyMember> recipients,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final contentId = _uuid.v4();
      final now = DateTime.now();
      final recipientIds = recipients.map((member) => member.id).toList();

      // 送信コンテンツを作成
      final sharedContent = SharedContent(
        id: contentId,
        title: title,
        description: description,
        type: SharedContentType.tab,
        contentId: shop.id,
        content: shop,
        sharedBy: user.uid,
        sharedByName: user.displayName ?? 'Unknown',
        sharedAt: now,
        sharedWith: recipientIds,
        status: TransmissionStatus.sent,
        isActive: true,
      );

      // Firestoreに保存
      await _firestore.collection('transmissions').doc(contentId).set({
        ...sharedContent.toMap(),
        'shopData': shop.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 受信者ごとに通知を作成（非同期で実行、エラーは無視）
      _createNotificationsAsync(
        contentId,
        recipientIds,
        title,
        description,
        user,
        now,
      );

      debugPrint('✅ リアルタイムコンテンツ送信完了: contentId=$contentId');
      return true;
    } catch (e) {
      debugPrint('❌ リアルタイムコンテンツ送信エラー: $e');
      debugPrint('🔍 エラー詳細: 送信者ID=${user.uid}, 受信者数=${recipients.length}');

      // 通知作成エラーの場合は、送信コンテンツ自体は成功とみなす
      if (e.toString().contains('permission-denied') &&
          e.toString().contains('notifications')) {
        debugPrint('⚠️ 通知作成エラーですが、送信コンテンツは成功とみなします');
        return true;
      }

      return false;
    }
  }

  /// リアルタイムで同期データを送信
  Future<bool> sendSyncDataRealtime({
    required Shop shop,
    required String title,
    required String description,
    required List<FamilyMember> recipients,
    required List<Item> items,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final syncId = _uuid.v4();
      final now = DateTime.now();
      final recipientIds = recipients.map((member) => member.id).toList();

      // 同期データを作成
      final syncData = SyncData(
        id: syncId,
        userId: user.uid,
        type: SyncDataType.tab,
        shopId: shop.id,
        shopName: shop.name,
        items: items,
        title: title,
        description: description,
        createdAt: now,
        sharedWith: recipientIds,
        isActive: true,
      );

      // Firestoreに保存
      await _firestore.collection('syncData').doc(syncId).set({
        ...syncData.toMap(),
        'shopData': shop.toMap(),
        'itemsData': items.map((item) => item.toMap()).toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 補助: 受信側 UI が transmissions を参照しているため、同様の transmissions ドキュメントも作成しておく
      try {
        final sharedContent = SharedContent(
          id: syncId,
          title: title,
          description: description,
          type: SharedContentType.tab,
          contentId: syncId,
          content: shop,
          sharedBy: user.uid,
          sharedByName: user.displayName ?? 'Unknown',
          sharedAt: now,
          sharedWith: recipientIds,
          status: TransmissionStatus.sent,
          isActive: true,
        );

        await _firestore.collection('transmissions').doc(syncId).set({
          ...sharedContent.toMap(),
          'shopData': shop.toMap(),
          'itemsData': items.map((item) => item.toMap()).toList(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('❌ RealtimeSharingService: 同期送信時のtransmissions作成エラー: $e');
        // 通知は既に作成されているため、ここで失敗しても送信は成功扱い
      }

      // 受信者ごとに通知を作成（非同期で実行、エラーは無視）
      _createSyncNotificationsAsync(
        syncId,
        recipientIds,
        title,
        description,
        user,
        now,
      );

      debugPrint('✅ リアルタイム同期データ送信完了: syncId=$syncId');
      return true;
    } catch (e) {
      debugPrint('❌ リアルタイム同期データ送信エラー: $e');
      debugPrint(
        '🔍 エラー詳細: 送信者ID=${user.uid}, 受信者数=${recipients.length}, アイテム数=${items.length}',
      );

      // 通知作成エラーの場合は、同期データ送信自体は成功とみなす
      if (e.toString().contains('permission-denied') &&
          e.toString().contains('notifications')) {
        debugPrint('⚠️ 通知作成エラーですが、同期データ送信は成功とみなします');
        return true;
      }

      return false;
    }
  }

  /// 受信コンテンツを適用（リアルタイム更新）
  Future<bool> applyReceivedContentRealtime(SharedContent content) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final now = DateTime.now();

      // 受信コンテンツの状態を更新
      await _firestore.collection('transmissions').doc(content.id).update({
        'status': TransmissionStatus.accepted.name,
        'acceptedAt': now.toIso8601String(),
        'acceptedBy': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 送信者に通知
      await _firestore
          .collection('notifications')
          .doc(content.sharedBy)
          .collection('items')
          .doc('${content.id}_accepted')
          .set({
            'type': 'content_accepted',
            'contentId': content.id,
            'title': content.title,
            'acceptedBy': user.uid,
            'acceptedByName': user.displayName ?? 'Unknown',
            'acceptedAt': now.toIso8601String(),
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });

      return true;
    } catch (e) {
      debugPrint('リアルタイム受信コンテンツ適用エラー: $e');
      return false;
    }
  }

  /// 通知を既読にする
  Future<void> markNotificationAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('notifications')
          .doc(user.uid)
          .collection('items')
          .doc(notificationId)
          .update({'isRead': true, 'readAt': DateTime.now().toIso8601String()});
    } catch (e) {
      debugPrint('通知既読エラー: $e');
    }
  }

  /// 通知を削除
  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('notifications')
          .doc(user.uid)
          .collection('items')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('通知削除エラー: $e');
    }
  }

  /// 接続状態を監視
  Stream<bool> get connectionStateStream {
    return Stream.value(_isConnected);
  }

  /// 通知を非同期で作成（エラーは無視）
  void _createNotificationsAsync(
    String contentId,
    List<String> recipientIds,
    String title,
    String description,
    User user,
    DateTime now,
  ) {
    // 非同期で通知を作成（エラーは無視）
    for (final recipientId in recipientIds) {
      _firestore
          .collection('notifications')
          .doc(recipientId)
          .collection('items')
          .doc(contentId)
          .set({
            'type': 'new_content',
            'contentId': contentId,
            'title': title,
            'description': description,
            'sharedBy': user.uid,
            'sharedByName': user.displayName ?? 'Unknown',
            'sharedAt': now.toIso8601String(),
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          })
          .then((_) => debugPrint('✅ 通知作成完了: 受信者ID=$recipientId'))
          .catchError(
            (error) => debugPrint('❌ 通知作成エラー (受信者ID=$recipientId): $error'),
          );
    }
  }

  /// 同期通知を非同期で作成（エラーは無視）
  void _createSyncNotificationsAsync(
    String syncId,
    List<String> recipientIds,
    String title,
    String description,
    User user,
    DateTime now,
  ) {
    // 非同期で同期通知を作成（エラーは無視）
    for (final recipientId in recipientIds) {
      _firestore
          .collection('notifications')
          .doc(recipientId)
          .collection('items')
          .doc(syncId)
          .set({
            'type': 'new_sync_data',
            'syncId': syncId,
            'title': title,
            'description': description,
            'sharedBy': user.uid,
            'sharedByName': user.displayName ?? 'Unknown',
            'sharedAt': now.toIso8601String(),
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          })
          .then((_) => debugPrint('✅ 同期通知作成完了: 受信者ID=$recipientId'))
          .catchError(
            (error) => debugPrint('❌ 同期通知作成エラー (受信者ID=$recipientId): $error'),
          );
    }
  }

  /// ファミリーIDをリセット（権限エラー時の対処）
  Future<void> _resetFamilyId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      debugPrint('🔧 RealtimeSharingService: ファミリーIDリセット開始');

      // ユーザー情報からファミリーIDを削除
      await _firestore.collection('users').doc(user.uid).update({
        'familyId': null,
      });

      // ローカル情報をクリア
      _familyId = null;
      _familyMembers = [];

      debugPrint('✅ RealtimeSharingService: ファミリーIDリセット完了');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ RealtimeSharingService: ファミリーIDリセットエラー: $e');
    }
  }

  /// ファミリー脱退（RealtimeSharingService版）
  Future<bool> leaveFamily() async {
    if (_familyId == null) return false;

    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      debugPrint('🔧 RealtimeSharingService: ファミリー脱退開始');

      // ファミリードキュメントから自分を非アクティブ化
      final familyRef = _firestore.collection('families').doc(_familyId);
      final snap = await familyRef.get();

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final membersData = (data['members'] as List<dynamic>?) ?? [];
        final remoteMembers = membersData
            .whereType<Map<String, dynamic>>()
            .map((m) => FamilyMember.fromMap(m))
            .toList();

        // 自分がメンバーリストに存在するかチェック
        final selfInMembers = remoteMembers.any((m) => m.id == user.uid);
        if (selfInMembers) {
          // 自分を非アクティブ化
          final updatedMembers = remoteMembers.map((member) {
            if (member.id == user.uid) {
              return member.copyWith(isActive: false);
            }
            return member;
          }).toList();

          await familyRef.update({
            'members': updatedMembers.map((m) => m.toMap()).toList(),
          });
        }
      }

      // ユーザー情報からファミリーIDを削除
      await _firestore.collection('users').doc(user.uid).update({
        'familyId': null,
      });

      // ローカル情報をクリア
      _familyId = null;
      _familyMembers = [];

      debugPrint('✅ RealtimeSharingService: ファミリー脱退成功');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ RealtimeSharingService: ファミリー脱退エラー: $e');
      return false;
    }
  }

  /// ファミリーIDをリセット（パブリックメソッド）
  Future<void> resetFamilyId() async {
    await _resetFamilyId();
  }

  /// サービスを破棄
  @override
  void dispose() {
    _familyListener?.cancel();
    _transmissionsListener?.cancel();
    _syncDataListener?.cancel();
    _notificationsListener?.cancel();
    super.dispose();
  }
}
