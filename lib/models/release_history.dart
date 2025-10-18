/// 変更内容のカテゴリ
enum ChangeCategory {
  newFeature('新機能'),
  bugFix('バグ修正'),
  improvement('改善点'),
  other('その他');

  const ChangeCategory(this.label);
  final String label;
}

/// 変更内容のデータモデル
class ChangeItem {
  final String description;
  final ChangeCategory category;

  const ChangeItem({
    required this.description,
    required this.category,
  });
}

/// リリースノートのデータモデル
class ReleaseNote {
  final String version;
  final DateTime releaseDate;
  final List<ChangeItem> changes;
  final String? developerComment;

  const ReleaseNote({
    required this.version,
    required this.releaseDate,
    required this.changes,
    this.developerComment,
  });
}

/// 更新履歴データを管理するクラス
class ReleaseHistory {
  /// 更新履歴の静的データ
  static final List<ReleaseNote> _releaseNotes = [
    ReleaseNote(
      version: '1.2.0',
      releaseDate: DateTime(2025, 10, 19),
      changes: [
        ChangeItem(
          description: 'リスト長押しで自由に並べ替えできる機能を追加。',
          category: ChangeCategory.newFeature,
        ),
        ChangeItem(
          description: '起動時のスプラッシュ画面でのアイコンがテーマに沿った色になるように変更。',
          category: ChangeCategory.improvement,
        ),
        ChangeItem(
          description: 'まいカゴプレミアム加入画面がテーマに沿った色になるように変更。',
          category: ChangeCategory.improvement,
        ),
        ChangeItem(
          description: '詳細設定がアプリを再起動しても、保持されるように修正。',
          category: ChangeCategory.bugFix,
        ),
        ChangeItem(
          description: 'アイテムを編集するさい、０を削除しなくても、数字が入力できるように修正。',
          category: ChangeCategory.improvement,
        ),
        ChangeItem(
          description: 'アイテム追加と編集のダイアログUIを統一。',
          category: ChangeCategory.improvement,
        ),
        ChangeItem(
          description: '使い方ページをより最適でわかりやすい説明に変更。',
          category: ChangeCategory.improvement,
        ),
        ChangeItem(
          description: 'リスト追加・編集のダイアログの入力欄の背景を白に変更。',
          category: ChangeCategory.improvement,
        ),
        ChangeItem(
          description: 'タブを共有する際、アイコンを設定し、共有タブを区別しやすい機能を追加。',
          category: ChangeCategory.newFeature,
        ),
      ],
    ),
  ];

  /// 全てのリリースノートを取得（新しい順）
  static List<ReleaseNote> getAllReleaseNotes() {
    return List.from(_releaseNotes.reversed);
  }

  /// 最新のリリースノートを取得
  static ReleaseNote? getLatestReleaseNote() {
    if (_releaseNotes.isEmpty) return null;
    return _releaseNotes.first;
  }

  /// 指定されたバージョンのリリースノートを取得
  static ReleaseNote? getReleaseNoteByVersion(String version) {
    try {
      return _releaseNotes.firstWhere((note) => note.version == version);
    } catch (e) {
      return null;
    }
  }

  /// 現在のアプリバージョンと最新リリースノートのバージョンを比較
  static bool isCurrentVersionLatest(String currentVersion) {
    final latest = getLatestReleaseNote();
    if (latest == null) return true;
    return latest.version == currentVersion;
  }

  /// バージョン比較（semantic versioning）
  static int compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    // 短い方のバージョンを0で埋める
    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }

    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }

    return 0;
  }
}
