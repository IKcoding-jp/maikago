import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maikago/services/shop_service.dart';
import 'package:maikago/utils/exceptions.dart';
import '../helpers/test_helpers.dart';
import '../mocks.mocks.dart';

void main() {
  late ShopService shopService;
  late MockDataService mockDataService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDataService = MockDataService();
    shopService = ShopService(dataService: mockDataService);
  });

  group('createNewShop', () {
    test('デフォルトショップ(id=0)はIDをそのまま使用', () {
      final shop = createSampleShop(id: '0', name: 'デフォルト');

      final result = shopService.createNewShop(shop, 0);

      expect(result.id, '0');
      expect(result.name, 'デフォルト');
    });

    test('デフォルトショップはcreatedAtが設定される', () {
      final shop = createSampleShop(id: '0', name: 'デフォルト');
      final before = DateTime.now();

      final result = shopService.createNewShop(shop, 0);

      expect(result.createdAt, isNotNull);
      expect(result.createdAt!.isAfter(before.subtract(const Duration(seconds: 1))), true);
    });

    test('通常ショップはID自動生成', () {
      final shop = createSampleShop(id: 'temp', name: 'スーパー');

      final result = shopService.createNewShop(shop, 3);

      expect(result.id, isNot('temp'));
      expect(result.id, endsWith('_3'));
    });

    test('通常ショップのcreatedAtが設定される', () {
      final shop = createSampleShop(id: 'temp', name: 'スーパー');
      final before = DateTime.now();

      final result = shopService.createNewShop(shop, 0);

      expect(result.createdAt, isNotNull);
      expect(result.createdAt!.isAfter(before.subtract(const Duration(seconds: 1))), true);
    });
  });

  group('saveShop', () {
    test('DataService.saveShopが呼ばれる', () async {
      final shop = createSampleShop(id: '1', name: 'スーパー');

      when(mockDataService.saveShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await shopService.saveShop(shop, isAnonymous: false);

      verify(mockDataService.saveShop(
        any,
        isAnonymous: false,
      )).called(1);
    });

    test('エラー時にrethrow', () async {
      final shop = createSampleShop(id: '1', name: 'スーパー');

      when(mockDataService.saveShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenThrow(Exception('Firebase error'));

      expect(
        () => shopService.saveShop(shop, isAnonymous: false),
        throwsException,
      );
    });
  });

  group('updateShop', () {
    test('DataService.updateShopが呼ばれる', () async {
      final shop = createSampleShop(id: '1', name: 'スーパー');

      when(mockDataService.updateShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await shopService.updateShop(shop, isAnonymous: false);

      verify(mockDataService.updateShop(
        any,
        isAnonymous: false,
      )).called(1);
    });

    test('エラー時にAppExceptionがスローされる', () async {
      final shop = createSampleShop(id: '1', name: 'スーパー');

      when(mockDataService.updateShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenThrow(Exception('Firebase error'));

      expect(
        () => shopService.updateShop(shop, isAnonymous: false),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('deleteShop', () {
    test('DataService.deleteShopが呼ばれる', () async {
      when(mockDataService.deleteShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await shopService.deleteShop('shop_1', isAnonymous: false);

      verify(mockDataService.deleteShop(
        'shop_1',
        isAnonymous: false,
      )).called(1);
    });

    test('デフォルトショップ削除時にSettingsPersistenceが記録される', () async {
      SharedPreferences.setMockInitialValues({});

      when(mockDataService.deleteShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await shopService.deleteShop('0', isAnonymous: false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('default_shop_deleted'), true);
    });

    test('通常ショップ削除時はSettingsPersistenceが記録されない', () async {
      SharedPreferences.setMockInitialValues({});

      when(mockDataService.deleteShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await shopService.deleteShop('shop_1', isAnonymous: false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('default_shop_deleted'), isNull);
    });

    test('エラー時にAppExceptionがスローされる', () async {
      when(mockDataService.deleteShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenThrow(Exception('Firebase error'));

      expect(
        () => shopService.deleteShop('shop_1', isAnonymous: false),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('removeSharedTabReferences', () {
    test('削除対象のIDが他ショップから除去される', () {
      final shops = [
        createSampleShop(
          id: 'shop_1',
          name: 'ショップ1',
          sharedTabs: ['shop_2', 'shop_3'],
          sharedGroupId: 'group_1',
        ),
        createSampleShop(
          id: 'shop_2',
          name: 'ショップ2（削除対象）',
          sharedTabs: ['shop_1'],
          sharedGroupId: 'group_1',
        ),
        createSampleShop(
          id: 'shop_3',
          name: 'ショップ3',
          sharedTabs: ['shop_1'],
          sharedGroupId: 'group_1',
        ),
      ];

      final result = shopService.removeSharedTabReferences(shops, 'shop_2');

      // shop_2は削除対象なので結果に含まれない
      expect(result.length, 2);
      // shop_1からshop_2への参照が除去
      final shop1 = result.firstWhere((s) => s.id == 'shop_1');
      expect(shop1.sharedTabs, ['shop_3']);
      // shop_3は変更なし
      final shop3 = result.firstWhere((s) => s.id == 'shop_3');
      expect(shop3.sharedTabs, ['shop_1']);
    });

    test('共有相手がいなくなった場合に共有マークが削除される', () {
      final shops = [
        createSampleShop(
          id: 'shop_1',
          name: 'ショップ1',
          sharedTabs: ['shop_2'],
          sharedGroupId: 'group_1',
        ),
        createSampleShop(
          id: 'shop_2',
          name: 'ショップ2（削除対象）',
          sharedTabs: ['shop_1'],
          sharedGroupId: 'group_1',
        ),
      ];

      final result = shopService.removeSharedTabReferences(shops, 'shop_2');

      expect(result.length, 1);
      final shop1 = result.first;
      expect(shop1.sharedTabs, isEmpty);
      // clearSharedGroupIdがtrueで呼ばれるためsharedGroupIdがnullになる
      expect(shop1.sharedGroupId, isNull);
    });

    test('共有関係のないショップは変更されない', () {
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1'),
        createSampleShop(id: 'shop_2', name: 'ショップ2（削除対象）'),
        createSampleShop(id: 'shop_3', name: 'ショップ3'),
      ];

      final result = shopService.removeSharedTabReferences(shops, 'shop_2');

      expect(result.length, 2);
      expect(result.every((s) => s.sharedTabs.isEmpty), true);
    });
  });

  group('createDefaultShop', () {
    test('デフォルトショップが正しく生成される', () {
      final shop = shopService.createDefaultShop();

      expect(shop.id, '0');
      expect(shop.name, 'デフォルト');
      expect(shop.items, isEmpty);
    });
  });

  group('shouldCreateDefaultShop', () {
    test('既存のデフォルトショップがある場合はfalse', () async {
      SharedPreferences.setMockInitialValues({});
      final shops = [createSampleShop(id: '0', name: 'デフォルト')];

      final result = await shopService.shouldCreateDefaultShop(shops);

      expect(result, false);
    });

    test('デフォルトショップがなく未削除の場合はtrue', () async {
      SharedPreferences.setMockInitialValues({});
      final shops = [createSampleShop(id: '1', name: 'スーパー')];

      final result = await shopService.shouldCreateDefaultShop(shops);

      expect(result, true);
    });

    test('削除済みの場合はfalse', () async {
      SharedPreferences.setMockInitialValues({'default_shop_deleted': true});
      final shops = [createSampleShop(id: '1', name: 'スーパー')];

      final result = await shopService.shouldCreateDefaultShop(shops);

      expect(result, false);
    });

    test('空のショップリストで未削除の場合はtrue', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await shopService.shouldCreateDefaultShop([]);

      expect(result, true);
    });
  });

  group('clearAllItems', () {
    test('アイテム削除後にショップが更新される', () async {
      final items = createSampleItems(3);
      final shop = createSampleShop(id: 'shop_1', name: 'スーパー', items: items);

      when(mockDataService.deleteItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});
      when(mockDataService.updateShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await shopService.clearAllItems(shop, items, isAnonymous: false);

      // 3件のアイテム削除
      verify(mockDataService.deleteItem(
        any,
        isAnonymous: false,
      )).called(3);
      // ショップ更新（items: []で）
      verify(mockDataService.updateShop(
        any,
        isAnonymous: false,
      )).called(1);
    });

    test('空のアイテムリストでもショップが更新される', () async {
      final shop = createSampleShop(id: 'shop_1', name: 'スーパー');

      when(mockDataService.updateShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await shopService.clearAllItems(shop, [], isAnonymous: false);

      verifyNever(mockDataService.deleteItem(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      ));
      verify(mockDataService.updateShop(
        any,
        isAnonymous: false,
      )).called(1);
    });
  });
}
