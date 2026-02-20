# テスト計画: テストカバレッジ向上 Phase 1（Issue #90）

## テスト方針

### アプローチ

- **ユニットテスト**のみ（Widgetテスト・統合テストは対象外）
- 既存の `mockito` + `MockDataService` パターンを踏襲
- Firebase依存は全て `MockDataService` でモック
- `DataCacheManager` は手動Fakeで代替（テスト容易性のため）

### テストパターン

```dart
// 共通セットアップパターン
late MockDataService mockDataService;
late FakeDataCacheManager fakeCacheManager;
late DataProviderState state;
late ItemRepository repository;

setUp(() {
  mockDataService = MockDataService();
  fakeCacheManager = FakeDataCacheManager();
  state = DataProviderState(notifyListeners: () {});
  repository = ItemRepository(
    dataService: mockDataService,
    cacheManager: fakeCacheManager,
    state: state,
  );
});
```

## 重点テストケース

### 楽観的更新 + ロールバック（ItemRepository）

1. `addItem` → キャッシュに即追加 → Firebase成功 → キャッシュに残る
2. `addItem` → キャッシュに即追加 → Firebase失敗 → キャッシュから除去
3. `deleteItem` → キャッシュから即除去 → Firebase成功 → 除去のまま
4. `deleteItem` → キャッシュから即除去 → Firebase失敗 → キャッシュに復元

### バウンス抑止（ItemRepository/ShopRepository）

1. `updateItem` → `pendingUpdates` にIDが登録される
2. `pendingUpdates` に登録されたIDは一定時間後にクリアされる

### sharedTabs連携（ShopRepository.deleteShop）

1. 他shopのsharedTabsに削除対象IDが含まれる → 除去される
2. sharedTabsが空になった場合の処理

## テスト実行

```bash
# 個別テスト実行
flutter test test/providers/repositories/item_repository_test.dart
flutter test test/providers/repositories/shop_repository_test.dart

# 全テスト実行
flutter test

# Lint確認
flutter analyze
```

## 成功基準

- [ ] ItemRepositoryの全パブリックメソッドにテストがある
- [ ] ShopRepositoryの全パブリックメソッドにテストがある
- [ ] 楽観的更新のロールバックパスがカバーされている
- [ ] `flutter test` 全テスト通過
- [ ] `flutter analyze` Lintエラーなし
