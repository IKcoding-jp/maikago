import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// ユーザーの表示名を管理するサービス
class UserDisplayService {
  static final UserDisplayService _instance = UserDisplayService._internal();
  factory UserDisplayService() => _instance;
  UserDisplayService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ローカルキャッシュ用のキー
  static const String _displayNamesCacheKey = 'user_display_names_cache';
  static const String _cacheTimestampKey = 'display_names_cache_timestamp';
  static const Duration _cacheExpiryDuration =
      Duration(hours: 24); // 24時間でキャッシュ期限切れ

  /// ユーザーIDから表示名を取得
  Future<String> getUserDisplayName(String userId) async {
    try {
      debugPrint('🔍 表示名取得開始: userId=$userId');

      // まず現在のユーザーかチェック
      final currentUser = _auth.currentUser;
      debugPrint('🔍 現在のユーザー: ${currentUser?.uid}');
      debugPrint('🔍 現在のユーザーの表示名: ${currentUser?.displayName}');

      if (currentUser?.uid == userId) {
        // 現在のユーザーの場合はFirebase Authから取得
        final displayName = currentUser?.displayName;
        debugPrint('🔍 現在のユーザーの表示名: $displayName');
        if (displayName != null && displayName.isNotEmpty) {
          // 現在のユーザーの表示名もキャッシュに保存
          await _saveDisplayNameToCache(userId, displayName);
          return displayName;
        }
        return 'ユーザー';
      }

      // まずローカルキャッシュから取得を試行
      final cachedDisplayName = await _getDisplayNameFromCache(userId);
      if (cachedDisplayName != null) {
        debugPrint('🔍 キャッシュから表示名取得: $cachedDisplayName');
        return cachedDisplayName;
      }

      // ファミリーメンバーのプロフィール情報を確認
      final familyMemberProfile = await _getFamilyMemberProfile(userId);
      if (familyMemberProfile != null) {
        debugPrint('🔍 ファミリーメンバープロフィールから取得: $familyMemberProfile');
        await _saveDisplayNameToCache(userId, familyMemberProfile);
        return familyMemberProfile;
      }

      // 他のユーザーの場合はFirestoreから取得
      debugPrint('🔍 Firestoreから表示名を取得: $userId');
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        debugPrint('🔍 Firestoreデータ: $data');
        final displayName = data?['displayName'] as String?;
        debugPrint('🔍 Firestoreから取得した表示名: $displayName');
        if (displayName != null && displayName.isNotEmpty) {
          await _saveDisplayNameToCache(userId, displayName);
          return displayName;
        }
      } else {
        debugPrint('🔍 Firestoreドキュメントが存在しません: $userId');
      }

      // 表示名が見つからない場合は短縮されたユーザーIDを返す
      final shortId = _getShortUserId(userId);
      debugPrint('🔍 短縮ユーザーIDを返します: $shortId');
      return shortId;
    } catch (e) {
      debugPrint('❌ ユーザー表示名取得エラー: $e');
      return _getShortUserId(userId);
    }
  }

  /// ファミリーメンバーのプロフィール情報を取得
  Future<String?> _getFamilyMemberProfile(String memberUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // 現在のユーザーがファミリーオーナーかチェック
      final subscriptionDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('subscription')
          .doc('current')
          .get();

      if (subscriptionDoc.exists) {
        final data = subscriptionDoc.data();
        final familyMembers = data?['familyMembers'] as List<dynamic>?;

        if (familyMembers != null && familyMembers.contains(memberUserId)) {
          // ファミリーメンバーのプロフィール情報を取得
          final memberProfileDoc = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('familyMembers')
              .doc(memberUserId)
              .get();

          if (memberProfileDoc.exists) {
            final profileData = memberProfileDoc.data();
            final displayName = profileData?['displayName'] as String?;
            if (displayName != null && displayName.isNotEmpty) {
              debugPrint('🔍 ファミリーメンバープロフィールから表示名取得: $displayName');
              return displayName;
            }
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ ファミリーメンバープロフィール取得エラー: $e');
      return null;
    }
  }

  /// 複数のユーザーIDから表示名を取得
  Future<Map<String, String>> getMultipleUserDisplayNames(
      List<String> userIds) async {
    final Map<String, String> displayNames = {};

    for (final userId in userIds) {
      displayNames[userId] = await getUserDisplayName(userId);
    }

    return displayNames;
  }

  /// ユーザーIDを短縮して表示用に整形
  String _getShortUserId(String userId) {
    if (userId.length <= 8) {
      return userId;
    }
    return '${userId.substring(0, 4)}...${userId.substring(userId.length - 4)}';
  }

  /// 現在のユーザーの表示名を取得
  String getCurrentUserDisplayName() {
    final currentUser = _auth.currentUser;
    return currentUser?.displayName ?? 'ユーザー';
  }

  /// 現在のユーザーのIDを取得
  String getCurrentUserId() {
    return _auth.currentUser?.uid ?? '';
  }

  /// 表示名をローカルキャッシュに保存
  Future<void> _saveDisplayNameToCache(
      String userId, String displayName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_displayNamesCacheKey);
      final Map<String, dynamic> cache = cacheData != null
          ? Map<String, dynamic>.from(json.decode(cacheData))
          : {};

      cache[userId] = {
        'displayName': displayName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(_displayNamesCacheKey, json.encode(cache));
      await prefs.setInt(
          _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ 表示名をキャッシュに保存: $userId -> $displayName');
    } catch (e) {
      debugPrint('❌ キャッシュ保存エラー: $e');
    }
  }

  /// ローカルキャッシュから表示名を取得
  Future<String?> _getDisplayNameFromCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_displayNamesCacheKey);
      final timestamp = prefs.getInt(_cacheTimestampKey);

      // キャッシュが期限切れの場合はクリア
      if (timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (cacheAge > _cacheExpiryDuration.inMilliseconds) {
          debugPrint('🔍 キャッシュが期限切れのためクリアします');
          await _clearCache();
          return null;
        }
      }

      if (cacheData != null) {
        final Map<String, dynamic> cache =
            Map<String, dynamic>.from(json.decode(cacheData));
        final userData = cache[userId] as Map<String, dynamic>?;

        if (userData != null) {
          final displayName = userData['displayName'] as String?;
          final userTimestamp = userData['timestamp'] as int?;

          // 個別のユーザーデータも期限切れチェック
          if (userTimestamp != null) {
            final userCacheAge =
                DateTime.now().millisecondsSinceEpoch - userTimestamp;
            if (userCacheAge > _cacheExpiryDuration.inMilliseconds) {
              debugPrint('🔍 ユーザーキャッシュが期限切れ: $userId');
              return null;
            }
          }

          if (displayName != null && displayName.isNotEmpty) {
            debugPrint('🔍 キャッシュから表示名取得成功: $userId -> $displayName');
            return displayName;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ キャッシュ取得エラー: $e');
      return null;
    }
  }

  /// キャッシュをクリア
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_displayNamesCacheKey);
      await prefs.remove(_cacheTimestampKey);
      debugPrint('✅ キャッシュをクリアしました');
    } catch (e) {
      debugPrint('❌ キャッシュクリアエラー: $e');
    }
  }

  /// キャッシュを手動でクリア（外部から呼び出し可能）
  Future<void> clearDisplayNamesCache() async {
    await _clearCache();
  }

  /// 特定のユーザーのキャッシュを削除
  Future<void> removeUserFromCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_displayNamesCacheKey);

      if (cacheData != null) {
        final Map<String, dynamic> cache =
            Map<String, dynamic>.from(json.decode(cacheData));
        cache.remove(userId);

        await prefs.setString(_displayNamesCacheKey, json.encode(cache));
        debugPrint('✅ ユーザーキャッシュを削除: $userId');
      }
    } catch (e) {
      debugPrint('❌ ユーザーキャッシュ削除エラー: $e');
    }
  }
}
