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

            // ステップ3: カメラ機能を使用
            _buildStepCard(
              context,
              stepNumber: 3,
              title: 'カメラ機能を使用',
              description: '画面下部の真ん中のカメラボタンをタップします。\n\n値札撮影：AIが商品名と価格を自動読み取り',
              icon: Icons.camera_alt_rounded,
              color: const Color(0xFFFFA500),
            ),
            const SizedBox(height: 16),

            // ステップ4: 商品を編集
            _buildStepCard(
              context,
              stepNumber: 4,
              title: '商品を編集',
              description:
                  '商品をタップして詳細を編集できます。\n\n専用の数字キーボードで個数、単価、割引率を簡単に入力できます！',
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
                  'リストを左右にスワイプして購入済みに移動させてください。\n\n購入済みリストに移動し、合計金額が自動計算されます！',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFFFFD700),
            ),
            const SizedBox(height: 24),

            // リストの操作方法
            _buildSectionHeader(context, 'リストの操作方法', Icons.touch_app_rounded),
            const SizedBox(height: 16),
            _buildListOperationCard(context),
            const SizedBox(height: 24),

            // カメラ機能の説明
            _buildSectionHeader(context, '値札撮影機能', Icons.camera_alt_rounded),
            const SizedBox(height: 16),
            _buildCameraFeatureCard(context),
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
            description: '画面下部の真ん中のカメラボタンをタップして、値札撮影で商品を自動追加できます。',
          ),
        ],
      ),
    );
  }

  Widget _buildListOperationCard(BuildContext context) {
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
            'リストアイテムの操作方法',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // タップ操作
          _buildOperationItem(
            context,
            icon: Icons.touch_app_rounded,
            title: 'タップ',
            description: '商品の編集・削除',
            details:
                'リストアイテムをタップすると、商品の編集画面が開きます。個数、単価、割引率の設定、商品名の変更、削除がすべてこの画面で行えます。',
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 16),

          // スワイプ操作
          _buildOperationItem(
            context,
            icon: Icons.swipe_rounded,
            title: 'スワイプ',
            description: '未購入と購入済みの移動',
            details:
                'リストアイテムを左右にスワイプすると、未購入と購入済みの間で移動できます。購入済みに移動すると合計金額が自動計算されます。',
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 16),

          // 長押し操作
          _buildOperationItem(
            context,
            icon: Icons.drag_indicator_rounded,
            title: '長押し',
            description: 'リストの並べ替え',
            details: 'リストアイテムを長押しすると並べ替えモードになります。ドラッグして好きな順番に並べ替えることができます。',
            color: const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String details,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        description,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  details,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
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
                  color: Colors.grey[600],
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
