# 設計ドキュメント

**Issue**: #3 - data_provider.dart責務分割
**作成日**: 2026-02-14

## アーキテクチャ概要

### 現状（Before）

```
┌──────────────────────────────────────────────────────┐
│           DataProvider (1,577行)                     │
│                                                      │
│  - アイテムCRUD                                       │
│  - ショップCRUD                                       │
│  - 共有グループ管理                                    │
│  - リアルタイム同期                                    │
│  - キャッシュ管理                                      │
│  - 認証連携                                           │
│  - 楽観的更新                                         │
│  - バウンス抑止                                       │
│  - バッチ更新制御                                      │
└──────────────────────────────────────────────────────┘
                    ↓
             DataService
```

**問題点**:
- 単一クラスに責務が集中（1,577行）
- 変更リスクが高い
- テストが困難
- 新規メンバーの理解に時間がかかる

---

### 改善後（After）

```
┌─────────────────────────────────────────────────────────────────┐
│                   DataProvider (ファサード, 413行)               │
│                                                                 │
│  - 外部インターフェースの提供                                     │
│  - 各Repository/Managerへの委譲                                  │
│  - notifyListeners()の統合管理                                   │
│  - AuthProvider連携                                             │
│  - reorderItems()（横断的関心事）                                 │
└─────────────────────────────────────────────────────────────────┘
           ↓              ↓              ↓              ↓
    ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
    │  Item    │   │  Shop    │   │ Realtime │   │ Shared   │
    │Repository│   │Repository│   │  Sync    │   │  Group   │
    │  (388行)  │   │  (379行)  │   │ Manager  │   │ Manager  │
    │          │   │          │   │  (195行)  │   │  (309行)  │
    └──────────┘   └──────────┘   └──────────┘   └──────────┘
           ↓              ↓              ↓              ↓
    ┌────────────────────────────────────────────────────────┐
    │              DataCacheManager (221行)                  │
    │                                                        │
    │  - items/shopsの保持                                   │
    │  - キャッシュTTL管理                                    │
    │  - データロード                                         │
    │  - 重複除去・関連付け                                   │
    └────────────────────────────────────────────────────────┘
                            ↓
                      DataService
```

**メリット**:
- 責務が明確に分離
- 各クラスが独立してテスト可能
- 変更の影響範囲が限定的
- コード理解が容易

---

## クラス設計

### 1. DataProvider (ファサード)

**責務**: 外部インターフェースの提供と各Repository/Managerへの委譲

**保持する状態**:
- `_itemRepository: ItemRepository`
- `_shopRepository: ShopRepository`
- `_realtimeSyncManager: RealtimeSyncManager`
- `_sharedGroupManager: SharedGroupManager`
- `_cacheManager: DataCacheManager`
- `_authProvider: AuthProvider?`
- `_authListener: VoidCallback?`
- `_isLoading: bool`
- `_isSynced: bool`

**公開メソッド**（外部インターフェース維持）:
```dart
// Getter
List<ListItem> get items
List<Shop> get shops
bool get isLoading
bool get isSynced
bool get isLocalMode

// 認証連携
void setAuthProvider(AuthProvider authProvider)

// アイテムCRUD
Future<void> addItem(ListItem item)
Future<void> updateItem(ListItem item)
Future<void> updateItemsBatch(List<ListItem> items)
Future<void> deleteItem(String itemId)
Future<void> deleteItems(List<String> itemIds)

// ショップCRUD
Future<void> addShop(Shop shop)
Future<void> updateShop(Shop shop)
Future<void> deleteShop(String shopId)
void updateShopName(int index, String newName)
void updateShopBudget(int index, int? budget)
void clearAllItems(int shopIndex)
void updateSortMode(int shopIndex, SortMode sortMode, bool isIncomplete)

// 並べ替え
Future<void> reorderItems(Shop updatedShop, List<ListItem> updatedItems)

// 共有グループ
Future<void> updateSharedGroup(String shopId, List<String> selectedTabIds, {String? name, String? sharedGroupIcon})
Future<void> removeFromSharedGroup(String shopId, {String? originalSharedGroupId, String? name})
Future<void> syncSharedGroupBudget(String sharedGroupId, int? newBudget)
Future<int> getSharedGroupTotal(String sharedGroupId)
int? getSharedGroupBudget(String sharedGroupId)

// 合計計算
Future<int> getDisplayTotal(Shop shop)

// データロード
Future<void> loadData()
Future<void> checkSyncStatus()
void clearData()
void setLocalMode(bool isLocal)

// その他
void notifyDataChanged()
Future<void> clearAnonymousSession()
void clearDisplayTotalCache()
```

