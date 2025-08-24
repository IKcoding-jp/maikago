import 'package:flutter/foundation.dart';
import 'package:maikago/env.dart';

/// セキュリティ監査サービス
/// APIキーの使用状況やセキュリティリスクを監視
class SecurityAuditService {
  static final SecurityAuditService _instance =
      SecurityAuditService._internal();
  factory SecurityAuditService() => _instance;
  SecurityAuditService._internal();

  // API使用回数の追跡
  int _visionApiCallCount = 0;
  int _openApiCallCount = 0;
  DateTime? _lastAuditTime;

  /// セキュリティ監査の実行
  Future<SecurityAuditResult> performAudit() async {
    debugPrint('🔒 セキュリティ監査を開始します');

    final result = SecurityAuditResult(
      timestamp: DateTime.now(),
      isProduction: Env.isProduction,
      apiKeysConfigured: Env.isApiKeysConfigured,
      securityWarning: Env.securityWarning,
      visionApiCallCount: _visionApiCallCount,
      openApiCallCount: _openApiCallCount,
      risks: _detectRisks(),
    );

    _lastAuditTime = result.timestamp;
    debugPrint('🔒 セキュリティ監査完了: ${result.risks.length}個のリスクを検出');

    return result;
  }

  /// リスクの検出
  List<SecurityRisk> _detectRisks() {
    final risks = <SecurityRisk>[];

    // 1. 本番環境でのAPIキー未設定
    if (Env.isProduction && !Env.isApiKeysConfigured) {
      risks.add(SecurityRisk(
        level: RiskLevel.critical,
        category: RiskCategory.apiConfiguration,
        message: '本番環境でAPIキーが正しく設定されていません',
        recommendation: '環境変数でAPIキーを設定してください',
      ));
    }

    // 2. 開発環境でのAPIキー露出
    if (!Env.isProduction && Env.isApiKeysConfigured) {
      risks.add(SecurityRisk(
        level: RiskLevel.warning,
        category: RiskCategory.apiConfiguration,
        message: '開発環境でAPIキーが設定されています',
        recommendation: '開発環境ではテスト用APIキーを使用してください',
      ));
    }

    // 3. 異常なAPI使用量
    if (_visionApiCallCount > 1000) {
      risks.add(SecurityRisk(
        level: RiskLevel.warning,
        category: RiskCategory.usageLimit,
        message: 'Vision APIの使用回数が異常に多いです: $_visionApiCallCount回',
        recommendation: 'API使用量を監視し、必要に応じて制限を設定してください',
      ));
    }

    if (_openApiCallCount > 1000) {
      risks.add(SecurityRisk(
        level: RiskLevel.warning,
        category: RiskCategory.usageLimit,
        message: 'OpenAI APIの使用回数が異常に多いです: $_openApiCallCount回',
        recommendation: 'API使用量を監視し、必要に応じて制限を設定してください',
      ));
    }

    return risks;
  }

  /// Vision API使用回数の記録
  void recordVisionApiCall() {
    _visionApiCallCount++;
    debugPrint('📊 Vision API使用回数: $_visionApiCallCount回');
  }

  /// OpenAI API使用回数の記録
  void recordOpenApiCall() {
    _openApiCallCount++;
    debugPrint('📊 OpenAI API使用回数: $_openApiCallCount回');
  }

  /// 使用回数のリセット
  void resetUsageCounts() {
    _visionApiCallCount = 0;
    _openApiCallCount = 0;
    debugPrint('📊 API使用回数をリセットしました');
  }

  /// 統計情報の取得
  Map<String, dynamic> getUsageStats() {
    return {
      'visionApiCallCount': _visionApiCallCount,
      'openApiCallCount': _openApiCallCount,
      'lastAuditTime': _lastAuditTime?.toIso8601String(),
    };
  }
}

/// セキュリティ監査結果
class SecurityAuditResult {
  final DateTime timestamp;
  final bool isProduction;
  final bool apiKeysConfigured;
  final String securityWarning;
  final int visionApiCallCount;
  final int openApiCallCount;
  final List<SecurityRisk> risks;

  SecurityAuditResult({
    required this.timestamp,
    required this.isProduction,
    required this.apiKeysConfigured,
    required this.securityWarning,
    required this.visionApiCallCount,
    required this.openApiCallCount,
    required this.risks,
  });

  bool get hasCriticalRisks =>
      risks.any((risk) => risk.level == RiskLevel.critical);
  bool get hasWarnings => risks.any((risk) => risk.level == RiskLevel.warning);
}

/// セキュリティリスク
class SecurityRisk {
  final RiskLevel level;
  final RiskCategory category;
  final String message;
  final String recommendation;

  SecurityRisk({
    required this.level,
    required this.category,
    required this.message,
    required this.recommendation,
  });
}

/// リスクレベル
enum RiskLevel {
  info,
  warning,
  critical,
}

/// リスクカテゴリ
enum RiskCategory {
  apiConfiguration,
  usageLimit,
  authentication,
  dataProtection,
}
