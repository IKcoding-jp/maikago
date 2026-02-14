# 要件定義

**Issue**: #3
**作成日**: 2026-02-14
**ラベル**: refactor, critical
**対象ファイル**: `lib/providers/data_provider.dart` (1,577行)

## ユーザーストーリー

開発者として、`data_provider.dart`が1,577行もあって変更が怖い。責務ごとに分割して安全に変更できるようにしたい。

### 現状の問題点

1. **単一ファイルの肥大化**: 1,577行の単一ファイルで、リスト・ショップ・共有グループ・リアルタイム同期・認証連携などすべてが1クラスに詰まっている
2. **変更リスク**: 一箇所の変更が予期せぬ副作用を引き起こす可能性が高い
3. **テストの困難さ**: モック化や単体テストが困難（すべての依存関係を含む）
4. **可読性の低下**: 責務が明確に分離されていないため、新規メンバーの理解に時間がかかる

## 現在の責務分析

### データ保持
- `_items: List<ListItem>` — 全アイテムのインメモリキャッシュ
- `_shops: List<Shop>` — 全ショップのインメモリキャッシュ
- `_isLoading`, `_isSynced`, `_isDataLoaded`, `_isLocalMode`, `_isBatchUpdating` — 各種フラグ
- `_pendingItemUpdates`, `_pendingShopUpdates` — 楽観的更新のバウンス抑止マップ
- `_lastSyncTime` — 最終同期時刻

### 認証連携
- `setAuthProvider()` — AuthProviderとの連携設定
- `_authListener` — ログイン/ログアウト時の自動データ切り替え
- `_shouldUseAnonymousSession` — 匿名セッション判定
- `_resetDataForLogin()` — ログイン時のデータリセット

### アイテムCRUD（楽観的更新）
- `addItem()` — アイテム追加
- `updateItem()` — アイテム更新
- `updateItemsBatch()` — バッチ更新
- `deleteItem()` — アイテム削除
- `deleteItems()` — 一括削除

### ショップCRUD（楽観的更新）
- `addShop()` — ショップ追加
- `updateShop()` — ショップ更新
- `deleteShop()` — ショップ削除
- `updateShopName()` — ショップ名更新
- `updateShopBudget()` — 予算更新
- `clearAllItems()` — ショップ内全アイテム削除
- `updateSortMode()` — ソートモード更新

### 並べ替え処理（特殊バッチ処理）
- `reorderItems()` — ショップとアイテムを一括更新（バッチフラグ管理）

### 共有グループ管理
- `updateSharedGroup()` — 共有グループ作成・更新
- `removeFromSharedGroup()` — 共有グループから削除
- `syncSharedGroupBudget()` — 共有グループ内予算同期
- `getSharedGroupTotal()` — 共有グループ合計
- `getSharedGroupBudget()` — 共有グループ予算取得

### リアルタイム同期
- `_startRealtimeSync()` — Firestore Streamの購読開始
- `_cancelRealtimeSync()` — 購読停止
- `_itemsSubscription`, `_shopsSubscription` — Stream購読オブジェクト
- 楽観的更新との競合回避（`_pendingItemUpdates`, `_pendingShopUpdates`による保護期間管理）

### データロード・キャッシュ
- `loadData()` — 初回ロード（5分キャッシュTTL）
- `_loadItems()`, `_loadShops()` — 単発取得
- `_associateItemsWithShops()` — アイテムとショップの関連付け
- `_removeDuplicateItems()` — 重複除去
- `checkSyncStatus()` — 同期状態チェック

### デフォルトショップ管理
- `_ensureDefaultShop()` — デフォルトショップ（ID='0'）の自動作成

### 合計・予算計算
- `getDisplayTotal()` — ショップごとの合計計算（税抜き）

### その他
- `clearData()` — データクリア（ログアウト時）
- `setLocalMode()` — ローカルモード切り替え
- `notifyDataChanged()` — 外部からの通知トリガー
- `saveUserTaxRateOverride()` — 税率保存（現在無効化）

## 要件一覧

### 必須要件

#### R1. 責務の明確な分割
- **R1.1**: アイテムCRUD操作を`ItemRepository`として分離
- **R1.2**: ショップCRUD操作を`ShopRepository`として分離
- **R1.3**: 共有グループ管理を`SharedGroupManager`として分離
- **R1.4**: リアルタイム同期ロジックを`RealtimeSyncManager`として分離
- **R1.5**: データロード・キャッシュ管理を`DataCacheManager`として分離

#### R2. 既存インターフェースの維持
- **R2.1**: 外部から呼び出されるすべてのpublicメソッドのシグネチャを変更しない
- **R2.2**: `DataProvider`のgetter (`items`, `shops`, `isLoading`, `isSynced`, `isLocalMode`) を維持
- **R2.3**: `ChangeNotifier`の`notifyListeners()`の呼び出しタイミングを維持