**委譲パターン**:
```dart
// 例: アイテム追加
Future<void> addItem(ListItem item) async {
  await _itemRepository.addItem(item);
  notifyListeners();
}

// 例: データロード
Future<void> loadData() async {
  _setLoading(true);
  try {
    await _cacheManager.loadData();
    _realtimeSyncManager.startRealtimeSync();
    _isSynced = true;
  } finally {
    _setLoading(false);
    notifyListeners();
  }
}
```

---

### 2. ItemRepository

**責務**: アイテムのCRUD操作、楽観的更新、バウンス抑止

**ファイルパス**: `lib/providers/repositories/item_repository.dart`

**保持する状態**:
- `_dataService: DataService`
- `_cacheManager: DataCacheManager`
- `_pendingItemUpdates: Map<String, DateTime>` — バウンス抑止用
- `_shouldUseAnonymousSession: bool Function()` — 匿名セッション判定

**公開メソッド**:
```dart
Future<void> addItem(ListItem item)
Future<void> updateItem(ListItem item)
Future<void> updateItemsBatch(List<ListItem> items)
Future<void> deleteItem(String itemId)
Future<void> deleteItems(List<String> itemIds)

// バウンス抑止用（RealtimeSyncManagerから参照）
bool isPendingUpdate(String itemId)
void markAsPending(String itemId)
void cleanupPendingUpdates()
```

**楽観的更新の流れ**:
```dart
Future<void> addItem(ListItem item) async {
  // 1. ローカルキャッシュを即座に更新
  _cacheManager.addItemToCache(item);

  // 2. UIに即座に通知（呼び出し元のDataProviderが実施）

  // 3. バックグラウンドでFirebase保存
  try {
    await _dataService.saveItem(item, isAnonymous: _shouldUseAnonymousSession());
  } catch (e) {
    // 4. エラー時はロールバック
    _cacheManager.removeItemFromCache(item.id);
    rethrow;
  }
}
```

**依存関係**:
- `DataService` (Firebase操作)
- `DataCacheManager` (キャッシュ操作)

---

### 3. ShopRepository

**責務**: ショップのCRUD操作、楽観的更新、デフォルトショップ管理

**ファイルパス**: `lib/providers/repositories/shop_repository.dart`

**保持する状態**:
- `_dataService: DataService`
- `_cacheManager: DataCacheManager`
- `_pendingShopUpdates: Map<String, DateTime>` — バウンス抑止用
- `_shouldUseAnonymousSession: bool Function()`

**公開メソッド**:
```dart
Future<void> addShop(Shop shop)
Future<void> updateShop(Shop shop)
Future<void> deleteShop(String shopId)
Future<void> ensureDefaultShop() // デフォルトショップ確保
void updateShopName(int index, String newName)
void updateShopBudget(int index, int? budget)
void clearAllItems(int shopIndex)
void updateSortMode(int shopIndex, SortMode sortMode, bool isIncomplete)

// バウンス抑止用（RealtimeSyncManagerから参照）
bool isPendingUpdate(String shopId)
void markAsPending(String shopId)
void cleanupPendingUpdates()
```

**デフォルトショップ管理**:
```dart
Future<void> ensureDefaultShop() async {
  // ローカルモード時のみ実行
  if (!_cacheManager.isLocalMode) return;

  // 削除済みフラグをチェック
  final isDeleted = await SettingsPersistence.loadDefaultShopDeleted();
  if (isDeleted) return;

  // デフォルトショップが存在しない場合のみ作成
  final hasDefaultShop = _cacheManager.shops.any((shop) => shop.id == '0');
  if (!hasDefaultShop) {
    final defaultShop = Shop(id: '0', name: 'デフォルト', ...);
    _cacheManager.addShopToCache(defaultShop);
  }
}
```

**依存関係**:
- `DataService` (Firebase操作)
- `DataCacheManager` (キャッシュ操作)
- `SettingsPersistence` (デフォルトショップ削除フラグ)

---

### 4. RealtimeSyncManager

**責務**: Firestore Streamの購読、楽観的更新との競合回避、バッチ更新制御

