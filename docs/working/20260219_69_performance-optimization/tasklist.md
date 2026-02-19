# タスクリスト

## フェーズ1: 高優先度修正（リビルド削減の核心）

- [ ] MainScreenのConsumer2<DataProvider, AuthProvider>をSelector/個別Consumerに分割
  - Consumer2を除去し、必要なデータ（shops, isLoading等）のみcontext.selectで取得
  - AuthProviderはbuild内で未使用のため除去
- [ ] TabController再作成をbuild()からdidChangeDependencies/リスナーに移動
  - build()内のdispose()+再作成パターンを排除
  - shops変更の検知はProvider.ofまたはdidChangeDependenciesで行う
- [ ] 主要画面にcontext.selectを導入
  - MainScreen: shops, isLoadingのみ監視
  - BottomSummaryWidget: 必要なサマリーデータのみ
  - ItemListSection: 対象shopのitemsのみ
- [ ] FutureBuilderのFutureをinitStateで変数に保存
  - advanced_settings_screen.dart: _getAutoCompleteEnabled(), _getStrikethroughEnabled()
  - setStateの後は変数をリフレッシュする方式に変更

## フェーズ2: 中優先度修正（追加最適化）

- [ ] build内ソート結果のキャッシュ化
  - MainScreenのincItems/comItemsのソートをキャッシュ
  - ショップ/アイテム変更時のみ再計算するロジック追加
- [ ] 空のsetState(() {})の整理
  - settings_screen.dart: 6箇所の空setStateを修正
  - advanced_settings_screen.dart: 2箇所の空setStateを修正
  - main_screen.dart: 1箇所の空setStateを修正
- [ ] _getCurrentThemeの呼び出し回数削減
  - advanced_settings_screen.dartのbuild冒頭で1回呼び出し、ローカル変数に保存
  - 他の設定画面でも同様にキャッシュ化
- [ ] 不要なlisten:true/Consumerの除去
  - recipe_confirm_screen.dart: Provider.of → context.readに変更
  - main_app_bar.dart: 不要なConsumer2を除去
- [ ] BottomSummaryWidgetの非同期処理最適化
  - _refreshData()のSharedPreferencesアクセスを同期キャッシュに置換
  - ダブルリビルドパターンの解消
- [ ] router.dartでキャッシュ済みThemeDataの利用
  - SettingsTheme.generateTheme()フォールバックをtp.themeDataに置換

## フェーズ3: Firestore効率化

- [ ] ショップ削除にWriteBatch導入
  - data_service.dart: deleteShop()のtransmissions更新+ユーザー更新+削除をバッチ化
- [ ] アイテムバッチ更新のWriteBatch化検討
  - item_repository.dart: 5件ずつのFuture.waitをWriteBatchに置換

## フェーズ4: 低優先度・微調整

- [ ] cacheExtentの調整（item_list_section.dart: 50 → デフォルト値に変更）
- [ ] 不要なConsumer/Consumer2の除去（残りの箇所）

## 依存関係

- フェーズ1 → フェーズ2 → フェーズ3 → フェーズ4（順次実行推奨）
- フェーズ1完了後に動作確認を行い、リグレッションがないことを確認してからフェーズ2に進む
- フェーズ3はフェーズ1・2と独立して実行可能だが、テスト観点で順次が望ましい
