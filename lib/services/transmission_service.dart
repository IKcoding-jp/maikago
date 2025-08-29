import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'data_service.dart';
import 'subscription_integration_service.dart';
import '../models/family_member.dart';
import '../models/shared_content.dart';
import '../models/shop.dart';
import '../models/item.dart';
import '../models/sync_data.dart';

/// 送信型共有機能を管理するサービス
/// - タブ・リストの送信・受信
/// - 送信履歴・受信履歴の管理
/// - 受け取り確認機能
/// - ファミリーメンバー管理
/// - タブ・リストの同期機能
class TransmissionService extends ChangeNotifier {
  // Firebase 依存は遅延取得にして、初期化失敗時や未初期化時のクラッシュを防止
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();
  final DataService _dataService = DataService();
  SubscriptionIntegrationService? _subscriptionService;

  // 送信・受信コンテンツ
  List<SharedContent> _sentContents = [];
  List<SharedContent> _receivedContents = [];
  List<TransmissionHistory> _transmissionHistory = [];
  bool _isLoading = false;

  // ファミリー情報
  String? _familyId;
  List<FamilyMember> _familyMembers = [];
  FamilyMember? _currentUserMember;

  // 同期データ
  List<SyncData> _syncDataList = [];
  bool _isSyncing = false;

  // Getters
  List<SharedContent> get sentContents => List.unmodifiable(_sentContents);
  List<SharedContent> get receivedContents =>
      List.unmodifiable(_receivedContents);
  List<TransmissionHistory> get transmissionHistory =>
      List.unmodifiable(_transmissionHistory);
  bool get isLoading => _isLoading;
  List<SyncData> get syncDataList => List.unmodifiable(_syncDataList);
  bool get isSyncing => _isSyncing;

  // ファミリー関連のGetters
  String? get familyId => _familyId;
  List<FamilyMember> get familyMembers => List.unmodifiable(_familyMembers);
  FamilyMember? get currentUserMember => _currentUserMember;
  bool get isFamilyMember => _currentUserMember != null;
  bool get isFamilyOwner => _currentUserMember?.role == FamilyRole.owner;
  bool get canUseFamilySharing => true; // 一時的に常にtrueを返す