**ファイルパス**: `lib/providers/managers/realtime_sync_manager.dart`

**保持する状態**:
- `_dataService: DataService`
- `_itemRepository: ItemRepository`
- `_shopRepository: ShopRepository`
- `_cacheManager: DataCacheManager`
- `_itemsSubscription: StreamSubscription<List<ListItem>>?`
- `_shopsSubscription: StreamSubscription<List<Shop>>?`
- `_isBatchUpdating: bool` — バッチ更新中フラグ
- `_shouldUseAnonymousSession: bool Function()`
- `_onSyncCompleted: VoidCallback?` — 同期完了時のコールバック

**公開メソッド**:
```dart
void startRealtimeSync()
void cancelRealtimeSync()

// バッチ更新制御
void beginBatchUpdate()
void endBatchUpdate()
bool get isBatchUpdating
```

**リアルタイム同期ロジック**:
```dart
void startRealtimeSync() {
  // 既存の購読を解除
  cancelRealtimeSync();

  // ローカルモードではスキップ
  if (_cacheManager.isLocalMode) return;

  // アイテムの購読
  _itemsSubscription = _dataService.getItems(isAnonymous: _shouldUseAnonymousSession()).listen(
    (remoteItems) {
      // バッチ更新中はスキップ
      if (_isBatchUpdating) return;

      // 保留中の更新をクリーンアップ（TTL: 10秒）
      _itemRepository.cleanupPendingUpdates();

      // ローカル優先マージ（楽観的更新の保護）
      final merged = <ListItem>[];
      for (final remote in remoteItems) {
        if (_itemRepository.isPendingUpdate(remote.id)) {
          // 保護期間内はローカル版を優先
          final local = _cacheManager.items.firstWhere((i) => i.id == remote.id, orElse: () => remote);
          merged.add(local);
        } else {
          merged.add(remote);
        }
      }

      // キャッシュを更新
      _cacheManager.updateItems(merged);
      _cacheManager.associateItemsWithShops();
      _cacheManager.removeDuplicateItems();

      // UIに通知
      _onSyncCompleted?.call();
    },
  );

  // ショップも同様に購読
  _shopsSubscription = _dataService.getShops(...).listen(...);
}
```

**バッチ更新制御**:
```dart
void beginBatchUpdate() {
  _isBatchUpdating = true;
}

void endBatchUpdate() {
  _isBatchUpdating = false;
  _onSyncCompleted?.call(); // バッチ完了時に1回だけ通知
}
```

**依存関係**:
- `DataService` (Stream取得)
- `ItemRepository` (pending updates確認)
- `ShopRepository` (pending updates確認)
- `DataCacheManager` (キャッシュ更新)

---

### 5. SharedGroupManager

**責務**: 共有グループの作成・編集・削除、合計・予算計算

**ファイルパス**: `lib/providers/managers/shared_group_manager.dart`

**保持する状態**:
- `_dataService: DataService`
- `_shopRepository: ShopRepository`
- `_cacheManager: DataCacheManager`
- `_shouldUseAnonymousSession: bool Function()`

**公開メソッド**:
```dart
Future<void> updateSharedGroup(String shopId, List<String> selectedTabIds, {String? name, String? sharedGroupIcon})
Future<void> removeFromSharedGroup(String shopId, {String? originalSharedGroupId, String? name})
Future<void> syncSharedGroupBudget(String sharedGroupId, int? newBudget)
Future<int> getSharedGroupTotal(String sharedGroupId)
int? getSharedGroupBudget(String sharedGroupId)
Future<int> getDisplayTotal(Shop shop)
```

