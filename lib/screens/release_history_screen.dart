import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:maikago/models/release_history.dart';
import 'package:maikago/drawer/settings/settings_theme.dart';

/// 更新履歴画面
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
        _currentAppVersion = '1.1.6'; // フォールバック（pubspec.yamlと一致させる）
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '更新履歴',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  widget.currentTheme == 'dark' ? Colors.white : Colors.black87,
            ),
      ),
      backgroundColor: SettingsTheme.getPrimaryColor(widget.currentTheme),
      foregroundColor: SettingsTheme.getContrastColor(
        SettingsTheme.getPrimaryColor(widget.currentTheme),
      ),
      iconTheme: IconThemeData(
        color: widget.currentTheme == 'dark' ? Colors.white : Colors.black87,
      ),
      elevation: 0,
    );
  }

  Widget _buildBody() {
    final releaseNotes = ReleaseHistory.getAllReleaseNotes();

    return Container(
      color: widget.currentTheme == 'dark'
          ? const Color(0xFF121212)
          : Colors.transparent,
      child: releaseNotes.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              itemCount: releaseNotes.length,
              itemBuilder: (context, index) {
                final note = releaseNotes[index];
                final isLatest = index == 0;
                final isCurrent = note.version == _currentAppVersion;

                return _buildReleaseNoteCard(note, isLatest, isCurrent);
              },
            ),
    );
  }

  /// 履歴が空の場合の表示
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: widget.currentTheme == 'dark'
                  ? Colors.white38
                  : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              '更新履歴はまだありません',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.currentTheme == 'dark'
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '新しいバージョンがリリースされると、\nここに更新内容が表示されます。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: widget.currentTheme == 'dark'
                    ? Colors.white54
                    : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReleaseNoteCard(
      ReleaseNote note, bool isLatest, bool isCurrent) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: _getCardColor(),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(note, isLatest, isCurrent),
            const SizedBox(height: 16),
            _buildChangesList(note.changes),
            if (note.developerComment != null) ...[
              const SizedBox(height: 16),
              _buildDeveloperComment(note.developerComment!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ReleaseNote note, bool isLatest, bool isCurrent) {
    return Row(
      children: [
        // バージョン番号
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SettingsTheme.getPrimaryColor(widget.currentTheme),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'v${note.version}',
            style: TextStyle(
              color: SettingsTheme.getContrastColor(
                SettingsTheme.getPrimaryColor(widget.currentTheme),
              ),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // バッジ
        if (isLatest) _buildBadge('最新', Colors.green),
        if (isCurrent) _buildBadge('現在', Colors.blue),
        const Spacer(),
        // リリース日
        Text(
          _formatDate(note.releaseDate),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: widget.currentTheme == 'dark'
                    ? Colors.white70
                    : Colors.black54,
              ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChangesList(List<ChangeItem> changes) {
    // カテゴリごとにグループ化
    final Map<ChangeCategory, List<ChangeItem>> groupedChanges = {};
    for (final change in changes) {
      groupedChanges.putIfAbsent(change.category, () => []).add(change);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // カテゴリごとに表示
        for (final category in ChangeCategory.values)
          if (groupedChanges.containsKey(category)) ...[
            _buildCategoryHeader(category),
            const SizedBox(height: 8),
            ...groupedChanges[category]!
                .map((change) => _buildChangeItem(change)),
            const SizedBox(height: 16),
          ],
      ],
    );
  }

  Widget _buildCategoryHeader(ChangeCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCategoryColor(category).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(category),
            size: 16,
            color: _getCategoryColor(category),
          ),
          const SizedBox(width: 8),
          Text(
            category.label,
            style: TextStyle(
              color: _getCategoryColor(category),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeItem(ChangeItem change) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getCategoryColor(change.category),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              change.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.currentTheme == 'dark'
                        ? Colors.white
                        : Colors.black87,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(ChangeCategory category) {
    switch (category) {
      case ChangeCategory.newFeature:
        return const Color.fromARGB(255, 0, 225, 255);
      case ChangeCategory.bugFix:
        return Colors.red;
      case ChangeCategory.improvement:
        return Colors.green;
      case ChangeCategory.other:
        return Colors.orange;
    }
  }

  IconData _getCategoryIcon(ChangeCategory category) {
    switch (category) {
      case ChangeCategory.newFeature:
        return Icons.star_rounded;
      case ChangeCategory.bugFix:
        return Icons.bug_report_rounded;
      case ChangeCategory.improvement:
        return Icons.trending_up_rounded;
      case ChangeCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  Widget _buildDeveloperComment(String comment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SettingsTheme.getPrimaryColor(widget.currentTheme)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SettingsTheme.getPrimaryColor(widget.currentTheme)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: SettingsTheme.getPrimaryColor(widget.currentTheme),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              comment,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.currentTheme == 'dark'
                        ? Colors.white
                        : Colors.black87,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCardColor() {
    switch (widget.currentTheme) {
      case 'dark':
        return const Color(0xFF1F1F1F);
      default:
        return Colors.white;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
