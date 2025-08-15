// デバッグ・最適化機能を提供するサービス
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../config.dart';

/// デバッグ・最適化機能を提供するサービス
/// - パフォーマンス監視
/// - メモリ使用量監視
/// - エラー追跡
/// - 使用状況分析
/// - ログ出力
class DebugService extends ChangeNotifier {
  static final DebugService _instance = DebugService._internal();
  factory DebugService() => _instance;
  DebugService._internal() {
    _initialize();
  }

  // パフォーマンス監視
  final Map<String, Stopwatch> _performanceTimers = {};
  final Map<String, List<Duration>> _performanceHistory = {};
  
  // メモリ監視
  Timer? _memoryMonitorTimer;
  final List<MemorySnapshot> _memoryHistory = [];
  
  // エラー追跡
  final List<ErrorLog> _errorLogs = [];
  
  // 使用状況分析
  final Map<String, int> _featureUsage = {};
  final Map<String, DateTime> _lastUsage = {};
  
  // ログ出力
  final List<LogEntry> _logs = [];
  static const int _maxLogEntries = 1000;

  /// 初期化処理
  void _initialize() {
    if (enableDebugMode) {
      _startMemoryMonitoring();
      _log('DebugService: 初期化完了', LogLevel.info);
    }
  }

  // === パフォーマンス監視 ===

  /// パフォーマンス計測開始
  void startPerformanceTimer(String name) {
    if (!enableDebugMode) return;
    
    _performanceTimers[name] = Stopwatch()..start();
    _log('パフォーマンス計測開始: $name', LogLevel.debug);
  }

  /// パフォーマンス計測終了
  Duration? stopPerformanceTimer(String name) {
    if (!enableDebugMode) return null;
    
    final timer = _performanceTimers.remove(name);
    if (timer == null) return null;
    
    timer.stop();
    final duration = timer.elapsed;
    
    // 履歴に追加
    _performanceHistory.putIfAbsent(name, () => []).add(duration);
    if (_performanceHistory[name]!.length > 100) {
      _performanceHistory[name]!.removeAt(0);
    }
    
    _log('パフォーマンス計測完了: $name - ${duration.inMilliseconds}ms', LogLevel.debug);
    
    // パフォーマンス警告
    if (duration.inMilliseconds > 100) {
      _log('パフォーマンス警告: $name が ${duration.inMilliseconds}ms かかりました', LogLevel.warning);
    }
    
    return duration;
  }

  /// パフォーマンス統計を取得
  Map<String, dynamic> getPerformanceStats(String name) {
    final history = _performanceHistory[name];
    if (history == null || history.isEmpty) {
      return {};
    }
    
    final durations = history.map((d) => d.inMilliseconds).toList();
    durations.sort();
    
    return {
      'count': durations.length,
      'min': durations.first,
      'max': durations.last,
      'avg': durations.reduce((a, b) => a + b) / durations.length,
      'median': durations[durations.length ~/ 2],
      'p95': durations[(durations.length * 0.95).round() - 1],
    };
  }

  /// 全パフォーマンス統計を取得
  Map<String, Map<String, dynamic>> getAllPerformanceStats() {
    final stats = <String, Map<String, dynamic>>{};
    for (final name in _performanceHistory.keys) {
      stats[name] = getPerformanceStats(name);
    }
    return stats;
  }

  // === メモリ監視 ===

