import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:maikago/services/item_service.dart';
import 'package:maikago/utils/exceptions.dart';
import '../helpers/test_helpers.dart';
import '../mocks.mocks.dart';

void main() {
  late ItemService itemService;
  late MockDataService mockDataService;

  setUp(() {
    mockDataService = MockDataService();
    itemService = ItemService(dataService: mockDataService);
  });

  group('createNewItem', () {
    test('IDが空の場合に自動生成される', () {
      final item = createSampleItem(id: '', name: 'テスト商品');

      final result = itemService.createNewItem(item, 0);

      expect(result.id, isNotEmpty);
      expect(result.name, 'テスト商品');
    });

    test('IDが設定済みの場合はそのまま使用', () {
      final item = createSampleItem(id: 'existing_id', name: 'テスト商品');

      final result = itemService.createNewItem(item, 0);

      expect(result.id, 'existing_id');
    });

    test('createdAtが現在時刻に設定される', () {
      final item = createSampleItem(id: '', name: 'テスト商品');
      final before = DateTime.now();

      final result = itemService.createNewItem(item, 0);

      final after = DateTime.now();
      expect(result.createdAt!.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(result.createdAt!.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('existingItemCountがIDに含まれる', () {
      final item = createSampleItem(id: '', name: 'テスト商品');

      final result = itemService.createNewItem(item, 5);

      expect(result.id, endsWith('_5'));
    });
  });

  group('saveItem', () {
    test('DataService.saveItemが呼ばれる', () async {
      final item = createSampleItem(id: '1', name: 'テスト');

      when(mockDataService.saveItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await itemService.saveItem(item, isAnonymous: false);

      verify(mockDataService.saveItem(
        any,
        isAnonymous: false,
      )).called(1);
    });

    test('isAnonymous=trueが正しく渡される', () async {
      final item = createSampleItem(id: '1', name: 'テスト');

      when(mockDataService.saveItem(
        any,
        isAnonymous: true,
      )).thenAnswer((_) async {});

      await itemService.saveItem(item, isAnonymous: true);

      verify(mockDataService.saveItem(
        any,
        isAnonymous: true,
      )).called(1);
    });

    test('DataService失敗時にrethrow', () async {
      final item = createSampleItem(id: '1', name: 'テスト');

      when(mockDataService.saveItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenThrow(Exception('Firebase error'));

      expect(
        () => itemService.saveItem(item, isAnonymous: false),
        throwsException,
      );
    });
  });

  group('updateItem', () {
    test('DataService.updateItemが呼ばれる', () async {
      final item = createSampleItem(id: '1', name: 'テスト');

      when(mockDataService.updateItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await itemService.updateItem(item, isAnonymous: false);

      verify(mockDataService.updateItem(
        any,
        isAnonymous: false,
      )).called(1);
    });

    test('DataService失敗時にAppExceptionがスローされる', () async {
      final item = createSampleItem(id: '1', name: 'テスト');

      when(mockDataService.updateItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenThrow(Exception('Firebase error'));

      expect(
        () => itemService.updateItem(item, isAnonymous: false),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('deleteItem', () {
    test('DataService.deleteItemが呼ばれる', () async {
      when(mockDataService.deleteItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await itemService.deleteItem('item_1', isAnonymous: false);

      verify(mockDataService.deleteItem(
        'item_1',
        isAnonymous: false,
      )).called(1);
    });

    test('DataService失敗時にAppExceptionがスローされる', () async {
      when(mockDataService.deleteItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenThrow(Exception('Firebase error'));

      expect(
        () => itemService.deleteItem('item_1', isAnonymous: false),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('updateItemsBatch', () {
    test('全アイテムが更新される', () async {
      final items = createSampleItems(3);

      when(mockDataService.updateItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await itemService.updateItemsBatch(items, isAnonymous: false);

      verify(mockDataService.updateItem(
        any,
        isAnonymous: false,
      )).called(3);
    });

    test('バッチサイズに分割して処理される', () async {
      final items = createSampleItems(7);

      when(mockDataService.updateItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      // batchSize=3で7アイテム → 3回のバッチ（3+3+1）
      await itemService.updateItemsBatch(items, isAnonymous: false, batchSize: 3);

      verify(mockDataService.updateItem(
        any,
        isAnonymous: false,
      )).called(7);
    });

    test('エラー時にrethrow', () async {
      final items = createSampleItems(3);

      when(mockDataService.updateItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenThrow(Exception('Firebase error'));

      expect(
        () => itemService.updateItemsBatch(items, isAnonymous: false),
        throwsException,
      );
    });
  });

  group('deleteItems', () {
    test('全アイテムが削除される', () async {
      final itemIds = ['item_0', 'item_1', 'item_2'];

      when(mockDataService.deleteItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await itemService.deleteItems(itemIds, isAnonymous: false);

      verify(mockDataService.deleteItem(
        any,
        isAnonymous: false,
      )).called(3);
    });

    test('バッチサイズに分割して削除される', () async {
      final itemIds = List.generate(7, (i) => 'item_$i');

      when(mockDataService.deleteItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await itemService.deleteItems(itemIds, isAnonymous: false, batchSize: 3);

      verify(mockDataService.deleteItem(
        any,
        isAnonymous: false,
      )).called(7);
    });

    test('エラー時にAppExceptionがスローされる', () async {
      final itemIds = ['item_0'];

      when(mockDataService.deleteItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenThrow(Exception('Firebase error'));

      expect(
        () => itemService.deleteItems(itemIds, isAnonymous: false),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('associateItemsWithShops', () {
    test('アイテムが対応するショップに関連付けられる', () {
      final items = [
        createSampleItem(id: 'item_1', name: '商品1', shopId: 'shop_1'),
        createSampleItem(id: 'item_2', name: '商品2', shopId: 'shop_2'),
        createSampleItem(id: 'item_3', name: '商品3', shopId: 'shop_1'),
      ];
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1'),
        createSampleShop(id: 'shop_2', name: 'ショップ2'),
      ];

      itemService.associateItemsWithShops(items, shops);

      expect(shops[0].items.length, 2);
      expect(shops[1].items.length, 1);
      expect(shops[0].items.map((i) => i.id), containsAll(['item_1', 'item_3']));
      expect(shops[1].items.first.id, 'item_2');
    });

    test('重複アイテムが除去される', () {
      final items = [
        createSampleItem(id: 'item_1', name: '商品1', shopId: 'shop_1'),
        createSampleItem(id: 'item_1', name: '商品1(重複)', shopId: 'shop_1'),
      ];
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1'),
      ];

      itemService.associateItemsWithShops(items, shops);

      expect(shops[0].items.length, 1);
      expect(shops[0].items.first.name, '商品1');
    });

    test('ショップに属さないアイテムは無視される', () {
      final items = [
        createSampleItem(id: 'item_1', name: '商品1', shopId: 'unknown_shop'),
      ];
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1'),
      ];

      itemService.associateItemsWithShops(items, shops);

      expect(shops[0].items, isEmpty);
    });

    test('空のアイテムリストでも正常に動作', () {
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1'),
      ];

      itemService.associateItemsWithShops([], shops);

      expect(shops[0].items, isEmpty);
    });
  });
}
