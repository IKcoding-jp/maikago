import 'package:flutter/material.dart';
import 'package:maikago/services/security_audit_service.dart';

/// セキュリティ監査結果を表示するウィジェット
class SecurityAuditWidget extends StatefulWidget {
  const SecurityAuditWidget({super.key});

  @override
  State<SecurityAuditWidget> createState() => _SecurityAuditWidgetState();
}

class _SecurityAuditWidgetState extends State<SecurityAuditWidget> {
  SecurityAuditResult? _auditResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _performAudit();
  }

  Future<void> _performAudit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final auditService = SecurityAuditService();
      final result = await auditService.performAudit();

      if (mounted) {
        setState(() {
          _auditResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('セキュリティ監査エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'セキュリティ監査',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isLoading ? null : _performAudit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_auditResult != null)
              _buildAuditResult(_auditResult!)
            else
              const Text('監査結果がありません'),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditResult(SecurityAuditResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 基本情報
        _buildInfoRow('環境', result.isProduction ? '本番' : '開発'),
        _buildInfoRow('APIキー設定', result.apiKeysConfigured ? '✅ 設定済み' : '❌ 未設定'),
        _buildInfoRow('Vision API使用回数', '${result.visionApiCallCount}回'),
        _buildInfoRow('OpenAI API使用回数', '${result.openApiCallCount}回'),

        if (result.securityWarning.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              result.securityWarning,
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        ],

        // リスク一覧
        if (result.risks.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            '検出されたリスク',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...result.risks.map((risk) => _buildRiskCard(risk)),
        ] else ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '✅ セキュリティリスクは検出されませんでした',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildRiskCard(SecurityRisk risk) {
    Color riskColor;
    IconData riskIcon;

    switch (risk.level) {
      case RiskLevel.critical:
        riskColor = Colors.red;
        riskIcon = Icons.error;
        break;
      case RiskLevel.warning:
        riskColor = Colors.orange;
        riskIcon = Icons.warning;
        break;
      case RiskLevel.info:
        riskColor = Colors.blue;
        riskIcon = Icons.info;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: riskColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(riskIcon, color: riskColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    risk.message,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '推奨対応: ${risk.recommendation}',
              style: TextStyle(color: riskColor.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
