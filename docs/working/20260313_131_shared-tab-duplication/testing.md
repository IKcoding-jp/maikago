# テスト計画

## テスト戦略

### ユニットテスト

- `test/providers/managers/data_cache_manager_test.dart`
  - `removeDuplicateShops()`: 重複ショップが除去されること
  - `removeDuplicateShops()`: 重複がない場合に変更がないこと
  - `removeDuplicateShops()`: 空リストで安全に動作すること

- `test/providers/managers/shared_group_manager_test.dart`
  - クロスリファレンス: 新規タブを既存共有グループに追加した場合、全タブの `sharedTabs` が正しいこと
  - クロスリファレンス: A↔B共有済みにCを追加 → B.sharedTabs=[A,C], C.sharedTabs=[A,B]
  - クロスリファレンス: 共有グループからタブを除去した場合、全タブの参照が更新されること

### 手動テスト（再現確認）

- [ ] タブ A, B を共有グループに設定
- [ ] 新規タブ C を作成し、A の編集画面で共有に追加
- [ ] アプリを再起動
- [ ] タブ数が変わらないことを確認（A, B, C の3つ）
- [ ] B の編集画面で C が共有タブとして表示されることを確認
- [ ] C の編集画面で A, B が共有タブとして表示されることを確認

## テスト実行コマンド

```bash
flutter test
flutter analyze
```
