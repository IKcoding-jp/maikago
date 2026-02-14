# タスクリスト

**Issue**: #3 - data_provider.dart責務分割
**作成日**: 2026-02-14

## フェーズ概要

| フェーズ | 内容 | リスク | 想定工数 |
|---------|------|--------|---------|
| Phase 0 | テスト準備・現状把握 | 低 | 2h |
| Phase 1 | キャッシュ管理の分離 | 中 | 4h |
| Phase 2 | アイテムCRUDの分離 | 低 | 4h |
| Phase 3 | ショップCRUDの分離 | 低 | 4h |
| Phase 4 | リアルタイム同期の分離 | 高 | 6h |
| Phase 5 | 共有グループ管理の分離 | 中 | 4h |
| Phase 6 | 最終統合・リファクタリング | 中 | 4h |

---

## Phase 0: テスト準備・現状把握

**目的**: 安全なリファクタリングのための基盤整備

### タスク

- [ ] **P0-1**: 既存テストの実行と確認
  - `flutter test`を実行し、現在のテストカバレッジを把握
  - テストがない場合は最低限の統合テストを追加
  - **成果物**: テスト実行結果レポート
  - **工数**: 1h

- [ ] **P0-2**: DataProviderの使用箇所の洗い出し
  - `grep -r "DataProvider" lib/`で全使用箇所を特定
  - 公開メソッドの呼び出し頻度を分析
  - **成果物**: 使用箇所一覧（Markdown表）
  - **工数**: 1h

- [ ] **P0-3**: 分割後のディレクトリ構造作成
  ```
  lib/providers/
    ├── data_provider.dart (メインファサード)
    ├── repositories/
    │   ├── item_repository.dart
    │   └── shop_repository.dart
    └── managers/
        ├── data_cache_manager.dart
        ├── realtime_sync_manager.dart
        └── shared_group_manager.dart
  ```
  - ディレクトリのみ作成（空ファイル）
  - **成果物**: ディレクトリ構造
  - **工数**: 0.5h

### 完了条件
- [ ] 既存テストがすべてパス
- [ ] 使用箇所一覧が完成
- [ ] ディレクトリ構造が作成済み

---

## Phase 1: キャッシュ管理の分離

**目的**: データロード・キャッシュTTLロジックを分離

### タスク

- [ ] **P1-1**: `DataCacheManager`クラス作成
  - 責務: データの保持、キャッシュTTL管理、ローカルモード管理
  - **移行対象**:
    - `_items`, `_shops`の保持
    - `_isDataLoaded`, `_lastSyncTime`, `_isLocalMode`
    - `loadData()`, `_loadItems()`, `_loadShops()`
    - `_associateItemsWithShops()`, `_removeDuplicateItems()`
    - `checkSyncStatus()`
    - `clearData()`
  - **成果物**: `lib/providers/managers/data_cache_manager.dart`
  - **工数**: 2h

- [ ] **P1-2**: DataProviderからDataCacheManagerへ委譲
  - `DataProvider`に`DataCacheManager`インスタンスを保持
  - getter (`items`, `shops`, `isLoading`, `isLocalMode`) をDataCacheManagerに委譲
  - `loadData()`を`_cacheManager.loadData()`に委譲
  - **成果物**: `data_provider.dart`の修正
  - **工数**: 1h

- [ ] **P1-3**: テスト実行と動作確認
  - `flutter test`でテストがパス
  - アプリ起動時のデータロードが正常動作
  - **成果物**: テスト結果レポート
  - **工数**: 1h

### 完了条件
- [ ] `DataCacheManager`が単独でテスト可能
- [ ] 既存テストがすべてパス
- [ ] アプリ起動時のデータロードが正常動作

---

## Phase 2: アイテムCRUDの分離

**目的**: アイテム操作を`ItemRepository`に分離

### タスク

- [ ] **P2-1**: `ItemRepository`クラス作成
  - 責務: アイテムCRUD、楽観的更新、バウンス抑止
  - **移行対象**:
    - `_pendingItemUpdates`
    - `addItem()`, `updateItem()`, `updateItemsBatch()`, `deleteItem()`, `deleteItems()`
    - `_performBackgroundOperations()`
  - 依存:
    - `DataService` (DIで注入)
    - `DataCacheManager` (items/shopsの読み書き)
  - **成果物**: `lib/providers/repositories/item_repository.dart`
  - **工数**: 2h

- [ ] **P2-2**: DataProviderからItemRepositoryへ委譲
  - `DataProvider`に`ItemRepository`インスタンスを保持
  - アイテム関連メソッドを`_itemRepository`に委譲
  - `notifyListeners()`の呼び出しタイミングを維持
  - **成果物**: `data_provider.dart`の修正
  - **工数**: 1h

