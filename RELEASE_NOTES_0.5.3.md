# リリースノート v0.5.3

## 🆕 新機能・改善

### Android 15対応
- **エッジツーエッジ表示対応**: Android 15以降でSDK 35をターゲットとするアプリのデフォルトエッジツーエッジ表示に対応
- **システムインセット処理**: ステータスバーとナビゲーションバーの透明化と適切なインセット処理を実装
- **テーマ設定更新**: ライトテーマとダークテーマの両方でエッジツーエッジ表示を有効化

### 技術的改善
- **AndroidManifest.xml更新**: `enableOnBackInvokedCallback="true"`を追加してAndroid 15の新しいバックナビゲーションに対応
- **styles.xml更新**: エッジツーエッジ表示用のテーマ設定を追加
  - `windowLayoutInDisplayCutoutMode`: shortEdges
  - `windowTranslucentStatus`: true
  - `windowTranslucentNavigation`: true
  - `statusBarColor`: transparent
  - `navigationBarColor`: transparent
- **Flutter UI更新**: MaterialAppレベルでSafeAreaを設定し、AppBarの透明化を実装

## 🔧 修正

### Android 15関連
- Android 15以降でのアプリ表示問題を解決
- システムインセット（ステータスバー、ナビゲーションバー）の適切な処理を実装
- エッジツーエッジ表示時のUI要素の重複を防止

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
