# テスト計画

**Issue**: #3 - data_provider.dart責務分割
**作成日**: 2026-02-14

## テスト戦略概要

### テストレベル

| レベル | 対象 | 目的 | ツール | カバレッジ目標 |
|--------|------|------|--------|---------------|
| 単体テスト | 各Repository/Manager | ロジックの正確性確認 | flutter test + mockito | 70%以上 |
| 統合テスト | DataProvider全体 | クラス間連携の確認 | flutter test | 主要フロー100% |
| ウィジェットテスト | UI層との連携 | 画面操作の動作確認 | flutter test + flutter_test | 主要画面100% |
| E2Eテスト | アプリ全体 | エンドツーエンドの動作確認 | 手動テスト | 主要シナリオ100% |

---

## Phase 0: テスト準備

### 既存テストの確認

**タスク**:
- [ ] `flutter test`を実行して現在のテストカバレッジを確認
- [ ] テストが失敗している場合は原因を特定して修正
- [ ] カバレッジレポートを生成（`flutter test --coverage`）

**コマンド**:
```bash
# テスト実行
flutter test

# カバレッジレポート生成
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

**期待結果**:
- すべての既存テストがパス
- カバレッジレポートが生成される

---

## Phase 1: DataCacheManager テスト

### 単体テスト

**ファイルパス**: `test/providers/managers/data_cache_manager_test.dart`

#### テストケース

##### TC1-1: データロード（初回）
```dart
test('loadData: 初回ロード時にFirebaseからデータを取得する', () async {
  // Arrange
  final mockDataService = MockDataService();
  when(mockDataService.getItemsOnce(isAnonymous: false))
    .thenAnswer((_) async => [ListItem(id: '1', name: 'テスト')]);
  when(mockDataService.getShopsOnce(isAnonymous: false))
    .thenAnswer((_) async => [Shop(id: '1', name: 'テストショップ', items: [])]);

  final cacheManager = DataCacheManager(
    dataService: mockDataService,
    shouldUseAnonymousSession: () => false,
  );

  // Act
  await cacheManager.loadData();

  // Assert
  expect(cacheManager.items.length, 1);
  expect(cacheManager.shops.length, 1);
  expect(cacheManager.isDataLoaded, true);
  verify(mockDataService.getItemsOnce(isAnonymous: false)).called(1);
  verify(mockDataService.getShopsOnce(isAnonymous: false)).called(1);
});
```

##### TC1-2: キャッシュTTL（5分以内）
```dart
test('loadData: 5分以内の再取得はスキップする', () async {
  // Arrange
  final mockDataService = MockDataService();
  when(mockDataService.getItemsOnce(isAnonymous: false))
    .thenAnswer((_) async => [ListItem(id: '1', name: 'テスト')]);
  when(mockDataService.getShopsOnce(isAnonymous: false))
    .thenAnswer((_) async => [Shop(id: '1', name: 'テストショップ', items: [])]);

  final cacheManager = DataCacheManager(
    dataService: mockDataService,
    shouldUseAnonymousSession: () => false,
  );

  // Act
  await cacheManager.loadData(); // 1回目
  await cacheManager.loadData(); // 2回目（5分以内）

  // Assert
  verify(mockDataService.getItemsOnce(isAnonymous: false)).called(1); // 1回だけ
  verify(mockDataService.getShopsOnce(isAnonymous: false)).called(1); // 1回だけ
});
```

##### TC1-3: ローカルモード時はFirebase読み込みをスキップ
```dart
test('loadData: ローカルモード時はFirebaseから読み込まない', () async {
  // Arrange
  final mockDataService = MockDataService();
  final cacheManager = DataCacheManager(
    dataService: mockDataService,
    shouldUseAnonymousSession: () => false,
  );
  cacheManager.setLocalMode(true);

  // Act
  await cacheManager.loadData();

  // Assert
  verifyNever(mockDataService.getItemsOnce(isAnonymous: anyNamed('isAnonymous')));
  verifyNever(mockDataService.getShopsOnce(isAnonymous: anyNamed('isAnonymous')));
});
```

##### TC1-4: アイテムとショップの関連付け
```dart
test('associateItemsWithShops: アイテムを対応するショップに正しく関連付ける', () {
  // Arrange
  final cacheManager = DataCacheManager(...);
  final shop1 = Shop(id: '1', name: 'ショップ1', items: []);
  final shop2 = Shop(id: '2', name: 'ショップ2', items: []);
  final item1 = ListItem(id: '1', name: 'アイテム1', shopId: '1');
  final item2 = ListItem(id: '2', name: 'アイテム2', shopId: '2');

  cacheManager.updateShops([shop1, shop2]);
  cacheManager.updateItems([item1, item2]);

  // Act
  cacheManager.associateItemsWithShops();

  // Assert
  expect(cacheManager.shops[0].items.length, 1);
  expect(cacheManager.shops[0].items[0].id, '1');
  expect(cacheManager.shops[1].items.length, 1);
  expect(cacheManager.shops[1].items[0].id, '2');
});
```

##### TC1-5: 重複除去
```dart
test('removeDuplicateItems: 重複したアイテムを除去する', () {
  // Arrange
  final cacheManager = DataCacheManager(...);
  final item1 = ListItem(id: '1', name: 'アイテム1');
  final item2 = ListItem(id: '1', name: 'アイテム1（重複）');

  cacheManager.updateItems([item1, item2]);

  // Act
  cacheManager.removeDuplicateItems();

  // Assert
  expect(cacheManager.items.length, 1);
  expect(cacheManager.items[0].name, 'アイテム1');
});
```

##### TC1-6: データクリア
```dart
test('clearData: データとフラグをすべてクリアする', () async {
  // Arrange
  final cacheManager = DataCacheManager(...);
  await cacheManager.loadData(); // データをロード

  // Act
  cacheManager.clearData();

  // Assert
  expect(cacheManager.items.length, 0);
  expect(cacheManager.shops.length, 0);
  expect(cacheManager.isDataLoaded, false);
});
```

---

## Phase 2: ItemRepository テスト

### 単体テスト

**ファイルパス**: `test/providers/repositories/item_repository_test.dart`

#### テストケース

##### TC2-1: アイテム追加（成功）
```dart
test('addItem: アイテムを正常に追加する', () async {
  // Arrange
  final mockDataService = MockDataService();
  final mockCacheManager = MockDataCacheManager();
  final repository = ItemRepository(
    dataService: mockDataService,
    cacheManager: mockCacheManager,
    shouldUseAnonymousSession: () => false,
  );

  final item = ListItem(id: '1', name: 'テスト', shopId: '1');

  // Act
  await repository.addItem(item);

  // Assert
  verify(mockCacheManager.addItemToCache(item)).called(1);
  verify(mockDataService.saveItem(item, isAnonymous: false)).called(1);
});
```

##### TC2-2: アイテム追加（Firebase保存失敗時のロールバック）
```dart
test('addItem: Firebase保存失敗時にロールバックする', () async {
  // Arrange
  final mockDataService = MockDataService();
  when(mockDataService.saveItem(any, isAnonymous: anyNamed('isAnonymous')))
    .thenThrow(Exception('network error'));

  final mockCacheManager = MockDataCacheManager();
  final repository = ItemRepository(...);

  final item = ListItem(id: '1', name: 'テスト', shopId: '1');

  // Act & Assert
  expect(() => repository.addItem(item), throwsException);
  verify(mockCacheManager.removeItemFromCache('1')).called(1);
});
```

##### TC2-3: アイテム更新
```dart
test('updateItem: アイテムを正常に更新する', () async {
  // Arrange
  final mockDataService = MockDataService();
  final mockCacheManager = MockDataCacheManager();
  final repository = ItemRepository(...);

  final item = ListItem(id: '1', name: '更新後', shopId: '1');

  // Act
  await repository.updateItem(item);

  // Assert
  verify(mockCacheManager.updateItemInCache(item)).called(1);
  verify(mockDataService.updateItem(item, isAnonymous: false)).called(1);
  expect(repository.isPendingUpdate('1'), true);
});
```

##### TC2-4: バッチ更新
```dart
test('updateItemsBatch: 複数アイテムを一括更新する', () async {
  // Arrange
  final mockDataService = MockDataService();
  final mockCacheManager = MockDataCacheManager();
  final repository = ItemRepository(...);

  final items = [
    ListItem(id: '1', name: 'アイテム1', shopId: '1'),
    ListItem(id: '2', name: 'アイテム2', shopId: '1'),
  ];

  // Act
  await repository.updateItemsBatch(items);

  // Assert
  verify(mockCacheManager.updateItemInCache(items[0])).called(1);
  verify(mockCacheManager.updateItemInCache(items[1])).called(1);
  verify(mockDataService.updateItem(items[0], isAnonymous: false)).called(1);
  verify(mockDataService.updateItem(items[1], isAnonymous: false)).called(1);
  expect(repository.isPendingUpdate('1'), true);
  expect(repository.isPendingUpdate('2'), true);
});
```

##### TC2-5: アイテム削除
```dart
test('deleteItem: アイテムを正常に削除する', () async {
  // Arrange
  final mockDataService = MockDataService();
  final mockCacheManager = MockDataCacheManager();
  when(mockCacheManager.items).thenReturn([
    ListItem(id: '1', name: 'テスト', shopId: '1'),
  ]);

  final repository = ItemRepository(...);

  // Act
  await repository.deleteItem('1');

  // Assert
  verify(mockCacheManager.removeItemFromCache('1')).called(1);
  verify(mockDataService.deleteItem('1', isAnonymous: false)).called(1);
});
```

##### TC2-6: バウンス抑止のクリーンアップ
```dart
test('cleanupPendingUpdates: 10秒以上経過したエントリを削除する', () {
  // Arrange
  final repository = ItemRepository(...);
  repository.markAsPending('1'); // 10秒以上前に登録されたと仮定

  // 10秒待機
  Future.delayed(Duration(seconds: 11));

  // Act
  repository.cleanupPendingUpdates();

  // Assert
  expect(repository.isPendingUpdate('1'), false);
});
```

---

## Phase 3: ShopRepository テスト

### 単体テスト

**ファイルパス**: `test/providers/repositories/shop_repository_test.dart`

#### テストケース

##### TC3-1: ショップ追加
```dart
test('addShop: ショップを正常に追加する', () async {
  // Arrange
  final mockDataService = MockDataService();
  final mockCacheManager = MockDataCacheManager();
  final repository = ShopRepository(...);

  final shop = Shop(id: '1', name: 'テストショップ', items: []);

  // Act
  await repository.addShop(shop);

  // Assert
  verify(mockCacheManager.addShopToCache(shop)).called(1);
  verify(mockDataService.saveShop(shop, isAnonymous: false)).called(1);
});
```

##### TC3-2: デフォルトショップ自動作成
```dart
test('ensureDefaultShop: デフォルトショップが存在しない場合のみ作成する', () async {
  // Arrange
  final mockCacheManager = MockDataCacheManager();
  when(mockCacheManager.isLocalMode).thenReturn(true);
  when(mockCacheManager.shops).thenReturn([]);

  final repository = ShopRepository(...);

  // Act
  await repository.ensureDefaultShop();

  // Assert
  verify(mockCacheManager.addShopToCache(argThat(
    predicate<Shop>((shop) => shop.id == '0' && shop.name == 'デフォルト')
  ))).called(1);
});
```

##### TC3-3: デフォルトショップが既に存在する場合は作成しない
```dart
test('ensureDefaultShop: デフォルトショップが既に存在する場合は作成しない', () async {
  // Arrange
  final mockCacheManager = MockDataCacheManager();
  when(mockCacheManager.isLocalMode).thenReturn(true);
  when(mockCacheManager.shops).thenReturn([
    Shop(id: '0', name: 'デフォルト', items: []),
  ]);

  final repository = ShopRepository(...);

  // Act
  await repository.ensureDefaultShop();

  // Assert
  verifyNever(mockCacheManager.addShopToCache(any));
});
```

##### TC3-4: ショップ削除時の共有タブ参照削除
```dart
test('deleteShop: 削除されたタブを他のタブのsharedTabsから削除する', () async {
  // Arrange
  final mockCacheManager = MockDataCacheManager();
  when(mockCacheManager.shops).thenReturn([
    Shop(id: '1', name: 'ショップ1', items: [], sharedTabs: ['2']),
    Shop(id: '2', name: 'ショップ2', items: [], sharedTabs: ['1']),
  ]);

  final repository = ShopRepository(...);

  // Act
  await repository.deleteShop('2');

  // Assert
  verify(mockCacheManager.removeShopFromCache('2')).called(1);
  verify(mockCacheManager.updateShopInCache(argThat(
    predicate<Shop>((shop) => shop.id == '1' && shop.sharedTabs.isEmpty)
  ))).called(1);
});
```

##### TC3-5: ショップ名更新
```dart
test('updateShopName: ショップ名を正常に更新する', () {
  // Arrange
  final mockCacheManager = MockDataCacheManager();
  when(mockCacheManager.shops).thenReturn([
    Shop(id: '1', name: '旧名前', items: []),
  ]);

  final repository = ShopRepository(...);

  // Act
  repository.updateShopName(0, '新名前');

  // Assert
  verify(mockCacheManager.updateShopInCache(argThat(
    predicate<Shop>((shop) => shop.id == '1' && shop.name == '新名前')
  ))).called(1);
});
```

---

## Phase 4: RealtimeSyncManager テスト

### 単体テスト

**ファイルパス**: `test/providers/managers/realtime_sync_manager_test.dart`

#### テストケース

##### TC4-1: リアルタイム同期開始
```dart
test('startRealtimeSync: Streamを購読する', () {
  // Arrange
  final mockDataService = MockDataService();
  final streamController = StreamController<List<ListItem>>();
  when(mockDataService.getItems(isAnonymous: false))
    .thenAnswer((_) => streamController.stream);

  final manager = RealtimeSyncManager(...);

  // Act
  manager.startRealtimeSync();

  // Assert
  verify(mockDataService.getItems(isAnonymous: false)).called(1);
});
```

##### TC4-2: 保護期間内はローカル版を優先
```dart
test('リアルタイム同期: 保護期間内はローカル版を優先する', () async {
  // Arrange
  final mockItemRepository = MockItemRepository();
  when(mockItemRepository.isPendingUpdate('1')).thenReturn(true);

  final mockCacheManager = MockDataCacheManager();
  when(mockCacheManager.items).thenReturn([
    ListItem(id: '1', name: 'ローカル版'),
  ]);

  final manager = RealtimeSyncManager(
    itemRepository: mockItemRepository,
    cacheManager: mockCacheManager,
    ...
  );

  final streamController = StreamController<List<ListItem>>();
  when(mockDataService.getItems(isAnonymous: false))
    .thenAnswer((_) => streamController.stream);

  manager.startRealtimeSync();

  // Act
  streamController.add([ListItem(id: '1', name: 'リモート版')]);
  await Future.delayed(Duration(milliseconds: 100));

  // Assert
  verify(mockCacheManager.updateItems(argThat(
    predicate<List<ListItem>>((items) => items[0].name == 'ローカル版')
  ))).called(1);
});
```

##### TC4-3: 保護期間外はリモート版を採用
```dart
test('リアルタイム同期: 保護期間外はリモート版を採用する', () async {
  // Arrange
  final mockItemRepository = MockItemRepository();
  when(mockItemRepository.isPendingUpdate('1')).thenReturn(false);

  final mockCacheManager = MockDataCacheManager();
  when(mockCacheManager.items).thenReturn([
    ListItem(id: '1', name: 'ローカル版'),
  ]);

  final manager = RealtimeSyncManager(...);

  final streamController = StreamController<List<ListItem>>();
  when(mockDataService.getItems(isAnonymous: false))
    .thenAnswer((_) => streamController.stream);

  manager.startRealtimeSync();

  // Act
  streamController.add([ListItem(id: '1', name: 'リモート版')]);
  await Future.delayed(Duration(milliseconds: 100));

  // Assert
  verify(mockCacheManager.updateItems(argThat(
    predicate<List<ListItem>>((items) => items[0].name == 'リモート版')
  ))).called(1);
});
```

##### TC4-4: バッチ更新中は同期をスキップ
```dart
test('リアルタイム同期: バッチ更新中は同期をスキップする', () async {
  // Arrange
  final manager = RealtimeSyncManager(...);

  final streamController = StreamController<List<ListItem>>();
  when(mockDataService.getItems(isAnonymous: false))
    .thenAnswer((_) => streamController.stream);

  manager.startRealtimeSync();

  // Act
  manager.beginBatchUpdate();
  streamController.add([ListItem(id: '1', name: 'リモート版')]);
  await Future.delayed(Duration(milliseconds: 100));

  // Assert
  verifyNever(mockCacheManager.updateItems(any));

  // バッチ更新終了後は同期する
  manager.endBatchUpdate();
  streamController.add([ListItem(id: '1', name: 'リモート版2')]);
  await Future.delayed(Duration(milliseconds: 100));

  verify(mockCacheManager.updateItems(any)).called(1);
});
```

##### TC4-5: 同期停止
```dart
test('cancelRealtimeSync: Streamの購読を停止する', () {
  // Arrange
  final manager = RealtimeSyncManager(...);
  manager.startRealtimeSync();

  // Act
  manager.cancelRealtimeSync();

  // Assert
  // 内部のSubscriptionがcancelされていることを確認
  // (実装により検証方法が異なる)
});
```

---

## Phase 5: SharedGroupManager テスト

### 単体テスト

**ファイルパス**: `test/providers/managers/shared_group_manager_test.dart`

#### テストケース

##### TC5-1: 共有グループ作成
```dart
test('updateSharedGroup: 共有グループを正常に作成する', () async {
  // Arrange
  final mockShopRepository = MockShopRepository();
  final mockCacheManager = MockDataCacheManager();
  when(mockCacheManager.shops).thenReturn([
    Shop(id: '1', name: 'ショップ1', items: [], sharedTabs: []),
    Shop(id: '2', name: 'ショップ2', items: [], sharedTabs: []),
  ]);

  final manager = SharedGroupManager(
    shopRepository: mockShopRepository,
    cacheManager: mockCacheManager,
    ...
  );

  // Act
  await manager.updateSharedGroup('1', ['2'], sharedGroupIcon: '🛒');

  // Assert
  // ショップ1が更新される
  verify(mockShopRepository.updateShop(argThat(
    predicate<Shop>((shop) =>
      shop.id == '1' &&
      shop.sharedTabs.contains('2') &&
      shop.sharedGroupIcon == '🛒'
    )
  ))).called(1);

  // ショップ2も更新される
  verify(mockShopRepository.updateShop(argThat(
    predicate<Shop>((shop) =>
      shop.id == '2' &&
      shop.sharedTabs.contains('1') &&
      shop.sharedGroupIcon == '🛒'
    )
  ))).called(1);
});
```

##### TC5-2: 共有グループ解除
```dart
test('removeFromSharedGroup: 共有グループから正常に削除する', () async {
  // Arrange
  final mockCacheManager = MockDataCacheManager();
  when(mockCacheManager.shops).thenReturn([
    Shop(id: '1', name: 'ショップ1', items: [], sharedTabs: ['2'], sharedGroupId: 'group1'),
    Shop(id: '2', name: 'ショップ2', items: [], sharedTabs: ['1'], sharedGroupId: 'group1'),
  ]);

  final manager = SharedGroupManager(...);

  // Act
  await manager.removeFromSharedGroup('1');

  // Assert
  // ショップ1から共有情報を削除
  verify(mockShopRepository.updateShop(argThat(
    predicate<Shop>((shop) =>
      shop.id == '1' &&
      shop.sharedTabs.isEmpty &&
      shop.sharedGroupId == null
    )
  ))).called(1);

  // ショップ2からもショップ1への参照を削除
  verify(mockShopRepository.updateShop(argThat(
    predicate<Shop>((shop) =>
      shop.id == '2' &&
      !shop.sharedTabs.contains('1')
    )
  ))).called(1);
});
```

##### TC5-3: 共有グループ合計計算
```dart
test('getSharedGroupTotal: 共有グループの合計を正しく計算する', () async {
  // Arrange
  final mockCacheManager = MockDataCacheManager();
  when(mockCacheManager.shops).thenReturn([
    Shop(id: '1', name: 'ショップ1', items: [
      ListItem(id: '1', name: 'アイテム1', price: 100, quantity: 2, isChecked: true),
    ], sharedGroupId: 'group1'),
    Shop(id: '2', name: 'ショップ2', items: [
      ListItem(id: '2', name: 'アイテム2', price: 200, quantity: 1, isChecked: true),
    ], sharedGroupId: 'group1'),
  ]);

  final manager = SharedGroupManager(...);

  // Act
  final total = await manager.getSharedGroupTotal('group1');

  // Assert
  expect(total, 400); // 100*2 + 200*1
});
```

##### TC5-4: 予算同期
```dart
test('syncSharedGroupBudget: 共有グループの予算を同期する', () async {
  // Arrange
  final mockCacheManager = MockDataCacheManager();
  when(mockCacheManager.shops).thenReturn([
    Shop(id: '1', name: 'ショップ1', items: [], sharedGroupId: 'group1'),
    Shop(id: '2', name: 'ショップ2', items: [], sharedGroupId: 'group1'),
  ]);

  final manager = SharedGroupManager(...);

  // Act
  await manager.syncSharedGroupBudget('group1', 5000);

  // Assert
  verify(mockShopRepository.updateShop(argThat(
    predicate<Shop>((shop) => shop.id == '1' && shop.budget == 5000)
  ))).called(1);
  verify(mockShopRepository.updateShop(argThat(
    predicate<Shop>((shop) => shop.id == '2' && shop.budget == 5000)
  ))).called(1);
});
```

---

## Phase 6: 統合テスト

### DataProvider統合テスト

**ファイルパス**: `test/providers/data_provider_integration_test.dart`

#### テストケース

##### TC6-1: アイテム追加→リアルタイム同期→削除の一連の流れ
```dart
test('統合: アイテム追加→リアルタイム同期→削除が正常に動作する', () async {
  // Arrange
  final dataProvider = DataProvider(...);
  await dataProvider.loadData();

  // Act 1: アイテム追加
  final item = ListItem(id: '1', name: 'テスト', shopId: '0');
  await dataProvider.addItem(item);

  // Assert 1: ローカルキャッシュに即座に反映
  expect(dataProvider.items.length, 1);
  expect(dataProvider.items[0].name, 'テスト');

  // Act 2: リアルタイム同期イベントをシミュレート
  // (テスト用にStreamControllerを使用)
  await Future.delayed(Duration(seconds: 1));

  // Assert 2: 保護期間内はローカル版を優先
  expect(dataProvider.items[0].name, 'テスト');

  // Act 3: 保護期間経過後のリアルタイム同期
  await Future.delayed(Duration(seconds: 11));
  // (リモート版をシミュレート)

  // Assert 3: リモート版を採用
  // ...

  // Act 4: 削除
  await dataProvider.deleteItem('1');

  // Assert 4: ローカルキャッシュから削除
  expect(dataProvider.items.length, 0);
});
```

##### TC6-2: ログイン→データロード→ログアウトの流れ
```dart
test('統合: ログイン→データロード→ログアウトが正常に動作する', () async {
  // Arrange
  final authProvider = MockAuthProvider();
  final dataProvider = DataProvider(...);
  dataProvider.setAuthProvider(authProvider);

  // Act 1: ログイン
  when(authProvider.isLoggedIn).thenReturn(true);
  authProvider.notifyListeners(); // ログイン状態変更を通知

  await Future.delayed(Duration(milliseconds: 100));

  // Assert 1: データがロードされる
  expect(dataProvider.isLoading, false);
  expect(dataProvider.isSynced, true);

  // Act 2: ログアウト
  when(authProvider.isLoggedIn).thenReturn(false);
  authProvider.notifyListeners(); // ログアウト状態変更を通知

  await Future.delayed(Duration(milliseconds: 100));

  // Assert 2: データがクリアされる
  expect(dataProvider.items.length, 0);
  expect(dataProvider.shops.length, 0);
  expect(dataProvider.isLocalMode, true);
});
```

##### TC6-3: バッチ更新（並べ替え）
```dart
test('統合: 並べ替え処理が正常に動作する', () async {
  // Arrange
  final dataProvider = DataProvider(...);
  await dataProvider.loadData();

  final shop = Shop(id: '1', name: 'テストショップ', items: [
    ListItem(id: '1', name: 'アイテム1', shopId: '1', order: 0),
    ListItem(id: '2', name: 'アイテム2', shopId: '1', order: 1),
  ]);

  // Act: 並べ替え（order入れ替え）
  final updatedItems = [
    shop.items[1].copyWith(order: 0),
    shop.items[0].copyWith(order: 1),
  ];
  final updatedShop = shop.copyWith(items: updatedItems);

  await dataProvider.reorderItems(updatedShop, updatedItems);

  // Assert: 順序が変更される
  expect(dataProvider.items[0].id, '2');
  expect(dataProvider.items[1].id, '1');

  // notifyListeners()が1回だけ呼ばれる（バッチ更新）
  // (モックで検証)
});
```

---

## ウィジェットテスト

### 主要画面のテスト

**ファイルパス**: `test/screens/main_screen_test.dart`

#### テストケース

##### TC7-1: アイテム追加ダイアログ
```dart
testWidgets('アイテム追加ダイアログが正常に動作する', (tester) async {
  // Arrange
  await tester.pumpWidget(MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider(...)),
      ],
      child: MainScreen(),
    ),
  ));

  // Act: 追加ボタンをタップ
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();

  // Assert: ダイアログが表示される
  expect(find.byType(Dialog), findsOneWidget);

  // Act: アイテム名を入力
  await tester.enterText(find.byType(TextField).first, 'テストアイテム');
  await tester.tap(find.text('保存'));
  await tester.pumpAndSettle();

  // Assert: アイテムがリストに追加される
  expect(find.text('テストアイテム'), findsOneWidget);
});
```

##### TC7-2: アイテム削除（スワイプ）
```dart
testWidgets('アイテムをスワイプで削除できる', (tester) async {
  // Arrange
  final dataProvider = DataProvider(...);
  await dataProvider.addItem(ListItem(id: '1', name: 'テスト', shopId: '0'));

  await tester.pumpWidget(MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dataProvider),
      ],
      child: MainScreen(),
    ),
  ));

  // Act: スワイプで削除
  await tester.drag(find.text('テスト'), Offset(-500, 0));
  await tester.pumpAndSettle();

  // Assert: アイテムが削除される
  expect(find.text('テスト'), findsNothing);
});
```

---

## E2Eテスト（手動）

### テストシナリオ

#### シナリオ1: 基本的なCRUD操作
1. アプリを起動
2. アイテムを3件追加（名前、価格、個数を入力）
3. 1件目のアイテムを編集（価格を変更）
4. 2件目のアイテムを削除（スワイプ）
5. 合計金額が正しく表示されることを確認

**期待結果**: すべての操作が正常に動作し、合計金額が正しい

---

#### シナリオ2: リアルタイム同期
1. デバイス1でアプリを起動してログイン
2. デバイス2でも同じアカウントでログイン
3. デバイス1でアイテムを追加
4. デバイス2で即座に反映されることを確認
5. デバイス2でアイテムを削除
6. デバイス1で即座に反映されることを確認

**期待結果**: 両デバイス間でリアルタイムに同期される

---

#### シナリオ3: 共有グループ
1. ショップAとショップBを作成
2. ショップAの設定から「共有」を選択
3. ショップBを共有相手として選択
4. 両ショップに異なるアイテムを追加
5. 共有グループの合計金額が正しく表示されることを確認
6. 予算を設定して、両ショップに反映されることを確認

**期待結果**: 共有グループの合計・予算が正常に動作

---

#### シナリオ4: オフライン→オンライン
1. ネットワークをオフにする
2. アイテムを3件追加
3. ローカルモードで正常に動作することを確認
4. ネットワークをオンにする
5. ログインする
6. ローカルデータがFirebaseに同期されることを確認

**期待結果**: オフライン時の操作がオンライン時に正常に同期される

---

## テストカバレッジ目標

| モジュール | 目標カバレッジ | 重要度 |
|-----------|---------------|--------|
| DataCacheManager | 80%以上 | 高 |
| ItemRepository | 80%以上 | 高 |
| ShopRepository | 80%以上 | 高 |
| RealtimeSyncManager | 70%以上 | 高（複雑なため） |
| SharedGroupManager | 70%以上 | 中 |
| DataProvider | 60%以上 | 中（ファサードのため） |

**全体目標**: 70%以上

---

## 継続的テスト

### CI/CD統合

**GitHub Actions / Codemagic**:
```yaml
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter analyze
    - run: flutter test --coverage
    - uses: codecov/codecov-action@v2
      with:
        files: ./coverage/lcov.info
