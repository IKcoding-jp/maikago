# 要件定義

**Issue**: #6
**作成日**: 2026-02-14
**ラベル**: refactor, major

## ユーザーストーリー
開発者「テーマ設定がグローバル変数で管理されていて、テストが書きにくい。Providerパターンに統一したい」

## 要件一覧
### 必須要件
- [ ] `currentGlobalFont`, `currentGlobalFontSize`, `currentGlobalTheme`をProviderに移行
- [ ] `themeNotifier`, `fontNotifier`のValueNotifierをProvider内部で管理
- [ ] `late final`の例外キャッチ初期化パターンを廃止
- [ ] `updateGlobalTheme()`, `updateGlobalFont()`, `updateGlobalFontSize()`をProviderメソッド化
- [ ] 既存のSettingsPersistenceとの連携を維持

### オプション要件
- [ ] `safeThemeNotifier`のフォールバック処理を簡素化

## 受け入れ基準
- [ ] グローバル変数が完全に削除されている
- [ ] テーマ/フォント変更が全画面で正しく反映される
- [ ] `flutter analyze`でエラーがない
- [ ] 既存の動作が変わらない（テーマ保存・復元が正常動作）
