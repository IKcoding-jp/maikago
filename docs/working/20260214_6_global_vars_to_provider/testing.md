# テスト計画

## テスト戦略

### ユニットテスト
- `test/providers/theme_provider_test.dart`
  - 初期値が正しいこと（pink, nunito, 16.0）
  - `updateTheme()`で`notifyListeners()`が呼ばれること
  - `updateFont()`でフォント名が更新されること
  - `updateFontSize()`でサイズが更新されること
  - `initFromPersistence()`で保存値が復元されること

### 手動確認
- テーマ変更が即時反映される
- フォント変更が即時反映される
- フォントサイズ変更が即時反映される
- アプリ再起動後に全設定が復元される

## テスト実行コマンド
```bash
flutter test test/providers/theme_provider_test.dart
```
