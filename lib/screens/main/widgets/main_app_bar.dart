import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:maikago/models/shop.dart';
import 'package:maikago/providers/data_provider.dart';
import 'package:maikago/services/one_time_purchase_service.dart';
import 'package:maikago/screens/main/utils/ui_calculations.dart';

/// メイン画面のAppBar（タブ表示＋追加ボタン）
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
    required this.sortedShops,
    required this.selectedIndex,
    required this.currentTheme,
    required this.customColors,
    required this.theme,
    required this.scaffoldBgLuminance,
    required this.onTabTap,
    required this.onTabLongPress,
    required this.onAddTab,
  });

  final List<Shop> sortedShops;
  final int selectedIndex;
  final String currentTheme;
  final Map<String, Color> customColors;
  final ThemeData theme;
  final double scaffoldBgLuminance;
  final void Function(int index) onTabTap;
  final void Function(int originalIndex) onTabLongPress;
  final VoidCallback onAddTab;

  double get _fontSize => theme.textTheme.bodyMedium?.fontSize ?? 16.0;

  @override
  Size get preferredSize =>
      Size.fromHeight(MainScreenCalculations.calculateTabHeight(_fontSize) + 16);

  @override
  Widget build(BuildContext context) {
    final tabHeight = MainScreenCalculations.calculateTabHeight(_fontSize);
    final tabPadding = MainScreenCalculations.calculateTabPadding(_fontSize);
    final maxLines = MainScreenCalculations.calculateMaxLines(_fontSize);

    return AppBar(
      toolbarHeight: tabHeight + 16,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness:
            scaffoldBgLuminance > 0.5 ? Brightness.dark : Brightness.light,
        statusBarBrightness:
            scaffoldBgLuminance > 0.5 ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
            theme.brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
      ),
      title: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: tabHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sortedShops.length,
            itemBuilder: (context, index) =>
                _buildTabItem(context, index, tabPadding, maxLines),
          ),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      foregroundColor:
          scaffoldBgLuminance > 0.5 ? Colors.black87 : Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        Consumer2<DataProvider, OneTimePurchaseService>(
          builder: (context, dataProvider, purchaseService, _) {
            return IconButton(
              icon: Icon(
                Icons.add,
                color: scaffoldBgLuminance > 0.5
                    ? Colors.black87
                    : Colors.white,
              ),
              onPressed: onAddTab,
              tooltip: 'タブ追加',
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    int index,
    double tabPadding,
    int maxLines,
  ) {
    final shop = sortedShops[index];
    final isSelected = index == selectedIndex;
    final dataProvider = context.read<DataProvider>();

    // 前後のショップと同じグループか判定
    final prevShop = index > 0 ? sortedShops[index - 1] : null;
    final nextShop =
        index < sortedShops.length - 1 ? sortedShops[index + 1] : null;

    final isSameGroupAsPrev = shop.sharedGroupId != null &&
        prevShop?.sharedGroupId == shop.sharedGroupId;
    final isSameGroupAsNext = shop.sharedGroupId != null &&
        nextShop?.sharedGroupId == shop.sharedGroupId;

    // ボーダーラディウスの決定
    BorderRadius borderRadius;
    if (isSameGroupAsPrev && isSameGroupAsNext) {
      borderRadius = BorderRadius.zero;
    } else if (isSameGroupAsPrev) {
      borderRadius =
          const BorderRadius.horizontal(right: Radius.circular(20));
    } else if (isSameGroupAsNext) {
      borderRadius =
          const BorderRadius.horizontal(left: Radius.circular(20));
    } else {
      borderRadius = BorderRadius.circular(20);
    }

    final margin = isSameGroupAsNext
        ? const EdgeInsets.only(right: 1)
        : const EdgeInsets.only(right: 8);

    return GestureDetector(
      onLongPress: () {
        final originalIndex =
            dataProvider.shops.indexWhere((s) => s.id == shop.id);
        if (originalIndex != -1) {
          onTabLongPress(originalIndex);
        }
      },
      onTap: () => onTabTap(index),
      child: Container(
        margin: margin,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: tabPadding,
        ),
        decoration: BoxDecoration(
          color: _getTabColor(isSelected, shop),
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (currentTheme == 'dark'
                    ? Colors.white.withAlpha((255 * 0.3).round())
                    : Colors.grey.withAlpha((255 * 0.3).round())),
            width: shop.sharedGroupId != null ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _getTabColor(true, shop)
                        .withAlpha((255 * 0.3).round()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                shop.name,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (currentTheme == 'dark'
                          ? Colors.white70
                          : Colors.black54),
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: _fontSize,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: maxLines,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTabColor(bool isSelected, Shop shop) {
    if (isSelected) {
      if (currentTheme == 'custom' && customColors.containsKey('tabColor')) {
        return customColors['tabColor']!;
      }
      if (currentTheme == 'light') return const Color(0xFF9E9E9E);
      if (currentTheme == 'dark') return Colors.grey[600]!;
      return theme.colorScheme.primary;
    }

    if (shop.sharedGroupId != null) {
      return currentTheme == 'dark'
          ? theme.colorScheme.primary.withValues(alpha: 0.2)
          : theme.colorScheme.primary.withValues(alpha: 0.1);
    }

    return currentTheme == 'dark' ? Colors.black : Colors.white;
  }
}
