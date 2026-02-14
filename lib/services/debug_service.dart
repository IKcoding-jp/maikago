import 'package:flutter/foundation.dart';
import '../config.dart';

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

  /// 製品版リリース用のデバッグログ制御
  /// 本番環境では常にfalseを返す
  /// 環境変数とFlutterのkDebugModeの両方を考慮
  bool get enableDebugMode =>
      isDebugMode &&
      !isProductionMode &&
      configEnableDebugMode; // config.dartの環境変数設定も考慮

  /// デバッグ情報を出力（製品版では無効化）
  void logDebug(String message) {
    if (enableDebugMode) {
      debugPrint('🔍 DEBUG: $message');
    }
  }

  /// 警告情報を出力（製品版では無効化）
  void logWarning(String message) {
    if (enableDebugMode) {
      debugPrint('⚠️ WARNING: $message');
    }
  }

  /// エラー情報を出力（製品版では無効化）
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (enableDebugMode) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('エラー詳細: $error');
      }
      if (stackTrace != null) {
        debugPrint('スタックトレース: $stackTrace');
      }
    }
  }

  /// パフォーマンス情報を出力（製品版では無効化）
  void logPerformance(String operation, Duration duration) {
    if (enableDebugMode) {
      debugPrint('⚡ PERFORMANCE: $operation took ${duration.inMilliseconds}ms');
    }
  }

  /// 一般的なデバッグログ出力（製品版では無効化）
  /// 既存のdebugPrint呼び出しを置き換えるためのメソッド
  void log(String message) {
    if (enableDebugMode) {
      debugPrint(message);
    }
  }

  /// 条件付きデバッグログ出力
  void logIf(bool condition, String message) {
    if (condition && enableDebugMode) {
      debugPrint(message);
    }
  }

  /// デバッグ情報を取得
  Map<String, dynamic> getDebugInfo() {
    return {
      'isDebugMode': isDebugMode,
      'isProductionMode': isProductionMode,
      'isProfileMode': isProfileMode,
      'enableDebugMode': enableDebugMode,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// デバッグ機能が利用可能かどうか
  bool get isDebugEnabled => enableDebugMode;

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
