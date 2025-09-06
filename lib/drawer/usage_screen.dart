import 'package:flutter/material.dart';

class UsageScreen extends StatelessWidget {
  const UsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使い方'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'まいカゴの使い方',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '簡単に使える買い物リスト管理アプリ',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 画面の見方
            _buildSectionHeader(context, '画面の見方', Icons.visibility_rounded),
            const SizedBox(height: 16),
            _buildScreenExplanationCard(context),
            const SizedBox(height: 24),

            // カメラ機能の説明
            _buildSectionHeader(context, 'カメラ機能', Icons.camera_alt_rounded),
            const SizedBox(height: 16),
            _buildCameraFeatureCard(context),
            const SizedBox(height: 24),

            // 基本的な使い方
            _buildSectionHeader(context, '基本的な使い方', Icons.play_circle_rounded),
            const SizedBox(height: 16),

            // ステップ1: ショッピングリストを作成
            _buildStepCard(
              context,
              stepNumber: 1,
              title: 'タブを作成',
              description:
                  '画面右上の「+」ボタンをタップして、新しいタブを作成します。\n\n例：「スーパー」「ドラッグストア」「コンビニ」など',
              icon: Icons.add_shopping_cart_rounded,
              color: const Color(0xFFFFB6C1),
            ),
            const SizedBox(height: 16),

            // ステップ2: 商品を追加
            _buildStepCard(
              context,
              stepNumber: 2,
              title: 'リストを追加',
              description:
                  'タブ内で画面右下の「+」ボタンをタップしてリストを追加します。\n\nリスト名、個数、価格、割引率を設定できます。',
              icon: Icons.add_circle_rounded,
              color: const Color(0xFF90EE90),
            ),
            const SizedBox(height: 16),

            // ステップ3: カメラで値札撮影
            _buildStepCard(
              context,
              stepNumber: 3,
              title: 'カメラで値札撮影',
              description:
                  '画面下部の真ん中のカメラボタンをタップして値札を撮影します。\n\nAIが自動で商品名と価格を読み取り、リストに追加できます。',
              icon: Icons.camera_alt_rounded,
              color: const Color(0xFFFFA500),
            ),
            const SizedBox(height: 16),

            // ステップ4: 商品を編集
            _buildStepCard(
              context,
              stepNumber: 4,
              title: '商品を編集',
              description: '商品をタップして詳細を編集できます。\n\n価格や個数を変更すると、合計金額が自動で更新されます！',
              icon: Icons.edit_rounded,
              color: const Color(0xFF87CEEB),
            ),
            const SizedBox(height: 16),

            // ステップ5: 購入完了
            _buildStepCard(
              context,
              stepNumber: 5,
              title: '購入完了',
              description:
                  'リストを買ったら、左側のチェックボックスをタップしてください。\n\n購入済みリストに移動し、合計金額が自動計算されます！',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFFFFD700),
            ),
            const SizedBox(height: 24),

            // （「タブの使い方」「便利な機能」「寄付者限定機能」「便利なヒント」を削除しました）
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildScreenExplanationCard(BuildContext context) {
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
          Text(
            '画面の構成',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildScreenElement(
            context,
            icon: Icons.tab_rounded,
            title: 'タブ',
            description: '画面上部に表示されるタブです。複数のタブを作成できます。',
          ),
          const SizedBox(height: 12),
          _buildScreenElement(
            context,
            icon: Icons.list_alt_rounded,
            title: '未購入リスト',
            description: '各タブ内に表示される未購入の商品一覧です。購入予定の商品がチェックボックス付きで表示されます。',
          ),
          const SizedBox(height: 12),
          _buildScreenElement(
            context,
            icon: Icons.check_circle_outline_rounded,
            title: '購入済みリスト',
            description: 'チェックした商品が移動する場所です。合計金額が自動計算されます。',
          ),
          const SizedBox(height: 12),
          _buildScreenElement(
            context,
            icon: Icons.account_balance_wallet_rounded,
            title: '予算設定',
            description: '各タブに予算を設定できます。残り予算が表示され、予算を超えると警告が表示されます。',
          ),
          const SizedBox(height: 12),
          _buildScreenElement(
            context,
            icon: Icons.attach_money_rounded,
            title: '合計金額表示',
            description: '画面下部に表示される購入済み商品の合計金額です。',
          ),
          const SizedBox(height: 12),
          _buildScreenElement(
            context,
            icon: Icons.camera_alt_rounded,
            title: 'カメラボタン',
            description: '画面下部の真ん中のカメラボタンをタップして値札を撮影し、自動でリストに追加できます。',
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFeatureCard(BuildContext context) {
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
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'AI値札読み取り機能',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '値札をカメラで撮影するだけで、AIが自動で商品名と価格を読み取り、リストに追加できます。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 20),

          // 使い方の詳細
          _buildCameraStep(
            context,
            stepNumber: 1,
            title: 'カメラボタンをタップ',
            description: '画面下部の真ん中のカメラアイコンをタップします。',
            icon: Icons.camera_alt_rounded,
          ),
          const SizedBox(height: 12),
          _buildCameraStep(
            context,
            stepNumber: 2,
            title: '値札を撮影',
            description: '商品の値札がはっきり見えるように撮影してください。',
            icon: Icons.photo_camera_rounded,
          ),
          const SizedBox(height: 12),
          _buildCameraStep(
            context,
            stepNumber: 3,
            title: 'AIが自動読み取り',
            description: 'AIが商品名と価格を自動で認識します。',
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: 12),
          _buildCameraStep(
            context,
            stepNumber: 4,
            title: 'リストに追加',
            description: '読み取った情報が自動でリストに追加されます。',
            icon: Icons.add_circle_rounded,
          ),

          const SizedBox(height: 20),

          // 注意事項
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '撮影時のご注意',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 他のお客様のご迷惑にならないよう静かに撮影してください\n'
                  '• 店舗スタッフの業務に支障をきたさないようご配慮ください\n'
                  '• 値札がはっきり見えるように撮影してください\n'
                  '• 読み取り精度を向上させるため、明るい場所で撮影してください',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                        height: 1.4,
                      ),
                ),
              ],
            ),
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
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 8),
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
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
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
      child: Row(
        children: [
          // ステップ番号とアイコン
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        stepNumber.toString(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // タイトルと説明
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenElement(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // _buildUsageExample は削除したセクションに関連するため不要
}
