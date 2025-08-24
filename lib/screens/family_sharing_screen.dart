// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/subscription_service.dart';
import 'subscription_screen.dart';
import '../providers/transmission_provider.dart';
import '../providers/data_provider.dart';
import '../models/family_member.dart';
import '../models/shared_content.dart';
import '../models/shop.dart';
import '../models/sync_data.dart';
import '../models/subscription_plan.dart';

/// 家族共有機能のメイン画面（共有対応版）
class FamilySharingScreen extends StatefulWidget {
  const FamilySharingScreen({super.key});

  @override
  State<FamilySharingScreen> createState() => _FamilySharingScreenState();
}

class _FamilySharingScreenState extends State<FamilySharingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // 受信通知の重複ダイアログ表示防止用
  final Set<String> _seenReceivedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // ファミリー情報を初期化（非同期処理を安全に実行）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTransmissionProvider();
    });
  }

  /// TransmissionProviderの初期化
  Future<void> _initializeTransmissionProvider() async {
    try {
      debugPrint('🔧 FamilySharingScreen: TransmissionProvider初期化開始');
      final transmissionProvider = Provider.of<TransmissionProvider>(
        context,
        listen: false,
      );
      await transmissionProvider.initialize();
      debugPrint('✅ FamilySharingScreen: TransmissionProvider初期化完了');
    } catch (e) {
      debugPrint('❌ FamilySharingScreen: TransmissionProvider初期化エラー: $e');
    }
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
        title: const Text('ファミリー共有'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withValues(alpha: 0.7),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          indicatorWeight: 3,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: const [
            Tab(icon: Icon(Icons.people, size: 20), text: 'メンバー'),
            Tab(icon: Icon(Icons.send, size: 20), text: '共有'),
            Tab(icon: Icon(Icons.settings, size: 20), text: '設定'),
          ],
        ),
      ),
      body: Consumer2<SubscriptionService, TransmissionProvider>(
        builder: (context, subscriptionService, transmissionProvider, child) {
          // メンバーかどうかで表示を切り替える
          final isMember = transmissionProvider.isFamilyMember;

          // メンバーでなければ、サブスクリプション状況に応じて案内を表示
          if (!isMember) {
            final canCreate =
                subscriptionService.currentPlan?.isFamilyPlan == true &&
                    subscriptionService.isSubscriptionActive;
            if (canCreate) {
              return _buildCreateFamilyPrompt(transmissionProvider);
            } else {
              return _buildJoinFamilyPrompt(subscriptionService);
            }
          }

          // ファミリープラン以外の場合は制限を表示
          if (subscriptionService.currentPlan?.type !=
              SubscriptionPlanType.family) {
            return _buildNonFamilyPlanLimitPrompt();
          }

          // 既にメンバーであれば通常のタブ表示
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMembersTab(transmissionProvider),
              _buildTransmissionTab(transmissionProvider),
              _buildSettingsTab(transmissionProvider),
            ],
          );
        },
      ),
    );
  }

  /// ファミリー参加案内
  Widget _buildJoinFamilyPrompt(SubscriptionService subscriptionService) {
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
              'ファミリー共有機能',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'ファミリー共有機能を利用するには、\nファミリープランに加入している人のグループに参加するか、\nファミリープランにアップグレードしてください。\n\n※ ファミリーに参加したメンバーは、\nファミリープランの特典（広告非表示、リスト無制限など）を\n利用できますが、ファミリープランに加入する必要はありません。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // QRコードスキャン画面に遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QRCodeScannerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('QRコードでグループに参加'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
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

  /// ファミリープラン以外の制限案内
  Widget _buildNonFamilyPlanLimitPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'ファミリー共有機能制限',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'ファミリー共有機能はファミリープランのみで利用できます。\n\n現在のプランでは、ファミリープラン加入者のグループに参加することで、\nファミリープランの特典（広告非表示、リスト無制限など）を利用できます。\n\n※ ファミリーに参加したメンバーは、\nファミリープランに加入する必要はありません。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/subscription');
                    },
                    icon: const Icon(Icons.upgrade),
                    label: const Text('ファミリープランにアップグレード'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // QRコードスキャン画面に遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QRCodeScannerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('QRコードでグループに参加'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
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

  /// フリープラン制限案内
  Widget _buildFreePlanLimitPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'フリープラン制限',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'ファミリー共有機能はフリープランでは利用できません。\n\nファミリープランにアップグレードして、家族やグループでリストを共有しましょう。',
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
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
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
              'グループ共有機能',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'グループ共有機能を利用するには、\nファミリープランへのアップグレードが必要です。',
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
  Widget _buildMembersTab(TransmissionProvider transmissionProvider) {
    // グループメンバーでない場合は作成案内を表示
    if (!transmissionProvider.isFamilyMember) {
      return _buildCreateFamilyPrompt(transmissionProvider);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // メンバーリスト
          _buildMembersList(transmissionProvider),

          // 招待ボタン（オーナーのみ）
          if (transmissionProvider.isFamilyOwner)
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
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

  /// グループ作成案内
  Widget _buildCreateFamilyPrompt(TransmissionProvider transmissionProvider) {
    final subscriptionService = Provider.of<SubscriptionService>(
      context,
      listen: false,
    );
    final canCreate = subscriptionService.currentPlan?.isFamilyPlan == true &&
        subscriptionService.isSubscriptionActive;

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
              'グループを作成',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'グループ共有を開始するには、\nグループを作成してください。\n作成後、メンバーを招待できます。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed:
                  canCreate ? () => _createFamily(transmissionProvider) : null,
              icon: const Icon(Icons.add),
              label: const Text('グループを作成'),
              style: ElevatedButton.styleFrom(
                backgroundColor: canCreate
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!canCreate) ...[
              Text(
                'グループ作成はファミリープラン加入者のみ利用できます。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const SubscriptionScreen(),
                    ),
                  );
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
              const SizedBox(height: 8),
            ],
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

  /// グループヘッダー
  Widget _buildFamilyHeader(TransmissionProvider transmissionProvider) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                    ).colorScheme.primary.withValues(alpha: 0.1),
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
                        'グループ情報',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${transmissionProvider.familyMembers.length}人のメンバー',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (transmissionProvider.isFamilyOwner)
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
  Widget _buildMembersList(TransmissionProvider transmissionProvider) {
    if (transmissionProvider.familyMembers.isEmpty) {
      return const Center(child: Text('メンバーがいません'));
    }

    // グループ作成直後でメンバーが1人（オーナーのみ）の場合
    if (transmissionProvider.familyMembers.length == 1 &&
        transmissionProvider.isFamilyOwner) {
      return _buildWelcomeMessage(transmissionProvider);
    }

    return Column(
      children: transmissionProvider.familyMembers.asMap().entries.map((entry) {
        final index = entry.key;
        final member = entry.value;
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Card(
            elevation: 4,
            shadowColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
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
                    Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.8),
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
                        ).colorScheme.primary.withValues(alpha: 0.2),
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
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1)
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
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
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
                    if (transmissionProvider.isFamilyOwner &&
                        member.role.name != 'owner' &&
                        member.id != transmissionProvider.currentUserMember?.id)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _showRemoveMemberDialog(
                            transmissionProvider,
                            member,
                          ),
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

  /// グループ作成直後のウェルカムメッセージ
  Widget _buildWelcomeMessage(TransmissionProvider transmissionProvider) {
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
              'グループを作成しました！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'メンバーを招待して、\n共有を開始しましょう。\n\nQRコードで\n簡単に招待できます。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 共有タブ
  Widget _buildTransmissionTab(TransmissionProvider transmissionProvider) {
    if (!transmissionProvider.isFamilyMember) {
      return const Center(child: Text('ファミリーに参加してから共有機能を利用できます'));
    }

    // グループ作成直後でメンバーが1人（オーナーのみ）の場合
    if (transmissionProvider.familyMembers.length == 1 &&
        transmissionProvider.isFamilyOwner) {
      return _buildTransmissionWelcomeMessage();
    }

    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final shops = dataProvider.shops;

        if (shops.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '買い物リストがありません',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'メイン画面でタブを追加してください',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 受信コンテンツ一覧（受け取り確認用）
        final receivedList = transmissionProvider.receivedContents
            .where((c) => c.status == TransmissionStatus.received && c.isActive)
            .toList();

        // 新着受信があれば確認ダイアログを自動表示（1回だけ）
        final newReceived = receivedList
            .where((c) => !_seenReceivedIds.contains(c.id))
            .toList();
        if (newReceived.isNotEmpty) {
          // マークして重複表示を防ぐ
          for (final c in newReceived) {
            _seenReceivedIds.add(c.id);
          }
          // 最初の新着をダイアログで確認
          Future.microtask(() async {
            if (!mounted) return;
            final content = newReceived.first;
            if (!mounted) return;

            if (!mounted) return;

            final confirmed = await showDialog<bool>(
              context: this.context,
              builder: (context) => AlertDialog(
                title: const Text('共有を受信しました'),
                content: Text(
                  '「${content.title}」を受け取りますか？\n送信者: ${content.sharedByName}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('キャンセル'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('受け取る'),
                  ),
                ],
              ),
            );
            if (!mounted) return;
            if (confirmed == true) {
              // 受け取り実行: ダイアログで上書き/新規を選べるように追加ダイアログを表示
              if (!mounted) return;
              final choice = await showDialog<bool?>(
                context: this.context,
                builder: (context) => AlertDialog(
                  title: const Text('受け取り方法'),
                  content: const Text('既存の同名タブがある場合、上書きしますか？（キャンセルで新規作成）'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('新規作成'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('同名があれば上書き'),
                    ),
                  ],
                ),
              );
              if (!mounted) return;

              final overwrite = choice == true;

              // 受け取り実行（overwrite フラグを伝搬）
              await transmissionProvider.applyReceivedTab(
                content,
                overwriteExisting: overwrite,
              );
            }
          });
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (receivedList.isNotEmpty) ...[
              const Text(
                '受信コンテンツ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...receivedList.map(
                (content) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(content.title),
                    subtitle: Text('送信者: ${content.sharedByName}'),
                    trailing: ElevatedButton(
                      onPressed: () =>
                          _applyReceivedContent(content, transmissionProvider),
                      child: const Text('受け取る'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 既存のショップ一覧
            ...shops.map(
              (shop) => _buildSimpleShopCard(shop, transmissionProvider),
            ),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  /// シンプルな買い物リストカード
  Widget _buildSimpleShopCard(
    Shop shop,
    TransmissionProvider transmissionProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showShareOptions(shop, transmissionProvider),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // アイコン
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // タブ名とアイテム数
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${shop.items.where((item) => !item.isChecked).length}個のアイテム',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // 共有ボタン
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () =>
                      _showShareOptions(shop, transmissionProvider),
                  tooltip: '共有',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 共有オプションダイアログを表示
  void _showShareOptions(Shop shop, TransmissionProvider transmissionProvider) {
    final availableRecipients = transmissionProvider.availableRecipients;

    if (availableRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('共有できるメンバーがいません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildShareOptionsSheet(
        shop: shop,
        transmissionProvider: transmissionProvider,
      ),
    );
  }

  /// 共有オプションシート
  Widget _buildShareOptionsSheet({
    required Shop shop,
    required TransmissionProvider transmissionProvider,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ハンドル
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // タイトル
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '「${shop.name}」を送信',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '送信するメンバーを選択してください',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            // メンバーリスト
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: transmissionProvider.availableRecipients.length,
                itemBuilder: (context, index) {
                  final member =
                      transmissionProvider.availableRecipients[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        member.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        member.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _sendToMember(shop, member, transmissionProvider);
                      },
                    ),
                  );
                },
              ),
            ),
            // 全員に送信ボタン
            if (transmissionProvider.availableRecipients.length > 1)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendToAllMembers(shop, transmissionProvider);
                    },
                    icon: const Icon(Icons.group),
                    label: const Text('全員に送信'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            // キャンセルボタン
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 特定のメンバーに送信
  void _sendToMember(
    Shop shop,
    FamilyMember member,
    TransmissionProvider transmissionProvider,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 簡単な確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: Text('「${shop.name}」を${member.displayName}に共有しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('共有'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 送信処理
    final success = await transmissionProvider.syncAndSendTab(
      shop: shop,
      title: shop.name,
      description: '${shop.items.length}個のアイテム',
      recipients: [member],
      items: shop.items,
    );

    if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(success ? '${member.displayName}に共有しました' : '共有に失敗しました'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// 全員に送信
  void _sendToAllMembers(
    Shop shop,
    TransmissionProvider transmissionProvider,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 簡単な確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: Text('「${shop.name}」を全員に共有しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('共有'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 送信処理
    final recipients = transmissionProvider.availableRecipients;

    final success = await transmissionProvider.syncAndSendTab(
      shop: shop,
      title: shop.name,
      description: '${shop.items.length}個のアイテム',
      recipients: recipients,
      items: shop.items,
    );

    if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(success ? '全員に共有しました' : '共有に失敗しました'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// 共有ヘッダー
  Widget _buildTransmissionHeader() {
    return Container(
      margin: const EdgeInsets.all(16.0),
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
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.send,
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
                      '共有',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'コンテンツを家族メンバーに送信できます\n同期送信では受信者が自動追加できます',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 送信可能なコンテンツセクション
  Widget _buildAvailableContentSection(
    TransmissionProvider transmissionProvider,
  ) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final availableShops = dataProvider.shops;

        return Container(
          margin: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '送信可能なコンテンツ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (availableShops.isEmpty)
                _buildEmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: '送信可能なコンテンツがありません',
                  subtitle: '買い物リストを作成すると、ここに表示されます',
                )
              else
                ...availableShops.map(
                  (shop) => _buildShopCard(shop, transmissionProvider),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 空の状態表示
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
  }) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: themeColor.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: themeColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Shopカード
  Widget _buildShopCard(Shop shop, TransmissionProvider transmissionProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_cart,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${shop.items.length}個のアイテム',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message:
                        '買い物リストをそのまま送信します。受信者は内容を確認できますが、自動的に自分のリストに追加されることはありません。',
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showSendDialog(shop, transmissionProvider),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('送信'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Tooltip(
                    message:
                        '買い物リストを同期データとして送信します。受信者は「適用」ボタンで自分のリストに自動追加できます。',
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showSyncSendDialog(shop, transmissionProvider),
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('同期送信'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '送信：内容確認のみ | 同期送信：自動追加可能',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 同期データセクション
  Widget _buildSyncDataSection(TransmissionProvider transmissionProvider) {
    final syncDataList = transmissionProvider.syncDataList;

    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sync, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                '同期データ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (syncDataList.isEmpty)
            _buildEmptyState(
              icon: Icons.sync,
              title: '同期データがありません',
              subtitle: '同期送信を行うと、ここに表示されます',
              color: Colors.green,
            )
          else
            ...syncDataList.map(
              (syncData) => _buildSyncDataCard(syncData, transmissionProvider),
            ),
        ],
      ),
    );
  }

  /// 同期データカード
  Widget _buildSyncDataCard(
    SyncData syncData,
    TransmissionProvider transmissionProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            syncData.type == SyncDataType.tab ? Icons.tab : Icons.list,
            color: Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          syncData.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${syncData.items.length}個のアイテム',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              '${syncData.createdAt.day}/${syncData.createdAt.month}/${syncData.createdAt.year}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              await _deleteSyncData(syncData, transmissionProvider);
            } else if (value == 'details') {
              _showSyncDataDetails(syncData);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18),
                  SizedBox(width: 8),
                  Text('詳細'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('削除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 受信コンテンツ関連UIは不要のため削除しました

  /// 共有タブのウェルカムメッセージ
  Widget _buildTransmissionWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              '共有機能',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '家族メンバーを招待すると、\n新しい共有機能を\n利用できるようになります。\n\nまずは家族メンバーを\n招待してみましょう！',
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
                backgroundColor: Colors.blue,
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
  Widget _buildSettingsTab(TransmissionProvider transmissionProvider) {
    if (!transmissionProvider.isFamilyMember) {
      return const Center(child: Text('ファミリーに参加してから設定を変更できます'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          if (!transmissionProvider.isFamilyOwner)
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text('ファミリーを脱退'),
                subtitle: const Text('このファミリーから脱退します'),
                onTap: () => _showLeaveFamilyDialog(transmissionProvider),
              ),
            ),

          // ファミリー解散ボタン（オーナーのみ）
          if (transmissionProvider.isFamilyOwner)
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('ファミリーを解散'),
                subtitle: const Text('ファミリーを完全に削除します（全メンバーが脱退）'),
                onTap: () => _showDissolveFamilyDialog(transmissionProvider),
              ),
            ),
        ],
      ),
    );
  }

  /// 設定タブのウェルカムメッセージ
  Widget _buildSettingsWelcomeMessage(TransmissionProvider familyService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings, size: 80, color: Colors.orange),
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

  // MARK: - Family Actions

  /// 送信ダイアログを表示
  void _showSendDialog(Shop shop, TransmissionProvider transmissionProvider) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) => _SendContentDialog(
        shop: shop,
        availableRecipients: transmissionProvider.availableRecipients,
        onSend: (title, description, recipients) async {
          final success = await transmissionProvider.syncAndSendTab(
            shop: shop,
            title: title,
            description: description,
            recipients: recipients,
            items: shop.items,
          );

          if (mounted) {
            if (success) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('コンテンツを送信しました'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('送信に失敗しました'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// 同期送信ダイアログを表示
  void _showSyncSendDialog(
    Shop shop,
    TransmissionProvider transmissionProvider,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) => _SyncSendContentDialog(
        shop: shop,
        availableRecipients: transmissionProvider.availableRecipients,
        onSend: (title, description, recipients) async {
          final success = await transmissionProvider.syncAndSendTab(
            shop: shop,
            title: title,
            description: description,
            recipients: recipients,
            items: shop.items,
          );

          if (mounted) {
            if (success) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('タブを同期して送信しました'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('同期送信に失敗しました'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// 同期データを削除
  Future<void> _deleteSyncData(
    SyncData syncData,
    TransmissionProvider transmissionProvider,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同期データを削除'),
        content: Text('「${syncData.title}」の同期データを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await transmissionProvider.deleteSyncData(syncData.id);
      if (mounted) {
        if (success) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('同期データを削除しました'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('削除に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 同期データ詳細を表示
  void _showSyncDataDetails(SyncData syncData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(syncData.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('タイプ: ${syncData.type.displayName}'),
            const SizedBox(height: 8),
            Text(
              '作成日時: ${syncData.createdAt.day}/${syncData.createdAt.month}/${syncData.createdAt.year}',
            ),
            const SizedBox(height: 8),
            Text('アイテム数: ${syncData.items.length}個'),
            if (syncData.appliedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                '適用日時: ${syncData.appliedAt!.day}/${syncData.appliedAt!.month}/${syncData.appliedAt!.year}',
              ),
            ],
            if (syncData.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('説明: ${syncData.description}'),
            ],
          ],
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

  /// 受信コンテンツを適用
  Future<void> _applyReceivedContent(
    SharedContent content,
    TransmissionProvider transmissionProvider,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await transmissionProvider.applyReceivedTab(content);
    if (mounted) {
      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('コンテンツを適用しました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('適用に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ステータスカラーを取得
  Color _getStatusColor(TransmissionStatus status) {
    switch (status) {
      case TransmissionStatus.sent:
        return Colors.blue;
      case TransmissionStatus.received:
        return Colors.orange;
      case TransmissionStatus.accepted:
        return Colors.green;
      case TransmissionStatus.deleted:
        return Colors.red;
    }
  }

  // MARK: - Family Actions

  /// ファミリー作成
  Future<void> _createFamily(TransmissionProvider transmissionProvider) async {
    final success = await transmissionProvider.createFamily();

    if (mounted) {
      if (success) {
        // ファミリー作成成功時は専用ページを表示
        _showFamilyCreatedPage(transmissionProvider);
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
  void _showFamilyCreatedPage(TransmissionProvider transmissionProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _FamilyCreatedDialog(familyService: transmissionProvider),
    );
  }

  /// QRコードスキャナーを表示
  void _showQRCodeScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRCodeScannerScreen(openedFromFamily: true),
      ),
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
        familyService: Provider.of<TransmissionProvider>(
          context,
          listen: false,
        ),
      ),
    );
  }

  /// ファミリー脱退確認ダイアログ
  void _showLeaveFamilyDialog(TransmissionProvider transmissionProvider) {
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
              await _leaveFamily(transmissionProvider);
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
  void _showDissolveFamilyDialog(TransmissionProvider transmissionProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ファミリーを解散'),
        content: Text(
          'ファミリーを解散しますか？\n\nこの操作により、全メンバー（${transmissionProvider.familyMembers.length}人）がファミリーから脱退し、ファミリーが完全に削除されます。\n\nこの操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dissolveFamily(transmissionProvider);
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
  Future<void> _leaveFamily(TransmissionProvider transmissionProvider) async {
    final success = await transmissionProvider.leaveFamily();

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
  Future<void> _dissolveFamily(
    TransmissionProvider transmissionProvider,
  ) async {
    final success = await transmissionProvider.dissolveFamily();

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
    TransmissionProvider transmissionProvider,
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
              await _removeMember(transmissionProvider, member);
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
    TransmissionProvider transmissionProvider,
    FamilyMember member,
  ) async {
    final success = await transmissionProvider.removeMember(member.id);

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
  final TransmissionProvider familyService;

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
  final bool openedFromFamily;

  const QRCodeScannerScreen({super.key, this.openedFromFamily = false});

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
            const Icon(Icons.error, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'エラーが発生しました',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
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
      if (!mounted) return;
      final familyService = Provider.of<TransmissionProvider>(
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
      final familyService = Provider.of<TransmissionProvider>(
        context,
        listen: false,
      );

      // 現在のファミリーIDをリセット（権限エラー対策）
      await familyService.resetFamilyId();

      // ファミリーに参加（招待トークンの使用済みマークは内部で処理）
      final success = await familyService.joinFamilyByQRCode(
        qrMap['inviteToken'],
      );

      if (mounted) {
        if (success) {
          // 自動移行の確認（現在は使用していないが将来の拡張のために残す）
          // final subscriptionService = Provider.of<SubscriptionService>(
          //   context,
          //   listen: false,
          // );
          // final currentPlan = subscriptionService.currentPlan;
          // final isAutoUpgraded = currentPlan?.type == SubscriptionPlanType.family;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ファミリーに参加しました！\nファミリープランの特典（広告非表示、リスト無制限など）が利用できるようになりました。\n\n※ ファミリープランに加入する必要はありません。',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 6),
            ),
          );
          // スキャナー画面を閉じる
          Navigator.pop(context);

          // 初期化して受信コンテンツを取得
          try {
            await familyService.initialize();
            final pending = familyService.receivedContents
                .where(
                  (c) => c.status == TransmissionStatus.received && c.isActive,
                )
                .toList();
            int appliedCount = 0;
            for (final content in pending) {
              final ok = await familyService.applyReceivedTab(content);
              if (ok) appliedCount++;
            }
            if (mounted) {
              if (appliedCount > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('共有コンテンツ $appliedCount 件を自動適用しました'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('自動適用処理でエラー: $e');
          }

          // スキャナーがファミリー画面以外から開かれた場合、ファミリー画面へ遷移
          if (!mounted) return;
          if (!widget.openedFromFamily) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FamilySharingScreen()),
            );
          }
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
  final TransmissionProvider familyService;

  const _FamilyCreatedDialog({required this.familyService});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 80, color: Colors.green),
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

/// 機能項目ウィジェット
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 送信コンテンツダイアログ
class _SendContentDialog extends StatefulWidget {
  final Shop shop;
  final List<FamilyMember> availableRecipients;
  final Function(
    String title,
    String description,
    List<FamilyMember> recipients,
  ) onSend;

  const _SendContentDialog({
    required this.shop,
    required this.availableRecipients,
    required this.onSend,
  });

  @override
  State<_SendContentDialog> createState() => _SendContentDialogState();
}

class _SendContentDialogState extends State<_SendContentDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<FamilyMember> _selectedRecipients = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.shop.name;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('コンテンツを送信'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル入力
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 説明入力
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明（任意）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // 受信者選択
            const Text(
              '送信先を選択:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (widget.availableRecipients.isEmpty)
              const Text('送信可能なメンバーがいません', style: TextStyle(color: Colors.grey))
            else
              ...widget.availableRecipients.map((member) {
                final isSelected = _selectedRecipients.contains(member);
                return CheckboxListTile(
                  title: Text(member.displayName),
                  subtitle: Text(member.role.displayName),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedRecipients.add(member);
                      } else {
                        _selectedRecipients.remove(member);
                      }
                    });
                  },
                );
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _canSend()
              ? () {
                  Navigator.pop(context);
                  widget.onSend(
                    _titleController.text.trim(),
                    _descriptionController.text.trim(),
                    _selectedRecipients,
                  );
                }
              : null,
          child: const Text('送信'),
        ),
      ],
    );
  }

  bool _canSend() {
    return _titleController.text.trim().isNotEmpty &&
        _selectedRecipients.isNotEmpty;
  }
}

/// 同期コンテンツダイアログ
class _SyncSendContentDialog extends StatefulWidget {
  final Shop shop;
  final List<FamilyMember> availableRecipients;
  final Function(
    String title,
    String description,
    List<FamilyMember> recipients,
  ) onSend;

  const _SyncSendContentDialog({
    required this.shop,
    required this.availableRecipients,
    required this.onSend,
  });

  @override
  State<_SyncSendContentDialog> createState() => _SyncSendContentDialogState();
}

class _SyncSendContentDialogState extends State<_SyncSendContentDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<FamilyMember> _selectedRecipients = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.shop.name;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('コンテンツを同期送信'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル入力
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 説明入力
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明（任意）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // 受信者選択
            const Text(
              '送信先を選択:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (widget.availableRecipients.isEmpty)
              const Text('送信可能なメンバーがいません', style: TextStyle(color: Colors.grey))
            else
              ...widget.availableRecipients.map((member) {
                final isSelected = _selectedRecipients.contains(member);
                return CheckboxListTile(
                  title: Text(member.displayName),
                  subtitle: Text(member.role.displayName),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedRecipients.add(member);
                      } else {
                        _selectedRecipients.remove(member);
                      }
                    });
                  },
                );
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _canSend()
              ? () {
                  Navigator.pop(context);
                  widget.onSend(
                    _titleController.text.trim(),
                    _descriptionController.text.trim(),
                    _selectedRecipients,
                  );
                }
              : null,
          child: const Text('送信'),
        ),
      ],
    );
  }

  bool _canSend() {
    return _titleController.text.trim().isNotEmpty &&
        _selectedRecipients.isNotEmpty;
  }
}
