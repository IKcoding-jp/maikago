import 'package:flutter/foundation.dart';
import 'package:maikago/config.dart';

/// ログ出力レベル（低い方がより詳細）
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

/// デバッグ機能を提供するサービス
/// kDebugModeガードにより、リリースビルドではログ出力を完全に抑制
/// ログレベルにより、デバッグビルドでも出力量を制御可能
class DebugService {
  factory DebugService() => _instance;
  DebugService._internal();

  static final DebugService _instance = DebugService._internal();

  /// configLogLevel文字列からLogLevelに変換
  static final LogLevel _minLevel = _parseLogLevel(configLogLevel);

  static LogLevel _parseLogLevel(String level) {
    switch (level.toLowerCase()) {
      case 'verbose':
        return LogLevel.verbose;
      case 'debug':
        return LogLevel.debug;
      case 'warning':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }

  /// 指定レベルが現在の最小レベル以上かどうか
  bool _shouldLog(LogLevel level) => level.index >= _minLevel.index;

  /// デバッグモードが有効かどうか
  bool get isDebugMode => kDebugMode;

  /// 本番環境かどうか
  bool get isProductionMode => kReleaseMode;

  /// 製品版リリース用のデバッグログ制御
  bool get enableDebugMode =>
      isDebugMode && !isProductionMode && configEnableDebugMode;

  /// デバッグレベルのログ出力（デフォルトでは非表示）
  void log(String message) {
    if (kDebugMode && _shouldLog(LogLevel.debug)) {
      debugPrint(message);
    }
  }

  /// 情報レベルのログ出力（デフォルトで表示）
  void logInfo(String message) {
    if (kDebugMode && _shouldLog(LogLevel.info)) {
      debugPrint(message);
    }
  }

  /// デバッグ情報を出力（debugレベル）
  void logDebug(String message) {
    if (kDebugMode && _shouldLog(LogLevel.debug)) {
      debugPrint('🔍 DEBUG: $message');
    }
  }

  /// 警告情報を出力（warningレベル）
  void logWarning(String message) {
    if (kDebugMode && _shouldLog(LogLevel.warning)) {
      debugPrint('⚠️ WARNING: $message');
    }
  }

  /// エラー情報を出力（errorレベル）
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode && _shouldLog(LogLevel.error)) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('エラー詳細: $error');
      }
      if (stackTrace != null) {
        debugPrint('スタックトレース: $stackTrace');
      }
    }
  }

  /// デバッグ情報を取得
  Map<String, dynamic> getDebugInfo() {
    return {
      'isDebugMode': isDebugMode,
      'isProductionMode': isProductionMode,
      'logLevel': _minLevel.name,
      'enableDebugMode': enableDebugMode,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// デバッグ機能が利用可能かどうか
  bool get isDebugEnabled => enableDebugMode;
}
