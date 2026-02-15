import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/models/sort_mode.dart';
import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/screens/main/utils/ui_calculations.dart';
import 'package:maikago/services/debug_service.dart';
import 'package:maikago/utils/snackbar_utils.dart';

/// メイン画面のアイテム操作（並べ替え・チェック切り替え）
class ItemOperations {
  ItemOperations._();

  /// チェック切り替え処理（未購入⇔購入済み）
  static Future<void> handleCheckToggle(
    BuildContext context, {
    required ListItem item,
    required bool checked,
    required String? selectedTabId,
    required int selectedTabIndex,
  }) async {
    final dataProvider = context.read<DataProvider>();
    if (dataProvider.shops.isEmpty) return;

    // 現在のショップを取得
    final shop = selectedTabId != null
        ? dataProvider.shops.firstWhere(
            (s) => s.id == selectedTabId,
            orElse: () => dataProvider.shops[
                selectedTabIndex.clamp(0, dataProvider.shops.length - 1)],
          )
        : dataProvider.shops[
            selectedTabIndex.clamp(0, dataProvider.shops.length - 1)];

    // 共有グループの合計を事前更新
    if (shop.sharedGroupId != null) {
      dataProvider.notifyDataChanged();
    }

    try {
      // チェック状態に応じて適切なsortOrderを設定
      final comItems = shop.items.where((e) => e.isChecked).toList();
      final incItems = shop.items.where((e) => !e.isChecked).toList();
      final newSortOrder = checked
          ? 10000 + comItems.length // 購入済みリストの末尾
          : incItems.length; // 未購入リストの末尾

      await dataProvider.updateItem(
        item.copyWith(isChecked: checked, sortOrder: newSortOrder),
      );

      // 共有グループの合計を更新
      if (shop.sharedGroupId != null) {
        dataProvider.notifyDataChanged();
      }
    } catch (e) {
      final shopIndex = dataProvider.shops.indexWhere((s) => s.id == shop.id);
      if (shopIndex != -1) {
        final currentShop = dataProvider.shops[shopIndex];
        final revertedItems = currentShop.items.map((shopItem) {
          return shopItem.id == item.id
              ? item.copyWith(isChecked: !checked)
              : shopItem;
        }).toList();
        dataProvider.shops[shopIndex] =
            currentShop.copyWith(items: revertedItems);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// アイテム削除処理
  static Future<void> deleteItem(
    BuildContext context, {
    required ListItem item,
    Future<void> Function()? onSuccess,
  }) async {
    try {
      await context.read<DataProvider>().deleteItem(item.id);
      if (onSuccess != null) await onSuccess();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// アイテム更新処理
  static Future<void> updateItem(
    BuildContext context, {
    required ListItem updatedItem,
  }) async {
    try {
      await context.read<DataProvider>().updateItem(updatedItem);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// リストの並べ替え処理（未購入/購入済み共通）
  ///
  /// 返り値: 状態更新が必要な場合に新しい(tabIndex, tabId)を返す。
  /// nullの場合は並べ替えが実行されなかったことを示す。
  static Future<({int tabIndex, String? tabId})?> reorderItems(
    BuildContext context, {
    required String? selectedTabId,
    required int selectedTabIndex,
    required int oldIndex,
    required int newIndex,
    required bool isIncomplete,
  }) async {
    if (oldIndex == newIndex) return null;

    final label = isIncomplete ? '未購入' : '購入済み';
    final dataProvider = context.read<DataProvider>();
    final shops = dataProvider.shops;
    if (shops.isEmpty) {
      DebugService().log('❌ $label並べ替え中断: shopsが空のため処理を停止します');
      return null;
    }

    int tabIndex = selectedTabIndex;
    String? tabId = selectedTabId;
    Shop? shop;
    if (tabId != null) {
      final matchedIndex = shops.indexWhere((s) => s.id == tabId);
      if (matchedIndex != -1) {
        shop = shops[matchedIndex];
        tabIndex = matchedIndex;
      } else {
        shop = shops[tabIndex.clamp(0, shops.length - 1)];
        tabId = shop.id;
      }
    } else {
      var safeIndex = tabIndex;
      if (safeIndex < 0 || safeIndex >= shops.length) {
        DebugService().log(
            '⚠️ $label並べ替え: selectedTabIndex=$safeIndex が範囲外。shops.length=${shops.length}');
        safeIndex = safeIndex.clamp(0, shops.length - 1);
        tabIndex = safeIndex;
      }
      shop = shops[tabIndex];
      tabId = shop.id;
    }

    // UIの表示順序と一致させるため、手動並べ替えモード時はsortOrder順にソート
    final targetItems = isIncomplete
        ? shop.items.where((e) => !e.isChecked).toList()
        : shop.items.where((e) => e.isChecked).toList();
    final sortMode = isIncomplete ? shop.incSortMode : shop.comSortMode;
    if (sortMode == SortMode.manual) {
      targetItems.sort(MainScreenCalculations.comparatorFor(SortMode.manual));
    }

    DebugService().log(
        '🔄 $label並べ替え開始: oldIndex=$oldIndex, newIndex=$newIndex, リスト長=${targetItems.length}');

    // 範囲チェック（調整前）
    if (oldIndex < 0 || oldIndex >= targetItems.length ||
        newIndex < 0 || newIndex > targetItems.length) {
      DebugService().log(
          '❌ インデックスが範囲外: oldIndex=$oldIndex, newIndex=$newIndex, リスト長=${targetItems.length}');
      return null;
    }

    // newIndexを調整（ReorderableListViewの仕様）
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // 調整後の範囲チェック
    if (newIndex < 0 || newIndex >= targetItems.length) {
      DebugService().log(
          '❌ 調整後のnewIndexが範囲外: newIndex=$newIndex, リスト長=${targetItems.length}');
      return null;
    }

    DebugService().log('✅ 調整後: oldIndex=$oldIndex, newIndex=$newIndex');

    // 並び替え処理
    final reordered = List<ListItem>.from(targetItems);
    final item = reordered[oldIndex];
    reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // sortOrderを更新
    final sortOrderOffset = isIncomplete ? 0 : 10000;
    final updatedItems = <ListItem>[];
    for (int i = 0; i < reordered.length; i++) {
      updatedItems.add(reordered[i].copyWith(sortOrder: sortOrderOffset + i));
    }

    // 反対側のリストは既存の状態を保持
    final otherItems = isIncomplete
        ? shop.items.where((e) => e.isChecked).toList()
        : shop.items.where((e) => !e.isChecked).toList();

    // ショップを更新
    final updatedShop = shop.copyWith(
      items: isIncomplete
          ? [...updatedItems, ...otherItems]
          : [...otherItems, ...updatedItems],
      incSortMode: isIncomplete ? SortMode.manual : shop.incSortMode,
      comSortMode: isIncomplete ? shop.comSortMode : SortMode.manual,
    );

    try {
      await dataProvider.reorderItems(updatedShop, updatedItems);
    } catch (e) {
      DebugService().log('❌ $labelリスト並べ替えエラー: $e');
      if (context.mounted) {
        showErrorSnackBar(context, '並べ替えの保存に失敗しました: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }

    return (tabIndex: tabIndex, tabId: tabId);
  }
}
