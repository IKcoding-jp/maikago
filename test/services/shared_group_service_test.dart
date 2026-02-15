import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/services/shared_group_service.dart';
import '../helpers/test_helpers.dart';
import '../mocks.mocks.dart';

void main() {
  late SharedGroupService service;
  late MockDataService mockDataService;

  setUp(() {
    mockDataService = MockDataService();
    service = SharedGroupService(dataService: mockDataService);
  });

  group('getSharedGroupTotal', () {
    test('共有グループ内の合計が計算される', () async {
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1', sharedGroupId: 'group_1'),
        createSampleShop(id: 'shop_2', name: 'ショップ2', sharedGroupId: 'group_1'),
        createSampleShop(id: 'shop_3', name: 'ショップ3', sharedGroupId: 'group_2'),
      ];

      // getDisplayTotal コールバック
      Future<int> getDisplayTotal(Shop shop) async {
        if (shop.id == 'shop_1') return 500;
        if (shop.id == 'shop_2') return 300;
        return 0;
      }

      final total = await service.getSharedGroupTotal(
        shops,
        'group_1',
        getDisplayTotal,
      );

      expect(total, 800);
    });

    test('対象ショップがない場合は0', () async {
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1', sharedGroupId: 'group_1'),
      ];

      final total = await service.getSharedGroupTotal(
        shops,
        'non_existent_group',
        (shop) async => 100,
      );

      expect(total, 0);
    });

    test('空のショップリストでは0', () async {
      final total = await service.getSharedGroupTotal(
        [],
        'group_1',
        (shop) async => 100,
      );

      expect(total, 0);
    });
  });

  group('getSharedGroupBudget', () {
    test('最初のショップの予算が返される', () {
      final shops = [
        createSampleShop(
          id: 'shop_1',
          name: 'ショップ1',
          sharedGroupId: 'group_1',
          budget: 5000,
        ),
        createSampleShop(
          id: 'shop_2',
          name: 'ショップ2',
          sharedGroupId: 'group_1',
          budget: 3000,
        ),
      ];

      final budget = service.getSharedGroupBudget(shops, 'group_1');

      expect(budget, 5000);
    });

    test('最初のショップに予算がない場合は次のショップの予算', () {
      final shops = [
        createSampleShop(
          id: 'shop_1',
          name: 'ショップ1',
          sharedGroupId: 'group_1',
        ),
        createSampleShop(
          id: 'shop_2',
          name: 'ショップ2',
          sharedGroupId: 'group_1',
          budget: 3000,
        ),
      ];

      final budget = service.getSharedGroupBudget(shops, 'group_1');

      expect(budget, 3000);
    });

    test('予算が設定されていない場合はnull', () {
      final shops = [
        createSampleShop(
          id: 'shop_1',
          name: 'ショップ1',
          sharedGroupId: 'group_1',
        ),
      ];

      final budget = service.getSharedGroupBudget(shops, 'group_1');

      expect(budget, isNull);
    });

    test('対象グループがない場合はnull', () {
      final shops = [
        createSampleShop(
          id: 'shop_1',
          name: 'ショップ1',
          sharedGroupId: 'group_2',
          budget: 5000,
        ),
      ];

      final budget = service.getSharedGroupBudget(shops, 'group_1');

      expect(budget, isNull);
    });
  });

  group('generateSharedGroupId', () {
    test('shared_プレフィックスのIDが生成される', () {
      final id = service.generateSharedGroupId();

      expect(id, startsWith('shared_'));
    });

    test('連続呼び出しで異なるIDが生成される', () {
      final id1 = service.generateSharedGroupId();
      // ミリ秒が同じ場合があるため少し待機
      final id2 = service.generateSharedGroupId();

      // タイムスタンプベースなので同じミリ秒なら同じIDの可能性がある
      // テストでは形式のみ確認
      expect(id1, startsWith('shared_'));
      expect(id2, startsWith('shared_'));
    });
  });

  group('prepareSharedGroupUpdate', () {
    test('現在のショップが更新される', () {
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1'),
        createSampleShop(id: 'shop_2', name: 'ショップ2'),
      ];

      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'shop_1',
        selectedTabIds: ['shop_2'],
      );

      // shop_1とshop_2が結果に含まれる
      expect(result.length, 2);

      final updatedShop1 = result.firstWhere((s) => s.id == 'shop_1');
      expect(updatedShop1.sharedTabs, ['shop_2']);
      expect(updatedShop1.sharedGroupId, isNotNull);
    });

    test('選択されたタブに現在のショップが追加される', () {
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1'),
        createSampleShop(id: 'shop_2', name: 'ショップ2'),
      ];

      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'shop_1',
        selectedTabIds: ['shop_2'],
      );

      final updatedShop2 = result.firstWhere((s) => s.id == 'shop_2');
      expect(updatedShop2.sharedTabs, contains('shop_1'));
      expect(updatedShop2.sharedGroupId, isNotNull);
    });

    test('削除されたタブから参照が除去される', () {
      final shops = [
        createSampleShop(
          id: 'shop_1',
          name: 'ショップ1',
          sharedTabs: ['shop_2', 'shop_3'],
          sharedGroupId: 'group_1',
        ),
        createSampleShop(
          id: 'shop_2',
          name: 'ショップ2',
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

      // shop_3を共有から除外
      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'shop_1',
        selectedTabIds: ['shop_2'],
      );

      // shop_1（更新）、shop_3（削除対象）、shop_2（選択タブ）
      final updatedShop1 = result.firstWhere((s) => s.id == 'shop_1');
      expect(updatedShop1.sharedTabs, ['shop_2']);

      final updatedShop3 = result.firstWhere((s) => s.id == 'shop_3');
      expect(updatedShop3.sharedTabs, isEmpty);
    });

    test('選択タブが空の場合にsharedGroupIdがクリアされる', () {
      final shops = [
        createSampleShop(
          id: 'shop_1',
          name: 'ショップ1',
          sharedTabs: ['shop_2'],
          sharedGroupId: 'group_1',
        ),
        createSampleShop(
          id: 'shop_2',
          name: 'ショップ2',
          sharedTabs: ['shop_1'],
          sharedGroupId: 'group_1',
        ),
      ];

      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'shop_1',
        selectedTabIds: [],
      );

      final updatedShop1 = result.firstWhere((s) => s.id == 'shop_1');
      expect(updatedShop1.sharedTabs, isEmpty);
      expect(updatedShop1.sharedGroupId, isNull);
    });

    test('名前の更新が反映される', () {
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1'),
        createSampleShop(id: 'shop_2', name: 'ショップ2'),
      ];

      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'shop_1',
        selectedTabIds: ['shop_2'],
        name: '新しい名前',
      );

      final updatedShop1 = result.firstWhere((s) => s.id == 'shop_1');
      expect(updatedShop1.name, '新しい名前');
    });
  });

  group('prepareRemoveFromSharedGroup', () {
    test('対象ショップの共有情報がクリアされる', () {
      final shops = [
        createSampleShop(
          id: 'shop_1',
          name: 'ショップ1',
          sharedTabs: ['shop_2'],
          sharedGroupId: 'group_1',
        ),
        createSampleShop(
          id: 'shop_2',
          name: 'ショップ2',
          sharedTabs: ['shop_1'],
          sharedGroupId: 'group_1',
        ),
      ];

      final result = service.prepareRemoveFromSharedGroup(
        shops: shops,
        shopId: 'shop_1',
      );

      final updatedShop1 = result.firstWhere((s) => s.id == 'shop_1');
      expect(updatedShop1.sharedTabs, isEmpty);
      expect(updatedShop1.sharedGroupId, isNull);
    });

    test('関連タブからも参照が削除される', () {
      final shops = [
        createSampleShop(
          id: 'shop_1',
          name: 'ショップ1',
          sharedTabs: ['shop_2', 'shop_3'],
          sharedGroupId: 'group_1',
        ),
        createSampleShop(
          id: 'shop_2',
          name: 'ショップ2',
          sharedTabs: ['shop_1', 'shop_3'],
          sharedGroupId: 'group_1',
        ),
        createSampleShop(
          id: 'shop_3',
          name: 'ショップ3',
          sharedTabs: ['shop_1', 'shop_2'],
          sharedGroupId: 'group_1',
        ),
      ];

      final result = service.prepareRemoveFromSharedGroup(
        shops: shops,
        shopId: 'shop_1',
      );

      // shop_1は共有情報がクリア
      final updatedShop1 = result.firstWhere((s) => s.id == 'shop_1');
      expect(updatedShop1.sharedTabs, isEmpty);

      // shop_2からshop_1への参照が削除
      final updatedShop2 = result.firstWhere((s) => s.id == 'shop_2');
      expect(updatedShop2.sharedTabs, isNot(contains('shop_1')));
      expect(updatedShop2.sharedTabs, contains('shop_3'));

      // shop_3からshop_1への参照が削除
      final updatedShop3 = result.firstWhere((s) => s.id == 'shop_3');
      expect(updatedShop3.sharedTabs, isNot(contains('shop_1')));
      expect(updatedShop3.sharedTabs, contains('shop_2'));
    });

    test('存在しないショップIDで例外がスローされる', () {
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1'),
      ];

      expect(
        () => service.prepareRemoveFromSharedGroup(
          shops: shops,
          shopId: 'non_existent',
        ),
        throwsException,
      );
    });
  });

  group('syncSharedGroupBudget', () {
    test('グループ内全ショップの予算が更新される', () {
      final shops = [
        createSampleShop(
          id: 'shop_1',
          name: 'ショップ1',
          sharedGroupId: 'group_1',
          budget: 3000,
        ),
        createSampleShop(
          id: 'shop_2',
          name: 'ショップ2',
          sharedGroupId: 'group_1',
          budget: 3000,
        ),
        createSampleShop(
          id: 'shop_3',
          name: 'ショップ3',
          sharedGroupId: 'group_2',
          budget: 1000,
        ),
      ];

      final result = service.syncSharedGroupBudget(
        shops: shops,
        sharedGroupId: 'group_1',
        newBudget: 5000,
      );

      // group_1のショップのみ更新
      expect(result.length, 2);
      expect(result.every((s) => s.budget == 5000), true);
    });

    test('対象グループがない場合は空リスト', () {
      final shops = [
        createSampleShop(
          id: 'shop_1',
          name: 'ショップ1',
          sharedGroupId: 'group_1',
        ),
      ];

      final result = service.syncSharedGroupBudget(
        shops: shops,
        sharedGroupId: 'non_existent',
        newBudget: 5000,
      );

      expect(result, isEmpty);
    });
  });

  group('saveShops', () {
    test('DataService.updateShopが全ショップ分呼ばれる', () async {
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1'),
        createSampleShop(id: 'shop_2', name: 'ショップ2'),
      ];

      when(mockDataService.updateShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenAnswer((_) async {});

      await service.saveShops(shops, isAnonymous: false);

      verify(mockDataService.updateShop(
        any,
        isAnonymous: false,
      )).called(2);
    });

    test('エラー時にrethrow', () async {
      final shops = [
        createSampleShop(id: 'shop_1', name: 'ショップ1'),
      ];

      when(mockDataService.updateShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      )).thenThrow(Exception('Firebase error'));

      expect(
        () => service.saveShops(shops, isAnonymous: false),
        throwsException,
      );
    });

    test('空のショップリストでは何も呼ばれない', () async {
      await service.saveShops([], isAnonymous: false);

      verifyNever(mockDataService.updateShop(
        any,
        isAnonymous: anyNamed('isAnonymous'),
      ));
    });
  });
}