**共有グループ作成ロジック**:
```dart
Future<void> updateSharedGroup(String shopId, List<String> selectedTabIds, {...}) async {
  // 共有グループIDを生成または再利用
  final currentShop = _cacheManager.shops.firstWhere((s) => s.id == shopId);
  final sharedGroupId = currentShop.sharedGroupId ?? 'shared_${DateTime.now().millisecondsSinceEpoch}';

  // 削除されたタブを検出
  final removedTabIds = currentShop.sharedTabs.where((id) => !selectedTabIds.contains(id)).toList();

  // 現在のショップを更新（楽観的更新）
  final updatedShop = currentShop.copyWith(
    sharedTabs: selectedTabIds,
    sharedGroupId: selectedTabIds.isEmpty ? null : sharedGroupId,
    sharedGroupIcon: selectedTabIds.isEmpty ? null : sharedGroupIcon,
  );

  // ShopRepositoryに委譲してキャッシュ更新 + Firebase保存
  await _shopRepository.updateShop(updatedShop);

  // 削除されたタブ側からも参照を削除
  for (final removedTabId in removedTabIds) {
    final removedTab = _cacheManager.shops.firstWhere((s) => s.id == removedTabId);
    final updatedSharedTabs = removedTab.sharedTabs.where((id) => id != shopId).toList();
    final updatedRemovedTab = removedTab.copyWith(
      sharedTabs: updatedSharedTabs,
      clearSharedGroupId: updatedSharedTabs.isEmpty,
    );
    await _shopRepository.updateShop(updatedRemovedTab);
  }

  // 他のタブも同じ共有グループに設定
  for (final tabId in selectedTabIds) {
    final tabShop = _cacheManager.shops.firstWhere((s) => s.id == tabId);
    final updatedSharedTabs = Set<String>.from(tabShop.sharedTabs)..add(shopId);
    final updatedTabShop = tabShop.copyWith(
      sharedGroupId: sharedGroupId,
      sharedTabs: updatedSharedTabs.toList(),
      sharedGroupIcon: sharedGroupIcon,
    );
    await _shopRepository.updateShop(updatedTabShop);
  }
}
```

**依存関係**:
- `DataService` (Firebase保存)
- `ShopRepository` (shop更新)
- `DataCacheManager` (shops読み取り)

---

### 6. DataCacheManager

**責務**: データの保持、キャッシュTTL管理、ローカルモード管理、データロード

**ファイルパス**: `lib/providers/managers/data_cache_manager.dart`

**保持する状態**:
- `_dataService: DataService`
- `_items: List<ListItem>`
- `_shops: List<Shop>`
- `_isDataLoaded: bool`
- `_lastSyncTime: DateTime?`
- `_isLocalMode: bool`
- `_shouldUseAnonymousSession: bool Function()`

**公開メソッド**:
```dart
// Getter
List<ListItem> get items
List<Shop> get shops
bool get isDataLoaded
bool get isLocalMode

// データロード
Future<void> loadData()
Future<void> clearData()
void setLocalMode(bool isLocal)

// キャッシュ操作（Repository/Managerから呼び出し）
void addItemToCache(ListItem item)
void updateItemInCache(ListItem item)
void removeItemFromCache(String itemId)
void updateItems(List<ListItem> items) // リアルタイム同期用

void addShopToCache(Shop shop)
void updateShopInCache(Shop shop)
void removeShopFromCache(String shopId)
void updateShops(List<Shop> shops) // リアルタイム同期用

// 関連付け・重複除去
void associateItemsWithShops()
void removeDuplicateItems()
```

**キャッシュTTLロジック**:
```dart
Future<void> loadData() async {
  // 既にデータが読み込まれている場合はスキップ（5分キャッシュ）
  if (_isDataLoaded && _items.isNotEmpty) {
    if (_lastSyncTime != null && DateTime.now().difference(_lastSyncTime!).inMinutes < 5) {
      debugPrint('データは既に読み込まれているためスキップ');
      return;
    }
  }

  // データクリアしてから読み込み
  _items.clear();
  _shops.clear();

  // ローカルモードでない場合のみFirebaseから読み込み
  if (!_isLocalMode) {
    await Future.wait([
      _loadItems(),
      _loadShops(),
    ]).timeout(const Duration(seconds: 30));
  }

  // 関連付けと重複除去
  associateItemsWithShops();
  removeDuplicateItems();

  _isDataLoaded = true;
  _lastSyncTime = DateTime.now();
}
```

**依存関係**:
- `DataService` (Firebase読み込み)

---

## 依存関係図

