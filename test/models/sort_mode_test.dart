import 'package:flutter_test/flutter_test.dart';
import 'package:maikago/models/sort_mode.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('SortMode', () {
    test('すべてのモードにラベルが設定されている', () {
      for (final mode in SortMode.values) {
        expect(mode.label, isNotEmpty);
      }
    });

    test('7つのソートモードが存在する', () {
      expect(SortMode.values.length, 7);
    });
  });

  group('comparatorFor', () {
    group('manual (手動並び替え)', () {
      test('sortOrderの昇順でソートされる', () {
        final items = [
          createSampleItem(id: 'a', sortOrder: 3),
          createSampleItem(id: 'b', sortOrder: 1),
          createSampleItem(id: 'c', sortOrder: 2),
        ];

        items.sort(comparatorFor(SortMode.manual));

        expect(items[0].sortOrder, 1);
        expect(items[1].sortOrder, 2);
        expect(items[2].sortOrder, 3);
      });

      test('sortOrderが同じ場合はidでソートされる', () {
        final items = [
          createSampleItem(id: 'c', sortOrder: 1),
          createSampleItem(id: 'a', sortOrder: 1),
          createSampleItem(id: 'b', sortOrder: 1),
        ];

        items.sort(comparatorFor(SortMode.manual));

        expect(items[0].id, 'a');
        expect(items[1].id, 'b');
        expect(items[2].id, 'c');
      });
    });

    group('qtyAsc (個数 少ない順)', () {
      test('数量の昇順でソートされる', () {
        final items = [
          createSampleItem(id: '1', quantity: 5),
          createSampleItem(id: '2', quantity: 1),
          createSampleItem(id: '3', quantity: 3),
        ];

        items.sort(comparatorFor(SortMode.qtyAsc));

        expect(items[0].quantity, 1);
        expect(items[1].quantity, 3);
        expect(items[2].quantity, 5);
      });
    });

    group('qtyDesc (個数 多い順)', () {
      test('数量の降順でソートされる', () {
        final items = [
          createSampleItem(id: '1', quantity: 1),
          createSampleItem(id: '2', quantity: 5),
          createSampleItem(id: '3', quantity: 3),
        ];

        items.sort(comparatorFor(SortMode.qtyDesc));

        expect(items[0].quantity, 5);
        expect(items[1].quantity, 3);
        expect(items[2].quantity, 1);
      });
    });

    group('priceAsc (値段 安い順)', () {
      test('価格の昇順でソートされる', () {
        final items = [
          createSampleItem(id: '1', price: 500),
          createSampleItem(id: '2', price: 100),
          createSampleItem(id: '3', price: 300),
        ];

        items.sort(comparatorFor(SortMode.priceAsc));

        expect(items[0].price, 100);
        expect(items[1].price, 300);
        expect(items[2].price, 500);
      });
    });

    group('priceDesc (値段 高い順)', () {
      test('価格の降順でソートされる', () {
        final items = [
          createSampleItem(id: '1', price: 100),
          createSampleItem(id: '2', price: 500),
          createSampleItem(id: '3', price: 300),
        ];

        items.sort(comparatorFor(SortMode.priceDesc));

        expect(items[0].price, 500);
        expect(items[1].price, 300);
        expect(items[2].price, 100);
      });
    });

    group('dateNew (追加が新しい順)', () {
      test('作成日時の降順でソートされる', () {
        final items = [
          createSampleItem(id: '1', createdAt: DateTime(2026, 1, 1)),
          createSampleItem(id: '2', createdAt: DateTime(2026, 1, 3)),
          createSampleItem(id: '3', createdAt: DateTime(2026, 1, 2)),
        ];

        items.sort(comparatorFor(SortMode.dateNew));

        expect(items[0].createdAt, DateTime(2026, 1, 3));
        expect(items[1].createdAt, DateTime(2026, 1, 2));
        expect(items[2].createdAt, DateTime(2026, 1, 1));
      });
    });

    group('dateOld (追加が古い順)', () {
      test('作成日時の昇順でソートされる', () {
        final items = [
          createSampleItem(id: '1', createdAt: DateTime(2026, 1, 3)),
          createSampleItem(id: '2', createdAt: DateTime(2026, 1, 1)),
          createSampleItem(id: '3', createdAt: DateTime(2026, 1, 2)),
        ];

        items.sort(comparatorFor(SortMode.dateOld));

        expect(items[0].createdAt, DateTime(2026, 1, 1));
        expect(items[1].createdAt, DateTime(2026, 1, 2));
        expect(items[2].createdAt, DateTime(2026, 1, 3));
      });
    });
  });
}
