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
        padding: const EdgeInsets.all(20),
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

            // ステップ3: 商品を編集
            _buildStepCard(
              context,
              stepNumber: 3,
              title: '商品を編集',
              description: '商品をタップして詳細を編集できます。\n\n価格や個数を変更すると、合計金額が自動で更新されます！',
              icon: Icons.edit_rounded,
              color: const Color(0xFF87CEEB),
            ),
            const SizedBox(height: 16),

            // ステップ4: 購入完了
            _buildStepCard(
              context,
              stepNumber: 4,
              title: '購入完了',
              description:
                  'リストを買ったら、左側のチェックボックスをタップしてください。\n\n購入済みリストに移動し、合計金額が自動計算されます！',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFFFFD700),
            ),
            const SizedBox(height: 24),

            // 音声入力の使い方
            _buildSectionHeader(context, '音声入力の使い方', Icons.mic_rounded),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '音声で簡単にリスト追加',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ホーム画面のマイクボタンをタップして話しかけるだけで、アイテムを追加できます。\n\n例: 「牛乳2本」「卵6個」「リンゴ3個」など、数量を一緒に言うと自動で反映されます。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '使い方のポイント：',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• マイクボタンをタップしてから話してください。'),
                        Text('• 余計な言葉は話さないようにしましょう。'),
                        Text('• はっきり喋ることで、正確にリストを追加できます。'),
                      ],
                    ),
                  ),
                ],
              ),
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
            title: 'リスト',
            description: '各タブ内に表示される商品の一覧です。購入予定の商品が表示されます。',
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
            icon: Icons.attach_money_rounded,
            title: '合計金額表示',
            description: '画面下部に表示される購入済み商品の合計金額です。',
          ),
          const SizedBox(height: 12),
          _buildScreenElement(
            context,
            icon: Icons.mic_rounded,
            title: '音声入力ボタン',
            description: 'ホーム画面のマイクボタンをタップして音声でアイテムを追加できます。',
          ),
        ],
      ),
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