```
┌────────────────────────────────────────────────────────┐
│                   DataProvider                         │
│                                                        │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │ AuthProvider │  │ DataService  │  │ChangeNotifier│ │
│  │   (外部)     │  │   (DI注入)    │  │  (継承)     │ │
│  └──────────────┘  └──────────────┘  └─────────────┘ │
└────────────────────────────────────────────────────────┘
         ↓                ↓                ↓
┌────────────────┐ ┌────────────────┐ ┌────────────────┐
│ItemRepository  │ │ShopRepository  │ │RealtimeSync    │
│                │ │                │ │  Manager       │
│  ┌──────────┐  │ │  ┌──────────┐  │ │                │
│  │DataCache │  │ │  │DataCache │  │ │  ┌──────────┐  │
│  │ Manager  │  │ │  │ Manager  │  │ │  │  Item    │  │
│  └──────────┘  │ │  └──────────┘  │ │  │Repository│  │
└────────────────┘ └────────────────┘ │  └──────────┘  │
         ↓                ↓           │  ┌──────────┐  │
┌────────────────┐ ┌────────────────┐ │  │  Shop    │  │
│SharedGroup     │ │DataCache       │ │  │Repository│  │
│  Manager       │ │  Manager       │ │  └──────────┘  │
│                │ │                │ │  ┌──────────┐  │
│  ┌──────────┐  │ │  ┌──────────┐  │ │  │DataCache │  │
│  │  Shop    │  │ │  │DataService│ │ │  │ Manager  │  │
│  │Repository│  │ │  └──────────┘  │ │  └──────────┘  │
│  └──────────┘  │ └────────────────┘ └────────────────┘
│  ┌──────────┐  │
│  │DataCache │  │
│  │ Manager  │  │
│  └──────────┘  │
└────────────────┘
```

**依存の方向**:
- DataProvider → 各Repository/Manager
- 各Repository/Manager → DataCacheManager
- 各Repository/Manager → DataService
- RealtimeSyncManager → ItemRepository, ShopRepository (pending updates確認)
- SharedGroupManager → ShopRepository (更新委譲)

**循環依存の回避**:
- Repository同士は直接依存しない
- ManagerがRepositoryを参照するのはOK（逆はNG)
- すべてがDataCacheManagerを参照するのはOK（中央キャッシュ）

---

## データフロー

### 1. アイテム追加のフロー

```
[ユーザー操作]
    ↓
[DataProvider.addItem()] ← UI層から呼び出し
    ↓
[ItemRepository.addItem()]
    ↓ (1) 楽観的更新
[DataCacheManager.addItemToCache()] ← ローカルキャッシュを即座に更新
    ↓
[DataProvider.notifyListeners()] ← UIを即座に更新
    ↓ (2) バックグラウンド保存
[DataService.saveItem()] ← Firebase保存
    ↓ (成功)
[完了]

    ↓ (失敗)
[DataCacheManager.removeItemFromCache()] ← ロールバック
    ↓
[DataProvider.notifyListeners()] ← UIを元に戻す
```

### 2. リアルタイム同期のフロー

```
[Firebase Firestore]
    ↓ (Streamイベント)
[RealtimeSyncManager._itemsSubscription]
    ↓
[バッチ更新中？] ── YES → スキップ
    ↓ NO
[ItemRepository.isPendingUpdate()] ← 楽観的更新の保護期間チェック
    ↓ (保護期間内)
[ローカル版を優先] ← 楽観的更新を上書きしない
    ↓ (保護期間外)
[リモート版を採用] ← Firestoreの最新データを反映
    ↓
[DataCacheManager.updateItems()] ← キャッシュを更新
    ↓
[DataCacheManager.associateItemsWithShops()] ← 関連付け
    ↓
[DataProvider.notifyListeners()] ← UIを更新
```

### 3. バッチ更新（並べ替え）のフロー

```
[ユーザー操作: ドラッグ&ドロップ]
    ↓
[DataProvider.reorderItems()]
    ↓
[RealtimeSyncManager.beginBatchUpdate()] ← notifyListeners()抑制開始
    ↓
[ItemRepository.updateItemsBatch()] ← 複数アイテムを一括更新
    ↓
[ShopRepository.updateShop()] ← ショップも更新
    ↓
[DataCacheManager.updateItems()] ← キャッシュ更新
[DataCacheManager.updateShopInCache()] ← キャッシュ更新
    ↓ (リアルタイム同期イベントが発生してもスキップされる)
[DataService.updateItem()] ← Firebase保存（並列実行）
[DataService.updateShop()] ← Firebase保存
    ↓
[RealtimeSyncManager.endBatchUpdate()] ← notifyListeners()抑制解除
    ↓
[DataProvider.notifyListeners()] ← 1回だけUIを更新
```

### 4. ログイン/ログアウトのフロー

