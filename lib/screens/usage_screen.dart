import 'package:flutter/material.dart';
import 'donation_screen.dart';

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
              title: 'ショッピングリストを作成',
              description:
                  '画面右上の「+」ボタンをタップして、新しいショッピングリストを作成します。\n\n例：「スーパー」「ドラッグストア」「コンビニ」など',
              icon: Icons.add_shopping_cart_rounded,
              color: const Color(0xFFFFB6C1),
            ),
            const SizedBox(height: 16),

            // ステップ2: 商品を追加
            _buildStepCard(
              context,
              stepNumber: 2,
              title: '商品を追加',
              description:
                  'ショッピングリスト内で画面右下の「+」ボタンをタップして商品を追加します。\n\n商品名、個数、価格、割引率を設定できます。',
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
                  '商品を買ったら、左側のチェックボックスをタップしてください。\n\n購入済みリストに移動し、合計金額が自動計算されます！',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFFFFD700),
            ),
            const SizedBox(height: 24),

            // リストの使い方
            _buildSectionHeader(context, 'リストの使い方', Icons.list_rounded),
            const SizedBox(height: 16),
            _buildListUsageCard(context),
            const SizedBox(height: 24),

            // 便利な機能
            _buildSectionHeader(context, '便利な機能', Icons.lightbulb_rounded),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(
                    context,
                    icon: Icons.sort_rounded,
                    title: '並び替え機能',
                    description: '商品を名前、価格、追加順で並び替えできます',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    context,
                    icon: Icons.delete_sweep_rounded,
                    title: '一括削除',
                    description: '購入済み商品をまとめて削除できます',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    context,
                    icon: Icons.calculate_rounded,
                    title: '簡単電卓',
                    description: '買い物中の計算を簡単に行えます',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    context,
                    icon: Icons.text_fields_rounded,
                    title: 'フォントサイズ変更',
                    description: '読みやすいサイズに調整できます',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    context,
                    icon: Icons.palette_rounded,
                    title: 'テーマカスタマイズ',
                    description: 'お好みの色やフォントにカスタマイズできます（寄付者限定機能）',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 寄付者限定機能について
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.1),
                    const Color(0xFFFFD700).withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD700),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '寄付者限定機能',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB8860B),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'テーマカスタマイズ機能は、アプリの開発を支援していただいた寄付者の方限定の機能です。\n\n寄付していただくと、お好みの色やフォントでアプリをカスタマイズできるようになります。\n\n※フォントサイズの変更は誰でもご利用いただけます。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.favorite_rounded),
                      label: const Text('寄付について詳しく'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DonationScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB8860B),
                        side: const BorderSide(color: Color(0xFFFFD700)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ヒント
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEAA7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.tips_and_updates_rounded,
                        color: Color(0xFF856404),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '便利なヒント',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF856404),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem('買い物前に予算を設定すると、予算オーバーを防げます'),
                  _buildTipItem('割引商品は元価格に取り消し線が表示されます'),
                  _buildTipItem('購入済み商品は自動で合計金額に含まれます'),
                  _buildTipItem('複数のショッピングリストを作って使い分けできます'),
                ],
              ),
            ),
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
        color: Colors.white,
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
            title: 'ショッピングリスト（タブ）',
            description: '画面上部に表示されるタブです。複数のリストを作成できます。',
          ),
          const SizedBox(height: 12),
          _buildScreenElement(
            context,
            icon: Icons.list_alt_rounded,
            title: '商品リスト',
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
        ],
      ),
    );
  }

  Widget _buildListUsageCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
            'リストの活用方法',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildUsageExample(
            context,
            title: 'スーパーでの買い物',
            description: '「スーパー」リストを作成して、食料品を追加',
            icon: Icons.shopping_cart_rounded,
          ),
          const SizedBox(height: 12),
          _buildUsageExample(
            context,
            title: 'ドラッグストアでの買い物',
            description: '「ドラッグストア」リストを作成して、日用品を追加',
            icon: Icons.local_pharmacy_rounded,
          ),
          const SizedBox(height: 12),
          _buildUsageExample(
            context,
            title: 'コンビニでの買い物',
            description: '「コンビニ」リストを作成して、軽食や飲み物を追加',
            icon: Icons.store_rounded,
          ),
          const SizedBox(height: 12),
          _buildUsageExample(
            context,
            title: '予算管理',
            description: '各リストに予算を設定して、買い物の予算管理',
            icon: Icons.account_balance_wallet_rounded,
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
        color: Colors.white,
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

  Widget _buildFeatureItem(
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

  Widget _buildUsageExample(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
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

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF856404),
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(top: 6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(color: Color(0xFF856404), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
