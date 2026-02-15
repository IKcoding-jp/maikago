import 'package:flutter/material.dart';

/// カメラ使用時のガイドラインと注意喚起ダイアログ
class CameraGuidelinesDialog extends StatefulWidget {
  const CameraGuidelinesDialog({
    super.key,
    this.showDontShowAgainCheckbox = true,
  });

  final bool showDontShowAgainCheckbox;

  @override
  State<CameraGuidelinesDialog> createState() => _CameraGuidelinesDialogState();
}

class _CameraGuidelinesDialogState extends State<CameraGuidelinesDialog> {
  bool _dontShowAgain = false;

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
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 撮影のコツ（簡略版）
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.camera_alt, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '撮影のコツ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• 値札を正面から大きく撮影\n'
                  '• 文字がくっきり見えるようピントを合わせる\n'
                  '• 手ブレしないようしっかり構える',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 撮影マナー（簡略版）
          _buildGuidelineSection(
            icon: Icons.volume_off,
            title: '静かに撮影',
            description: '他のお客様のご迷惑にならないよう静かに撮影してください。',
          ),

          _buildGuidelineSection(
            icon: Icons.store,
            title: '店舗への配慮',
            description: '店舗の利用規約を確認し、撮影が禁止されている場合は控えてください。',
          ),

          const SizedBox(height: 12),

          // 読み取り精度について（赤色で注意喚起）
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '読み取り精度について',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'カメラの画質やピント、値札の種類によっては、正しく読み取れず、リストが間違った名前や金額で表示されてしまうこともあります。その場合は手動で書き換えてください。',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // プライバシー情報（簡略版）
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                SizedBox(height: 8),
                Text(
                  '• 画像は端末内で処理され、外部に送信されません\n'
                  '• 商品名と価格の読み取りのみに使用されます',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 「二度と表示しない」チェックボックス（条件付き表示）
          if (widget.showDontShowAgainCheckbox)
            Row(
              children: [
                Checkbox(
                  value: _dontShowAgain,
                  onChanged: (value) {
                    setState(() {
                      _dontShowAgain = value ?? false;
                    });
                  },
                  activeColor: Colors.blue,
                ),
                const Expanded(
                  child: Text(
                    '二度と表示しない',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop({
            'confirmed': false,
            'dontShowAgain':
                widget.showDontShowAgainCheckbox ? _dontShowAgain : false,
          }),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop({
            'confirmed': true,
            'dontShowAgain':
                widget.showDontShowAgainCheckbox ? _dontShowAgain : false,
          }),
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
