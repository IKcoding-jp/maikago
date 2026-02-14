import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/models/sort_mode.dart';

/// サンプルアイテムを生成
ListItem createSampleItem({
  String? id,
  String? name,
  int? quantity,
  int? price,
  double? discount,
  bool? isChecked,
  String? shopId,
  DateTime? createdAt,
  bool? isReferencePrice,
  String? janCode,
  int? sortOrder,
  bool? isRecipeOrigin,
  String? recipeName,
}) {
  return ListItem(
    id: id ?? '1',
    name: name ?? 'サンプル商品',
    quantity: quantity ?? 1,
    price: price ?? 100,
    discount: discount ?? 0.0,
    isChecked: isChecked ?? false,
    shopId: shopId ?? '0',
    createdAt: createdAt ?? DateTime(2026, 1, 1, 12, 0, 0),
    isReferencePrice: isReferencePrice ?? false,
    janCode: janCode,
    sortOrder: sortOrder ?? 0,
    isRecipeOrigin: isRecipeOrigin ?? false,
    recipeName: recipeName,
  );
}

/// サンプルショップを生成
Shop createSampleShop({
  String? id,
  String? name,
  List<ListItem>? items,
  int? budget,
  DateTime? createdAt,
  SortMode? incSortMode,
  SortMode? comSortMode,
  List<String>? sharedTabs,
  String? sharedGroupId,
}) {
  return Shop(
    id: id ?? '0',
    name: name ?? 'デフォルト',
    items: items ?? [],
    budget: budget,
    createdAt: createdAt ?? DateTime(2026, 1, 1, 12, 0, 0),
    incSortMode: incSortMode,
    comSortMode: comSortMode,
    sharedTabs: sharedTabs,
    sharedGroupId: sharedGroupId,
  );
}

/// 複数のサンプルアイテムを生成
List<ListItem> createSampleItems(int count, {String? shopId}) {
  return List.generate(
    count,
    (index) => createSampleItem(
      id: 'item_$index',
      name: 'サンプル商品$index',
      price: (index + 1) * 100,
      quantity: index + 1,
      shopId: shopId ?? '0',
      createdAt: DateTime(2026, 1, 1, 12, 0, index),
      sortOrder: index,
    ),
  );
}
