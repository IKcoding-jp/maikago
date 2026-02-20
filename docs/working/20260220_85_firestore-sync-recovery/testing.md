# テスト計画

## テスト戦略

### ユニットテスト

#### RealtimeSyncManager テスト
- `test/providers/managers/realtime_sync_manager_test.dart`
  - `isSubscriptionActive` が購読開始時に `true` になること
  - `isSubscriptionActive` がキャンセル時に `false` になること
  - `onError` 発生時に自動再購読がスケジュールされること
  - 指数バックオフの待機時間が正しいこと（1s, 2s, 4s, 8s, 16s）
  - 最大リトライ回数（5回）を超えたらリトライ停止すること
  - `cancelRealtimeSync()` でリトライタイマーもキャンセルされること
  - ローカルモード時は購読が開始されないこと

#### DataCacheManager テスト
- `test/providers/managers/data_cache_manager_test.dart`
  - TTLチェックで早期リターンしてもリアルタイム購読に影響しないこと
  - `clearLastSyncTime()` でTTLがリセットされること
  - `forceReload = true` でTTLを無視してデータ再読み込みすること

#### DataProvider テスト
- `test/providers/data_provider_test.dart`
  - `loadData()` でリアルタイム購読が未確立なら `startRealtimeSync()` が呼ばれること
  - TTLキャッシュ有効でも購読未確立なら `startRealtimeSync()` が呼ばれること
  - `_resetDataForLogin()` で `clearLastSyncTime()` が呼ばれること
  - ログアウト→ログインシーケンスで購読が正しく再開されること
  - ローカルモード切り替え時にリスナーが適切に管理されること

### 統合テスト（手動）

#### シナリオ1: ログアウト→5分以内にログイン
1. アプリにログイン、リアルタイム同期が動作していることを確認
2. ログアウト
3. 5分以内にログイン
4. 別デバイスまたはFirebaseコンソールでデータを変更
5. **期待**: 変更がリアルタイムで反映される

#### シナリオ2: ネットワーク切断→復帰
1. アプリにログイン、リアルタイム同期が動作していることを確認
2. 機内モードをON（ネットワーク切断）
3. 30秒待機
4. 機内モードをOFF（ネットワーク復帰）
5. 別デバイスまたはFirebaseコンソールでデータを変更
6. **期待**: 変更がリアルタイムで反映される

#### シナリオ3: 複数回のloadData()呼び出し
1. アプリにログイン
2. 画面遷移を繰り返す（loadData()が複数回呼ばれる状況）
3. 別デバイスまたはFirebaseコンソールでデータを変更
4. **期待**: 変更がリアルタイムで反映される

#### シナリオ4: バックグラウンド→フォアグラウンド
1. アプリにログイン
2. ホームに戻る（バックグラウンド）
3. 5分以上待機
4. アプリを再度開く（フォアグラウンド）
5. 別デバイスまたはFirebaseコンソールでデータを変更
6. **期待**: 変更がリアルタイムで反映される

## テスト実行コマンド

```bash
# 全テスト実行
flutter test

# 関連テストのみ
flutter test test/providers/managers/realtime_sync_manager_test.dart
flutter test test/providers/managers/data_cache_manager_test.dart
flutter test test/providers/data_provider_test.dart

# 静的分析
flutter analyze
```

## 回帰テスト確認項目

- [ ] 既存のバッチ更新（複数アイテム一括操作）が正常に動作すること
- [ ] 楽観的更新（即座のUI反映）が正常に動作すること
- [ ] 共有グループでの他ユーザーの変更が反映されること
- [ ] ローカルモード（未ログイン）での動作に影響がないこと
- [ ] Web版での同期が正常に動作すること
