import 'package:flutter/foundation.dart';
import '../services/transmission_service.dart';
import '../services/realtime_sharing_service.dart';
import '../models/family_member.dart';
import '../models/shared_content.dart';
import '../models/shop.dart';
import '../models/item.dart';
import '../models/sync_data.dart';

/// 共有機能のProviderクラス
/// TransmissionServiceとRealtimeSharingServiceを統合して状態管理を行う
class TransmissionProvider extends ChangeNotifier {
  final TransmissionService _transmissionService;
  final RealtimeSharingService _realtimeSharingService;

  TransmissionProvider({
    required TransmissionService transmissionService,
    required RealtimeSharingService realtimeSharingService,
  })  : _transmissionService = transmissionService,
        _realtimeSharingService = realtimeSharingService {
    // サービスの変更を監視
    _transmissionService.addListener(_onTransmissionServiceChanged);
    _realtimeSharingService.addListener(_onRealtimeSharingServiceChanged);
  }

  @override
  void dispose() {
    _transmissionService.removeListener(_onTransmissionServiceChanged);
    _realtimeSharingService.removeListener(_onRealtimeSharingServiceChanged);
    super.dispose();
  }

  void _onTransmissionServiceChanged() {
    notifyListeners();
  }

  void _onRealtimeSharingServiceChanged() {
    notifyListeners();
  }

  // TransmissionService のプロパティを公開
  List<SharedContent> get sentContents => _transmissionService.sentContents;
  List<SharedContent> get receivedContents =>
      _realtimeSharingService.receivedContents.isNotEmpty
          ? _realtimeSharingService.receivedContents
          : _transmissionService.receivedContents;
  List<TransmissionHistory> get transmissionHistory =>
      _transmissionService.transmissionHistory;
  bool get isTransmissionLoading => _transmissionService.isLoading;
  List<SyncData> get syncDataList => _transmissionService.syncDataList;
  bool get isSyncing => _transmissionService.isSyncing;

  // ファミリー関連のプロパティを公開（リアルタイム優先）
  List<FamilyMember> get familyMembers =>
      _realtimeSharingService.familyMembers.isNotEmpty
          ? _realtimeSharingService.familyMembers
          : _transmissionService.familyMembers;
  FamilyMember? get currentUserMember => _transmissionService.currentUserMember;
  bool get isFamilyMember => _transmissionService.isFamilyMember;
  bool get isFamilyOwner => _transmissionService.isFamilyOwner;
  bool get isFamilyLoading => _transmissionService.isLoading;

  // リアルタイム共有関連のプロパティ
  bool get isRealtimeConnected => _realtimeSharingService.isConnected;
  List<SharedContent> get realtimeReceivedContents =>
      _realtimeSharingService.receivedContents;
  List<SyncData> get realtimeSyncDataList =>
      _realtimeSharingService.syncDataList;
  List<Map<String, dynamic>> get realtimeNotifications =>
      _realtimeSharingService.notifications;
  Stream<bool> get connectionStateStream =>
      _realtimeSharingService.connectionStateStream;

  /// 送信型共有機能が利用可能かどうか
  bool get canUseTransmission {
    return _transmissionService.canUseFamilySharing && isFamilyMember;
  }

  /// 送信可能なメンバーのリスト（自分以外）
  List<FamilyMember> get availableRecipients {
    return familyMembers
        .where((member) => member.id != currentUserMember?.id)
        .toList();
  }

  /// 初期化
  Future<void> initialize() async {
    try {
      debugPrint('🔧 TransmissionProvider: 初期化開始');

      // 並列で初期化を実行
      await Future.wait([
        _transmissionService.initialize().then((_) {
          debugPrint('✅ TransmissionProvider: TransmissionService初期化完了');
        }).catchError((e) {
          debugPrint(
            '❌ TransmissionProvider: TransmissionService初期化エラー: $e',
          );
          // 権限エラーの場合は、ファミリーIDをリセット
          if (e.toString().contains('permission-denied')) {
            debugPrint(
              '🔒 TransmissionProvider: 権限エラーを検出。ファミリーIDをリセットします。',
            );
            _transmissionService.resetFamilyId();
          }
        }),
        _realtimeSharingService.initialize().then((_) {
          debugPrint('✅ TransmissionProvider: RealtimeSharingService初期化完了');
        }).catchError((e) {
          debugPrint(
            '❌ TransmissionProvider: RealtimeSharingService初期化エラー: $e',
          );
          // 権限エラーの場合は、ファミリーIDをリセット
          if (e.toString().contains('permission-denied')) {
            debugPrint(
              '🔒 TransmissionProvider: 権限エラーを検出。ファミリーIDをリセットします。',
            );
            _realtimeSharingService.resetFamilyId();
          }
        }),
      ]);

      debugPrint('✅ TransmissionProvider: 初期化完了');
    } catch (e) {
      debugPrint('❌ TransmissionProvider初期化エラー: $e');
    }
  }

