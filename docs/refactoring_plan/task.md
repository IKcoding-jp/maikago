# まいカゴ リファクタリング計画タスク

## フェーズ1: 分析と計画 ✅
- [x] プロジェクト構造の把握
- [x] 主要ファイルの責務分析
- [x] リファクタリング計画書の作成
- [x] ユーザーレビュー/承認

## フェーズ2: UI分割 (main_screen.dart) 🔄
- [ ] TabBarWidget の切り出し
- [ ] IncompleteListWidget の切り出し
- [ ] CompletedListWidget の切り出し
- [ ] BottomSummaryWidget の独立ファイル化
- [x] BudgetDialog の切り出し
- [x] SortDialog の切り出し
- [x] ItemEditDialog の切り出し
- [/] TabEditDialog の切り出し

## フェーズ3: Provider分割 (data_provider.dart)
- [ ] ItemProvider の作成（アイテムCRUD）
- [ ] ShopProvider の作成（ショップCRUD）
- [ ] SyncProvider の作成（リアルタイム同期）
- [ ] SharedGroupProvider の作成（共有グループ管理）

## フェーズ4: サービス層の整理
- [ ] Repository層の導入
- [ ] OCRサービスの初期化/破棄の一元化
- [ ] 広告サービスの初期化/破棄の一元化
- [ ] テーマ/フォント管理の一元化

## フェーズ5: パフォーマンス最適化
- [ ] TabController の最適化
- [ ] notifyListeners の呼び出し頻度削減
- [ ] ListView.builder の最適化（cacheExtent、const化）
- [ ] メモ化の導入

## フェーズ6: テストとドキュメント
- [ ] 既存テストの確認と実行
- [ ] 新規ユニットテストの追加
- [ ] リファクタリング結果のドキュメント化
