import 'package:flutter/material.dart';
import 'package:maikago/models/release_history.dart';

/// カテゴリセクション（アイコン＋ラベル＋変更リスト）
class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.category,
    required this.items,
  });

  final ChangeCategory category;
  final List<ChangeItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _getCategoryColor(isDark);
    final bgColor = _getCategoryBgColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // カテゴリラベル（背景付きピル型）
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getCategoryIcon(), size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                category.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // 変更アイテム
        ...items.map((item) => _buildItem(context, theme, item, color)),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    ThemeData theme,
    ChangeItem item,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7, right: 10),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              item.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// テーマに依存しないセマンティックカラー（ライト/ダーク対応）
  Color _getCategoryColor(bool isDark) {
    switch (category) {
      case ChangeCategory.newFeature:
        // 鮮やかなティール/エメラルド
        return isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
      case ChangeCategory.bugFix:
        // 明瞭なアンバー/オレンジ
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case ChangeCategory.improvement:
        // はっきりしたブルー
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      case ChangeCategory.other:
        // ニュートラルグレー
        return isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    }
  }

  /// カテゴリラベルの背景色
  Color _getCategoryBgColor(bool isDark) {
    switch (category) {
      case ChangeCategory.newFeature:
        return isDark
            ? const Color(0xFF0D9488).withValues(alpha: 0.15)
            : const Color(0xFF0D9488).withValues(alpha: 0.08);
      case ChangeCategory.bugFix:
        return isDark
            ? const Color(0xFFD97706).withValues(alpha: 0.15)
            : const Color(0xFFD97706).withValues(alpha: 0.08);
      case ChangeCategory.improvement:
        return isDark
            ? const Color(0xFF2563EB).withValues(alpha: 0.15)
            : const Color(0xFF2563EB).withValues(alpha: 0.08);
      case ChangeCategory.other:
        return isDark
            ? const Color(0xFF6B7280).withValues(alpha: 0.15)
            : const Color(0xFF6B7280).withValues(alpha: 0.08);
    }
  }

  IconData _getCategoryIcon() {
    switch (category) {
      case ChangeCategory.newFeature:
        return Icons.auto_awesome_rounded;
      case ChangeCategory.bugFix:
        return Icons.build_rounded;
      case ChangeCategory.improvement:
        return Icons.trending_up_rounded;
      case ChangeCategory.other:
        return Icons.more_horiz_rounded;
    }
  }
}