  /// コンテンツを送信（リアルタイム対応）
  Future<bool> sendContent({
    required Shop shop,
    required String title,
    required String description,
    required List<FamilyMember> recipients,
  }) async {
    debugPrint('🚀 TransmissionProvider: 送信開始');
    debugPrint(
      '📋 送信情報: shop=${shop.name}, title=$title, recipients=${recipients.length}人',
    );
    debugPrint(
      '👥 受信者詳細: ${recipients.map((r) => '${r.displayName}(${r.id})').join(', ')}',
    );

    if (!canUseTransmission) {
      debugPrint('❌ TransmissionProvider: 送信機能が利用できません');
      return false;
    }

    // リアルタイム送信を試行
    if (_realtimeSharingService.isConnected) {
      debugPrint('🔄 TransmissionProvider: リアルタイム送信を試行中...');
      try {
        final realtimeSuccess =
            await _realtimeSharingService.sendContentRealtime(
          shop: shop,
          title: title,
          description: description,
          recipients: recipients,
        );
        if (realtimeSuccess) {
          debugPrint('✅ TransmissionProvider: リアルタイム送信成功');
          return true;
        } else {
          debugPrint('⚠️ TransmissionProvider: リアルタイム送信失敗、フォールバックを試行');
        }
      } catch (e) {
        debugPrint('❌ TransmissionProvider: リアルタイム送信エラー: $e');
      }
    } else {
      debugPrint('ℹ️ TransmissionProvider: リアルタイム接続なし、通常送信を試行');
    }

    // フォールバック: 通常の送信
    debugPrint('🔄 TransmissionProvider: 通常送信を試行中...');
    try {
      final result = await _transmissionService.sendContent(
        shop: shop,
        title: title,
        description: description,
        recipients: recipients,
      );
      debugPrint('✅ TransmissionProvider: 通常送信完了 - 結果: $result');
      return result;
    } catch (e) {
      debugPrint('❌ TransmissionProvider: 通常送信エラー: $e');
      return false;
    }
  }

  /// タブとリストを同期して送信（リアルタイム対応）
  Future<bool> syncAndSendTab({
    required Shop shop,
    required String title,
    required String description,
    required List<FamilyMember> recipients,
    required List<Item> items,
  }) async {
    if (!canUseTransmission) return false;

    // リアルタイム同期送信を試行
    if (_realtimeSharingService.isConnected) {
      final realtimeSuccess =
          await _realtimeSharingService.sendSyncDataRealtime(
        shop: shop,
        title: title,
        description: description,
        recipients: recipients,
        items: items,
      );
      if (realtimeSuccess) return true;
    }

    // フォールバック: 通常の同期送信
    return await _transmissionService.syncAndSendTab(
      shop: shop,
      title: title,
      description: description,
      recipients: recipients,
      items: items,
    );
  }

  /// 受信コンテンツを受け取り
  Future<bool> acceptReceivedContent(SharedContent receivedContent) async {
    if (!canUseTransmission) return false;

    return await _transmissionService.acceptReceivedContent(receivedContent);
  }

  /// 受信したタブを自分のアプリに適用（リアルタイム対応）
  Future<bool> applyReceivedTab(
    SharedContent receivedContent, {
    bool overwriteExisting = false,
  }) async {
    if (!canUseTransmission) return false;

    // リアルタイム適用を試行（リアルタイム側は上書きフラグ非対応のためフォールバックのみ）
    if (_realtimeSharingService.isConnected) {
      final realtimeSuccess = await _realtimeSharingService
          .applyReceivedContentRealtime(receivedContent);
      if (realtimeSuccess) return true;
    }

    // フォールバック: 通常の適用（上書きフラグを伝搬）
    return await _transmissionService.applyReceivedTab(
      receivedContent,
      overwriteExisting: overwriteExisting,
    );
  }

  /// 通知を既読にする
  Future<void> markNotificationAsRead(String notificationId) async {
    await _realtimeSharingService.markNotificationAsRead(notificationId);
  }

  /// 通知を削除
  Future<void> deleteNotification(String notificationId) async {
    await _realtimeSharingService.deleteNotification(notificationId);
  }

  /// 送信したコンテンツを削除
  Future<bool> deleteSentContent(String contentId) async {
    if (!canUseTransmission) return false;

    return await _transmissionService.deleteSentContent(contentId);
  }

  /// 受信したコンテンツを削除
  Future<bool> deleteReceivedContent(String contentId) async {
    if (!canUseTransmission) return false;

    return await _transmissionService.deleteReceivedContent(contentId);
  }

  /// 同期データを削除
  Future<bool> deleteSyncData(String syncId) async {
    if (!canUseTransmission) return false;

    return await _transmissionService.deleteSyncData(syncId);
  }

