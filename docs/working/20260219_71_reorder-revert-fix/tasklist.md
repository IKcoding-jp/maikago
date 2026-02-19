# タスクリスト

## フェーズ1: 修正実装

- [x] `lib/providers/repositories/item_repository.dart`の`reorderItems()`メソッドで、キャッシュ更新直後（Firebase書き込み前）に`_state.notifyListeners()`を追加

## フェーズ2: 検証

- [ ] `flutter analyze` でエラーがないことを確認
- [ ] `flutter test` で既存テストがすべてパスすることを確認
- [ ] 手動テスト：未購入リストの並べ替えが即座に反映されること
- [ ] 手動テスト：購入済みリストの並べ替えが即座に反映されること

## 依存関係

- フェーズ1 → フェーズ2（順次実行）
