import 'package:flutter/foundation.dart';

/// デバッグ機能を提供するサービス
/// 開発時のみ有効で、本番環境では無効化される
class DebugService extends ChangeNotifier {
  static final DebugService _instance = DebugService._internal();
  factory DebugService() => _instance;
  DebugService._internal();

  /// デバッグモードが有効かどうか
  bool get isDebugMode => kDebugMode;

  /// 本番環境かどうか
  bool get isProductionMode => kReleaseMode;

  /// プロファイルモードかどうか
  bool get isProfileMode => kProfileMode;

  /// デバッグ情報を出力
  void logDebug(String message) {
    if (isDebugMode) {
      debugPrint('🔍 DEBUG: $message');
    }
  }

  /// 警告情報を出力
  void logWarning(String message) {
    if (isDebugMode) {
      debugPrint('⚠️ WARNING: $message');
    }
  }

  /// エラー情報を出力
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (isDebugMode) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('Error details: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// パフォーマンス情報を出力
  void logPerformance(String operation, Duration duration) {
    if (isDebugMode) {
      debugPrint('⚡ PERFORMANCE: $operation took ${duration.inMilliseconds}ms');
    }
  }

  /// デバッグ情報を取得
  Map<String, dynamic> getDebugInfo() {
    return {
      'isDebugMode': isDebugMode,
      'isProductionMode': isProductionMode,
      'isProfileMode': isProfileMode,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// デバッグ機能が利用可能かどうか
  bool get isDebugEnabled => isDebugMode;

  /// デバッグ機能を無効化（本番環境用）
  void disableDebug() {
    // 本番環境では何もしない
    if (isProductionMode) {
      return;
    }
  }

  /// デバッグ機能を有効化（開発環境用）
  void enableDebug() {
    // 開発環境では何もしない（デフォルトで有効）
    if (isDebugMode) {
      return;
    }
  }
}