```
[AuthProvider状態変更]
    ↓
[DataProvider._authListener] ← 認証状態変更を検知
    ↓ (ログイン)
[DataProvider._resetDataForLogin()]
    ↓
[RealtimeSyncManager.cancelRealtimeSync()] ← 旧ユーザーのStream停止
    ↓
[DataCacheManager.clearData()] ← データクリア
    ↓
[DataProvider.loadData()] ← 新ユーザーのデータをロード
    ↓
[DataCacheManager.loadData()] ← Firebase読み込み
    ↓
[RealtimeSyncManager.startRealtimeSync()] ← 新ユーザーのStream開始
    ↓
[DataProvider.notifyListeners()] ← UIを更新

    ↓ (ログアウト)
[DataProvider.clearData()]
    ↓
[RealtimeSyncManager.cancelRealtimeSync()] ← Stream停止
    ↓
[DataCacheManager.clearData()] ← データクリア
    ↓
[DataCacheManager.setLocalMode(true)] ← ローカルモードに切り替え
    ↓
[DataProvider.notifyListeners()] ← UIを更新
```

---

## 楽観的更新の仕組み

### 保護期間による競合回避

1. **ローカル更新時**:
   - `ItemRepository.updateItem()`が呼ばれる
   - `_pendingItemUpdates[item.id] = DateTime.now()`で保護期間開始（10秒）
   - ローカルキャッシュを即座に更新
   - UIに即座に反映
   - バックグラウンドでFirebase保存

2. **リアルタイム同期イベント受信時**:
   - `RealtimeSyncManager._itemsSubscription`でイベント受信
   - `ItemRepository.isPendingUpdate(item.id)`で保護期間チェック
   - **保護期間内**: ローカル版を優先（Firestoreの更新を無視）
   - **保護期間外**: リモート版を採用（Firestoreの最新データを反映）

3. **保護期間のクリーンアップ**:
   - 同期イベント受信時に`ItemRepository.cleanupPendingUpdates()`を呼び出し
   - 10秒以上経過したエントリを削除
   - メモリリークを防ぐ

### バッチ更新時の競合回避

1. **バッチ更新開始**:
   - `RealtimeSyncManager.beginBatchUpdate()`で`_isBatchUpdating = true`
   - `notifyListeners()`がオーバーライドでスキップされる
   - リアルタイム同期イベントもスキップされる

2. **バッチ処理**:
   - 複数のアイテム・ショップを一括更新
   - ローカルキャッシュを更新
   - Firebaseに並列保存（最大5件ずつ）

3. **バッチ更新完了**:
   - `RealtimeSyncManager.endBatchUpdate()`で`_isBatchUpdating = false`
   - `DataProvider.notifyListeners()`を1回だけ呼び出し
   - UIが一度に更新される（ちらつき防止）

---

## エラーハンドリング

### 楽観的更新のロールバック

```dart
Future<void> addItem(ListItem item) async {
  // 楽観的更新
  _cacheManager.addItemToCache(item);

  try {
    // Firebase保存
    await _dataService.saveItem(item, isAnonymous: _shouldUseAnonymousSession());
  } catch (e) {
    // エラー時はロールバック
    _cacheManager.removeItemFromCache(item.id);

    // エラーメッセージを整形して再throw
    if (e.toString().contains('permission-denied')) {
      throw Exception('権限がありません。ログイン状態を確認してください。');
    } else {
      throw Exception('アイテムの追加に失敗しました。ネットワーク接続を確認してください。');
    }
  }
}
```

### タイムアウト処理

```dart
Future<void> loadData() async {
  try {
    await Future.wait([
      _loadItems(),
      _loadShops(),
    ]).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('データ読み込みがタイムアウトしました', const Duration(seconds: 30));
      },
    );
  } catch (e) {
    debugPrint('データ読み込みエラー: $e');
    // デフォルトショップだけは確保
    await _shopRepository.ensureDefaultShop();
    rethrow;
  }
}
```

---

## テスト戦略

### 単体テスト

#### ItemRepository
```dart
test('addItem: 楽観的更新が成功する', () async {
  final mockDataService = MockDataService();
  final mockCacheManager = MockDataCacheManager();
  final repository = ItemRepository(
    dataService: mockDataService,
    cacheManager: mockCacheManager,
  );

  final item = ListItem(id: '1', name: 'テスト');
  await repository.addItem(item);

  verify(mockCacheManager.addItemToCache(item)).called(1);
  verify(mockDataService.saveItem(item, isAnonymous: false)).called(1);
});

test('addItem: Firebase保存失敗時にロールバックする', () async {
  final mockDataService = MockDataService();
  when(mockDataService.saveItem(any, isAnonymous: anyNamed('isAnonymous')))
    .thenThrow(Exception('network error'));

  final mockCacheManager = MockDataCacheManager();
  final repository = ItemRepository(...);

  final item = ListItem(id: '1', name: 'テスト');
  expect(() => repository.addItem(item), throwsException);

  verify(mockCacheManager.removeItemFromCache('1')).called(1);
});
```