- [ ] **P2-3**: 単体テスト作成
  - `ItemRepository`の単体テストを作成
  - モックを使用して`DataService`依存を解消
  - 楽観的更新のロールバックをテスト
  - **成果物**: `test/providers/repositories/item_repository_test.dart`
  - **工数**: 1h

### 完了条件
- [ ] `ItemRepository`が単独でテスト可能
- [ ] アイテム追加・更新・削除が正常動作
- [ ] 楽観的更新とロールバックが正常動作
- [ ] 単体テストカバレッジ70%以上

---

## Phase 3: ショップCRUDの分離

**目的**: ショップ操作を`ShopRepository`に分離

### タスク

- [ ] **P3-1**: `ShopRepository`クラス作成
  - 責務: ショップCRUD、楽観的更新、バウンス抑止
  - **移行対象**:
    - `_pendingShopUpdates`
    - `addShop()`, `updateShop()`, `deleteShop()`
    - `updateShopName()`, `updateShopBudget()`, `clearAllItems()`, `updateSortMode()`
    - `_ensureDefaultShop()`
  - 依存:
    - `DataService` (DIで注入)
    - `DataCacheManager` (shops/itemsの読み書き)
  - **成果物**: `lib/providers/repositories/shop_repository.dart`
  - **工数**: 2h

- [ ] **P3-2**: DataProviderからShopRepositoryへ委譲
  - `DataProvider`に`ShopRepository`インスタンスを保持
  - ショップ関連メソッドを`_shopRepository`に委譲
  - デフォルトショップ作成ロジックを`ShopRepository`に移動
  - **成果物**: `data_provider.dart`の修正
  - **工数**: 1h

- [ ] **P3-3**: 単体テスト作成
  - `ShopRepository`の単体テストを作成
  - デフォルトショップ自動作成をテスト
  - 削除時の共有タブ参照削除をテスト
  - **成果物**: `test/providers/repositories/shop_repository_test.dart`
  - **工数**: 1h

### 完了条件
- [ ] `ShopRepository`が単独でテスト可能
- [ ] ショップ追加・更新・削除が正常動作
- [ ] デフォルトショップ自動作成が正常動作
- [ ] 単体テストカバレッジ70%以上

---

## Phase 4: リアルタイム同期の分離

**目的**: リアルタイム同期ロジックを`RealtimeSyncManager`に分離

**注意**: このフェーズは最も複雑で、楽観的更新との競合回避ロジックが含まれる。慎重に実施すること。

### タスク

- [ ] **P4-1**: `RealtimeSyncManager`クラス作成
  - 責務: Firestore Streamの購読、楽観的更新との競合回避
  - **移行対象**:
    - `_itemsSubscription`, `_shopsSubscription`
    - `_startRealtimeSync()`, `_cancelRealtimeSync()`
    - リスナー内の`_pendingItemUpdates`/`_pendingShopUpdates`チェックロジック
  - 依存:
    - `DataService` (Stream取得)
    - `ItemRepository` (pendingUpdatesへのアクセス)
    - `ShopRepository` (pendingUpdatesへのアクセス)
    - `DataCacheManager` (items/shopsの更新)
  - **成果物**: `lib/providers/managers/realtime_sync_manager.dart`
  - **工数**: 3h

- [ ] **P4-2**: DataProviderからRealtimeSyncManagerへ委譲
  - `DataProvider`に`RealtimeSyncManager`インスタンスを保持
  - `loadData()`完了後に`_syncManager.startRealtimeSync()`を呼び出し
  - `dispose()`時に`_syncManager.cancelRealtimeSync()`を呼び出し
  - **成果物**: `data_provider.dart`の修正
  - **工数**: 1h

- [ ] **P4-3**: バッチ更新フラグの管理統合
  - `_isBatchUpdating`フラグを`RealtimeSyncManager`に移動
  - `notifyListeners()`のオーバーライドを`RealtimeSyncManager`で管理
  - `updateItemsBatch()`, `reorderItems()`での連携を確認
  - **成果物**: `realtime_sync_manager.dart`, `data_provider.dart`の修正
  - **工数**: 1h

- [ ] **P4-4**: 統合テストと動作確認
  - 複数デバイスでの同時編集をシミュレート
  - 楽観的更新のバウンス抑止が正常動作するか確認
  - バッチ更新中の同期スキップが正常動作するか確認
  - **成果物**: テスト結果レポート
  - **工数**: 1h

### 完了条件
- [ ] リアルタイム同期が正常動作
- [ ] 楽観的更新との競合が発生しない
- [ ] バッチ更新中の同期スキップが動作
- [ ] 複数デバイス間での即時反映が動作

---

## Phase 5: 共有グループ管理の分離

**目的**: 共有グループロジックを`SharedGroupManager`に分離

### タスク

