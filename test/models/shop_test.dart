import 'package:flutter_test/flutter_test.dart';
import 'package:maikago/models/shop.dart';
import 'package:maikago/models/sort_mode.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Shop', () {
    group('コンストラクタ', () {
      test('必須フィールドのみで生成できる', () {
        final shop = Shop(id: '0', name: 'デフォルト');

        expect(shop.id, '0');
        expect(shop.name, 'デフォルト');
        expect(shop.items, isEmpty);
        expect(shop.budget, isNull);
        expect(shop.createdAt, isNull);
        expect(shop.incSortMode, SortMode.dateNew);
        expect(shop.comSortMode, SortMode.dateNew);
        expect(shop.sharedTabs, isEmpty);
        expect(shop.sharedGroupId, isNull);
        expect(shop.sharedGroupIcon, isNull);
      });

      test('全フィールドを指定して生成できる', () {
        final items = [createSampleItem()];
        final createdAt = DateTime(2026, 1, 1);
        final shop = Shop(
          id: '1',
          name: 'スーパー',
          items: items,
          budget: 5000,
          createdAt: createdAt,
          incSortMode: SortMode.priceAsc,
          comSortMode: SortMode.dateOld,
          sharedTabs: ['tab1', 'tab2'],
          sharedGroupId: 'group_1',
          sharedGroupIcon: 'star',
        );

        expect(shop.items.length, 1);
        expect(shop.budget, 5000);
        expect(shop.createdAt, createdAt);
        expect(shop.incSortMode, SortMode.priceAsc);
        expect(shop.comSortMode, SortMode.dateOld);
        expect(shop.sharedTabs, ['tab1', 'tab2']);
        expect(shop.sharedGroupId, 'group_1');
        expect(shop.sharedGroupIcon, 'star');
      });
    });

    group('copyWith', () {
      test('指定したフィールドのみ更新される', () {
        final shop = createSampleShop(name: '元の名前', budget: 3000);
        final copied = shop.copyWith(name: '新しい名前', budget: 5000);

        expect(copied.name, '新しい名前');
        expect(copied.budget, 5000);
        expect(copied.id, shop.id);
      });

      test('clearBudgetでbudgetをnullにできる', () {
        final shop = createSampleShop(budget: 5000);
        final copied = shop.copyWith(clearBudget: true);

        expect(copied.budget, isNull);
      });

      test('clearSharedGroupIdでsharedGroupIdをnullにできる', () {
        final shop = createSampleShop(sharedGroupId: 'group_1');
        final copied = shop.copyWith(clearSharedGroupId: true);

        expect(copied.sharedGroupId, isNull);
      });

      test('itemsはイミュータブルである', () {
        final items = [createSampleItem(id: '1', name: '商品A')];
        final shop = createSampleShop(items: items);

        // 直接変更はUnsupportedErrorを発生させる
        expect(
          () => shop.items.add(createSampleItem(id: '2', name: '商品B')),
          throwsUnsupportedError,
        );
        expect(shop.items.length, 1);
      });

      test('copyWithでitemsを変更しても元のインスタンスに影響しない', () {
        final items = [createSampleItem(id: '1', name: '商品A')];
        final shop = createSampleShop(items: items);
        final copied = shop.copyWith(
          items: [...shop.items, createSampleItem(id: '2', name: '商品B')],
        );

        expect(shop.items.length, 1);
        expect(copied.items.length, 2);
      });
    });

    group('イミュータブル性', () {
      test('sharedTabsはイミュータブルである', () {
        final shop = createSampleShop(sharedTabs: ['tab1', 'tab2']);

        expect(
          () => shop.sharedTabs.add('tab3'),
          throwsUnsupportedError,
        );
        expect(shop.sharedTabs.length, 2);
      });
    });

    group('fromJson 型安全性', () {
      test('nameがnullの場合にデフォルト値が適用される', () {
        final json = <String, dynamic>{
          'id': '1',
          'name': null,
        };

        final shop = Shop.fromJson(json);
        expect(shop.name, '');
      });
    });

    group('toJson / fromJson', () {
      test('正常にシリアライズ・デシリアライズできる', () {
        final items = [
          createSampleItem(id: '1', name: 'りんご', price: 100),
          createSampleItem(id: '2', name: 'バナナ', price: 200),
        ];
        final createdAt = DateTime(2026, 2, 1, 10, 0, 0);
        final shop = Shop(
          id: 'shop_1',
          name: 'スーパー',
          items: items,
          budget: 5000,
          createdAt: createdAt,
          incSortMode: SortMode.priceAsc,
          comSortMode: SortMode.dateOld,
          sharedTabs: ['tab1'],
          sharedGroupId: 'group_1',
          sharedGroupIcon: 'cart',
        );

        final json = shop.toJson();
        final restored = Shop.fromJson(json);

        expect(restored.id, shop.id);
        expect(restored.name, shop.name);
        expect(restored.items.length, 2);
        expect(restored.items[0].name, 'りんご');
        expect(restored.items[1].name, 'バナナ');
        expect(restored.budget, 5000);
        expect(restored.createdAt, createdAt);
        expect(restored.incSortMode, SortMode.priceAsc);
        expect(restored.comSortMode, SortMode.dateOld);
        expect(restored.sharedTabs, ['tab1']);
        expect(restored.sharedGroupId, 'group_1');
        expect(restored.sharedGroupIcon, 'cart');
      });

      test('null値のフィールドを正しくハンドリングする', () {
        final json = {
          'id': '0',
          'name': 'テスト',
        };

        final shop = Shop.fromJson(json);

        expect(shop.id, '0');
        expect(shop.name, 'テスト');
        expect(shop.items, isEmpty);
        expect(shop.budget, isNull);
        expect(shop.createdAt, isNull);
        expect(shop.incSortMode, SortMode.dateNew);
        expect(shop.comSortMode, SortMode.dateNew);
        expect(shop.sharedTabs, isEmpty);
      });

      test('budgetが文字列の場合もパースできる', () {
        final json = {
          'id': '0',
          'name': 'テスト',
          'budget': '3000',
        };

        final shop = Shop.fromJson(json);
        expect(shop.budget, 3000);
      });

      test('不正なSortMode値はデフォルト値にフォールバックする', () {
        final json = {
          'id': '0',
          'name': 'テスト',
          'incSortMode': 'invalid_mode',
          'comSortMode': 'unknown',
        };

        final shop = Shop.fromJson(json);
        expect(shop.incSortMode, SortMode.dateNew);
        expect(shop.comSortMode, SortMode.dateNew);
      });
    });

    group('toMap / fromMap', () {
      test('正常にシリアライズ・デシリアライズできる', () {
        final shop = createSampleShop(
          id: 'map_test',
          name: 'マップテスト',
          budget: 2000,
        );

        final map = shop.toMap();
        final restored = Shop.fromMap(map);

        expect(restored.id, shop.id);
        expect(restored.name, shop.name);
        expect(restored.budget, shop.budget);
      });
    });
  });
}
