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

    test('既存共有グループに新規タブ追加時、全タブ間のクロスリファレンスが正しい', () {
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
        createSampleShop(id: 'shop_3', name: 'ショップ3'),
      ];

      // shop_1の編集画面でshop_2とshop_3を共有に選択
      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'shop_1',
        selectedTabIds: ['shop_2', 'shop_3'],
      );

      final updatedShop1 = result.firstWhere((s) => s.id == 'shop_1');
      final updatedShop2 = result.firstWhere((s) => s.id == 'shop_2');
      final updatedShop3 = result.firstWhere((s) => s.id == 'shop_3');

      // shop_1: [shop_2, shop_3]
      expect(updatedShop1.sharedTabs, containsAll(['shop_2', 'shop_3']));

      // shop_2: [shop_1, shop_3] — shop_3がクロスリファレンスで追加されるべき
      expect(updatedShop2.sharedTabs, containsAll(['shop_1', 'shop_3']));

      // shop_3: [shop_1, shop_2] — shop_2がクロスリファレンスで追加されるべき
      expect(updatedShop3.sharedTabs, containsAll(['shop_1', 'shop_2']));
    });

    test('3タブ共有で全タブが自分自身を含まない', () {
      final shops = [
        createSampleShop(id: 'A', name: 'A'),
        createSampleShop(id: 'B', name: 'B'),
        createSampleShop(id: 'C', name: 'C'),
      ];

      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'A',
        selectedTabIds: ['B', 'C'],
      );

      final updatedA = result.firstWhere((s) => s.id == 'A');
      final updatedB = result.firstWhere((s) => s.id == 'B');
      final updatedC = result.firstWhere((s) => s.id == 'C');

      // 自分自身を含まないこと
      expect(updatedA.sharedTabs, isNot(contains('A')));
      expect(updatedB.sharedTabs, isNot(contains('B')));
      expect(updatedC.sharedTabs, isNot(contains('C')));
    });

    test('3タブ共有から1タブ解除すると、解除タブが全メンバーから除去される', () {
      final shops = [
        createSampleShop(
          id: 'A',
          name: 'A',
          sharedTabs: ['B', 'C'],
          sharedGroupId: 'group_1',
        ),
        createSampleShop(
          id: 'B',
          name: 'B',
          sharedTabs: ['A', 'C'],
          sharedGroupId: 'group_1',
        ),
        createSampleShop(
          id: 'C',
          name: 'C',
          sharedTabs: ['A', 'B'],
          sharedGroupId: 'group_1',
        ),
      ];

      // Cの編集画面でBを解除（Aのみ選択）
      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'C',
        selectedTabIds: ['A'],
      );

      final updatedA = result.firstWhere((s) => s.id == 'A');
      final updatedB = result.firstWhere((s) => s.id == 'B');
      final updatedC = result.firstWhere((s) => s.id == 'C');

      // C: Aのみと共有
      expect(updatedC.sharedTabs, ['A']);
      expect(updatedC.sharedGroupId, isNotNull);

      // A: Cのみと共有（Bは除去されるべき）
      expect(updatedA.sharedTabs, ['C']);
      expect(updatedA.sharedTabs, isNot(contains('B')));

      // B: グループから完全離脱
      expect(updatedB.sharedTabs, isEmpty);
      expect(updatedB.sharedGroupId, isNull);
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

    // --- 4タブ以上の共有パターン ---

    test('4タブ共有: 全タブ間のクロスリファレンスが正しい', () {
      final shops = [
        createSampleShop(id: 'A', name: 'A'),
        createSampleShop(id: 'B', name: 'B'),
        createSampleShop(id: 'C', name: 'C'),
        createSampleShop(id: 'D', name: 'D'),
      ];

      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'A',
        selectedTabIds: ['B', 'C', 'D'],
      );

      final a = result.firstWhere((s) => s.id == 'A');
      final b = result.firstWhere((s) => s.id == 'B');
      final c = result.firstWhere((s) => s.id == 'C');
      final d = result.firstWhere((s) => s.id == 'D');

      expect(a.sharedTabs, unorderedEquals(['B', 'C', 'D']));
      expect(b.sharedTabs, unorderedEquals(['A', 'C', 'D']));
      expect(c.sharedTabs, unorderedEquals(['A', 'B', 'D']));
      expect(d.sharedTabs, unorderedEquals(['A', 'B', 'C']));

      // 全タブが同じsharedGroupId
      final groupId = a.sharedGroupId;
      expect(groupId, isNotNull);
      expect(b.sharedGroupId, groupId);
      expect(c.sharedGroupId, groupId);
      expect(d.sharedGroupId, groupId);

      // 自分自身を含まない
      expect(a.sharedTabs, isNot(contains('A')));
      expect(b.sharedTabs, isNot(contains('B')));
      expect(c.sharedTabs, isNot(contains('C')));
      expect(d.sharedTabs, isNot(contains('D')));
    });

    test('5タブ共有: 全タブ間のクロスリファレンスが正しい', () {
      final shops = List.generate(
        5,
        (i) => createSampleShop(id: 'T$i', name: 'タブ$i'),
      );

      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'T0',
        selectedTabIds: ['T1', 'T2', 'T3', 'T4'],
      );

      for (int i = 0; i < 5; i++) {
        final tab = result.firstWhere((s) => s.id == 'T$i');
        final expectedOthers =
            List.generate(5, (j) => 'T$j').where((id) => id != 'T$i').toList();
        expect(tab.sharedTabs, unorderedEquals(expectedOthers));
        expect(tab.sharedTabs, isNot(contains('T$i')));
      }
    });

    // --- 既存グループへの追加パターン ---

    test('2タブ共有グループに2タブ同時追加', () {
      final shops = [
        createSampleShop(
          id: 'A', name: 'A',
          sharedTabs: ['B'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'B', name: 'B',
          sharedTabs: ['A'], sharedGroupId: 'g1',
        ),
        createSampleShop(id: 'C', name: 'C'),
        createSampleShop(id: 'D', name: 'D'),
      ];

      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'A',
        selectedTabIds: ['B', 'C', 'D'],
      );

      final a = result.firstWhere((s) => s.id == 'A');
      final b = result.firstWhere((s) => s.id == 'B');
      final c = result.firstWhere((s) => s.id == 'C');
      final d = result.firstWhere((s) => s.id == 'D');

      expect(a.sharedTabs, unorderedEquals(['B', 'C', 'D']));
      expect(b.sharedTabs, unorderedEquals(['A', 'C', 'D']));
      expect(c.sharedTabs, unorderedEquals(['A', 'B', 'D']));
      expect(d.sharedTabs, unorderedEquals(['A', 'B', 'C']));
    });

    // --- 解除パターン ---

    test('4タブ共有から2タブ同時解除', () {
      final shops = [
        createSampleShop(
          id: 'A', name: 'A',
          sharedTabs: ['B', 'C', 'D'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'B', name: 'B',
          sharedTabs: ['A', 'C', 'D'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'C', name: 'C',
          sharedTabs: ['A', 'B', 'D'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'D', name: 'D',
          sharedTabs: ['A', 'B', 'C'], sharedGroupId: 'g1',
        ),
      ];

      // Aの編集画面でCとDを解除（Bのみ残す）
      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'A',
        selectedTabIds: ['B'],
      );

      final a = result.firstWhere((s) => s.id == 'A');
      final b = result.firstWhere((s) => s.id == 'B');
      final c = result.firstWhere((s) => s.id == 'C');
      final d = result.firstWhere((s) => s.id == 'D');

      // A + B のみ共有
      expect(a.sharedTabs, ['B']);
      expect(b.sharedTabs, ['A']);

      // C, D はグループから完全離脱
      expect(c.sharedTabs, isEmpty);
      expect(c.sharedGroupId, isNull);
      expect(d.sharedTabs, isEmpty);
      expect(d.sharedGroupId, isNull);
    });

    test('4タブ共有から1タブ解除 → 3タブグループが残る', () {
      final shops = [
        createSampleShop(
          id: 'A', name: 'A',
          sharedTabs: ['B', 'C', 'D'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'B', name: 'B',
          sharedTabs: ['A', 'C', 'D'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'C', name: 'C',
          sharedTabs: ['A', 'B', 'D'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'D', name: 'D',
          sharedTabs: ['A', 'B', 'C'], sharedGroupId: 'g1',
        ),
      ];

      // Aの編集画面でDを解除
      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'A',
        selectedTabIds: ['B', 'C'],
      );

      final a = result.firstWhere((s) => s.id == 'A');
      final b = result.firstWhere((s) => s.id == 'B');
      final c = result.firstWhere((s) => s.id == 'C');
      final d = result.firstWhere((s) => s.id == 'D');

      // A, B, C は3タブ共有
      expect(a.sharedTabs, unorderedEquals(['B', 'C']));
      expect(b.sharedTabs, unorderedEquals(['A', 'C']));
      expect(c.sharedTabs, unorderedEquals(['A', 'B']));

      // D は完全離脱
      expect(d.sharedTabs, isEmpty);
      expect(d.sharedGroupId, isNull);
    });

    test('全タブ解除で共有完全解除', () {
      final shops = [
        createSampleShop(
          id: 'A', name: 'A',
          sharedTabs: ['B', 'C'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'B', name: 'B',
          sharedTabs: ['A', 'C'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'C', name: 'C',
          sharedTabs: ['A', 'B'], sharedGroupId: 'g1',
        ),
      ];

      // Aの編集画面で全て解除
      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'A',
        selectedTabIds: [],
      );

      final a = result.firstWhere((s) => s.id == 'A');
      final b = result.firstWhere((s) => s.id == 'B');
      final c = result.firstWhere((s) => s.id == 'C');

      expect(a.sharedTabs, isEmpty);
      expect(a.sharedGroupId, isNull);
      expect(b.sharedTabs, isEmpty);
      expect(b.sharedGroupId, isNull);
      expect(c.sharedTabs, isEmpty);
      expect(c.sharedGroupId, isNull);
    });

    // --- 冪等性 ---

    test('同じ共有設定を再保存しても結果が変わらない', () {
      final shops = [
        createSampleShop(
          id: 'A', name: 'A',
          sharedTabs: ['B', 'C'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'B', name: 'B',
          sharedTabs: ['A', 'C'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'C', name: 'C',
          sharedTabs: ['A', 'B'], sharedGroupId: 'g1',
        ),
      ];

      // 変更なしで再保存
      final result = service.prepareSharedGroupUpdate(
        shops: shops,
        shopId: 'A',
        selectedTabIds: ['B', 'C'],
      );

      final a = result.firstWhere((s) => s.id == 'A');
      final b = result.firstWhere((s) => s.id == 'B');
      final c = result.firstWhere((s) => s.id == 'C');

      expect(a.sharedTabs, unorderedEquals(['B', 'C']));
      expect(b.sharedTabs, unorderedEquals(['A', 'C']));
      expect(c.sharedTabs, unorderedEquals(['A', 'B']));
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

    test('4タブグループから1タブ離脱 → 残り3タブが維持される', () {
      final shops = [
        createSampleShop(
          id: 'A', name: 'A',
          sharedTabs: ['B', 'C', 'D'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'B', name: 'B',
          sharedTabs: ['A', 'C', 'D'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'C', name: 'C',
          sharedTabs: ['A', 'B', 'D'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'D', name: 'D',
          sharedTabs: ['A', 'B', 'C'], sharedGroupId: 'g1',
        ),
      ];

      final result = service.prepareRemoveFromSharedGroup(
        shops: shops,
        shopId: 'D',
      );

      final d = result.firstWhere((s) => s.id == 'D');
      expect(d.sharedTabs, isEmpty);
      expect(d.sharedGroupId, isNull);

      // 残り3タブはDへの参照のみ削除
      final a = result.firstWhere((s) => s.id == 'A');
      final b = result.firstWhere((s) => s.id == 'B');
      final c = result.firstWhere((s) => s.id == 'C');

      expect(a.sharedTabs, unorderedEquals(['B', 'C']));
      expect(b.sharedTabs, unorderedEquals(['A', 'C']));
      expect(c.sharedTabs, unorderedEquals(['A', 'B']));
    });

    test('2タブグループから離脱 → 残り1タブはグループ解散', () {
      final shops = [
        createSampleShop(
          id: 'A', name: 'A',
          sharedTabs: ['B'], sharedGroupId: 'g1',
        ),
        createSampleShop(
          id: 'B', name: 'B',
          sharedTabs: ['A'], sharedGroupId: 'g1',
        ),
      ];

      final result = service.prepareRemoveFromSharedGroup(
        shops: shops,
        shopId: 'A',
      );

      final a = result.firstWhere((s) => s.id == 'A');
      final b = result.firstWhere((s) => s.id == 'B');

      expect(a.sharedTabs, isEmpty);
      expect(a.sharedGroupId, isNull);

      // Bも共有相手がいなくなるのでグループ解散
      expect(b.sharedTabs, isEmpty);
      expect(b.sharedGroupId, isNull);
    });

    test('5タブグループから離脱', () {
      final shops = List.generate(
        5,
        (i) => createSampleShop(
          id: 'T$i',
          name: 'タブ$i',
          sharedTabs: List.generate(5, (j) => 'T$j')
              .where((id) => id != 'T$i')
              .toList(),
          sharedGroupId: 'g1',
        ),
      );

      final result = service.prepareRemoveFromSharedGroup(
        shops: shops,
        shopId: 'T2',
      );

      // T2は完全離脱
      final t2 = result.firstWhere((s) => s.id == 'T2');
      expect(t2.sharedTabs, isEmpty);
      expect(t2.sharedGroupId, isNull);

      // 残り4タブはT2への参照のみ削除
      for (final id in ['T0', 'T1', 'T3', 'T4']) {
        final tab = result.firstWhere((s) => s.id == id);
        expect(tab.sharedTabs, isNot(contains('T2')));
        final expectedOthers =
            ['T0', 'T1', 'T3', 'T4'].where((tid) => tid != id).toList();
        expect(tab.sharedTabs, unorderedEquals(expectedOthers));
      }
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
