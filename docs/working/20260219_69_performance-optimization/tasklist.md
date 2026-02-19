# タスクリスト

**ステータス**: 完了
**完了日**: 2026-02-19

## フェーズ1: 高優先度修正（リビルド削減の核心）

- [x] MainScreenのConsumer2<DataProvider, AuthProvider>をConsumer<DataProvider>に変更
  - Consumer2を除去し、AuthProviderのリスニングを排除
  - AuthProviderはbuild内で未使用のため除去
- [ ] ~~TabController再作成をbuild()からdidChangeDependencies/リスナーに移動~~
  - ※ Consumer builderのライフサイクルとの整合性問題のためスキップ（リグレッションリスク大）
- [ ] ~~主要画面にcontext.selectを導入~~
  - ※ context.watchへの変更でTabController同期が壊れる問題が判明しスキップ
- [x] FutureBuilderのFutureをinitStateで変数に保存
  - advanced_settings_screen.dart: _autoCompleteFuture, _strikethroughFuture

## フェーズ2: 中優先度修正（追加最適化）

- [ ] ~~build内ソート結果のキャッシュ化~~ （スコープ外・将来のIssueで対応）
- [ ] ~~空のsetState(() {})の整理~~ （低影響・高リスクのためスキップ）
- [x] _getCurrentThemeの呼び出し回数削減
  - advanced_settings_screen.dartのbuild冒頭で1回呼び出し、引数で各メソッドに渡す方式に変更
- [x] 不要なlisten:true/Consumerの除去
  - recipe_confirm_screen.dart: Provider.of → context.readに変更
  - main_app_bar.dart: 不要なConsumer2を除去
- [ ] ~~BottomSummaryWidgetの非同期処理最適化~~ （スコープ外・将来のIssueで対応）
- [x] router.dartでキャッシュ済みThemeDataの利用
  - SettingsTheme.generateTheme()フォールバックをtp.themeDataに置換

## フェーズ3: Firestore効率化

- [x] ショップ削除にWriteBatch導入
  - data_service.dart: deleteShop()のfallbackパスtransmissions更新をバッチ化
- [ ] ~~アイテムバッチ更新のWriteBatch化検討~~ （効果が限定的のためスキップ）

## フェーズ4: 低優先度・微調整

- [x] cacheExtentの調整（item_list_section.dart: 50 → 250に変更）
- [ ] ~~不要なConsumer/Consumer2の除去（残りの箇所）~~ （スコープ外・将来のIssueで対応）

## 依存関係

- フェーズ1 → フェーズ2 → フェーズ3 → フェーズ4（順次実行推奨）
- フェーズ1完了後に動作確認を行い、リグレッションがないことを確認してからフェーズ2に進む
- フェーズ3はフェーズ1・2と独立して実行可能だが、テスト観点で順次が望ましい
