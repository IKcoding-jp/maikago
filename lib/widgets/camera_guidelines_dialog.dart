import 'package:flutter/material.dart';

/// カメラ使用時のガイドラインと注意喚起ダイアログ
class CameraGuidelinesDialog extends StatelessWidget {
  const CameraGuidelinesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.camera_alt, color: Colors.blue),
          SizedBox(width: 8),
          Text('撮影時のご注意'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '棚札撮影時のガイドライン',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 撮影マナー
            _buildGuidelineSection(
              icon: Icons.volume_off,
              title: '静かに撮影',
              description: '他のお客様のご迷惑にならないよう、静かに撮影してください。',
            ),

            _buildGuidelineSection(
              icon: Icons.people_outline,
              title: '場所に配慮',
              description: '他のお客様の邪魔にならない場所で撮影してください。',
            ),

            _buildGuidelineSection(
              icon: Icons.store,
              title: '店舗への配慮',
              description: '店舗スタッフの業務に支障をきたさないようご配慮ください。',
            ),

            _buildGuidelineSection(
              icon: Icons.security,
              title: '利用規約の確認',
              description: '店舗の利用規約で撮影が禁止されている場合は撮影をお控えください。',
            ),

            const SizedBox(height: 16),

            // プライバシー情報
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.privacy_tip, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'プライバシーについて',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 撮影した画像は商品名と価格の読み取りのみに使用されます\n'
                    '• 個人を特定できる情報は含まれません\n'
                    '• 画像は端末内で処理され、外部に送信されることはありません\n'
                    '• 読み取った情報は買い物リスト作成のためだけに使用されます',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('了解して撮影開始'),
        ),
      ],
    );
  }

  Widget _buildGuidelineSection({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
