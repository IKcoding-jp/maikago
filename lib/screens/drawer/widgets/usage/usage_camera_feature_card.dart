import 'package:flutter/material.dart';
import 'package:maikago/utils/theme_utils.dart';

class UsageCameraFeatureCard extends StatelessWidget {
  const UsageCameraFeatureCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'AI値札撮影機能',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '値札をカメラで撮影すると、AIが商品名や価格を読み取って、自動でリスト化してくれます。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).subtextColor,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 20),

          // 値札撮影モードの手順
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '値札撮影の手順：',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildCameraStep(
                context,
                stepNumber: 1,
                title: 'カメラボタンをタップ',
                description: '画面下部の真ん中のカメラアイコンをタップします。',
                icon: Icons.camera_alt_rounded,
              ),
              const SizedBox(height: 8),
              _buildCameraStep(
                context,
                stepNumber: 2,
                title: '値札を撮影',
                description: '商品の値札がはっきり見えるように撮影してください。',
                icon: Icons.photo_camera_rounded,
              ),
              const SizedBox(height: 8),
              _buildCameraStep(
                context,
                stepNumber: 3,
                title: 'AIが自動読み取り',
                description: 'AIが商品名と価格を自動で認識します。',
                icon: Icons.auto_awesome_rounded,
              ),
              const SizedBox(height: 8),
              _buildCameraStep(
                context,
                stepNumber: 4,
                title: 'リストに追加',
                description: '読み取った情報が自動でリストに追加されます。',
                icon: Icons.add_circle_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraStep(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).subtextColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
