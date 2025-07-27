import 'package:flutter/material.dart';

/// 今後の新機能画面
/// アプリに今後追加される予定の機能リストを表示
class UpcomingFeaturesScreen extends StatelessWidget {
  const UpcomingFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今後の新機能')),
      body: const Center(child: Text('今後の新機能画面')),
    );
  }
}