#### R3. 楽観的更新の仕組みを維持
- **R3.1**: `_pendingItemUpdates`, `_pendingShopUpdates`の保護期間管理を維持
- **R3.2**: バッチ更新時の`_isBatchUpdating`フラグによる`notifyListeners()`抑制を維持
- **R3.3**: リアルタイム同期との競合回避ロジックを維持

#### R4. 認証連携の維持
- **R4.1**: `AuthProvider`との連携メカニズムを維持
- **R4.2**: ログイン/ログアウト時の自動データ切り替えを維持
- **R4.3**: 匿名セッション判定ロジックを維持

#### R5. テスタビリティの向上
- **R5.1**: 各Repository/Managerクラスを独立してテスト可能にする
- **R5.2**: `DataService`への依存をDIで注入可能にする
- **R5.3**: モック化可能なインターフェース設計

#### R6. パフォーマンスの維持
- **R6.1**: 現在の5分キャッシュTTL機構を維持
- **R6.2**: リアルタイム同期のStream購読数を増やさない
- **R6.3**: `notifyListeners()`の呼び出し回数を増やさない

### オプション要件

#### O1. 段階的なマイグレーション
- **O1.1**: 分割後もすべてのテストがパスすること
- **O1.2**: 分割後も既存の画面コードを一切変更しない

#### O2. ドキュメント整備
- **O2.1**: 各Repository/Managerクラスの責務を明確にドキュメント化
- **O2.2**: アーキテクチャ図を作成（`design.md`に記載）

#### O3. 将来の拡張性
- **O3.1**: 新しい機能追加時に適切なクラスに配置できるよう責務を明確にする
- **O3.2**: 他のProviderとの依存関係を最小化する

## 受け入れ基準

### AC1. コンパイルエラーなし
- すべてのDartファイルが`flutter analyze`でエラー・警告なしでパスすること

### AC2. 既存機能の完全動作
- 以下の機能が分割後も完全に動作すること:
  - リスト追加・編集・削除
  - ショップ追加・編集・削除
  - 共有グループ作成・編集・解除
  - リアルタイム同期（複数デバイス間での即時反映）
  - ログイン/ログアウト時のデータ切り替え
  - ローカルモード（オフライン動作）
  - バッチ更新（並べ替え処理）

### AC3. テストカバレッジ
- 既存のテストがすべてパスすること（`flutter test`）
- 新規作成したRepository/Managerクラスに対する単体テストを追加

### AC4. パフォーマンス維持
- アプリ起動時のデータロード時間が現状と同等（±10%以内）
- リスト追加・更新のレスポンスが現状と同等

### AC5. コード行数削減
- `DataProvider`クラスが500行以下に削減されること
- 各Repository/Managerクラスが300行以下であること

### AC6. ドキュメント完備
- `design.md`にアーキテクチャ図と責務が明記されていること
- 各クラスの先頭に責務を説明するコメントが記載されていること

## 非機能要件

### NFR1. 後方互換性
- 既存の画面コード（`main_screen.dart`等）を一切変更せずに動作すること
- `DataProvider`の公開インターフェースを維持すること

### NFR2. 保守性
- 1ファイルあたりの行数を500行以下に制限
- 循環依存を発生させない
- 各クラスの責務を単一にする（Single Responsibility Principle）

### NFR3. 可読性
- クラス名・メソッド名から責務が明確に理解できること
- 複雑なロジックには日本語コメントを付与すること

## 制約事項

### C1. 既存コード変更の最小化
- 画面層（`screens/`, `drawer/`）のコード変更は原則禁止
- `main.dart`のProvider登録部分のみ変更可能

### C2. 段階的な実施
- 一度にすべてを変更せず、フェーズに分けて実施（`tasklist.md`参照）
- 各フェーズ後に動作確認とテストを実施

### C3. Firebase依存の維持
- `DataService`への依存は維持（Firebaseアクセス層の変更は今回のスコープ外）

## リスク評価

### 高リスク
- **リアルタイム同期ロジックの分割**: 楽観的更新との競合回避が複雑
- **バッチ更新フラグの管理**: `_isBatchUpdating`の管理を誤るとUIが更新されない

### 中リスク
- **認証連携の分離**: `AuthProvider`リスナーの管理を誤るとメモリリークの可能性
- **キャッシュTTLの移行**: 5分キャッシュロジックの移行時にバグの可能性

### 低リスク
- **アイテム・ショップCRUD分離**: ロジックが単純で分離が容易
- **合計計算ロジックの分離**: 純粋関数で副作用なし

## 成功指標

- `data_provider.dart`の行数が1,577行から500行以下に削減
- 新規メンバーのオンボーディング時間が50%短縮（責務が明確なため）
- 単体テストカバレッジが70%以上
- リファクタリング後のバグ報告が0件（1週間以内）