- [ ] **P5-1**: `SharedGroupManager`クラス作成
  - 責務: 共有グループのCRUD、合計・予算計算
  - **移行対象**:
    - `updateSharedGroup()`, `removeFromSharedGroup()`, `syncSharedGroupBudget()`
    - `getSharedGroupTotal()`, `getSharedGroupBudget()`
    - `getDisplayTotal()` (合計計算ロジック)
  - 依存:
    - `DataService` (Firestore保存)
    - `ShopRepository` (shop更新の委譲)
    - `DataCacheManager` (shops読み取り)
  - **成果物**: `lib/providers/managers/shared_group_manager.dart`
  - **工数**: 2h

- [ ] **P5-2**: DataProviderからSharedGroupManagerへ委譲
  - `DataProvider`に`SharedGroupManager`インスタンスを保持
  - 共有グループ関連メソッドを`_sharedGroupManager`に委譲
  - **成果物**: `data_provider.dart`の修正
  - **工数**: 1h

- [ ] **P5-3**: 単体テスト作成
  - 共有グループ作成・削除のテスト
  - 共有タブ参照の整合性テスト
  - 合計・予算計算のテスト
  - **成果物**: `test/providers/managers/shared_group_manager_test.dart`
  - **工数**: 1h

### 完了条件
- [ ] 共有グループ作成・編集・削除が正常動作
- [ ] 共有グループ合計・予算計算が正常動作
- [ ] 単体テストカバレッジ70%以上

---

## Phase 6: 最終統合・リファクタリング

**目的**: コードクリーンアップと最終検証

### タスク

- [ ] **P6-1**: DataProviderのリファクタリング
  - 残っているprivateメソッドを適切なクラスに移動
  - `reorderItems()`を`ItemRepository` + `ShopRepository`の連携に置き換え
  - `_isBatchUpdating`のオーバーライドロジックを整理
  - **成果物**: `data_provider.dart`の修正
  - **工数**: 2h

- [ ] **P6-2**: 認証連携の整理
  - `setAuthProvider()`, `_resetDataForLogin()`の処理を見直し
  - `DataCacheManager`との連携を明確化
  - **成果物**: `data_provider.dart`の修正
  - **工数**: 1h

- [ ] **P6-3**: 最終テストと動作確認
  - `flutter analyze`でwarning/error 0件
  - `flutter test`で全テストパス
  - 実機での動作確認（iOS/Android/Web）
  - **成果物**: テスト結果レポート、動作確認レポート
  - **工数**: 1h

- [ ] **P6-4**: ドキュメント更新
  - `design.md`のアーキテクチャ図を最新化
  - 各クラスのKDocコメントを追加
  - `CLAUDE.md`の「アーキテクチャ」セクションを更新
  - **成果物**: ドキュメント更新
  - **工数**: 0.5h

### 完了条件
- [ ] `data_provider.dart`が500行以下
- [ ] 各Repository/Managerが300行以下
- [ ] `flutter analyze`でwarning/error 0件
- [ ] 全テストパス
- [ ] ドキュメント更新完了

---

## リスク管理

### 高リスクタスク

| タスク | リスク内容 | 軽減策 |
|-------|----------|--------|
| P4-1 | リアルタイム同期ロジックの分離失敗 | 段階的な移行、既存ロジックを残したまま新ロジックを並行実装 |
| P4-3 | バッチ更新フラグ管理の誤り | フラグ管理をRealtimeSyncManagerに集約、単体テスト充実 |

### 中リスクタスク

| タスク | リスク内容 | 軽減策 |
|-------|----------|--------|
| P1-2 | キャッシュ管理移行時のバグ | 既存テストの充実、段階的な委譲 |
| P5-1 | 共有グループロジックの複雑性 | ドキュメント充実、単体テスト追加 |

---

## 進捗管理

### チェックリスト

- [ ] Phase 0: テスト準備・現状把握
- [ ] Phase 1: キャッシュ管理の分離
- [ ] Phase 2: アイテムCRUDの分離
- [ ] Phase 3: ショップCRUDの分離
- [ ] Phase 4: リアルタイム同期の分離
- [ ] Phase 5: 共有グループ管理の分離
- [ ] Phase 6: 最終統合・リファクタリング

### 完了基準（全体）

- [ ] `data_provider.dart`が500行以下
- [ ] `flutter analyze`でwarning/error 0件
- [ ] `flutter test`で全テストパス
- [ ] 実機動作確認完了（iOS/Android/Web）
- [ ] ドキュメント更新完了
- [ ] 単体テストカバレッジ70%以上

---

## 備考

- **並行作業**: Phase 2とPhase 3は依存関係が少ないため並行実施可能
- **ロールバック**: 各フェーズ完了時にGitコミットを作成し、問題発生時はロールバック可能にする
- **コードレビュー**: Phase 4完了後に中間レビューを実施し、設計の妥当性を確認
