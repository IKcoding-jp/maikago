import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 通知サービスクラス
/// ファミリープラン期限切れなどの通知を管理
class NotificationService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NotificationData> _notifications = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _notificationListener;

  /// 通知一覧
  List<NotificationData> get notifications => List.unmodifiable(_notifications);

  /// ローディング状態
  bool get isLoading => _isLoading;

  /// 未読通知数
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// 通知リスナーを開始
  void startListening() {
    final user = _auth.currentUser;
    if (user == null) return;

    _notificationListener?.cancel();
    _notificationListener = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) {
        _notifications = snapshot.docs
            .map((doc) => NotificationData.fromFirestore(doc))
            .toList();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('通知リスナーエラー: $error');
      },
    );
  }

  /// 通知リスナーを停止
  void stopListening() {
    _notificationListener?.cancel();
    _notificationListener = null;
  }

  /// 通知を既読にする
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // ローカル状態も更新
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('通知既読処理エラー: $e');
    }
  }

  /// 全ての通知を既読にする
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final unreadNotifications = _notifications.where((n) => !n.isRead);

      for (final notification in unreadNotifications) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notification.id);
        batch.update(docRef, {'isRead': true});
      }

      await batch.commit();

      // ローカル状態も更新
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('全通知既読処理エラー: $e');
    }
  }

  /// 通知を削除
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // ローカル状態も更新
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('通知削除エラー: $e');
    }
  }

  /// 古い通知を削除（30日以上前）
  Future<void> deleteOldNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final oldNotifications = _notifications
          .where((n) => n.createdAt.isBefore(thirtyDaysAgo))
          .toList();

      if (oldNotifications.isEmpty) return;

      final batch = _firestore.batch();
      for (final notification in oldNotifications) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notification.id);
        batch.delete(docRef);
      }

      await batch.commit();
      debugPrint('古い通知を削除しました: ${oldNotifications.length}件');
    } catch (e) {
      debugPrint('古い通知削除エラー: $e');
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

/// 通知データクラス
class NotificationData {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? ownerId;
  final DateTime createdAt;
  final bool isRead;

  const NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.ownerId,
    required this.createdAt,
    required this.isRead,
  });

  /// Firestoreドキュメントから作成
  factory NotificationData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationData(
      id: doc.id,
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      ownerId: data['ownerId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  /// コピーを作成
  NotificationData copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    String? ownerId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationData(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'NotificationData(id: $id, type: $type, title: $title, isRead: $isRead)';
  }
}
