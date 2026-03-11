import 'package:flutter/material.dart';
import 'package:maikago/screens/drawer/widgets/usage/usage_camera_feature_card.dart';
import 'package:maikago/screens/drawer/widgets/usage/usage_header.dart';
import 'package:maikago/screens/drawer/widgets/usage/usage_list_operation_card.dart';
import 'package:maikago/screens/drawer/widgets/usage/usage_screen_explanation_card.dart';
import 'package:maikago/screens/drawer/widgets/usage/usage_section_header.dart';
import 'package:maikago/screens/drawer/widgets/usage/usage_step_card.dart';
import 'package:maikago/services/settings_theme.dart';

class UsageScreen extends StatelessWidget {
  const UsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使い方'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            UsageHeader(),
            SizedBox(height: 24),

            // 画面の見方
            UsageSectionHeader(
              title: '画面の見方',
              icon: Icons.visibility_rounded,
            ),
            SizedBox(height: 16),
            UsageScreenExplanationCard(),
            SizedBox(height: 24),

            // 基本的な使い方
            UsageSectionHeader(
              title: '基本的な使い方',
              icon: Icons.play_circle_rounded,
            ),
            SizedBox(height: 16),

            // ステップ1: ショッピングリストを作成
            UsageStepCard(
              stepNumber: 1,
              title: 'タブを作成',
              description:
                  '画面右上の「+」ボタンをタップして、新しいタブを作成します。\n\n例：「スーパー」「ドラッグストア」「コンビニ」など',
              icon: Icons.add_shopping_cart_rounded,
              color: AppColors.primary,
            ),
            SizedBox(height: 16),

            // ステップ2: 商品を追加
            UsageStepCard(
              stepNumber: 2,
              title: 'リストを追加',
              description:
                  'タブ内で画面右下の「+」ボタンをタップしてリストを追加します。\n\nリスト名、個数、価格、割引率を設定できます。',
              icon: Icons.add_circle_rounded,
              color: AppColors.featureGreen,
            ),
            SizedBox(height: 16),

            // ステップ3: カメラ機能を使用
            UsageStepCard(
              stepNumber: 3,
              title: 'カメラ機能を使用',
              description: '画面下部の真ん中のカメラボタンをタップします。\n\n値札撮影：AIが商品名と価格を自動読み取り',
              icon: Icons.camera_alt_rounded,
              color: AppColors.featureOrange,
            ),
            SizedBox(height: 16),

            // ステップ4: 商品を編集
            UsageStepCard(
              stepNumber: 4,
              title: '商品を編集',
              description:
                  '商品をタップして詳細を編集できます。\n\n専用の数字キーボードで個数、単価、割引率を簡単に入力できます！',
              icon: Icons.edit_rounded,
              color: AppColors.featureSky,
            ),
            SizedBox(height: 16),

            // ステップ5: 購入完了
            UsageStepCard(
              stepNumber: 5,
              title: '購入完了',
              description:
                  'リストを左右にスワイプして購入済みに移動させてください。\n\n購入済みリストに移動し、合計金額が自動計算されます！',
              icon: Icons.check_circle_rounded,
              color: AppColors.featureGold,
            ),
            SizedBox(height: 24),

            // リストの操作方法
            UsageSectionHeader(
              title: 'リストの操作方法',
              icon: Icons.touch_app_rounded,
            ),
            SizedBox(height: 16),
            UsageListOperationCard(),
            SizedBox(height: 24),

            // カメラ機能の説明
            UsageSectionHeader(
              title: '値札撮影機能',
              icon: Icons.camera_alt_rounded,
            ),
            SizedBox(height: 16),
            UsageCameraFeatureCard(),
            SizedBox(height: 24),

            // （「タブの使い方」「便利な機能」「寄付者限定機能」「便利なヒント」を削除しました）
          ],
        ),
      ),
    );
  }
}
