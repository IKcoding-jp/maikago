import 'package:flutter/material.dart';
import '../models/family_member.dart';

/// ファミリーメンバーリストを表示するウィジェット
class FamilyMemberListWidget extends StatelessWidget {
  final List<FamilyMember> members;
  final FamilyMember? currentUserMember;
  final bool isOwner;
  final Function(String) onRemoveMember;
  final VoidCallback onLeaveFamily;
  final VoidCallback onDissolveFamily;

  const FamilyMemberListWidget({
    super.key,
    required this.members,
    required this.currentUserMember,
    required this.isOwner,
    required this.onRemoveMember,
    required this.onLeaveFamily,
    required this.onDissolveFamily,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Center(child: Text('メンバーがいません'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length + (isOwner ? 2 : 1), // 解散ボタンと離脱ボタン
      itemBuilder: (context, index) {
        if (index < members.length) {
          return _buildMemberCard(context, members[index]);
        } else if (index == members.length && !isOwner) {
          return _buildLeaveFamilyButton(context);
        } else if (index == members.length && isOwner) {
          return _buildDissolveFamilyButton(context);
        } else {
          return _buildLeaveFamilyButton(context);
        }
      },
    );
  }

  Widget _buildMemberCard(BuildContext context, FamilyMember member) {
    final isCurrentUser = currentUserMember?.id == member.id;
    final canRemove = isOwner && !isCurrentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: member.photoUrl != null
              ? NetworkImage(member.photoUrl!)
              : null,
          child: member.photoUrl == null
              ? Text(
                  member.displayName.isNotEmpty
                      ? member.displayName[0].toUpperCase()
                      : '?',
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isCurrentUser)
              const Chip(
                label: Text('あなた'),
                backgroundColor: Colors.blue,
                labelStyle: TextStyle(color: Colors.white, fontSize: 12),
              ),
            Chip(
              label: Text(member.role.displayName),
              backgroundColor: member.role == FamilyRole.owner
                  ? Colors.orange
                  : Colors.grey,
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.email),
            Text(
              '参加日: ${_formatDate(member.joinedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: canRemove
            ? IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () => onRemoveMember(member.id),
                tooltip: 'メンバーを削除',
              )
            : null,
      ),
    );
  }

  Widget _buildLeaveFamilyButton(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.red.shade50,
      child: ListTile(
        leading: const Icon(Icons.exit_to_app, color: Colors.red),
        title: const Text(
          'ファミリーを離脱',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('ファミリーから離脱します'),
        onTap: onLeaveFamily,
      ),
    );
  }

  Widget _buildDissolveFamilyButton(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.red.shade50,
      child: ListTile(
        leading: const Icon(Icons.delete_forever, color: Colors.red),
        title: const Text(
          'ファミリーを解散',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('ファミリーを解散します（取り消せません）'),
        onTap: onDissolveFamily,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