  /// メモリ監視開始
  void _startMemoryMonitoring() {
    if (!enableDebugMode) return;
    
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _takeMemorySnapshot();
    });
  }

  /// メモリスナップショット取得
  void _takeMemorySnapshot() {
    if (!enableDebugMode) return;
    
    final snapshot = MemorySnapshot(
      timestamp: DateTime.now(),
      // 実際のメモリ使用量はプラットフォーム固有のAPIが必要
      usedMemory: 0, // TODO: 実装
      totalMemory: 0, // TODO: 実装
    );
    
    _memoryHistory.add(snapshot);
    if (_memoryHistory.length > 100) {
      _memoryHistory.removeAt(0);
    }
    
    _log('メモリスナップショット: ${snapshot.usedMemory}MB / ${snapshot.totalMemory}MB', LogLevel.debug);
  }

  /// メモリ統計を取得
  Map<String, dynamic> getMemoryStats() {
    if (_memoryHistory.isEmpty) return {};
    
    final usedMemory = _memoryHistory.map((s) => s.usedMemory).toList();
    final totalMemory = _memoryHistory.map((s) => s.totalMemory).toList();
    
    return {
      'current': {
        'used': _memoryHistory.last.usedMemory,
        'total': _memoryHistory.last.totalMemory,
        'percentage': _memoryHistory.last.totalMemory > 0 
            ? (_memoryHistory.last.usedMemory / _memoryHistory.last.totalMemory * 100).round()
            : 0,
      },
      'average': {
        'used': usedMemory.reduce((a, b) => a + b) / usedMemory.length,
        'total': totalMemory.reduce((a, b) => a + b) / totalMemory.length,
      },
      'peak': {
        'used': usedMemory.reduce((a, b) => a > b ? a : b),
        'total': totalMemory.reduce((a, b) => a > b ? a : b),
      },
    };
  }

  // === エラー追跡 ===

  /// エラーログを追加
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!enableDebugMode) return;
    
    final errorLog = ErrorLog(
      timestamp: DateTime.now(),
      message: message,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );
    
    _errorLogs.add(errorLog);
    if (_errorLogs.length > 100) {
      _errorLogs.removeAt(0);
    }
    
    _log('エラー: $message', LogLevel.error);
    if (error != null) {
      _log('エラー詳細: $error', LogLevel.error);
    }
    if (stackTrace != null) {
      _log('スタックトレース: $stackTrace', LogLevel.error);
    }
  }

  /// エラーログを取得
  List<ErrorLog> getErrorLogs() {
    return List.unmodifiable(_errorLogs);
  }

  /// エラー統計を取得
  Map<String, dynamic> getErrorStats() {
    if (_errorLogs.isEmpty) return {};
    
    final now = DateTime.now();
    final last24h = _errorLogs.where((log) => 
        now.difference(log.timestamp).inHours < 24).length;
    final last7d = _errorLogs.where((log) => 
        now.difference(log.timestamp).inDays < 7).length;
    
    return {
      'total': _errorLogs.length,
      'last24h': last24h,
      'last7d': last7d,
      'recent': _errorLogs.take(10).toList(),
    };
  }

  // === 使用状況分析 ===

  /// 機能使用を記録
  void recordFeatureUsage(String featureName) {
    if (!enableDebugMode) return;
    
    _featureUsage[featureName] = (_featureUsage[featureName] ?? 0) + 1;
    _lastUsage[featureName] = DateTime.now();
    
    _log('機能使用: $featureName (${_featureUsage[featureName]}回目)', LogLevel.debug);
  }

  /// 使用状況統計を取得
  Map<String, dynamic> getUsageStats() {
    final now = DateTime.now();
    final recentUsage = _lastUsage.entries
        .where((entry) => now.difference(entry.value).inHours < 24)
        .map((entry) => entry.key)
        .toList();
    
    return {
      'totalFeatures': _featureUsage.length,
      'mostUsed': () {
        final sorted = _featureUsage.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return sorted.take(5)
          .map((e) => {'feature': e.key, 'count': e.value})
          .toList();
      }(),
      'recentlyUsed': recentUsage,
      'usageCounts': Map.unmodifiable(_featureUsage),
    };
  }

  // === ログ出力 ===

  /// ログを追加
  void _log(String message, LogLevel level) {
    if (!enableDebugMode) return;
    
    final logEntry = LogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: level,
    );
    
    _logs.add(logEntry);
    if (_logs.length > _maxLogEntries) {
      _logs.removeAt(0);
    }
    
    // コンソールにも出力
    switch (level) {
      case LogLevel.debug:
        debugPrint('🔍 DEBUG: $message');
        break;
      case LogLevel.info:
        debugPrint('ℹ️ INFO: $message');
        break;
      case LogLevel.warning:
        debugPrint('⚠️ WARNING: $message');
        break;
      case LogLevel.error:
        debugPrint('❌ ERROR: $message');
        break;
    }
  }

  /// ログを取得
  List<LogEntry> getLogs([LogLevel? minLevel]) {
    if (minLevel == null) {
      return List.unmodifiable(_logs);
    }
    
    return _logs
        .where((log) => log.level.index >= minLevel.index)
        .toList();
  }

  /// ログをクリア
  void clearLogs() {
    _logs.clear();
    _log('ログをクリアしました', LogLevel.info);
  }

  // === 全体的な統計 ===

  /// 全体的な統計を取得
  Map<String, dynamic> getOverallStats() {
    return {
      'performance': getAllPerformanceStats(),
      'memory': getMemoryStats(),
      'errors': getErrorStats(),
      'usage': getUsageStats(),
      'logs': {
        'total': _logs.length,
        'recent': _logs.take(10).toList(),
      },
    };
  }

  /// デバッグ情報を出力
  void printDebugInfo() {
    if (!enableDebugMode) return;
    
    final stats = getOverallStats();
    _log('=== デバッグ情報 ===', LogLevel.info);
    _log('パフォーマンス統計: ${stats['performance']}', LogLevel.info);
    _log('メモリ統計: ${stats['memory']}', LogLevel.info);
    _log('エラー統計: ${stats['errors']}', LogLevel.info);
    _log('使用状況統計: ${stats['usage']}', LogLevel.info);
    _log('==================', LogLevel.info);
  }

  @override
  void dispose() {
    _memoryMonitorTimer?.cancel();
    super.dispose();
  }
}

// === データクラス ===

/// ログレベル
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// ログエントリ
class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;

  LogEntry({
    required this.timestamp,
    required this.message,
    required this.level,
  });

  @override
  String toString() {
    return '${timestamp.toIso8601String()} [${level.name.toUpperCase()}] $message';
  }
}

/// エラーログ
class ErrorLog {
  final DateTime timestamp;
  final String message;
  final String? error;
  final String? stackTrace;

  ErrorLog({
    required this.timestamp,
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    return '${timestamp.toIso8601String()} ERROR: $message${error != null ? ' - $error' : ''}';
  }
}

/// メモリスナップショット
class MemorySnapshot {
  final DateTime timestamp;
  final int usedMemory; // MB
  final int totalMemory; // MB

  MemorySnapshot({
    required this.timestamp,
    required this.usedMemory,
    required this.totalMemory,
  });

  @override
  String toString() {
    return '${timestamp.toIso8601String()} MEMORY: ${usedMemory}MB / ${totalMemory}MB';
  }
}
