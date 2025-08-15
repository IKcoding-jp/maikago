# リリースノート v0.5.4

## 🔧 修正

### Android 15非推奨API対応
- **非推奨APIの削除**: Android 15で非推奨になったエッジツーエッジ表示関連のAPIを削除
  - `windowTranslucentStatus` - 削除
  - `windowTranslucentNavigation` - 削除
  - `statusBarColor` - 削除
  - `navigationBarColor` - 削除
- **新しいAPIへの移行**: Android 15で推奨される新しいAPIに更新
  - `windowLightStatusBar` - 追加（ライトテーマ: true, ダークテーマ: false）
  - `windowLightNavigationBar` - 追加（ライトテーマ: true, ダークテーマ: false）
  - `systemNavigationBarIconBrightness` - 追加

### 技術的改善
- **styles.xml更新**: ライトテーマとダークテーマの両方で非推奨APIを削除
- **Flutter UI更新**: SystemUiOverlayStyleから非推奨の`statusBarColor`を削除
- **エッジツーエッジ表示の最適化**: Android 15の新しいガイドラインに準拠

## 🚨 重要

### Google Play Console対応
- Android 15で非推奨になったAPIの使用を停止
- エッジツーエッジ表示の警告を解決
- アプリの審査通過を確保

## 📱 対応プラットフォーム

- **Android**: API 23 (Android 6.0) - API 35 (Android 15)
- **iOS**: 既存の対応範囲を維持
- **Web**: 既存の対応範囲を維持

## 🚀 インストール・更新

このバージョンは以下の方法でインストール・更新できます：

1. **Google Play Store**: 自動更新または手動更新
2. **APK直接インストール**: リリースページからAPKをダウンロード

## 📋 既知の問題

現在、既知の問題はありません。

## 🔮 今後の予定

- さらなるUI/UX改善
- パフォーマンス最適化
- 新機能の追加

---

**開発チーム**: ikcoding  
**リリース日**: 2024年12月
