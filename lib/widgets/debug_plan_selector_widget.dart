import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// デバッグ用のプラン変更ウィジェット
/// リリースビルドでは非表示
class DebugPlanSelectorWidget extends StatefulWidget {
  const DebugPlanSelectorWidget({super.key});

  @override
  State<DebugPlanSelectorWidget> createState() => _DebugPlanSelectorWidgetState();
}

class _DebugPlanSelectorWidgetState extends State<DebugPlanSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    // リリースモードでは何も表示しない
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    // TODO: サブスクリプション統合後に再実装
    return const Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔧 デバッグ: プラン変更',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'サブスクリプション統合後に再実装予定',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}