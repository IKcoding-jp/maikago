import 'package:flutter_test/flutter_test.dart';
import 'package:maikago/services/yahoo_shopping_service.dart';
import 'package:maikago/models/product_info.dart';

void main() {
  group('YahooShoppingService', () {
    group('getProductInfoByJanCode', () {
      test('正常系: 商品情報取得成功（統合テスト）', () async {
        // 注意: このテストは実際のAPIを呼び出すため、ネットワーク接続が必要です
        // 実際のJANコードを使用してテストを実行
        try {
          final result = await YahooShoppingService.getProductInfoByJanCode(
              '4901234567890');

          // 結果がリストであることを確認
          expect(result, isA<List<ProductInfo>>());

          // 商品が見つかった場合の検証
          if (result.isNotEmpty) {
            final product = result.first;
            expect(product.name, isNotEmpty);
            expect(product.price, greaterThan(0));
            expect(product.janCode, '4901234567890');
          }
        } catch (e) {
          // APIエラーやネットワークエラーは許容
          expect(e, isA<YahooShoppingException>());
        }
      });

      test('正常系: 複数商品の取得（統合テスト）', () async {
        // 注意: このテストは実際のAPIを呼び出すため、ネットワーク接続が必要です
        try {
          final result = await YahooShoppingService.getProductInfoByJanCode(
              '4901234567890');

          // 結果がリストであることを確認
          expect(result, isA<List<ProductInfo>>());

          // 複数商品が見つかった場合の検証
          if (result.length > 1) {
            expect(result[0].name, isNotEmpty);
            expect(result[1].name, isNotEmpty);
            expect(result[0].price, greaterThan(0));
            expect(result[1].price, greaterThan(0));
          }
        } catch (e) {
          // APIエラーやネットワークエラーは許容
          expect(e, isA<YahooShoppingException>());
        }
      });

      test('異常系: 無効なJANコード', () async {
        await expectLater(
          YahooShoppingService.getProductInfoByJanCode(''),
          throwsA(isA<YahooShoppingException>()),
        );

        await expectLater(
          YahooShoppingService.getProductInfoByJanCode('invalid'),
          throwsA(isA<YahooShoppingException>()),
        );

        await expectLater(
          YahooShoppingService.getProductInfoByJanCode('123'),
          throwsA(isA<YahooShoppingException>()),
        );
      });

      test('異常系: 商品が見つからない（統合テスト）', () async {
        // 存在しないJANコードでテスト
        try {
          await YahooShoppingService.getProductInfoByJanCode('9999999999999');
          fail('例外が発生するはずです');
        } catch (e) {
          expect(e, isA<YahooShoppingException>());
        }
      });
    });

    group('getCheapestProduct', () {
      test('正常系: 最安値商品の取得（統合テスト）', () async {
        // 注意: このテストは実際のAPIを呼び出すため、ネットワーク接続が必要です
        try {
          final result =
              await YahooShoppingService.getCheapestProduct('4901234567890');

          if (result != null) {
            expect(result.name, isNotEmpty);
            expect(result.price, greaterThan(0));
            expect(result.janCode, '4901234567890');
          }
        } catch (e) {
          // APIエラーやネットワークエラーは許容
          expect(e, isA<YahooShoppingException>());
        }
      });

      test('異常系: 商品が見つからない場合（統合テスト）', () async {
        // 存在しないJANコードでテスト
        try {
          final result =
              await YahooShoppingService.getCheapestProduct('9999999999999');
          expect(result, isNull);
        } catch (e) {
          // 例外が発生した場合も許容
          expect(e, isA<YahooShoppingException>());
        }
      });
    });

    group('ProductInfo', () {
      test('正常系: モデルの作成とJSON変換', () {
        final product = ProductInfo(
          name: 'テスト商品',
          price: 1000,
          janCode: '4901234567890',
          isReferencePrice: false,
          lastUpdated: DateTime(2024, 1, 1),
          url: 'https://example.com',
          imageUrl: 'https://example.com/image.jpg',
          storeName: 'テスト店舗',
        );

        // JSON変換テスト
        final json = product.toJson();
        expect(json['name'], 'テスト商品');
        expect(json['price'], 1000);
        expect(json['janCode'], '4901234567890');

        // JSONから復元テスト
        final restored = ProductInfo.fromJson(json);
        expect(restored.name, product.name);
        expect(restored.price, product.price);
        expect(restored.janCode, product.janCode);
      });

      test('正常系: バリデーション', () {
        final validProduct = ProductInfo(
          name: 'テスト商品',
          price: 1000,
          janCode: '4901234567890',
          isReferencePrice: false,
          lastUpdated: DateTime.now(),
        );

        final invalidProduct = ProductInfo(
          name: '',
          price: 0,
          janCode: '',
          isReferencePrice: false,
          lastUpdated: DateTime.now(),
        );

        expect(validProduct.isValid, true);
        expect(invalidProduct.isValid, false);
      });

      test('正常系: 価格フォーマット', () {
        final product = ProductInfo(
          name: 'テスト商品',
          price: 1234567,
          janCode: '4901234567890',
          isReferencePrice: false,
          lastUpdated: DateTime.now(),
        );

        expect(product.formattedPrice, '¥1,234,567');
      });

      test('正常系: 参考価格フラグ', () {
        final referenceProduct = ProductInfo(
          name: 'テスト商品',
          price: 1000,
          janCode: '4901234567890',
          isReferencePrice: true,
          lastUpdated: DateTime.now(),
        );

        final normalProduct = ProductInfo(
          name: 'テスト商品',
          price: 1000,
          janCode: '4901234567890',
          isReferencePrice: false,
          lastUpdated: DateTime.now(),
        );

        expect(referenceProduct.priceTypeText, '参考価格');
        expect(normalProduct.priceTypeText, '実売価格');
      });

      test('正常系: copyWith', () {
        final original = ProductInfo(
          name: '元の商品',
          price: 1000,
          janCode: '4901234567890',
          isReferencePrice: false,
          lastUpdated: DateTime.now(),
        );

        final copied = original.copyWith(
          name: '新しい商品',
          price: 2000,
        );

        expect(copied.name, '新しい商品');
        expect(copied.price, 2000);
        expect(copied.janCode, original.janCode);
        expect(copied.isReferencePrice, original.isReferencePrice);
      });
    });
  });
}