  /// 送信型共有サービスを初期化
  Future<void> initialize() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _setLoading(true);
      await _loadFamilyInfo(user.uid);
      await _loadTransmissionData(user.uid);
      await _loadSyncData(user.uid);
    } catch (e) {
      debugPrint('送信型共有初期化エラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 送信・受信データを読み込み
  Future<void> _loadTransmissionData(String userId) async {
    try {
      // 送信したコンテンツを読み込み
      await _loadSentContents(userId);

      // 受信したコンテンツを読み込み
      await _loadReceivedContents(userId);

      // 送信履歴を読み込み
      await _loadTransmissionHistory(userId);

      notifyListeners();
    } catch (e) {
      debugPrint('送信・受信データ読み込みエラー: $e');
    }
  }

  /// 同期データを読み込み
  Future<void> _loadSyncData(String userId) async {
    try {
      final syncQuery = await _firestore
          .collection('syncData')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      _syncDataList =
          syncQuery.docs.map((doc) => SyncData.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('同期データ読み込みエラー: $e');
      _syncDataList = [];
    }
  }

  /// 送信したコンテンツを読み込み
  Future<void> _loadSentContents(String userId) async {
    try {
      final sentQuery = await _firestore
          .collection('transmissions')
          .where('sharedBy', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('sharedAt', descending: true)
          .get();

      _sentContents = sentQuery.docs
          .map((doc) => SharedContent.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('送信コンテンツ読み込みエラー: $e');
      _sentContents = [];
    }
  }

  /// 受信したコンテンツを読み込み
  Future<void> _loadReceivedContents(String userId) async {
    try {
      final receivedQuery = await _firestore
          .collection('transmissions')
          .where('sharedWith', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('sharedAt', descending: true)
          .get();

      _receivedContents = receivedQuery.docs
          .map((doc) => SharedContent.fromMap(doc.data()))
          .map((content) {
        // ローカル側では、もし自分が受信対象で送信者でなければ
        // ステータスを'received'として扱う（送信者側は'sent'のまま）
        if (content.sharedWith.contains(userId) &&
            content.sharedBy != userId &&
            content.status == TransmissionStatus.sent) {
          return content.copyWith(status: TransmissionStatus.received);
        }
        return content;
      }).toList();
    } catch (e) {
      debugPrint('受信コンテンツ読み込みエラー: $e');
      _receivedContents = [];
    }
  }

  /// 送信履歴を読み込み
  Future<void> _loadTransmissionHistory(String userId) async {
    try {
      final historyQuery = await _firestore
          .collection('transmissionHistory')
          .where('senderId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('sentAt', descending: true)
          .get();

      _transmissionHistory = historyQuery.docs
          .map((doc) => TransmissionHistory.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('送信履歴読み込みエラー: $e');
      _transmissionHistory = [];
    }
  }

  /// ファミリー情報を読み込み
  Future<void> _loadFamilyInfo(String userId) async {
    try {
      debugPrint('🔧 TransmissionService: ファミリー情報読み込み開始 - ユーザーID: $userId');

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _familyId = userData['familyId'] as String?;

        debugPrint('👨‍👩‍👧‍👦 TransmissionService: ファミリーID: $_familyId');

        if (_familyId != null) {
          await _loadFamilyMembers();
        } else {
          debugPrint('ℹ️ TransmissionService: ファミリーIDが設定されていません');
        }
      } else {
        debugPrint('❌ TransmissionService: ユーザードキュメントが存在しません');
      }
    } catch (e) {
      debugPrint('❌ TransmissionService: ファミリー情報読み込みエラー: $e');
    }
  }

  /// ファミリーメンバーを読み込み
  Future<void> _loadFamilyMembers() async {
    try {
      if (_familyId == null) return;

      debugPrint('👨‍👩‍👧‍👦 TransmissionService: ファミリーメンバー読み込み開始');
      final familyDoc =
          await _firestore.collection('families').doc(_familyId).get();

      if (familyDoc.exists) {
        final familyData = familyDoc.data() as Map<String, dynamic>;
        final membersData = familyData['members'] as List<dynamic>? ?? [];
        final ownerIdInDoc = familyData['ownerId']?.toString();

        debugPrint('📊 TransmissionService: メンバーデータ: $membersData');

        // membersData を処理（nullや不正な要素は除外）
        _familyMembers = membersData
            .whereType<Map<String, dynamic>>()
            .map((memberData) => FamilyMember.fromMap(memberData))
            .where((member) => member.isActive)
            .toList();

        // フォールバック: メンバーが空で ownerId が設定されており、
        // その ownerId が自分なら少なくとも自分をオーナーとしてローカルに反映
        if (_familyMembers.isEmpty && ownerIdInDoc != null) {
          final currentUserId = _auth.currentUser?.uid;
          if (currentUserId != null && currentUserId == ownerIdInDoc) {
            final fallbackOwner = FamilyMember(
              id: currentUserId,
              displayName: _auth.currentUser?.displayName ?? 'Owner',
              email: _auth.currentUser?.email ?? '',
              photoUrl: _auth.currentUser?.photoURL,
              role: FamilyRole.owner,
              joinedAt: DateTime.now(),
              isActive: true,
            );
            _familyMembers = [fallbackOwner];
          }
        }

        debugPrint(
          '✅ TransmissionService: ファミリーメンバー読み込み完了 (${_familyMembers.length}人)',
        );

        // 各メンバーの詳細情報をログ出力
        for (final member in _familyMembers) {
          debugPrint(
            '👤 メンバー: ${member.displayName} (ID: ${member.id}, Email: ${member.email}, Role: ${member.role})',
          );
        }

        // 現在のユーザーのメンバー情報を設定
        final currentUserId = _auth.currentUser?.uid;
        if (currentUserId != null) {
          final found = _familyMembers.where((m) => m.id == currentUserId);
          if (found.isNotEmpty) {
            _currentUserMember = found.first;
          } else {
            final isOwnerByDoc =
                ownerIdInDoc != null && ownerIdInDoc == currentUserId;
            _currentUserMember = FamilyMember(
              id: currentUserId,
              displayName: _auth.currentUser?.displayName ?? 'Unknown',
              email: _auth.currentUser?.email ?? '',
              photoUrl: _auth.currentUser?.photoURL,
              role: isOwnerByDoc ? FamilyRole.owner : FamilyRole.member,
              joinedAt: DateTime.now(),
              isActive: true,
            );
          }

          debugPrint(
            '👤 TransmissionService: 現在のユーザーメンバー: ${_currentUserMember?.displayName} (${_currentUserMember?.role})',
          );
        }
      } else {
        debugPrint('❌ TransmissionService: ファミリードキュメントが存在しません');
        _familyMembers = [];
      }
    } catch (e) {
      debugPrint('❌ TransmissionService: ファミリーメンバー読み込みエラー: $e');
      _familyMembers = [];

      // 権限エラーの場合は、ファミリーIDをリセット
      if (e.toString().contains('permission-denied')) {
        debugPrint(
          '🔒 TransmissionService: ファミリーアクセス権限がありません。ファミリーIDをリセットします。',
        );
        await _resetFamilyId();
      }
    }
  }

  /// コンテンツを送信
  Future<bool> sendContent({
    required Shop shop,
    required String title,
    required String description,
    required List<FamilyMember> recipients,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    debugPrint('🚀 TransmissionService: 送信開始');
    debugPrint('👤 送信者: ${user.displayName} (${user.uid})');
    debugPrint(
      '📋 送信内容: shop=${shop.name}, title=$title, recipients=${recipients.length}人',
    );

    for (final recipient in recipients) {
      debugPrint(
        '👥 受信者: ${recipient.displayName} (ID: ${recipient.id}, Email: ${recipient.email})',
      );
    }

    _setLoading(true);
    try {
      final contentId = _uuid.v4();
      final now = DateTime.now();
      final recipientIds = recipients.map((member) => member.id).toList();
      final recipientNames =
          recipients.map((member) => member.displayName).toList();

      debugPrint('🆔 生成されたcontentId: $contentId');
      debugPrint('📝 受信者IDリスト: $recipientIds');

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

      // Firestoreに送信コンテンツを保存
      debugPrint('💾 TransmissionService: Firestoreに送信コンテンツを保存中...');
      try {
        await _firestore.collection('transmissions').doc(contentId).set({
          ...sharedContent.toMap(),
          'shopData': shop.toMap(),
        });
        debugPrint('✅ TransmissionService: 送信コンテンツ保存完了');
      } catch (e) {
        debugPrint('❌ TransmissionService: 送信コンテンツ保存エラー: $e');
        rethrow;
      }

      // 送信履歴を作成
      final historyId = _uuid.v4();
      final transmissionHistory = TransmissionHistory(
        id: historyId,
        contentId: contentId,
        contentTitle: title,
        contentType: SharedContentType.tab,
        senderId: user.uid,
        senderName: user.displayName ?? 'Unknown',
        receiverIds: recipientIds,
        receiverNames: recipientNames,
        sentAt: now,
        status: TransmissionStatus.sent,
      );

      // 送信履歴を保存
      await _firestore
          .collection('transmissionHistory')
          .doc(historyId)
          .set(transmissionHistory.toMap());

      // ローカルデータを更新
      _sentContents.insert(0, sharedContent);
      _transmissionHistory.insert(0, transmissionHistory);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('コンテンツ送信エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 受信コンテンツを受け取り（自分のリストに追加）
  Future<bool> acceptReceivedContent(SharedContent receivedContent) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    try {
      final now = DateTime.now();

      // 受信コンテンツの状態を更新
      await _firestore
          .collection('transmissions')
          .doc(receivedContent.id)
          .update({
        'status': TransmissionStatus.accepted.name,
        'acceptedAt': now.toIso8601String(),
      });

      // 実際のShopコレクションに受信したコンテンツを追加
      // これは既存のDataServiceと連携して実装する必要があります
      if (receivedContent.content != null) {
        final newShopId = _uuid.v4();
        final newShop = receivedContent.content!.copyWith(
          id: newShopId,
          name: '${receivedContent.title} (受信)',
        );

        await _firestore.collection('shops').doc(newShopId).set({
          ...newShop.toMap(),
          'userId': user.uid,
          'receivedFrom': receivedContent.sharedBy,
          'receivedAt': now.toIso8601String(),
        });
      }

      // ローカルデータを更新
      final updatedContent = receivedContent.copyWith(
        status: TransmissionStatus.accepted,
      );
      final index = _receivedContents.indexWhere(
        (content) => content.id == receivedContent.id,
      );
      if (index >= 0) {
        _receivedContents[index] = updatedContent;
      }
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('受信コンテンツ受け取りエラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 送信したコンテンツを削除
  Future<bool> deleteSentContent(String contentId) async {
    _setLoading(true);
    try {
      // Firestoreから論理削除
      await _firestore.collection('transmissions').doc(contentId).update({
        'isActive': false,
        'status': TransmissionStatus.deleted.name,
        'deletedAt': DateTime.now().toIso8601String(),
      });

      // ローカルから削除
      _sentContents.removeWhere((content) => content.id == contentId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('送信コンテンツ削除エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 受信したコンテンツを削除
  Future<bool> deleteReceivedContent(String contentId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    try {
      // 受信者リストから自分を削除
      final contentDoc =
          await _firestore.collection('transmissions').doc(contentId).get();
      if (contentDoc.exists) {
        final data = contentDoc.data()!;
        final sharedWith = List<String>.from(data['sharedWith'] ?? []);
        sharedWith.remove(user.uid);

        if (sharedWith.isEmpty) {
          // 受信者がいなくなった場合は論理削除
          await _firestore.collection('transmissions').doc(contentId).update({
            'isActive': false,
            'status': TransmissionStatus.deleted.name,
            'deletedAt': DateTime.now().toIso8601String(),
          });
        } else {
          // 受信者リストを更新
          await _firestore.collection('transmissions').doc(contentId).update({
            'sharedWith': sharedWith,
          });
        }
      }

      // ローカルから削除
      _receivedContents.removeWhere((content) => content.id == contentId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('受信コンテンツ削除エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// タブとリストを同期して送信
  Future<bool> syncAndSendTab({
    required Shop shop,
    required String title,
    required String description,
    required List<FamilyMember> recipients,
    required List<Item> items,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _setSyncing(true);
    try {
      final syncId = _uuid.v4();
      final now = DateTime.now();
      final recipientIds = recipients.map((member) => member.id).toList();
      final recipientNames =
          recipients.map((member) => member.displayName).toList();

      // 送信対象のアイテムは常に shop.items（未購入・購入済みの両方）を使用する
      final allItems = List<Item>.from(shop.items);

      // 同期データを作成
      final syncData = SyncData(
        id: syncId,
        userId: user.uid,
        type: SyncDataType.tab,
        shopId: shop.id,
        shopName: shop.name,
        items: allItems,
        title: title,
        description: description,
        createdAt: now,
        sharedWith: recipientIds,
        isActive: true,
      );

      // 送信コンテンツを作成
      final sharedContent = SharedContent(
        id: syncId,
        title: title,
        description: description,
        type: SharedContentType.tab,
        // sync用のSharedContentはsyncDataのIDをcontentIdとして保持します
        contentId: syncId,
        content: shop,
        sharedBy: user.uid,
        sharedByName: user.displayName ?? 'Unknown',
        sharedAt: now,
        sharedWith: recipientIds,
        status: TransmissionStatus.sent,
        isActive: true,
      );

      // Firestoreに同期データと送信コンテンツを保存
      await Future.wait([
        _firestore.collection('syncData').doc(syncId).set({
          ...syncData.toMap(),
          'shopData': shop.toMap(),
          'itemsData': allItems.map((item) => item.toMap()).toList(),
          'timestamp': FieldValue.serverTimestamp(),
        }),
        _firestore.collection('transmissions').doc(syncId).set({
          ...sharedContent.toMap(),
          'shopData': shop.toMap(),
          'itemsData': allItems.map((item) => item.toMap()).toList(),
          'timestamp': FieldValue.serverTimestamp(),
        }),
      ]);

      // 送信履歴を作成
      final historyId = _uuid.v4();
      final transmissionHistory = TransmissionHistory(
        id: historyId,
        contentId: syncId,
        contentTitle: title,
        contentType: SharedContentType.tab,
        senderId: user.uid,
        senderName: user.displayName ?? 'Unknown',
        receiverIds: recipientIds,
        receiverNames: recipientNames,
        sentAt: now,
        status: TransmissionStatus.sent,
      );

      // 送信履歴を保存
      await _firestore
          .collection('transmissionHistory')
          .doc(historyId)
          .set(transmissionHistory.toMap());

      // ローカルデータを更新
      _syncDataList.insert(0, syncData);
      _sentContents.insert(0, sharedContent);
      _transmissionHistory.insert(0, transmissionHistory);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('タブ同期送信エラー: $e');
      return false;
    } finally {
      _setSyncing(false);
    }
  }

  /// 受信したタブを自分のアプリに適用
  Future<bool> applyReceivedTab(
    SharedContent receivedContent, {
    bool overwriteExisting = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // 同期データを取得（syncData が存在しなければ transmissions の shopData を使う）
      final syncDoc = await _firestore
          .collection('syncData')
          .doc(receivedContent.contentId)
          .get();

      Map<String, dynamic>? syncMap;
      if (syncDoc.exists) {
        syncMap = syncDoc.data() as Map<String, dynamic>;
      } else {
        // fallback: transmissions ドキュメントから shopData/itemsData を取得
        final transDoc = await _firestore
            .collection('transmissions')
            .doc(receivedContent.id)
            .get();
        if (transDoc.exists) {
          syncMap = transDoc.data();
        }
      }

      if (syncMap == null) {
        debugPrint(
          '受信データが見つかりません: ${receivedContent.contentId} / ${receivedContent.id}',
        );
        return false;
      }

      // 受信者を sharedWith に追加（transmissions または syncData を更新）
      try {
        final sharedWith = (syncMap['sharedWith'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        if (!sharedWith.contains(user.uid)) {
          sharedWith.add(user.uid);
          // 更新先は syncData が元なら syncData、そうでなければ transmissions
          if (syncDoc.exists) {
            await _firestore
                .collection('syncData')
                .doc(receivedContent.contentId)
                .update({
              'sharedWith': sharedWith,
              'appliedAt': DateTime.now().toIso8601String(),
            });
          } else {
            await _firestore
                .collection('transmissions')
                .doc(receivedContent.id)
                .update({
              'sharedWith': sharedWith,
              'acceptedAt': DateTime.now().toIso8601String(),
              'status': TransmissionStatus.accepted.name,
            });
          }
        }
      } catch (e) {
        debugPrint('受信データ sharedWith 更新エラー: $e');
      }

      // ローカルへ保存：shopData と itemsData があれば保存する
      try {
        final shopData = syncMap['shopData'] as Map<String, dynamic>? ??
            syncMap['content'] as Map<String, dynamic>?;
        final itemsData = (syncMap['itemsData'] as List<dynamic>?) ??
            (syncMap['items'] as List<dynamic>?);

        // 保存先 shopId を決定。overwriteExisting=true の場合は既存の同名タブを探して上書き
        final targetUserShops =
            _firestore.collection('users').doc(user.uid).collection('shops');

        String targetShopId = _uuid.v4();
        if (shopData != null) {
          final shopMap = Map<String, dynamic>.from(shopData);
          // 同名上書きが要求されている場合は既存のショップを検索
          if (overwriteExisting) {
            try {
              final existingQuery = await targetUserShops
                  .where('name', isEqualTo: shopMap['name'])
                  .limit(1)
                  .get();
              if (existingQuery.docs.isNotEmpty) {
                targetShopId = existingQuery.docs.first.id;
              }
            } catch (e) {
              debugPrint('既存ショップ検索エラー: $e');
            }
          }

          // 保存（既存ID を使えば上書き、なければ新規作成）
          shopMap['id'] = targetShopId;
          shopMap['createdAt'] =
              shopMap['createdAt'] ?? DateTime.now().toIso8601String();
          final shop = Shop.fromMap(shopMap);
          await _dataService.saveShop(shop);

          // items を保存
          if (itemsData != null && itemsData.isNotEmpty) {
            final incomingIds = <String>[];
            for (final rawItem in itemsData) {
              try {
                final itemMap = Map<String, dynamic>.from(rawItem as Map);
                itemMap['id'] = itemMap['id']?.toString() ?? _uuid.v4();
                incomingIds.add(itemMap['id']);
                itemMap['shopId'] = targetShopId;
                itemMap['createdAt'] =
                    itemMap['createdAt'] ?? DateTime.now().toIso8601String();
                final item = Item.fromMap(itemMap);
                await _dataService.saveItem(item);
              } catch (e) {
                debugPrint('受信アイテム保存エラー: $e');
              }
            }

            // overwrite の場合、既存の同タブに属するアイテムで incoming に含まれないものは削除する
            if (overwriteExisting) {
              try {
                final userItemsRef = _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('items');
                final existingItemsSnap = await userItemsRef
                    .where('shopId', isEqualTo: targetShopId)
                    .get();
                for (final ex in existingItemsSnap.docs) {
                  if (!incomingIds.contains(ex.id)) {
                    await userItemsRef.doc(ex.id).delete();
                  }
                }
              } catch (e) {
                debugPrint('既存アイテム整理エラー: $e');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('ローカル保存エラー: $e');
      }

      // 受信コンテンツの状態を更新（transmissions）
      try {
        await _firestore
            .collection('transmissions')
            .doc(receivedContent.id)
            .update({
          'status': TransmissionStatus.accepted.name,
          'acceptedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('transmissions ステータス更新エラー: $e');
      }

      // ローカルデータを更新
      final updatedContent = receivedContent.copyWith(
        status: TransmissionStatus.accepted,
      );

      final index = _receivedContents.indexWhere(
        (c) => c.id == receivedContent.id,
      );
      if (index != -1) {
        _receivedContents[index] = updatedContent;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('受信タブ適用エラー: $e');
      return false;
    }
  }

  /// 同期データを取得
  Future<List<SyncData>> getSyncDataForUser(String userId) async {
    try {
      final syncQuery = await _firestore
          .collection('syncData')
          .where('sharedWith', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return syncQuery.docs.map((doc) => SyncData.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('同期データ取得エラー: $e');
      return [];
    }
  }

  /// 送信可能なShopリストを取得（同期データ付き）
  Future<List<Shop>> getAvailableShopsForTransmission() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // ユーザーのShopを取得（実際のアプリではDataProviderから取得）
      // ここでは仮のデータを返す
      return [];
    } catch (e) {
      debugPrint('送信可能Shop取得エラー: $e');
      return [];
    }
  }

  /// 同期状態をチェック
  Future<bool> checkSyncStatus(String syncId) async {
    try {
      final syncDoc = await _firestore.collection('syncData').doc(syncId).get();

      return syncDoc.exists && syncDoc.data()?['isActive'] == true;
    } catch (e) {
      debugPrint('同期状態チェックエラー: $e');
      return false;
    }
  }

  /// 同期データを削除
  Future<bool> deleteSyncData(String syncId) async {
    try {
      await _firestore.collection('syncData').doc(syncId).update({
        'isActive': false,
      });

      // ローカルデータから削除
      _syncDataList.removeWhere((data) => data.id == syncId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('同期データ削除エラー: $e');
      return false;
    }
  }

  /// 送信統計を取得
  Map<String, int> getTransmissionStats() {
    return {
      'totalSent': _sentContents.length,
      'totalReceived': _receivedContents.length,
      'totalAccepted': _receivedContents
          .where((content) => content.status == TransmissionStatus.accepted)
          .length,
      'totalPending': _receivedContents
          .where((content) => content.status == TransmissionStatus.received)
          .length,
    };
  }

  /// データを再読み込み
  Future<void> refresh() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _loadTransmissionData(user.uid);
    await _loadSyncData(user.uid);
  }

  // MARK: - ファミリー管理機能

  /// ファミリーを作成
  Future<bool> createFamily() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    try {
      // 既にユーザーがファミリーに所属していないかを厳密にチェックする。
      // 勝手に新規作成される事象を防ぐため、usersドキュメントのfamilyIdを優先的に参照する。
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final existingFamilyId =
            (userDoc.exists ? (userDoc.data()?['familyId'] as String?) : null);
        if (existingFamilyId != null && existingFamilyId.isNotEmpty) {
          debugPrint(
            '🔒 TransmissionService: ユーザーは既にファミリーに所属しています familyId=$existingFamilyId - 新規作成を中止します',
          );

          // ローカル状態を既存ファミリーに合わせて更新しておく
          _familyId = existingFamilyId;
          await _loadFamilyMembers();

          return false;
        }
      } catch (e) {
        // ユーザードキュメント取得に失敗しても安全側で処理を続ける。
        debugPrint('ユーザードキュメントチェック中にエラー: $e');
      }

      final familyId = _uuid.v4();
      final now = DateTime.now();

      // ファミリーオーナーを作成
      final owner = FamilyMember(
        id: user.uid,
        displayName: user.displayName ?? 'Unknown',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        role: FamilyRole.owner,
        joinedAt: now,
        isActive: true,
      );

      // ファミリーを作成
      await _firestore.collection('families').doc(familyId).set({
        'id': familyId,
        'name': '${owner.displayName}のファミリー',
        'createdBy': user.uid,
        'createdByName': owner.displayName,
        'ownerId': user.uid, // オーナーIDを追加
        'createdAt': now.toIso8601String(),
        'members': [owner.toMap()],
        'isActive': true,
      });

      // ユーザー情報にファミリーIDを設定
      await _firestore.collection('users').doc(user.uid).update({
        'familyId': familyId,
      });

      // ローカル情報を更新
      _familyId = familyId;
      _familyMembers = [owner];
      _currentUserMember = owner;

      // オーナーのサブスクリプション情報をファミリープランに更新（可能な場合）
      try {
        final ownerSubRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('subscription')
            .doc('current');
        await ownerSubRef.set({
          'planType': 'family',
          'isActive': true,
          'expiryDate': null,
          'familyMembers': FieldValue.arrayUnion([user.uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('✅ TransmissionService: オーナーのサブスクリプションをファミリーに設定しました');
      } catch (e) {
        debugPrint('❌ TransmissionService: オーナーのサブスクリプション更新に失敗しました: $e');
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ファミリー作成エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// QRコード招待でファミリーに参加
  Future<bool> joinFamilyByQRCode(String inviteToken) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    _setLoading(true);
    try {
      debugPrint('🔧 TransmissionService: ファミリー招待承認開始 - トークン: $inviteToken');

      // 招待トークンからファミリーIDを取得
      final inviteDoc =
          await _firestore.collection('familyInvites').doc(inviteToken).get();

      if (!inviteDoc.exists) {
        debugPrint('❌ TransmissionService: 招待トークンが存在しません');
        return false;
      }

      final inviteData = inviteDoc.data() as Map<String, dynamic>;
      final familyId = inviteData['familyId'] as String;
      final inviteId = inviteToken;
      final expiresAt = DateTime.parse(inviteData['expiresAt']);
      final isUsed = inviteData['isUsed'] ?? false;

      // 招待の有効性をチェック
      if (DateTime.now().isAfter(expiresAt)) {
        debugPrint('❌ TransmissionService: 招待トークンの期限が切れています');
        return false;
      }

      if (isUsed) {
        debugPrint('❌ TransmissionService: 招待トークンは既に使用済みです');
        return false;
      }

      debugPrint('✅ TransmissionService: 招待トークンが有効です - ファミリーID: $familyId');

      // 新しいメンバーを作成
      final member = FamilyMember(
        id: user.uid,
        displayName: user.displayName ?? 'Unknown',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        role: FamilyRole.member,
        joinedAt: DateTime.now(),
        isActive: true,
      );

      debugPrint('👤 TransmissionService: 新しいメンバーを作成: ${member.displayName}');

      // バッチ処理で複数の更新を同時に実行
      final batch = _firestore.batch();

      // 1. ファミリーにメンバーを追加（権限エラーを回避するため、直接更新を試みる）
      final familyRef = _firestore.collection('families').doc(familyId);
      batch.update(familyRef, {
        'members': FieldValue.arrayUnion([member.toMap()]),
      });

      // 2. ユーザー情報にファミリーIDを設定
      final userRef = _firestore.collection('users').doc(user.uid);
      batch.update(userRef, {'familyId': familyId});

      // 3. 招待を使用済みにマーク
      final inviteRef = _firestore.collection('familyInvites').doc(inviteId);
      batch.update(inviteRef, {
        'isUsed': true,
        'usedAt': DateTime.now().toIso8601String(),
        'usedBy': user.uid,
      });

      // バッチ処理を実行
      try {
        await batch.commit();
        debugPrint('✅ TransmissionService: ファミリーメンバー追加完了');

        // ローカル情報を更新
        _familyId = familyId;
        _familyMembers = [member];
        _currentUserMember = member;

        debugPrint('✅ TransmissionService: ファミリー招待承認完了');

        // ファミリー情報を再読み込み（権限があれば）
        try {
          await _loadFamilyMembers();
        } catch (e) {
          debugPrint('ℹ️ TransmissionService: ファミリーメンバー情報の読み込みをスキップ: $e');
        }

        // 招待ユーザー自身のサブスクリプション情報を可能な範囲でファミリープランとして更新
        try {
          final subRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('subscription')
              .doc('current');
          final memberIds = _familyMembers.map((m) => m.id).toList();

          // 現在のプランを確認
          final currentSubDoc = await subRef.get();
          final currentPlanType = currentSubDoc.data()?['planType'] ?? 'free';

          // どのプランからでもファミリープランに自動移行
          if (currentPlanType != 'family') {
            await subRef.set({
              'planType': 'family',
              'isActive': true,
              'expiryDate': null,
              'familyMembers': memberIds,
              'autoUpgradedFrom': currentPlanType, // 移行元プランを記録
              'upgradedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            debugPrint(
              '✅ TransmissionService: $currentPlanTypeからファミリープランへの自動移行が完了しました',
            );
          } else {
            // 既にファミリープランの場合は既存の設定を維持
            await subRef.set({
              'familyMembers': memberIds,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            debugPrint('ℹ️ TransmissionService: 既存のファミリープラン設定を維持しました');
          }
        } catch (e) {
          debugPrint('ℹ️ TransmissionService: 招待ユーザーのサブスクリプション更新に失敗: $e');
        }

        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('❌ TransmissionService: バッチ処理エラー: $e');

        // 権限エラーの詳細を確認
        if (e.toString().contains('permission-denied')) {
          debugPrint('🔒 TransmissionService: ファミリー更新権限がありません');
          debugPrint('詳細エラー: $e');

          // 招待トークンのみを使用済みにマークして終了
          try {
            await _firestore.collection('familyInvites').doc(inviteId).update({
              'isUsed': true,
              'usedAt': DateTime.now().toIso8601String(),
              'usedBy': user.uid,
              'error': 'Permission denied when adding member',
            });
          } catch (updateError) {
            debugPrint('❌ TransmissionService: 招待トークン更新エラー: $updateError');
          }
        }
        return false;
      }
    } catch (e) {
      debugPrint('❌ TransmissionService: 招待承認エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// QRコードデータを取得
  Future<Map<String, dynamic>?> getQRCodeData() async {
    if (!isFamilyOwner) return null;

    try {
      final inviteToken = _uuid.v4();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7));

      // 招待トークンを作成
      await _firestore.collection('familyInvites').doc(inviteToken).set({
        'familyId': _familyId,
        'createdBy': _auth.currentUser?.uid,
        'createdByName': _auth.currentUser?.displayName ?? 'Unknown',
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isUsed': false,
      });

      return {
        'type': 'family_invite',
        'familyId': _familyId,
        'inviteToken': inviteToken,
        'createdByName': _auth.currentUser?.displayName ?? 'Unknown',
        'expiresAt': expiresAt.toIso8601String(),
      };
    } catch (e) {
      debugPrint('QRコードデータ取得エラー: $e');
      return null;
    }
  }

  /// QRコード招待トークンを検証
  Future<bool> validateQRCodeInviteToken(String token) async {
    try {
      debugPrint('🔧 TransmissionService: 招待トークン検証開始 - トークン: $token');

      final inviteDoc =
          await _firestore.collection('familyInvites').doc(token).get();

      if (!inviteDoc.exists) {
        debugPrint('❌ TransmissionService: 招待トークンが存在しません');
        return false;
      }

      final inviteData = inviteDoc.data() as Map<String, dynamic>;
      final expiresAt = DateTime.parse(inviteData['expiresAt']);
      final isUsed = inviteData['isUsed'] ?? false;
      final familyId = inviteData['familyId'] as String?;

      debugPrint('📅 TransmissionService: 招待期限: $expiresAt');
      debugPrint('🔍 TransmissionService: 使用済み: $isUsed');
      debugPrint('👨‍👩‍👧‍👦 TransmissionService: ファミリーID: $familyId');

      // 期限切れチェック
      if (DateTime.now().isAfter(expiresAt)) {
        debugPrint('❌ TransmissionService: 招待トークンの期限が切れています');
        return false;
      }

      // 使用済みチェック
      if (isUsed) {
        debugPrint('❌ TransmissionService: 招待トークンは既に使用済みです');
        return false;
      }

      debugPrint('✅ TransmissionService: 招待トークンが有効です');
      return true;
    } catch (e) {
      debugPrint('❌ TransmissionService: QRコード招待トークン検証エラー: $e');

      // 権限エラーの場合は、トークンが無効であることを示す
      if (e.toString().contains('permission-denied')) {
        debugPrint('🔒 TransmissionService: 招待トークンへのアクセス権限がありません');
        return false;
      }

      return false;
    }
  }

  /// QRコード招待トークンを使用済みにマーク
  Future<bool> markQRCodeInviteTokenAsUsed(String token) async {
    try {
      await _firestore.collection('familyInvites').doc(token).update({
        'isUsed': true,
        'usedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('QRコード招待トークン使用済みマークエラー: $e');
      return false;
    }
  }

  /// SubscriptionIntegrationServiceを設定
  void setSubscriptionService(SubscriptionIntegrationService service) {
    // 既に同じServiceが設定されている場合は何もしない
    if (_subscriptionService == service) {
      return;
    }
    _subscriptionService = service;
  }

  /// ファミリー脱退
  Future<bool> leaveFamily() async {
    if (_familyId == null) return false;

    // オーナー判定の堅牢化: _currentUserMember に依存せず families.ownerId を確認
    final user = _auth.currentUser;
    if (user == null) return false;

    String? ownerIdInDoc;
    try {
      final famSnap =
          await _firestore.collection('families').doc(_familyId).get();
      if (famSnap.exists) {
        final fData = famSnap.data() as Map<String, dynamic>;
        ownerIdInDoc = fData['ownerId']?.toString();
      }
    } catch (e) {
      debugPrint('❌ TransmissionService: 脱退前のファミリーデータ取得エラー: $e');
    }

    final isOwnerByDoc = ownerIdInDoc != null && ownerIdInDoc == user.uid;
    if (isOwnerByDoc) return false; // オーナーは離脱できない

    _setLoading(true);
    try {
      // 最新のメンバー配列を取得してから自分を非アクティブ化
      final familyRef = _firestore.collection('families').doc(_familyId);
      final snap = await familyRef.get();
      final data = snap.data();
      final membersData = (data?['members'] as List<dynamic>?) ?? [];
      final remoteMembers = membersData
          .whereType<Map<String, dynamic>>()
          .map((m) => FamilyMember.fromMap(m))
          .toList();

      // 自分がメンバーリストに存在するかチェック
      final selfInMembers = remoteMembers.any((m) => m.id == user.uid);
      if (!selfInMembers) {
        debugPrint(
          '⚠️ TransmissionService: 自分がメンバーリストに存在しません。直接familyIdを削除します。',
        );
        // 自分がメンバーリストに存在しない場合は、直接ユーザー情報からfamilyIdを削除
        await _firestore.collection('users').doc(user.uid).update({
          'familyId': null,
        });
      } else {
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

        // ユーザー情報からファミリーIDを削除
        await _firestore.collection('users').doc(user.uid).update({
          'familyId': null,
        });
      }

      // ローカル情報をクリア
      _familyId = null;
      _familyMembers = [];
      _currentUserMember = null;
      _sentContents = [];
      _receivedContents = [];

      // SubscriptionIntegrationServiceにファミリー脱退を通知（特典無効化）
      // 次のフレームで通知することでビルド中のsetStateエラーを回避
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _subscriptionService?.notifyListeners();
      });

      // ファミリープラン加入者でないメンバーが脱退した場合は、元のプランへ復元
      try {
        final subRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('subscription')
            .doc('current');

        final currentSubDoc = await subRef.get();
        final data = currentSubDoc.data();
        final currentPlanType = data?['planType']?.toString();
        final autoUpgradedFrom = data?['autoUpgradedFrom']?.toString();

        // 招待参加時に family へ自動移行された記録があれば、それを元に戻す
        if (currentPlanType == 'family' &&
            autoUpgradedFrom != null &&
            autoUpgradedFrom.isNotEmpty) {
          await subRef.set({
            'planType': autoUpgradedFrom,
            'isActive': autoUpgradedFrom != 'free',
            'familyMembers': [],
            'autoUpgradedFrom': FieldValue.delete(),
            'upgradedAt': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint(
              '✅ TransmissionService: 脱退に伴いプランを$autoUpgradedFromへ復元しました');
        } else if (currentPlanType == 'family' &&
            (autoUpgradedFrom == null || autoUpgradedFrom.isEmpty)) {
          // 参加前の情報が不明な場合はフリープランへフォールバック
          await subRef.set({
            'planType': 'free',
            'isActive': false,
            'familyMembers': [],
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint('ℹ️ TransmissionService: 脱退時に元プラン情報が無いためフリープランへ戻しました');
        }
      } catch (e) {
        debugPrint('ℹ️ TransmissionService: 脱退後のサブスク復元処理に失敗: $e');
      }

      notifyListeners();
      debugPrint('✅ TransmissionService: ファミリー脱退成功');
      return true;
    } catch (e) {
      debugPrint('ファミリー離脱エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ファミリー解散
  Future<bool> dissolveFamily() async {
    if (_familyId == null) return false;

    // オーナー判定の堅牢化: _currentUserMember に依存せず families.ownerId を確認
    final user = _auth.currentUser;
    if (user == null) return false;

    String? ownerIdInDoc;
    List<FamilyMember> remoteMembers = [];
    try {
      final famSnap =
          await _firestore.collection('families').doc(_familyId).get();
      if (famSnap.exists) {
        final fData = famSnap.data() as Map<String, dynamic>;
        ownerIdInDoc = fData['ownerId']?.toString();
        final membersData = (fData['members'] as List<dynamic>?) ?? [];
        remoteMembers = membersData
            .whereType<Map<String, dynamic>>()
            .map((m) => FamilyMember.fromMap(m))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ TransmissionService: 解散前のファミリーデータ取得エラー: $e');
    }

    final isOwnerByDoc = ownerIdInDoc != null && ownerIdInDoc == user.uid;
    if (!isFamilyOwner && !isOwnerByDoc) return false;

    _setLoading(true);
    try {
      debugPrint('🔧 TransmissionService: ファミリー解散開始 - familyId: $_familyId');

      // ファミリードキュメントを解散状態に更新
      await _firestore.collection('families').doc(_familyId).update({
        'dissolvedAt': DateTime.now().toIso8601String(),
        'isActive': false,
        'dissolvedBy': _auth.currentUser!.uid,
      });

      // 解散通知を各メンバーに送信（最新メンバーで実施）
      final batch = _firestore.batch();
      final notifyTargets =
          remoteMembers.isNotEmpty ? remoteMembers : _familyMembers;
      for (final member in notifyTargets) {
        if (member.id != _auth.currentUser!.uid) {
          // 自分以外のメンバー
          final notificationRef = _firestore
              .collection('notifications')
              .doc(member.id)
              .collection('items')
              .doc();

          batch.set(notificationRef, {
            'type': 'family_dissolved',
            'familyId': _familyId,
            'familyName': 'ファミリー',
            'dissolvedBy': _auth.currentUser!.uid,
            'dissolvedByName': _currentUserMember?.displayName ?? 'Unknown',
            'createdAt': DateTime.now().toIso8601String(),
            'isRead': false,
          });
        }
      }
      await batch.commit();

      // すべてのメンバーのユーザードキュメントから familyId を削除
      try {
        final batch2 = _firestore.batch();
        final targets = notifyTargets.isNotEmpty ? notifyTargets : [];
        for (final member in targets) {
          final uref = _firestore.collection('users').doc(member.id);
          batch2.update(uref, {'familyId': null});
        }
        // 自分がリストに含まれていないケースもケア
        final selfRef =
            _firestore.collection('users').doc(_auth.currentUser!.uid);
        batch2.update(selfRef, {'familyId': null});
        await batch2.commit();
      } catch (e) {
        debugPrint('⚠️ TransmissionService: メンバーのfamilyId解除中のエラー: $e');
      }

      // ローカル情報をクリア
      _familyId = null;
      _familyMembers = [];
      _currentUserMember = null;
      _sentContents = [];
      _receivedContents = [];

      notifyListeners();
      debugPrint('✅ TransmissionService: ファミリー解散成功');
      return true;
    } catch (e) {
      debugPrint('❌ TransmissionService: ファミリー解散エラー: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// メンバー削除
  Future<bool> removeMember(String memberId) async {
    if (!isFamilyOwner) return false;
    if (_familyId == null) return false;

    _setLoading(true);
    try {
      // 最新のメンバー配列を取得してから対象を非アクティブ化
      final familyRef = _firestore.collection('families').doc(_familyId);
      final snap = await familyRef.get();
      final data = snap.data();
      final membersData = (data?['members'] as List<dynamic>?) ?? [];
      final remoteMembers = membersData
          .whereType<Map<String, dynamic>>()
          .map((m) => FamilyMember.fromMap(m))
          .toList();

      final updatedMembers = remoteMembers.map((member) {
        if (member.id == memberId) {
          return member.copyWith(isActive: false);
        }
        return member;
      }).toList();

      await familyRef.update({
        'members': updatedMembers.map((m) => m.toMap()).toList(),
      });

      // ユーザー情報からファミリーIDを削除
      await _firestore.collection('users').doc(memberId).update({
        'familyId': null,
      });

      // 対象メンバーのサブスクを元のプランへ復元（参加前が記録されている場合）
      try {
        final subRef = _firestore
            .collection('users')
            .doc(memberId)
            .collection('subscription')
            .doc('current');

        final currentSubDoc = await subRef.get();
        final data = currentSubDoc.data();
        final currentPlanType = data?['planType']?.toString();
        final autoUpgradedFrom = data?['autoUpgradedFrom']?.toString();

        if (currentPlanType == 'family' &&
            autoUpgradedFrom != null &&
            autoUpgradedFrom.isNotEmpty) {
          await subRef.set({
            'planType': autoUpgradedFrom,
            'isActive': autoUpgradedFrom != 'free',
            'familyMembers': [],
            'autoUpgradedFrom': FieldValue.delete(),
            'upgradedAt': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint(
              '✅ TransmissionService: メンバー削除に伴い対象のプランを$autoUpgradedFromへ復元しました (memberId=$memberId)');
        } else if (currentPlanType == 'family' &&
            (autoUpgradedFrom == null || autoUpgradedFrom.isEmpty)) {
          await subRef.set({
            'planType': 'free',
            'isActive': false,
            'familyMembers': [],
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint(
              'ℹ️ TransmissionService: メンバー削除時に元プラン情報が無いためフリープランへ戻しました (memberId=$memberId)');
        }
      } catch (e) {
        debugPrint('ℹ️ TransmissionService: メンバー削除後のサブスク復元処理に失敗: $e');
      }

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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSyncing(bool syncing) {
    if (_isSyncing != syncing) {
      _isSyncing = syncing;
      notifyListeners();
    }
  }

  /// ファミリーIDをリセット（権限エラー時の対処）
  Future<void> _resetFamilyId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      debugPrint('🔧 TransmissionService: ファミリーIDリセット開始');

      // ユーザー情報からファミリーIDを削除
      await _firestore.collection('users').doc(user.uid).update({
        'familyId': null,
      });

      // ローカル情報をクリア
      _familyId = null;
      _familyMembers = [];
      _currentUserMember = null;

      debugPrint('✅ TransmissionService: ファミリーIDリセット完了');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ TransmissionService: ファミリーIDリセットエラー: $e');
    }
  }

  /// ファミリーIDをリセット（パブリックメソッド）
  Future<void> resetFamilyId() async {
    await _resetFamilyId();
  }

  /// ファミリー解散通知を処理
  Future<void> handleFamilyDissolvedNotification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // ファミリー解散通知を確認
      final notificationsQuery = await _firestore
          .collection('notifications')
          .doc(user.uid)
          .collection('items')
          .where('type', isEqualTo: 'family_dissolved')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notificationsQuery.docs) {
        final data = doc.data();
        final familyId = data['familyId'] as String?;

        if (familyId != null && familyId == _familyId) {
          // 通知を既読にマーク
          await doc.reference.update({'isRead': true});

          // ローカル情報をクリア
          _familyId = null;
          _familyMembers = [];
          _currentUserMember = null;
          _sentContents = [];
          _receivedContents = [];

          // ユーザー情報からファミリーIDを削除
          await _firestore.collection('users').doc(user.uid).update({
            'familyId': null,
          });

          notifyListeners();
          debugPrint('🔧 TransmissionService: ファミリー解散通知を処理しました');
          break;
        }
      }
    } catch (e) {
      debugPrint('ファミリー解散通知処理エラー: $e');
    }
  }
}
