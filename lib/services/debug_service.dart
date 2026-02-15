import 'package:flutter/foundation.dart';
import '../config.dart';

/// デバッグ機能を提供するサービス
/// kDebugModeガードにより、リリースビルドではログ出力と文字列生成を抑制
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
  /// 環境変数とFlutterのkDebugModeの両方を考慮
  bool get enableDebugMode =>
      isDebugMode &&
      !isProductionMode &&
      configEnableDebugMode;

  /// 一般的なログ出力（デバッグモードのみ）
  /// 全debugPrint呼び出しの統一的な置き換え先
  void log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// デバッグ情報を出力（デバッグモードのみ）
  void logDebug(String message) {
    if (kDebugMode) {
      debugPrint('🔍 DEBUG: $message');
    }
  }

  /// 警告情報を出力（デバッグモードのみ）
  void logWarning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: $message');
    }
  }

  /// エラー情報を出力（デバッグモードのみ）
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('エラー詳細: $error');
      }
      if (stackTrace != null) {
        debugPrint('スタックトレース: $stackTrace');
      }
    }
  }

  /// パフォーマンス情報を出力（デバッグモードのみ）
  void logPerformance(String operation, Duration duration) {
    if (kDebugMode) {
      debugPrint('⚡ PERFORMANCE: $operation took ${duration.inMilliseconds}ms');
    }
  }

  /// 条件付きデバッグログ出力
  void logIf(bool condition, String message) {
    if (condition && kDebugMode) {
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
}
