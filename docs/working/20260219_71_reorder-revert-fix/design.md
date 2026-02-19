# 設計書

## 実装方針

### 変更対象ファイル

- `lib/providers/repositories/item_repository.dart` - `reorderItems()`メソッドにキャッシュ更新後の即時通知を追加

### 新規作成ファイル

- なし

## 修正内容

### 現在の処理フロー（問題あり）

```
reorderItems()
├── pendingUpdates タイムスタンプ設定（同期）
├── _cacheManager.shops 更新（同期）
├── _cacheManager.items 更新（同期）
├── await _dataService.updateShop()  ← ここでイベントループに制御移行
├── await _dataService.updateItem() × N
└── return（runBatchUpdate.finally で notifyListeners）
```

### 修正後の処理フロー

```
reorderItems()
├── pendingUpdates タイムスタンプ設定（同期）
├── _cacheManager.shops 更新（同期）
├── _cacheManager.items 更新（同期）
├── _state.notifyListeners()  ← ★追加：UI即時更新
├── await _dataService.updateShop()
├── await _dataService.updateItem() × N
└── return（runBatchUpdate.finally で notifyListeners → 重複だが無害）
```

### 修正コード

`item_repository.dart`の`reorderItems()`メソッド、キャッシュ更新ループの直後（`if (!_cacheManager.isLocalMode)` の前）に以下を追加:

```dart
// 即座にUI更新（ReorderableListViewの巻き戻り防止）
_state.notifyListeners();
```

## 影響範囲

- `RealtimeSyncManager.runBatchUpdate()` - `finally`ブロックの`notifyListeners()`は2回目の呼び出しとなるが、`ChangeNotifier`の仕様上、リスナーが再度呼ばれるだけで副作用なし
- `DataProvider.reorderItems()` - 変更不要
- `ItemListSection` / `ReorderableListView` - 変更不要（`Consumer<DataProvider>`が再ビルドを受けるだけ）

## Flutter固有の注意点

- `ReorderableListView`は`onReorder`コールバック後、次フレームで`itemBuilder`を呼び直すため、その時点でデータモデルが更新済みである必要がある
- `notifyListeners()`はウィジェットの再ビルドをスケジュールするだけで同期的にビルドは走らない。実際の再ビルドは次フレームで行われる
- `isBatchUpdating = true`の間に`notifyListeners()`を呼んでも、Firestoreリスナーのスキップ処理には影響しない（`isBatchUpdating`チェックはリスナーコールバック内で行われるため）
