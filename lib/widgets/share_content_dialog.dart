import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transmission_provider.dart';
import '../providers/data_provider.dart';
import '../models/family_member.dart';
import '../models/shop.dart';

/// コンテンツ共有ダイアログ
class ShareContentDialog extends StatefulWidget {
  const ShareContentDialog({super.key});

  @override
  State<ShareContentDialog> createState() => _ShareContentDialogState();
}

class _ShareContentDialogState extends State<ShareContentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Shop? _selectedShop;
  List<String> _selectedMemberIds = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransmissionProvider>(
      builder: (context, transmissionProvider, child) {
        final members = transmissionProvider.familyMembers
            .where(
              (member) =>
                  member.id != transmissionProvider.currentUserMember?.id,
            )
            .toList();

        if (members.isEmpty) {
          return AlertDialog(
            title: const Text('共有'),
            content: const Text('共有できるメンバーがいません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: const Text('コンテンツを共有'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 共有するコンテンツの選択
                  const Text(
                    '共有するリストを選択してください',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildShopSelector(),
                  const SizedBox(height: 16),

                  // タイトル
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'タイトル',
                      hintText: '共有するコンテンツのタイトル',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'タイトルを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 説明
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '説明（任意）',
                      hintText: '共有するコンテンツの説明',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // 共有先メンバーの選択
                  const Text(
                    '共有先を選択してください',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildMemberSelector(members),

                  if (_isLoading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _shareContent,
              child: const Text('共有'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShopSelector() {
    // 実際のデータプロバイダからショップリストを取得
    final dataProvider = Provider.of<DataProvider>(context);
    final shops = dataProvider.shops;

    if (shops.isEmpty) {
      return const Text('共有するリストがありません', style: TextStyle(color: Colors.grey));
    }

    return DropdownButtonFormField<Shop>(
      value: _selectedShop,
      decoration: const InputDecoration(
        labelText: '共有するリスト',
        border: OutlineInputBorder(),
      ),
      items: shops.map((shop) {
        return DropdownMenuItem(value: shop, child: Text(shop.name));
      }).toList(),
      onChanged: (shop) {
        setState(() {
          _selectedShop = shop;
          if (shop != null && _titleController.text.isEmpty) {
            _titleController.text = shop.name;
          }
        });
      },
      validator: (value) {
        if (value == null) {
          return '共有するリストを選択してください';
        }
        return null;
      },
    );
  }

  Widget _buildMemberSelector(List<FamilyMember> members) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListView.builder(
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          final isSelected = _selectedMemberIds.contains(member.id);

          return CheckboxListTile(
            title: Text(member.displayName),
            subtitle: Text(member.email),
            value: isSelected,
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _selectedMemberIds.add(member.id);
                } else {
                  _selectedMemberIds.remove(member.id);
                }
              });
            },
          );
        },
      ),
    );
  }

  Future<void> _shareContent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedShop == null) return;
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('共有先を選択してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transmissionProvider = Provider.of<TransmissionProvider>(
        context,
        listen: false,
      );

      // 選択されたメンバーIDからFamilyMemberオブジェクトを取得
      final selectedMembers = transmissionProvider.familyMembers
          .where((member) => _selectedMemberIds.contains(member.id))
          .toList();

      final success = await transmissionProvider.syncAndSendTab(
        shop: _selectedShop!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        recipients: selectedMembers,
        items: _selectedShop!.items,
      );

      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'コンテンツを共有しました' : '共有に失敗しました'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
