import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/ocr_session_result.dart';
import '../models/list.dart';
import '../models/shop.dart';
import '../providers/data_provider.dart';
import '../utils/dialog_utils.dart';
// unused imports removed

/// 保存モード
// SaveMode enum is removed

/// OCR結果確認・編集画面
class OcrResultConfirmScreen extends StatefulWidget {
  final OcrSessionResult ocrResult;
  final String currentShopId;

  /// ダイアログとして表示するヘルパーメソッド
  static Future<SaveResult?> show(
    BuildContext context, {
    required OcrSessionResult ocrResult,
    required String currentShopId,
  }) {
    return showConstrainedDialog<SaveResult>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: OcrResultConfirmScreen(
            ocrResult: ocrResult,
            currentShopId: currentShopId,
          ),
        ),
      ),
    );
  }

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
  // SaveMode related variables removed
  bool _isProcessing = false;

  /// インデックスごとのマッチング情報: OCRアイテムIndex -> 既存アイテム
  final Map<int, ListItem?> _matchedItems = {};

  /// ユーザーが上書きを選択したインデックスのセット
  final Set<int> _itemsToOverwrite = {};

  // _selectedShopForUpdate is removed

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.ocrResult.items);

    // 初期状態で現在のショップとのマッチングを実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runInitialMatching();
    });
  }

  /// 初期マッチング実行
  void _runInitialMatching() {
    final dataProvider = context.read<DataProvider>();
    final currentShop = dataProvider.shops.firstWhere(
      (s) => s.id == widget.currentShopId,
      orElse: () => Shop(id: '', name: 'Unknown'),
    );

    if (currentShop.id.isNotEmpty) {
      _matchItems(currentShop.items);
    }
  }

  /// 商品マッチングロジック
  void _matchItems(List<ListItem> existingItems) {
    setState(() {
      _matchedItems.clear();
      _itemsToOverwrite.clear();

      for (int i = 0; i < _items.length; i++) {
        final ocrItem = _items[i];
        if (ocrItem.name.isEmpty) continue;

        // 名前によるマッチング（完全一致 or 簡易正規化）
        final match = existingItems.cast<ListItem?>().firstWhere(
          (e) {
            final existingName = _normalize(e!.name);
            final ocrName = _normalize(ocrItem.name);
            return existingName == ocrName ||
                existingName.contains(
                    ocrName) || // 既存商品名がOCR結果を含む（例: "新鮮たまご" in "たまご" はNGだが逆はOK）
                ocrName.contains(
                    existingName); // OCR結果が既存商品名を含む（例: "新鮮たまご" contains "たまご"）
          },
          orElse: () => null,
        );

        if (match != null) {
          _matchedItems[i] = match;
          // デフォルトで上書きをONにする
          _itemsToOverwrite.add(i);
        }
      }
    });
  }

  /// 既存商品を選択するダイアログを表示
  Future<void> _showSelectExistingItemDialog(int index) async {
    final dataProvider = context.read<DataProvider>();
    final currentShop = dataProvider.shops.firstWhere(
      (s) => s.id == widget.currentShopId,
      orElse: () => Shop(id: '', name: 'Unknown'),
    );

    if (currentShop.id.isEmpty) return;

    final selected = await showConstrainedDialog<ListItem>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('既存商品を選択'),
          children: [
            if (currentShop.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('既存の商品がありません'),
              ),
            ...currentShop.items.map((item) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(context, item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text(
                        '¥${item.price}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );

    if (selected != null) {
      setState(() {
        _matchedItems[index] = selected;
        _itemsToOverwrite.add(index);
      });
    }
  }

  /// 簡易的な文字列正規化（マッチング精度向上用）
  String _normalize(String text) {
    return text.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

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
      await _saveToCurrentShop();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 現在のショップにマージ保存
  Future<void> _saveToCurrentShop() async {
    final dataProvider = context.read<DataProvider>();
    final uuid = const Uuid();

    // 更新前の合計金額（差分計算用）
    final currentShop = dataProvider.shops.firstWhere(
      (s) => s.id == widget.currentShopId,
      orElse: () => Shop(id: '', name: ''),
    );
    // ショップが見つからない場合のエラーハンドリング
    if (currentShop.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存先リストが見つかりません')),
        );
      }
      return;
    }

    int updatedCount = 0;
    int addedCount = 0;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final matched = _matchedItems[i];
      final doOverwrite = _itemsToOverwrite.contains(i);

      if (matched != null && doOverwrite) {
        // 上書き更新
        final updatedItem = matched.copyWith(
          price: item.price,
          quantity: item.quantity,
          timestamp: DateTime.now(),
        );
        await dataProvider.updateItem(updatedItem);
        updatedCount++;
      } else {
        // 新規追加
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
        addedCount++;
      }
    }

    if (mounted) {
      Navigator.of(context).pop(
        SaveResult.success(
          message: '$updatedCount件更新、$addedCount件追加しました',
          targetShopId: widget.currentShopId,
          isUpdateMode: true,
        ),
      );
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _matchedItems.remove(index);
      _itemsToOverwrite.remove(index);

      // インデックスがずれるのでマッチングを再計算
      // 注意: 大規模データだと重くなる可能性があるが、OCR結果（数十件）なら問題ない
      _recalculateMatchingAfterRemoval();
    });
  }

  void _recalculateMatchingAfterRemoval() {
    // 既存のマッチング状態を一旦退避させるか、最初からやり直す
    _runInitialMatching();
  }

  void _updateItem(int index, OcrSessionResultItem updatedItem) {
    setState(() {
      _items[index] = updatedItem;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min, // コンテンツに合わせて高さを縮める
        children: [
          // カスタムヘッダー (AppBarの代わり)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '読み取り結果の確認',
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 商品リスト
          Flexible(
            child: _items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: _buildEmptyState(context),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true, // リストの中身に合わせて高さを決定可能にする
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return _buildItemCard(context, index);
                    },
                  ),
          ),
          // 合計金額
          _buildTotalSummary(context),
          // 保存ボタン
          _buildSaveButton(context),
        ],
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
            '商品がありません',
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
    final matchedItem = _matchedItems[index];
    final isOverwrite = _itemsToOverwrite.contains(index);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: matchedItem != null
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // マッチングエリア（「既存商品→矢印→OCR結果」の順にする）
          if (matchedItem != null) ...[
            Container(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '既存の商品が見つかりました',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _matchedItems.remove(index);
                            _itemsToOverwrite.remove(index);
                          });
                        },
                        child: Text(
                          '解除',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.error,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 既存商品情報
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            matchedItem.name,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '¥${matchedItem.price}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // 矢印（マッチング枠の下）
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(vertical: 4),
              width: double.infinity,
              child: Icon(
                Icons.arrow_downward,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          // OCR結果（編集エリア）
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 商品名
                TextFormField(
                  initialValue: item.name,
                  decoration: const InputDecoration(
                    labelText: '読み取り商品名',
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
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
                // 上書きスイッチ（マッチしている場合のみここに表示）
                if (matchedItem != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        isOverwrite ? '上書き更新' : '別に追加',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isOverwrite
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isOverwrite,
                        onChanged: (val) {
                          setState(() {
                            if (val) {
                              _itemsToOverwrite.add(index);
                            } else {
                              _itemsToOverwrite.remove(index);
                            }
                          });
                        },
                        activeTrackColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 紐付けボタン（マッチしていない場合のみ下に表示）
          if (matchedItem == null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _showSelectExistingItemDialog(index),
                  icon: const Icon(Icons.link, size: 20),
                  label: const Text('既存の商品と紐付ける'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalSummary(BuildContext context) {
    final theme = Theme.of(context);
    final dataProvider = context.read<DataProvider>();

    // 現在のショップの合計（非同期でない簡易計算）
    final currentShop = dataProvider.shops.firstWhere(
      (s) => s.id == widget.currentShopId,
      orElse: () => Shop(id: '', name: '', items: []),
    );

    // 現在の合計金額計算
    int currentTotal = 0;
    for (final item in currentShop.items) {
      if (!item.isChecked) {
        // チェック済みを除くかどうかは要件次第だが、通常合計に含まれる
        currentTotal += item.price * item.quantity;
      }
    }

    // 差分計算
    int diff = 0;
    for (int i = 0; i < _items.length; i++) {
      final newItem = _items[i];
      final matchedItem = _matchedItems[i];
      final isOverwrite = _itemsToOverwrite.contains(i);

      if (matchedItem != null && isOverwrite) {
        // 上書きの場合: 新しい価格 - 古い価格
        diff += (newItem.price * newItem.quantity) -
            (matchedItem.price * matchedItem.quantity);
      } else {
        // 新規追加の場合: 新しい価格そのままプラス
        diff += newItem.price * newItem.quantity;
      }
    }

    final newTotal = currentTotal + diff;
    final sign = diff >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '現在の合計',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '¥$currentTotal',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '更新後の合計',
                style: theme.textTheme.titleMedium,
              ),
              Row(
                children: [
                  Text(
                    '¥$newTotal',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($sign¥$diff)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: diff >= 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
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
              : const Text(
                  '保存する',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