```

### テスト実行頻度
- **プルリクエスト作成時**: 全テスト実行
- **main ブランチマージ時**: 全テスト + E2Eテスト
- **毎日深夜**: 全テスト + カバレッジレポート生成

---

## バグ発見時の対応

### バグ報告テンプレート
```markdown
## バグ概要
[簡潔な説明]

## 再現手順
1. ...
2. ...

## 期待結果
[何が起こるべきか]

## 実際の結果
[何が起こったか]

## 環境
- デバイス: ...
- OS: ...
- アプリバージョン: ...

## 関連コード
- ファイル: ...
- 行数: ...
```

### バグ修正フロー
1. バグを再現するテストケースを追加
2. テストが失敗することを確認（Red）
3. バグを修正
4. テストが成功することを確認（Green）
5. コードをリファクタリング（Refactor）
6. プルリクエストを作成

---

## テスト実施チェックリスト

### Phase 1完了時
- [ ] DataCacheManagerの単体テストがすべてパス
- [ ] カバレッジが80%以上
- [ ] `flutter analyze`でwarning/error 0件

### Phase 2完了時
- [ ] ItemRepositoryの単体テストがすべてパス
- [ ] カバレッジが80%以上
- [ ] 統合テスト（アイテム追加→削除）がパス

### Phase 3完了時
- [ ] ShopRepositoryの単体テストがすべてパス
- [ ] カバレッジが80%以上
- [ ] デフォルトショップ自動作成が正常動作

### Phase 4完了時
- [ ] RealtimeSyncManagerの単体テストがすべてパス
- [ ] カバレッジが70%以上
- [ ] リアルタイム同期の統合テストがパス
- [ ] バッチ更新の統合テストがパス

### Phase 5完了時
- [ ] SharedGroupManagerの単体テストがすべてパス
- [ ] カバレッジが70%以上
- [ ] 共有グループのE2Eテストがパス

### Phase 6完了時
- [ ] 全単体テストがパス
- [ ] 全統合テストがパス
- [ ] 全ウィジェットテストがパス
- [ ] 全E2Eテストがパス
- [ ] 全体カバレッジが70%以上
- [ ] `flutter analyze`でwarning/error 0件