#### RealtimeSyncManager
```dart
test('リアルタイム同期: 保護期間内はローカル版を優先', () async {
  final repository = MockItemRepository();
  when(repository.isPendingUpdate('1')).thenReturn(true);

  final cacheManager = MockDataCacheManager();
  when(cacheManager.items).thenReturn([
    ListItem(id: '1', name: 'ローカル版'),
  ]);

  final manager = RealtimeSyncManager(...);
  // Streamイベントをシミュレート
  final remoteItems = [ListItem(id: '1', name: 'リモート版')];
  // ... (内部ロジックのテスト)

  verify(cacheManager.updateItems(argThat(contains(ListItem(id: '1', name: 'ローカル版'))))).called(1);
});
```

### 統合テスト

```dart
testWidgets('アイテム追加→リアルタイム同期→削除の一連の流れ', (tester) async {
  await tester.pumpWidget(MyApp());

  // アイテム追加
  await tester.tap(find.byIcon(Icons.add));
  await tester.enterText(find.byType(TextField), 'テストアイテム');
  await tester.tap(find.text('保存'));
  await tester.pump();

  // UIに即座に反映されることを確認
  expect(find.text('テストアイテム'), findsOneWidget);

  // Firebase保存完了を待つ
  await tester.pumpAndSettle();

  // 削除
  await tester.drag(find.text('テストアイテム'), Offset(-500, 0));
  await tester.pumpAndSettle();

  expect(find.text('テストアイテム'), findsNothing);
});
```

---

## マイグレーション計画

### Phase 1: DataCacheManager分離
- `data_cache_manager.dart`を作成
- `loadData()`, `clearData()`, `items/shops`getterを移行
- DataProviderからは委譲のみ

### Phase 2: ItemRepository分離
- `item_repository.dart`を作成
- アイテムCRUDメソッドを移行
- `_pendingItemUpdates`を移行

### Phase 3: ShopRepository分離
- `shop_repository.dart`を作成
- ショップCRUDメソッドを移行
- `_pendingShopUpdates`を移行

### Phase 4: RealtimeSyncManager分離（最も複雑）
- `realtime_sync_manager.dart`を作成
- `_startRealtimeSync()`, `_cancelRealtimeSync()`を移行
- `_isBatchUpdating`フラグを移行
- 楽観的更新との連携を実装

### Phase 5: SharedGroupManager分離
- `shared_group_manager.dart`を作成
- 共有グループ関連メソッドを移行

### Phase 6: 最終リファクタリング
- DataProviderをファサードとして整理
- 不要なコードを削除
- ドキュメント更新

---

## パフォーマンス考慮事項

### notifyListeners()の最適化
- バッチ更新時は1回だけ呼び出し（`_isBatchUpdating`フラグ）
- リアルタイム同期時も無駄な通知を避ける

### Streamの購読数
- 分割後も`_itemsSubscription`, `_shopsSubscription`の2つのみ
- Repository分割によって購読数を増やさない

### キャッシュTTL
- 5分以内の再取得はスキップ
- `_isDataLoaded`, `_lastSyncTime`でキャッシュ管理

### 並列処理
- アイテム・ショップの読み込みは`Future.wait()`で並列実行
- バッチ更新時のFirebase保存も並列実行（最大5件ずつ）

---

## 将来の拡張性

### 新機能追加時の配置ガイドライン
- **アイテムに関する機能**: ItemRepositoryに追加
- **ショップに関する機能**: ShopRepositoryに追加
- **共有グループに関する機能**: SharedGroupManagerに追加
- **同期に関する機能**: RealtimeSyncManagerに追加
- **キャッシュに関する機能**: DataCacheManagerに追加

### 今後の改善案
- Riverpod等の最新状態管理への移行検討
- Repository層のインターフェース化（テスタビリティ向上）
- オフラインキューイング機能の追加（DataCacheManagerに実装）
