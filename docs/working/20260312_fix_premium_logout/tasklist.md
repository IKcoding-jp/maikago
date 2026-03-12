# タスクリスト

## フェーズ1: OneTimePurchaseServiceにリセット機能追加
- [ ] `resetForLogout()` メソッドを追加（`_currentUserId` を空文字にリセット + `notifyListeners()`）
- [ ] `isPremiumUnlocked` が `_currentUserId` 空文字時に `false` を返すことを確認

## フェーズ2: AuthProviderからリセット呼び出し
- [ ] `_updateServicesForUser(null)` の else 分岐で `_purchaseService.resetForLogout()` を呼び出す

## フェーズ3: テスト
- [ ] 既存テストが通ることを確認（`flutter test`）
- [ ] ログアウト→プレミアムリセットのユニットテスト追加（可能であれば）

## 依存関係
- フェーズ1 → フェーズ2（順次実行）
- フェーズ3はフェーズ2完了後
