import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/models/list.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/services/feature_access_control.dart';
import 'package:maikago/widgets/premium_upgrade_dialog.dart';
import 'package:maikago/utils/snackbar_utils.dart';
import 'package:maikago/screens/main/dialogs/budget_dialog.dart';
import 'package:maikago/screens/main/dialogs/sort_dialog.dart';
import 'package:maikago/screens/main/dialogs/item_edit_dialog.dart';
import 'package:maikago/screens/main/dialogs/tab_edit_dialog.dart';
import 'package:maikago/screens/main/dialogs/tab_add_dialog.dart';
import 'package:maikago/screens/main/dialogs/bulk_delete_dialog.dart';

/// メイン画面のダイアログ表示ロジック
class DialogHandlers {
  /// タブ追加ダイアログ（ショップ数制限チェック含む）
  static void showAddTabDialog(
    BuildContext context, {
    required String nextShopId,
    required ValueChanged<String> onNextShopIdChanged,
  }) {
    final featureControl = context.read<FeatureAccessControl>();
    final dataProvider = context.read<DataProvider>();
    final currentShopCount = dataProvider.shops.length;
    if (!featureControl.canCreateShop(currentShopCount: currentShopCount)) {
      PremiumUpgradeDialog.show(
        context,
        title: 'ショップ数の上限',
        message:
            '無料版ではショップは${FeatureAccessControl.maxFreeShops}つまでです。\nプレミアムにアップグレードすると無制限に作成できます。',
        onUpgrade: () => context.push('/subscription'),
      );
      return;
    }

    TabAddDialog.show(
      context,
      nextShopId: nextShopId,
      onAdded: (newNextShopId) {
        onNextShopIdChanged(newNextShopId);
        return Future<void>.value();
      },
    );
  }

  /// 予算設定ダイアログ
  static void showBudgetDialog(BuildContext context, Shop shop) {
    BudgetDialog.show(context, shop);
  }

  /// タブ編集ダイアログ
  static void showTabEditDialog(
    BuildContext context, {
    required int tabIndex,
    required List<Shop> shops,
  }) {
    TabEditDialog.show(
      context,
      tabIndex: tabIndex,
      shops: shops,
      customTheme: Theme.of(context),
    );
  }

  /// アイテム編集ダイアログ
  static void showItemEditDialog(
    BuildContext context, {
    ListItem? original,
    required Shop shop,
  }) {
    ItemEditDialog.show(
      context,
      original: original,
      shop: shop,
      onItemSaved: null,
    );
  }

  /// ソートダイアログ
  static void showSortDialog(
    BuildContext context, {
    required bool isIncomplete,
    required Shop shop,
    required VoidCallback onSortChanged,
  }) {
    final dataProvider = context.read<DataProvider>();
    if (dataProvider.shops.isEmpty) return;

    SortDialog.show(
      context,
      shop: shop,
      isIncomplete: isIncomplete,
      onSortChanged: onSortChanged,
    );
  }

  /// 一括削除ダイアログ
  static void showBulkDeleteDialog(
    BuildContext context, {
    required Shop shop,
    required bool isIncomplete,
  }) {
    final itemsToDelete = isIncomplete
        ? shop.items.where((item) => !item.isChecked).toList()
        : shop.items.where((item) => item.isChecked).toList();

    if (itemsToDelete.isEmpty) {
      showInfoSnackBar(context, '削除するアイテムがありません',
          duration: const Duration(seconds: 2));
      return;
    }

    BulkDeleteDialog.show(
      context,
      shop: shop,
      isIncomplete: isIncomplete,
      onDeleted: null,
    );
  }
}
