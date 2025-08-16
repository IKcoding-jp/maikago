import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/family_sharing_service.dart';
import '../models/family_member.dart';
import '../models/shared_content.dart';
import '../widgets/family_member_list_widget.dart';
import '../widgets/shared_content_list_widget.dart';
import '../widgets/invite_member_dialog.dart';
import '../widgets/share_content_dialog.dart';
import '../widgets/debug_plan_selector_widget.dart';

/// ファミリー共有機能のメイン画面
class FamilySharingScreen extends StatefulWidget {
  const FamilySharingScreen({super.key});

  @override
  State<FamilySharingScreen> createState() => _FamilySharingScreenState();
}

class _FamilySharingScreenState extends State<FamilySharingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FamilySharingService _familyService = FamilySharingService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _familyService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _familyService,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ファミリー共有'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'メンバー'),
              Tab(text: '共有したもの'),
              Tab(text: '共有されたもの'),
            ],
          ),
          actions: [
            if (_familyService.isFamilyOwner)
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: _showInviteDialog,
                tooltip: 'メンバーを招待',
              ),
            if (_familyService.isFamilyMember)
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _showShareDialog,
                tooltip: 'コンテンツを共有',
              ),
          ],
        ),
        body: Consumer<FamilySharingService>(
          builder: (context, service, child) {
            if (!service.canUseFamilySharing) {
              return Column(
                children: [
                  Expanded(child: _buildUpgradePrompt()),
                  const DebugPlanSelectorWidget(),
                ],
              );
            }

            if (service.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!service.isFamilyMember) {
              return Column(
                children: [
                  Expanded(child: _buildCreateFamilyPrompt()),
                  const DebugPlanSelectorWidget(),
                ],
              );
            }

            return Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMembersTab(),
                      _buildSharedTab(),
                      _buildReceivedTab(),
                    ],
                  ),
                ),
                const DebugPlanSelectorWidget(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'ファミリープランが必要です',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'ファミリー共有機能を利用するには、ファミリープランにアップグレードしてください。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/subscription');
              },
              child: const Text('プランを確認'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateFamilyPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'ファミリーを作成',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '家族とリストやタブを共有するために、ファミリーを作成してください。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createFamily,
              child: const Text('ファミリーを作成'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    return Consumer<FamilySharingService>(
      builder: (context, service, child) {
        return FamilyMemberListWidget(
          members: service.familyMembers,
          currentUserMember: service.currentUserMember,
          isOwner: service.isFamilyOwner,
          onRemoveMember: (memberId) => _removeMember(memberId),
          onLeaveFamily: _leaveFamily,
          onDissolveFamily: _dissolveFamily,
        );
      },
    );
  }

  Widget _buildSharedTab() {
    return Consumer<FamilySharingService>(
      builder: (context, service, child) {
        return SharedContentListWidget(
          contents: service.sharedContents,
          type: SharedContentListType.shared,
          onRemoveContent: (contentId) => _removeSharedContent(contentId),
        );
      },
    );
  }

  Widget _buildReceivedTab() {
    return Consumer<FamilySharingService>(
      builder: (context, service, child) {
        return SharedContentListWidget(
          contents: service.receivedContents,
          type: SharedContentListType.received,
          onRemoveContent: (contentId) => _removeSharedContent(contentId),
        );
      },
    );
  }

  Future<void> _createFamily() async {
    final success = await _familyService.createFamily();
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ファミリーを作成しました')));
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ファミリーの作成に失敗しました')));
    }
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => const InviteMemberDialog(),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => const ShareContentDialog(),
    );
  }

  Future<void> _removeMember(String memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーを削除'),
        content: const Text('このメンバーをファミリーから削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _familyService.removeMember(memberId);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('メンバーを削除しました')));
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('メンバーの削除に失敗しました')));
      }
    }
  }

  Future<void> _leaveFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ファミリーを離脱'),
        content: const Text('ファミリーから離脱しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('離脱'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _familyService.leaveFamily();
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ファミリーから離脱しました')));
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ファミリーからの離脱に失敗しました')));
      }
    }
  }

  Future<void> _dissolveFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ファミリーを解散'),
        content: const Text('ファミリーを解散しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('解散'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _familyService.dissolveFamily();
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ファミリーを解散しました')));
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ファミリーの解散に失敗しました')));
      }
    }
  }

  Future<void> _removeSharedContent(String contentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('共有を削除'),
        content: const Text('この共有を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _familyService.removeSharedContent(contentId);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('共有を削除しました')));
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('共有の削除に失敗しました')));
      }
    }
  }
}
