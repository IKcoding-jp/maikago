import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:maikago/models/release_history.dart';
import 'package:maikago/services/settings_theme.dart';
import 'package:maikago/utils/theme_utils.dart';
import 'package:go_router/go_router.dart';

/// 更新履歴画面（タイムラインデザイン）
class ReleaseHistoryScreen extends StatefulWidget {
  const ReleaseHistoryScreen({
    super.key,
    required this.currentTheme,
    required this.currentFont,
    required this.currentFontSize,
  });

  final String currentTheme;
  final String currentFont;
  final double currentFontSize;

  @override
  State<ReleaseHistoryScreen> createState() => _ReleaseHistoryScreenState();
}

class _ReleaseHistoryScreenState extends State<ReleaseHistoryScreen> {
  String _currentAppVersion = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentAppVersion = packageInfo.version;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentAppVersion = '';
        _isLoading = false;
      });
    }
  }

  Color get _primaryColor =>
      SettingsTheme.getPrimaryColor(widget.currentTheme);
  Color get _onPrimaryColor =>
      SettingsTheme.getOnPrimaryColor(widget.currentTheme);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '更新履歴',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _onPrimaryColor,
              ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: _onPrimaryColor,
        iconTheme: IconThemeData(color: _onPrimaryColor),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final releaseNotes = ReleaseHistory.getAllReleaseNotes();

    if (releaseNotes.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 32,
      ),
      itemCount: releaseNotes.length,
      itemBuilder: (context, index) {
        final note = releaseNotes[index];
        final isFirst = index == 0;
        final isLast = index == releaseNotes.length - 1;
        final isCurrent = note.version == _currentAppVersion;

        return _TimelineEntry(
          note: note,
          isFirst: isFirst,
          isLast: isLast,
          isCurrent: isCurrent,
          primaryColor: _primaryColor,
          onPrimaryColor: _onPrimaryColor,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
            ),
            const SizedBox(height: 16),
            Text(
              '更新履歴はまだありません',
              style: TextStyle(
                fontSize: theme.textTheme.headlineMedium?.fontSize,
                fontWeight: FontWeight.bold,
                color: theme.subtextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '新しいバージョンがリリースされると、\nここに更新内容が表示されます。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: theme.textTheme.bodyMedium?.fontSize,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// タイムラインの1エントリ（左にラインとドット、右にカード）
class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.note,
    required this.isFirst,
    required this.isLast,
    required this.isCurrent,
    required this.primaryColor,
    required this.onPrimaryColor,
  });

  final ReleaseNote note;
  final bool isFirst;
  final bool isLast;
  final bool isCurrent;
  final Color primaryColor;
  final Color onPrimaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = theme.dividerColor;
    final dotColor = isFirst ? primaryColor : lineColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイムライン（ドット＋ライン）
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // 上のライン
                Container(
                  width: 2,
                  height: 8,
                  color: isFirst ? Colors.transparent : lineColor,
                ),
                // ドット
                Container(
                  width: isFirst ? 14 : 10,
                  height: isFirst ? 14 : 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst ? dotColor : Colors.transparent,
                    border: Border.all(
                      color: dotColor,
                      width: isFirst ? 0 : 2,
                    ),
                  ),
                ),
                // 下のライン
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // カード本体
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildCard(context, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isFirst
            ? Border.all(
                color: primaryColor.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          _buildHeader(context, theme),
          // 変更内容
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildChanges(context, theme),
          ),
          // 開発者コメント
          if (note.developerComment != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildComment(context, theme, note.developerComment!),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: isFirst
            ? primaryColor.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // バージョン番号
          Text(
            'v${note.version}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          // バッジ
          if (isCurrent)
            _buildPill(context, '現在のバージョン', primaryColor),
          if (isFirst && !isCurrent)
            _buildPill(
                context, '最新', theme.colorScheme.primary),
          const Spacer(),
          // 日付
          Text(
            _formatDate(note.releaseDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }

  Widget _buildChanges(BuildContext context, ThemeData theme) {
    // カテゴリごとにグループ化
    final grouped = <ChangeCategory, List<ChangeItem>>{};
    for (final change in note.changes) {
      grouped.putIfAbsent(change.category, () => []).add(change);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in ChangeCategory.values)
          if (grouped.containsKey(category)) ...[
            const SizedBox(height: 10),
            _CategorySection(
              category: category,
              items: grouped[category]!,
            ),
          ],
      ],
    );
  }

  Widget _buildComment(
      BuildContext context, ThemeData theme, String comment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              color: primaryColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              comment,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

/// カテゴリセクション（アイコン＋ラベル＋変更リスト）
class _CategorySection extends StatelessWidget {
  const _CategorySection({
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
