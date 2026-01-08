import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/ocr_session_result.dart';
import '../models/list.dart';
import '../models/shop.dart';
import '../providers/data_provider.dart';
import '../widgets/existing_list_selector_dialog.dart';
import '../widgets/update_confirm_dialog.dart';

/// 保存モード
enum SaveMode {
  /// 新しいリストとして保存
  createNew,

  /// 既存のリストを更新
  updateExisting,
}

/// OCR結果確認・編集画面
class OcrResultConfirmScreen extends StatefulWidget {
  final OcrSessionResult ocrResult;
  final String currentShopId;

  const OcrResultConfirmScreen({
    super.key,
    required this.ocrResult,
    required this.currentShopId,
  });

  @override
  State<OcrResultConfirmScreen> createState() => _OcrResultConfirmScreenState();
}

class _OcrResultConfirmScreenState extends State<OcrResultConfirmScreen> {
  late List<OcrSessionResultItem> _items;
  SaveMode _saveMode = SaveMode.createNew;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.ocrResult.items);
  }

  int get _totalPrice =>
      _items.fold(0, (sum, item) => sum + item.price * item.quantity);

  Future<void> _handleSave() async {
    if (_isProcessing) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品を1つ以上追加してください')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_saveMode == SaveMode.createNew) {
        await _saveAsNew();
      } else {
        await _saveAsUpdate();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _saveAsNew() async {
    final dataProvider = context.read<DataProvider>();
    final uuid = const Uuid();

    for (final item in _items) {
      final listItem = ListItem(
        id: uuid.v4(),
        name: item.name,
        quantity: item.quantity,
        price: item.price,
        shopId: widget.currentShopId,
        createdAt: DateTime.now(),
        timestamp: DateTime.now(),
      );

      await dataProvider.addItem(listItem);
    }

    if (mounted) {
      Navigator.of(context).pop(
        SaveResult.success(
          message: '${_items.length}個の商品を追加しました',
          targetShopId: widget.currentShopId,
          isUpdateMode: false,
        ),
      );
    }
  }

  Future<void> _saveAsUpdate() async {
    final dataProvider = context.read<DataProvider>();

    // 既存リスト選択ダイアログを表示
    final selectedShop = await ExistingListSelectorDialog.show(
      context: context,
      shops: dataProvider.shops,
      currentShopId: widget.currentShopId,
    );

    if (selectedShop == null || !mounted) return;

    // 更新確認ダイアログを表示
    final confirmed = await UpdateConfirmDialog.show(
      context: context,
      targetListName: selectedShop.name,
      currentItemCount: selectedShop.items.length,
      newItemCount: _items.length,
      newTotalPrice: _totalPrice,
      onConfirm: () async {
        await _replaceShopItems(selectedShop);
      },
    );

    if (confirmed && mounted) {
      Navigator.of(context).pop(
        SaveResult.success(
          message: '「${selectedShop.name}」を更新しました',
          targetShopId: selectedShop.id,
          isUpdateMode: true,
        ),
      );
    }
  }

  Future<void> _replaceShopItems(Shop targetShop) async {
    final dataProvider = context.read<DataProvider>();
    final uuid = const Uuid();

    // 1. 既存のアイテムを全て削除
    final existingItemIds = targetShop.items.map((e) => e.id).toList();
    if (existingItemIds.isNotEmpty) {
      await dataProvider.deleteItems(existingItemIds);
    }

    // 2. 新しいアイテムを追加
    for (final item in _items) {
      final listItem = ListItem(
        id: uuid.v4(),
        name: item.name,
        quantity: item.quantity,
        price: item.price,
        shopId: targetShop.id,
        createdAt: DateTime.now(),
        timestamp: DateTime.now(),
      );

      await dataProvider.addItem(listItem);
    }
  }

  void _addItem() {
    setState(() {
      _items.add(OcrSessionResultItem(
        id: const Uuid().v4(),
        name: '',
        price: 0,
        quantity: 1,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, OcrSessionResultItem updatedItem) {
    setState(() {
      _items[index] = updatedItem;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('読み取り結果の確認'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 商品リスト
          Expanded(
            child: _items.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return _buildItemCard(context, index);
                    },
                  ),
          ),
          // 合計金額
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '合計 (${_items.length}個)',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '¥$_totalPrice',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // 保存モード選択
          _buildSaveModeSelector(context),
          // 保存ボタン
          _buildSaveButton(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '商品がありません',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '右下の＋ボタンで商品を追加してください',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    final item = _items[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 商品名
            TextFormField(
              initialValue: item.name,
              decoration: const InputDecoration(
                labelText: '商品名',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                _updateItem(index, item.copyWith(name: value));
              },
            ),
            const SizedBox(height: 12),
            // 価格と数量
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: item.price.toString(),
                    decoration: const InputDecoration(
                      labelText: '価格',
                      prefixText: '¥',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final price = int.tryParse(value) ?? 0;
                      _updateItem(index, item.copyWith(price: price));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: '数量',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final quantity = int.tryParse(value) ?? 1;
                      _updateItem(index,
                          item.copyWith(quantity: quantity.clamp(1, 99)));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 削除ボタン
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: '削除',
                ),
              ],
            ),
            // 小計
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '小計: ¥${item.price * item.quantity}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveModeSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '保存方法',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // 新規保存オプション
          RadioListTile<SaveMode>(
            value: SaveMode.createNew,
            groupValue: _saveMode,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _saveMode = value;
                });
              }
            },
            title: const Text('新しいリストとして保存'),
            subtitle: const Text('現在のタブに商品を追加します'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          // 既存更新オプション
          RadioListTile<SaveMode>(
            value: SaveMode.updateExisting,
            groupValue: _saveMode,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _saveMode = value;
                });
              }
            },
            title: const Text('既存のリストを最新にする'),
            subtitle: const Text('選択したリストの内容を置き換えます'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _saveMode == SaveMode.createNew ? '保存する' : 'リストを選択して更新',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
