import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maikago/models/list.dart';
import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/services/recipe_parser_service.dart';
import 'package:uuid/uuid.dart';

enum AddMode { append, integrate }

enum VolumeHandling { addUp, addSeparate }

class RecipeConfirmScreen extends StatefulWidget {
  final List<RecipeIngredient> initialIngredients;
  final String recipeTitle;
  final String sourceText;

  const RecipeConfirmScreen({
    super.key,
    required this.initialIngredients,
    required this.recipeTitle,
    required this.sourceText,
  });

  @override
  State<RecipeConfirmScreen> createState() => _RecipeConfirmScreenState();
}

class _RecipeConfirmScreenState extends State<RecipeConfirmScreen> {
  late List<RecipeIngredient> _ingredients;
  late TextEditingController _titleController;
  AddMode _addMode = AddMode.append;
  String? _selectedShopId;

  // 統合設定: 材料ごとの統合ON/OFFと分量処理
  final Map<int, bool> _integrationToggles = {};
  final Map<int, VolumeHandling> _volumeHandlings = {};
  final Map<int, ListItem?> _matchedItems = {};

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.initialIngredients);
    _titleController = TextEditingController(text: widget.recipeTitle);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    if (dataProvider.shops.isNotEmpty) {
      _selectedShopId = dataProvider.shops.first.id;
    }

    // 初期設定
    for (int i = 0; i < _ingredients.length; i++) {
      _integrationToggles[i] = true;
      _volumeHandlings[i] = VolumeHandling.addUp;
      _findMatch(i);
    }
  }

  void _findMatch(int index) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final ingredient = _ingredients[index];

    // 単純な名前一致で既存アイテムを探す
    final matched = dataProvider.items.firstWhere(
      (item) =>
          item.name == ingredient.name ||
          item.name == ingredient.normalizedName,
      orElse: () =>
          ListItem(id: '', name: '', quantity: 0, price: 0, shopId: ''),
    );

    if (matched.id.isNotEmpty) {
      _matchedItems[index] = matched;
    } else {
      _matchedItems[index] = null;
    }
  }

  void _editIngredient(int index) async {
    final ingredient = _ingredients[index];
    final nameController = TextEditingController(text: ingredient.name);
    final qtyController =
        TextEditingController(text: ingredient.quantity ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('材料の編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '材料名'),
            ),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: '分量'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text,
              'quantity': qtyController.text,
            }),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _ingredients[index].name = result['name']!;
        _ingredients[index].quantity =
            result['quantity']!.isEmpty ? null : result['quantity'];
        _findMatch(index);
      });
    }
  }

  void _deleteIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      // インデックスがずれるのでマップを再構築する必要があるが、
      // 簡単のため、このデモではインデックス管理を工夫するか、リスト全体を再構築する
      final newToggles = <int, bool>{};
      final newVolume = <int, VolumeHandling>{};

      for (int i = 0; i < _ingredients.length; i++) {
        // 削除された分を飛ばして再割り当て（不完全だが、とりあえずの実装）
        // 本来はIDベースで管理すべき
        newToggles[i] = true;
        newVolume[i] = VolumeHandling.addUp;
      }
      _integrationToggles.clear();
      _integrationToggles.addAll(newToggles);
      _volumeHandlings.clear();
      _volumeHandlings.addAll(newVolume);

      // 再検索
      for (int i = 0; i < _ingredients.length; i++) {
        _findMatch(i);
      }
    });
  }

  Future<void> _onAdd() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final shopId = _selectedShopId ?? '0';

    for (int i = 0; i < _ingredients.length; i++) {
      final ingredient = _ingredients[i];
      if (ingredient.isExcluded) continue;

      bool shouldIntegrate = _addMode == AddMode.integrate &&
          _integrationToggles[i] == true &&
          _matchedItems[i] != null;

      if (shouldIntegrate && _volumeHandlings[i] == VolumeHandling.addUp) {
        // 合算
        final existing = _matchedItems[i]!;
        // 数量は単純に +1 する（レシピ由来の分量は名称に含まれるため）
        await dataProvider.updateItem(existing.copyWith(
          quantity: existing.quantity + 1,
          isRecipeOrigin: true,
          recipeName: _titleController.text.trim(),
        ));
      } else {
        // 新規追加（追記、または統合OFF、または別追加）
        final displayName = ingredient.quantity != null
            ? '${ingredient.name} (${ingredient.quantity})'
            : ingredient.name;

        final newItem = ListItem(
          id: const Uuid().v4(),
          name: displayName,
          quantity: 1, // 個数は一律1に固定
          price: 0,
          shopId: shopId,
          isRecipeOrigin: true,
          recipeName: _titleController.text.trim(),
          createdAt: DateTime.now(),
        );
        await dataProvider.addItem(newItem);
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('買い物リストに追加しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('材料の確認'),
      ),
      body: Column(
        children: [
          _buildHeader(dataProvider),
          const Divider(),
          Expanded(
            child: ListView.separated(
              itemCount: _ingredients.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _buildIngredientTile(index),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(DataProvider dataProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              const Text('レシピ名: '),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'レシピの名称（例: 肉じゃが）',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('追加先: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedShopId,
                  isExpanded: true,
                  items: dataProvider.shops.map((shop) {
                    return DropdownMenuItem(
                      value: shop.id,
                      child: Text(shop.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedShopId = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('方式 : '),
              ChoiceChip(
                label: const Text('追記'),
                selected: _addMode == AddMode.append,
                onSelected: (val) => setState(() => _addMode = AddMode.append),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('統合'),
                selected: _addMode == AddMode.integrate,
                onSelected: (val) =>
                    setState(() => _addMode = AddMode.integrate),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '※レシピ由来タグは追加後に表示されます',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientTile(int index) {
    final ingredient = _ingredients[index];
    final matched = _matchedItems[index];
    final isIntegrateMode = _addMode == AddMode.integrate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (ingredient.quantity != null)
                      Text(ingredient.quantity!,
                          style: const TextStyle(color: Colors.grey))
                    else
                      const Text('分量が曖昧なため省略しました',
                          style: TextStyle(fontSize: 12, color: Colors.orange)),
                  ],
                ),
              ),
              TextButton(
                  onPressed: () => _editIngredient(index),
                  child: const Text('編集')),
              IconButton(
                  onPressed: () => _deleteIngredient(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red)),
            ],
          ),
          if (isIntegrateMode) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('統合: ', style: TextStyle(fontSize: 13)),
                Switch(
                  value: _integrationToggles[index] ?? false,
                  onChanged: matched == null
                      ? null
                      : (val) =>
                          setState(() => _integrationToggles[index] = val),
                ),
                if (matched != null &&
                    (_integrationToggles[index] ?? false)) ...[
                  const SizedBox(width: 8),
                  const Text('分量: ', style: TextStyle(fontSize: 13)),
                  DropdownButton<VolumeHandling>(
                    value: _volumeHandlings[index],
                    items: const [
                      DropdownMenuItem(
                          value: VolumeHandling.addUp, child: Text('合算')),
                      DropdownMenuItem(
                          value: VolumeHandling.addSeparate,
                          child: Text('別追加')),
                    ],
                    onChanged: (val) =>
                        setState(() => _volumeHandlings[index] = val!),
                  ),
                ],
              ],
            ),
            if (matched != null && (_integrationToggles[index] ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '一致候補: 「${matched.name} ${matched.quantity}個（既存）」',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              )
            else if (isIntegrateMode && matched == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: const Text('一致するアイテムが見つかりません',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('戻る'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onAdd,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('追加する',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
