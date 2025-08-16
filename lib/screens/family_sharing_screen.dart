import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/subscription_service.dart';
import '../services/family_sharing_service.dart';
import '../models/family_member.dart';
import '../models/shared_content.dart';
import '../models/shop.dart';
import '../models/item.dart';

/// 家族共有機能のメイン画面（修正版）
class FamilySharingScreen extends StatefulWidget {
  const FamilySharingScreen({super.key});

  @override
  State<FamilySharingScreen> createState() => _FamilySharingScreenState();
}

class _FamilySharingScreenState extends State<FamilySharingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // ファミリー情報を初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final familyService = Provider.of<FamilySharingService>(
        context,
        listen: false,
      );
      familyService.initialize();
      // 共有コンテンツも読み込む
      familyService.loadSharedContents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('家族共有'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withOpacity(0.7),
          tabs: const [
            Tab(text: 'メンバー', icon: Icon(Icons.people)),
            Tab(text: '共有', icon: Icon(Icons.share)),
            Tab(text: '設定', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: Consumer2<SubscriptionService, FamilySharingService>(
        builder: (context, subscriptionService, familyService, child) {
          // ファミリープラン権限チェック
          final currentPlan = subscriptionService.currentPlan;
          final isFamilyPlan = currentPlan?.isFamilyPlan ?? false;
          final isActive = subscriptionService.isSubscriptionActive;

          if (!isFamilyPlan || !isActive) {
            return _buildUpgradePrompt(subscriptionService);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMembersTab(familyService),
              _buildSharingTab(familyService),
              _buildSettingsTab(familyService),
            ],
          );
        },
      ),
    );
  }

  /// ファミリープランアップグレード案内
  Widget _buildUpgradePrompt(SubscriptionService subscriptionService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              '家族共有機能',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '家族共有機能を利用するには、\nファミリープランへのアップグレードが必要です。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/subscription');
              },
              icon: const Icon(Icons.upgrade),
              label: const Text('ファミリープランにアップグレード'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }

  /// メンバータブ
  Widget _buildMembersTab(FamilySharingService familyService) {
    // ファミリーメンバーでない場合は作成案内を表示
    if (!familyService.isFamilyMember) {
      return _buildCreateFamilyPrompt(familyService);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // メンバーリスト
          _buildMembersList(familyService),

          // 招待ボタン（オーナーのみ）
          if (familyService.isFamilyOwner)
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showInviteOptions(),
                icon: const Icon(Icons.person_add, size: 24),
                label: const Text(
                  'メンバーを招待',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// ファミリー作成案内
  Widget _buildCreateFamilyPrompt(FamilySharingService familyService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'ファミリーを作成',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '家族共有を開始するには、\nファミリーを作成してください。\n作成後、家族メンバーを招待できます。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _createFamily(familyService),
              icon: const Icon(Icons.add),
              label: const Text('ファミリーを作成'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showQRCodeScanner(),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QRコードで参加'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ファミリーヘッダー
  Widget _buildFamilyHeader(FamilySharingService familyService) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.family_restroom_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ファミリー情報',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${familyService.familyMembers.length}人のメンバー',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (familyService.isFamilyOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'オーナー',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// メンバーリスト
  Widget _buildMembersList(FamilySharingService familyService) {
    if (familyService.familyMembers.isEmpty) {
      return const Center(child: Text('メンバーがいません'));
    }

    // ファミリー作成直後でメンバーが1人（オーナーのみ）の場合
    if (familyService.familyMembers.length == 1 &&
        familyService.isFamilyOwner) {
      return _buildWelcomeMessage(familyService);
    }

    return Column(
      children: familyService.familyMembers.asMap().entries.map((entry) {
        final index = entry.key;
        final member = entry.value;
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Card(
            elevation: 4,
            shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  ],
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        member.photoUrl != null && member.photoUrl!.isNotEmpty
                        ? NetworkImage(member.photoUrl!)
                        : null,
                    backgroundColor:
                        member.photoUrl == null || member.photoUrl!.isEmpty
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : null,
                    child: member.photoUrl == null || member.photoUrl!.isEmpty
                        ? Text(
                            member.displayName.isNotEmpty
                                ? member.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                title: Text(
                  member.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: member.role.name == 'owner'
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    member.role.name == 'owner' ? 'オーナー' : 'メンバー',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: member.role.name == 'owner'
                          ? Colors.orange
                          : Colors.blue,
                    ),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // オーナーのみが他のメンバーを削除可能（自分は削除不可）
                    if (familyService.isFamilyOwner &&
                        member.role.name != 'owner' &&
                        member.id != familyService.currentUserMember?.id)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () =>
                              _showRemoveMemberDialog(familyService, member),
                          tooltip: 'メンバーを削除',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// ファミリー作成直後のウェルカムメッセージ
  Widget _buildWelcomeMessage(FamilySharingService familyService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'ファミリーを作成しました！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '家族メンバーを招待して、\n共有を開始しましょう。\n\nQRコードまたはメールで\n簡単に招待できます。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 共有タブ
  Widget _buildSharingTab(FamilySharingService familyService) {
    if (!familyService.isFamilyMember) {
      return const Center(child: Text('ファミリーに参加してから共有機能を利用できます'));
    }

    // ファミリー作成直後でメンバーが1人（オーナーのみ）の場合
    if (familyService.familyMembers.length == 1 &&
        familyService.isFamilyOwner) {
      return _buildSharingWelcomeMessage(familyService);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 共有したコンテンツ
          _buildSharedContentSection(familyService),

          const SizedBox(height: 24),

          // 共有されたコンテンツ
          _buildReceivedContentSection(familyService),

          const SizedBox(height: 24),

          // 共有ボタン
          _buildShareButton(familyService),
        ],
      ),
    );
  }

  /// 共有したコンテンツセクション
  Widget _buildSharedContentSection(FamilySharingService familyService) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.upload,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '共有したコンテンツ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (familyService.sharedContents.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: const Center(
                child: Text(
                  'まだ共有したコンテンツがありません',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            )
          else
            ...familyService.sharedContents.map(
              (content) => _buildSharedContentCard(content),
            ),
        ],
      ),
    );
  }

  /// 共有されたコンテンツセクション
  Widget _buildReceivedContentSection(FamilySharingService familyService) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.download,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '共有されたコンテンツ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (familyService.receivedContents.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: const Center(
                child: Text(
                  'まだ共有されたコンテンツがありません',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            )
          else
            ...familyService.receivedContents.map(
              (content) => _buildReceivedContentCard(content),
            ),
        ],
      ),
    );
  }

  /// 共有ボタン
  Widget _buildShareButton(FamilySharingService familyService) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showShareOptions(familyService),
        icon: const Icon(Icons.share, size: 24),
        label: const Text(
          'コンテンツを共有',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  /// 共有コンテンツカード
  Widget _buildSharedContentCard(SharedContent content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Icon(Icons.upload, color: Colors.green, size: 20),
        ),
        title: Text(content.title),
        subtitle: Text(
          '${content.sharedAt.day}/${content.sharedAt.month}/${content.sharedAt.year}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _showDeleteSharedContentDialog(content),
        ),
      ),
    );
  }

  /// 共有されたコンテンツカード
  Widget _buildReceivedContentCard(SharedContent content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(Icons.download, color: Colors.blue, size: 20),
        ),
        title: Text(content.title),
        subtitle: Text(
          '${content.sharedByName}から ${content.sharedAt.day}/${content.sharedAt.month}/${content.sharedAt.year}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new, color: Colors.blue),
          onPressed: () => _openSharedContent(content),
        ),
      ),
    );
  }

  /// 共有オプション表示
  void _showShareOptions(FamilySharingService familyService) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '共有するコンテンツを選択',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.green),
              title: const Text('タブを共有'),
              subtitle: const Text('買い物タブを家族と共有'),
              onTap: () {
                Navigator.pop(context);
                _showShareListDialog(familyService);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tab, color: Colors.blue),
              title: const Text('リストを共有'),
              subtitle: const Text('お気に入りのリストを家族と共有'),
              onTap: () {
                Navigator.pop(context);
                _showShareTabDialog(familyService);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// タブ共有ダイアログ
  void _showShareListDialog(FamilySharingService familyService) {
    // TODO: 実際のタブ選択機能を実装
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タブを共有'),
        content: const Text('共有するタブを選択してください'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _shareSampleList(familyService);
            },
            child: const Text('サンプルリストを共有'),
          ),
        ],
      ),
    );
  }

  /// リスト共有ダイアログ
  void _showShareTabDialog(FamilySharingService familyService) {
    // TODO: 実際のリスト選択機能を実装
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リストを共有'),
        content: const Text('共有するリストを選択してください'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _shareSampleTab(familyService);
            },
            child: const Text('サンプルリストを共有'),
          ),
        ],
      ),
    );
  }

  /// サンプルタブを共有
  Future<void> _shareSampleList(FamilySharingService familyService) async {
    final shopId = 'sample_tab_${DateTime.now().millisecondsSinceEpoch}';
    final success = await familyService.shareContent(
      shop: Shop(
        id: shopId,
        name: 'サンプル買い物タブ',
        items: [
          Item(
            id: 'item_1',
            name: 'りんご',
            quantity: 3,
            price: 150,
            shopId: shopId,
          ),
          Item(
            id: 'item_2',
            name: 'バナナ',
            quantity: 2,
            price: 100,
            shopId: shopId,
          ),
          Item(
            id: 'item_3',
            name: '牛乳',
            quantity: 1,
            price: 200,
            shopId: shopId,
          ),
        ],
        createdAt: DateTime.now(),
      ),
      title: 'サンプル買い物タブ',
      description: '家族で共有する買い物タブ',
      memberIds: familyService.familyMembers
          .where((member) => member.id != familyService.currentUserMember?.id)
          .map((member) => member.id)
          .toList(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('リストを共有しました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('リストの共有に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// サンプルリストを共有
  Future<void> _shareSampleTab(FamilySharingService familyService) async {
    final shopId = 'sample_list_${DateTime.now().millisecondsSinceEpoch}';
    final success = await familyService.shareContent(
      shop: Shop(
        id: shopId,
        name: 'サンプルリスト',
        items: [
          Item(
            id: 'list_item_1',
            name: 'お気に入り1',
            quantity: 1,
            price: 0,
            shopId: shopId,
          ),
          Item(
            id: 'list_item_2',
            name: 'お気に入り2',
            quantity: 1,
            price: 0,
            shopId: shopId,
          ),
          Item(
            id: 'list_item_3',
            name: 'お気に入り3',
            quantity: 1,
            price: 0,
            shopId: shopId,
          ),
        ],
        createdAt: DateTime.now(),
      ),
      title: 'サンプルリスト',
      description: '家族で共有するリスト',
      memberIds: familyService.familyMembers
          .where((member) => member.id != familyService.currentUserMember?.id)
          .map((member) => member.id)
          .toList(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('リストを共有しました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('リストの共有に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 共有コンテンツ削除ダイアログ
  void _showDeleteSharedContentDialog(SharedContent content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('共有を削除'),
        content: Text('「${content.title}」の共有を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSharedContent(content);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 共有コンテンツを削除
  Future<void> _deleteSharedContent(SharedContent content) async {
    final familyService = Provider.of<FamilySharingService>(
      context,
      listen: false,
    );
    final success = await familyService.removeSharedContent(content.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('共有を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('共有の削除に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 共有コンテンツを開く
  void _openSharedContent(SharedContent content) {
    // TODO: 実際のコンテンツ表示機能を実装
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(content.title),
        content: Text(
          '共有者: ${content.sharedByName}\n共有日: ${content.sharedAt.day}/${content.sharedAt.month}/${content.sharedAt.year}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// 共有タブのウェルカムメッセージ
  Widget _buildSharingWelcomeMessage(FamilySharingService familyService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              '共有機能',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '家族メンバーを招待すると、\nタブやリストを共有できるようになります。\n\nまずは家族メンバーを\n招待してみましょう！',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // タブをメンバータブに切り替え
                _tabController.animateTo(0);
              },
              icon: const Icon(Icons.people),
              label: const Text('メンバーを招待'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 設定タブ
  Widget _buildSettingsTab(FamilySharingService familyService) {
    if (!familyService.isFamilyMember) {
      return const Center(child: Text('ファミリーに参加してから設定を変更できます'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ファミリー設定',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // ファミリー情報
          Card(
            child: ListTile(
              leading: const Icon(Icons.family_restroom_rounded),
              title: const Text('ファミリー情報'),
              subtitle: Text('メンバー数: ${familyService.familyMembers.length}人'),
              trailing: familyService.isFamilyOwner
                  ? const Chip(
                      label: Text('オーナー'),
                      backgroundColor: Colors.orange,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                    )
                  : const Chip(
                      label: Text('メンバー'),
                      backgroundColor: Colors.blue,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // 危険な操作セクション
          const Text(
            '危険な操作',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),

          // ファミリー脱退ボタン（メンバーのみ）
          if (!familyService.isFamilyOwner)
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text('ファミリーを脱退'),
                subtitle: const Text('このファミリーから脱退します'),
                onTap: () => _showLeaveFamilyDialog(familyService),
              ),
            ),

          // ファミリー解散ボタン（オーナーのみ）
          if (familyService.isFamilyOwner)
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('ファミリーを解散'),
                subtitle: const Text('ファミリーを完全に削除します（全メンバーが脱退）'),
                onTap: () => _showDissolveFamilyDialog(familyService),
              ),
            ),
        ],
      ),
    );
  }

  /// 設定タブのウェルカムメッセージ
  Widget _buildSettingsWelcomeMessage(FamilySharingService familyService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'ファミリー設定',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'ファミリーの設定や\nプライバシー設定を\n管理できます。\n\nまずは家族メンバーを\n招待してから設定しましょう！',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // タブをメンバータブに切り替え
                _tabController.animateTo(0);
              },
              icon: const Icon(Icons.people),
              label: const Text('メンバーを招待'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Actions

  /// ファミリー作成
  Future<void> _createFamily(FamilySharingService familyService) async {
    final success = await familyService.createFamily();

    if (mounted) {
      if (success) {
        // ファミリー作成成功時は専用ページを表示
        _showFamilyCreatedPage(familyService);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ファミリーの作成に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ファミリー作成成功ページを表示
  void _showFamilyCreatedPage(FamilySharingService familyService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FamilyCreatedDialog(familyService: familyService),
    );
  }

  /// QRコードスキャナーを表示
  void _showQRCodeScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRCodeScannerScreen()),
    );
  }

  /// 招待オプション表示
  void _showInviteOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '招待方法を選択',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.blue),
              title: const Text('QRコードで招待'),
              subtitle: const Text('QRコードを表示して招待'),
              onTap: () {
                Navigator.pop(context);
                _showQRCodeInvite();
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.green),
              title: const Text('メールで招待'),
              subtitle: const Text('メールアドレスで招待'),
              onTap: () {
                Navigator.pop(context);
                _showEmailInvite();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// QRコード招待表示
  void _showQRCodeInvite() {
    showDialog(
      context: context,
      builder: (context) => _QRCodeInviteDialog(
        familyService: Provider.of<FamilySharingService>(
          context,
          listen: false,
        ),
      ),
    );
  }

  /// メール招待表示
  void _showEmailInvite() {
    // TODO: メール招待機能を実装
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('メール招待機能は今後実装予定です')));
  }

  /// ファミリー脱退確認ダイアログ
  void _showLeaveFamilyDialog(FamilySharingService familyService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ファミリーを脱退'),
        content: const Text('このファミリーから脱退しますか？\n\n脱退すると、ファミリーの共有機能が利用できなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _leaveFamily(familyService);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('脱退する'),
          ),
        ],
      ),
    );
  }

  /// ファミリー解散確認ダイアログ
  void _showDissolveFamilyDialog(FamilySharingService familyService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ファミリーを解散'),
        content: Text(
          'ファミリーを解散しますか？\n\nこの操作により、全メンバー（${familyService.familyMembers.length}人）がファミリーから脱退し、ファミリーが完全に削除されます。\n\nこの操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dissolveFamily(familyService);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('解散する'),
          ),
        ],
      ),
    );
  }

  /// ファミリー脱退
  Future<void> _leaveFamily(FamilySharingService familyService) async {
    final success = await familyService.leaveFamily();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ファミリーから脱退しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // 家族共有画面を閉じる
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ファミリー脱退に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ファミリー解散
  Future<void> _dissolveFamily(FamilySharingService familyService) async {
    final success = await familyService.dissolveFamily();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ファミリーを解散しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // 家族共有画面を閉じる
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ファミリー解散に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// メンバー削除確認ダイアログ
  void _showRemoveMemberDialog(
    FamilySharingService familyService,
    FamilyMember member,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーを削除'),
        content: Text(
          '${member.displayName}をファミリーから削除しますか？\n\nこの操作により、${member.displayName}はファミリーから脱退し、共有機能が利用できなくなります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeMember(familyService, member);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }

  /// メンバー削除
  Future<void> _removeMember(
    FamilySharingService familyService,
    FamilyMember member,
  ) async {
    final success = await familyService.removeMember(member.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.displayName}をファミリーから削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メンバー削除に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// QRコード招待ダイアログ
class _QRCodeInviteDialog extends StatefulWidget {
  final FamilySharingService familyService;

  const _QRCodeInviteDialog({required this.familyService});

  @override
  State<_QRCodeInviteDialog> createState() => _QRCodeInviteDialogState();
}

class _QRCodeInviteDialogState extends State<_QRCodeInviteDialog> {
  Map<String, dynamic>? _qrData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQRCodeData();
  }

  Future<void> _loadQRCodeData() async {
    try {
      final qrData = await widget.familyService.getQRCodeData();
      if (mounted) {
        setState(() {
          _qrData = qrData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QRコードデータの取得に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.qr_code,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'QRコードで招待',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'このQRコードを家族メンバーに\n見せてください',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // QRコード表示
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_qrData != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: _qrData.toString(),
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.error, size: 48, color: Colors.red),
                    SizedBox(height: 8),
                    Text(
                      'QRコードの生成に失敗しました',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              '有効期限: 7日間',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
                ElevatedButton.icon(
                  onPressed: _qrData != null
                      ? () {
                          // TODO: QRコードを保存・共有する機能を実装
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('QRコード保存機能は今後実装予定です')),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.save),
                  label: const Text('保存'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// QRコードスキャナー画面
class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({super.key});

  @override
  State<QRCodeScannerScreen> createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen> {
  MobileScannerController? controller;
  bool _isProcessing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    try {
      controller = MobileScannerController();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カメラの初期化に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコードをスキャン'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller == null) {
      return _buildErrorView('カメラの初期化に失敗しました');
    }

    return _buildScanner();
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: controller!,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (!_isProcessing && barcode.rawValue != null) {
                _isProcessing = true;
                _processQRCode(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () async {
                  try {
                    await controller?.toggleTorch();
                  } catch (e) {
                    debugPrint('フラッシュ切り替えエラー: $e');
                  }
                },
                icon: const Icon(Icons.flash_on, color: Colors.white),
              ),
              IconButton(
                onPressed: () async {
                  try {
                    await controller?.switchCamera();
                  } catch (e) {
                    debugPrint('カメラ切り替えエラー: $e');
                  }
                },
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'エラーが発生しました',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('戻る'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processQRCode(String qrData) async {
    try {
      debugPrint('QRコードデータを受信: $qrData');

      // スキャナーを一時停止
      await controller?.stop();

      // QRコードデータを解析
      final qrMap = _parseQRCodeData(qrData);
      if (qrMap == null) {
        _showErrorDialog('無効なQRコードです');
        return;
      }

      // ファミリー招待かどうかチェック
      if (qrMap['type'] != 'family_invite') {
        _showErrorDialog('ファミリー招待用のQRコードではありません');
        return;
      }

      // 招待トークンを検証
      final familyService = Provider.of<FamilySharingService>(
        context,
        listen: false,
      );
      final isValid = await familyService.validateQRCodeInviteToken(
        qrMap['inviteToken'],
      );

      if (!isValid) {
        _showErrorDialog('招待トークンが無効です。期限切れまたは既に使用済みの可能性があります。');
        return;
      }

      // 招待確認ダイアログを表示
      _showInviteConfirmationDialog(qrMap);
    } catch (e) {
      debugPrint('QRコード処理エラー: $e');
      _showErrorDialog('QRコードの処理中にエラーが発生しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Map<String, dynamic>? _parseQRCodeData(String qrData) {
    try {
      debugPrint('QRコードデータを解析中: $qrData');

      // QRコードデータをMapに変換
      // 実際の実装では、JSON形式でエンコードされたデータを想定
      if (qrData.startsWith('{') && qrData.endsWith('}')) {
        // 簡易的なJSON解析（実際の実装では適切なJSONパーサーを使用）
        final cleanData = qrData.replaceAll('{', '').replaceAll('}', '');
        final pairs = cleanData.split(',');
        final Map<String, dynamic> result = {};

        for (final pair in pairs) {
          final keyValue = pair.split(':');
          if (keyValue.length == 2) {
            final key = keyValue[0].trim().replaceAll('"', '');
            final value = keyValue[1].trim().replaceAll('"', '');
            result[key] = value;
          }
        }

        debugPrint('解析結果: $result');
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('QRコードデータ解析エラー: $e');
      return null;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                });
                // スキャナーを再開
                controller?.start();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInviteConfirmationDialog(Map<String, dynamic> qrMap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ファミリーに参加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ファミリーID: ${qrMap['familyId']}'),
            const SizedBox(height: 8),
            Text('招待者: ${qrMap['createdByName'] ?? '不明'}'),
            const SizedBox(height: 16),
            const Text('このファミリーに参加しますか？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                });
                // スキャナーを再開
                controller?.start();
              }
            },
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _joinFamily(qrMap);
            },
            child: const Text('参加する'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinFamily(Map<String, dynamic> qrMap) async {
    try {
      final familyService = Provider.of<FamilySharingService>(
        context,
        listen: false,
      );

      // 招待トークンを使用済みにマーク
      await familyService.markQRCodeInviteTokenAsUsed(qrMap['inviteToken']);

      // ファミリーに参加
      final success = await familyService.joinFamilyByQRCode(
        qrMap['inviteToken'],
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ファミリーに参加しました！'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // スキャナー画面を閉じる
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ファミリー参加に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('ファミリー参加エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ファミリー参加に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

/// ファミリー作成成功ダイアログ
class _FamilyCreatedDialog extends StatelessWidget {
  final FamilySharingService familyService;

  const _FamilyCreatedDialog({required this.familyService});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'ファミリーを作成しました！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'ファミリーを作成しました。\n家族メンバーを招待して、共有を開始しましょう。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