  /// 送信可能なShopリストを取得
  Future<List<Shop>> getAvailableShopsForTransmission() async {
    if (!canUseTransmission) return [];

    return await _transmissionService.getAvailableShopsForTransmission();
  }

  /// 同期データを取得
  Future<List<SyncData>> getSyncDataForUser(String userId) async {
    if (!canUseTransmission) return [];

    return await _transmissionService.getSyncDataForUser(userId);
  }

  /// 同期状態をチェック
  Future<bool> checkSyncStatus(String syncId) async {
    if (!canUseTransmission) return false;

    return await _transmissionService.checkSyncStatus(syncId);
  }

  /// 送信統計を取得
  Map<String, int> getTransmissionStats() {
    final totalSent = sentContents.length;
    final totalReceived = receivedContents.length;
    final totalAccepted = receivedContents
        .where((content) => content.status == TransmissionStatus.accepted)
        .length;
    final totalSynced = syncDataList.length;

    return {
      'totalSent': totalSent,
      'totalReceived': totalReceived,
      'totalAccepted': totalAccepted,
      'totalSynced': totalSynced,
    };
  }

  /// 同期統計を取得
  Map<String, int> getSyncStats() {
    final totalTabs =
        syncDataList.where((data) => data.type == SyncDataType.tab).length;
    final totalLists =
        syncDataList.where((data) => data.type == SyncDataType.list).length;
    final totalApplied =
        syncDataList.where((data) => data.appliedAt != null).length;

    return {
      'totalTabs': totalTabs,
      'totalLists': totalLists,
      'totalApplied': totalApplied,
    };
  }

  /// データを更新
  Future<void> refresh() async {
    if (!canUseTransmission) return;

    try {
      await _transmissionService.initialize();
    } catch (e) {
      debugPrint('TransmissionProvider更新エラー: $e');
    }
  }

  // MARK: - ファミリー管理機能

  /// ファミリーを作成
  ///
  /// 注意: 自動的/バックグラウンドからの呼び出しを防ぐため、
  /// 引数 `userInitiated` が true の場合のみ実際の作成処理を行います。
  Future<bool> createFamily({bool userInitiated = false}) async {
    if (!userInitiated) {
      debugPrint(
          '🔒 TransmissionProvider: createFamily は userInitiated=true のときのみ実行されます');
      return false;
    }
    return await _transmissionService.createFamily();
  }

  /// QRコード招待でファミリーに参加
  Future<bool> joinFamilyByQRCode(String inviteToken) async {
    return await _transmissionService.joinFamilyByQRCode(inviteToken);
  }

  /// QRコードデータを取得
  Future<Map<String, dynamic>?> getQRCodeData() async {
    return await _transmissionService.getQRCodeData();
  }

  /// QRコード招待トークンを検証
  Future<bool> validateQRCodeInviteToken(String token) async {
    return await _transmissionService.validateQRCodeInviteToken(token);
  }

  /// QRコード招待トークンを使用済みにマーク
  Future<bool> markQRCodeInviteTokenAsUsed(String token) async {
    return await _transmissionService.markQRCodeInviteTokenAsUsed(token);
  }

  /// ファミリー脱退
  Future<bool> leaveFamily() async {
    try {
      debugPrint('🔧 TransmissionProvider: ファミリー脱退開始');

      // まずTransmissionServiceで脱退を試行
      final result = await _transmissionService.leaveFamily();
      if (result) {
        debugPrint('✅ TransmissionProvider: TransmissionService脱退成功');
        return true;
      }

      // フォールバック: RealtimeSharingServiceで脱退を試行
      debugPrint(
        '⚠️ TransmissionProvider: TransmissionService脱退失敗、RealtimeSharingServiceで試行',
      );
      final fallbackResult = await _realtimeSharingService.leaveFamily();
      if (fallbackResult) {
        debugPrint('✅ TransmissionProvider: RealtimeSharingService脱退成功');
        return true;
      }

      debugPrint('❌ TransmissionProvider: 両方のサービスで脱退失敗');
      return false;
    } catch (e) {
      debugPrint('❌ TransmissionProvider: ファミリー脱退エラー: $e');
      return false;
    }
  }

  /// ファミリー解散
  Future<bool> dissolveFamily() async {
    return await _transmissionService.dissolveFamily();
  }

  /// メンバー削除
  Future<bool> removeMember(String memberId) async {
    return await _transmissionService.removeMember(memberId);
  }

  /// ファミリーIDをリセット（権限エラー時の対処）
  Future<void> resetFamilyId() async {
    await _transmissionService.resetFamilyId();
  }

  /// ファミリー解散通知を処理
  Future<void> handleFamilyDissolvedNotification() async {
    await _transmissionService.handleFamilyDissolvedNotification();
  }
}
