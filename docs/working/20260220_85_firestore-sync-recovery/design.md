# 設計書

## 実装方針

### 設計原則

- 既存のファサードパターン（DataProvider → Repository/Manager委譲）を維持
- リアルタイム購読の状態管理を `RealtimeSyncManager` 内に閉じ込める
- TTLキャッシュ（データ読み込み最適化）とリアルタイム購読（同期接続）の責務を明確に分離

### 変更対象ファイル

#### 1. `lib/providers/managers/realtime_sync_manager.dart`
- 購読アクティブ状態プロパティ `isSubscriptionActive` の追加
- 指数バックオフ付き自動再購読メカニズムの実装
- `onError` コールバックの強化

```dart
// 追加するプロパティ・メソッドのイメージ
bool get isSubscriptionActive =>
    _itemsSubscription != null && _shopsSubscription != null;

int _retryCount = 0;
static const int _maxRetries = 5;
Timer? _retryTimer;

void _scheduleRetry() {
  if (_retryCount >= _maxRetries) {
    DebugService().log('リアルタイム同期: 最大リトライ回数に到達');
    return;
  }
  final delay = Duration(seconds: math.min(pow(2, _retryCount).toInt(), 300));
  _retryCount++;
  _retryTimer = Timer(delay, () {
    startRealtimeSync();
  });
}

void _resetRetryCount() {
  _retryCount = 0;
  _retryTimer?.cancel();
}
```

#### 2. `lib/providers/managers/data_cache_manager.dart`
- `loadData()` の早期リターン条件を「データ読み込み」のみに限定
- リアルタイム購読の開始判定を呼び出し元（DataProvider）に委ねる
- `clearLastSyncTime()` メソッドの追加（認証変更時にTTLリセット用）

```dart
// 変更イメージ
Future<void> loadData({bool forceReload = false}) async {
  // TTLチェックはデータの再読み込みのみに影響
  // リアルタイム購読の開始判定はここでは行わない
  if (!forceReload && _isDataLoaded && _items.isNotEmpty) {
    if (_lastSyncTime != null &&
        DateTime.now().difference(_lastSyncTime!).inMinutes < 5) {
      DebugService().log('データは既に読み込まれているためスキップ');
      return;
    }
  }
  // ... 以下既存ロジック
}

void clearLastSyncTime() {
  _lastSyncTime = null;
}
```

#### 3. `lib/providers/data_provider.dart`
- `loadData()` でTTL結果に関わらずリアルタイム購読状態を確認
- `_resetDataForLogin()` でTTLキャッシュをリセット
- ローカルモード切り替え時のリスナー管理を整理

```dart
// 変更イメージ: loadData() 内
Future<void> loadData() async {
  // ... 既存のデータ読み込みロジック

  // リアルタイム同期: 購読状態を確認し、未確立なら開始
  if (!_cacheManager.isLocalMode && !_syncManager.isSubscriptionActive) {
    DebugService().log('リアルタイム同期を開始（購読未確立のため）');
    _syncManager.startRealtimeSync();
  }
}

// 変更イメージ: _resetDataForLogin()
void _resetDataForLogin() {
  _syncManager.cancelRealtimeSync();
  _cacheManager.clearData();
  _cacheManager.clearLastSyncTime(); // TTLリセット追加
  _state.isSynced = false;
}
```

#### 4. `lib/providers/data_provider_state.dart`
- 同期接続状態の追加（オプション）

### 新規作成ファイル

なし（既存ファイルの修正のみ）

## 影響範囲

- `DataProvider` のファサードインターフェースは変更なし（外部API互換）
- `RealtimeSyncManager` の内部実装変更（購読状態追跡・リトライ追加）
- `DataCacheManager` のTTLロジック変更（リアルタイム購読との分離）
- バッチ更新（`isBatchUpdating`）・楽観的更新（`pendingUpdates`）のロジックへの影響なし

## Flutter固有の注意点

- **Provider依存関係**: `DataProvider` → `RealtimeSyncManager` → `DataCacheManager` の依存方向は変更なし
- **プラットフォーム分岐（kIsWeb）**: Web版でも同様のリアルタイム同期が使われているため、修正はプラットフォーム共通
- **data_provider.dart**: ファサードパターンを維持。`loadData()` 内のリアルタイム購読確認ロジックのみ追加
- **Timer/指数バックオフ**: `dart:async` の `Timer` を使用。アプリ破棄時に `_retryTimer?.cancel()` を確実に呼ぶ

## リスクと対策

| リスク | 対策 |
|--------|------|
| 指数バックオフで無限リトライ | 最大5回、最大待機5分で制限 |
| リトライ中にログアウト | `cancelRealtimeSync()` でタイマーもキャンセル |
| 購読状態プロパティの不整合 | `startRealtimeSync` / `cancelRealtimeSync` 内でのみ更新 |
| TTLリセットによるFirestore読み取り増加 | 認証変更時のみリセットするため、通常使用では影響なし |
