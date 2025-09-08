import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product_info.dart';
import 'product_name_summarizer_service.dart';

/// Yahoo!ショッピングAPIとの通信を行うサービスクラス
class YahooShoppingService {
  static const String _baseUrl =
      'https://shopping.yahooapis.jp/ShoppingWebService/V3/itemSearch';
  static const String _appId =
      'dj00aiZpPUd3R1kzSG13OWdOMiZzPWNvbnN1bWVyc2VjcmV0Jng9MWI-';

  /// JANコードから商品情報を取得
  ///
  /// [janCode] JANコード（バーコード）
  /// 戻り値: 商品情報のリスト（複数の店舗で販売されている場合）
  static Future<List<ProductInfo>> getProductInfoByJanCode(
      String janCode) async {
    try {
      // 利用回数チェック
      _checkDailyRequestLimit();

      log('YahooShoppingService: JANコード $janCode で商品情報を検索開始');

      // JANコードのバリデーション
      if (!_isValidJanCode(janCode)) {
        throw YahooShoppingException('無効なJANコードです: $janCode');
      }

      // APIリクエストの構築
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'appid': _appId,
        'jan_code': janCode, // JANコード検索用パラメータ
        'results': '1', // 商品名確認のため1件のみ
      });

      log('YahooShoppingService: APIリクエスト送信 - $uri');

      // HTTPリクエストの実行
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Maikago/1.0.2',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw YahooShoppingException('APIリクエストがタイムアウトしました');
        },
      );

      log('YahooShoppingService: APIレスポンス受信 - ステータス: ${response.statusCode}');

      // レスポンスの処理
      if (response.statusCode == 200) {
        // 成功したリクエストをカウント
        _incrementRequestCount();
        return await _parseResponse(response.body, janCode);
      } else if (response.statusCode == 429) {
        // API利用制限に達した場合
        throw YahooShoppingRateLimitException(
            'API利用制限に達しました。しばらく時間をおいてから再度お試しください。');
      } else if (response.statusCode == 403) {
        // 認証エラー
        throw YahooShoppingException('API認証エラーです。アプリケーションIDを確認してください。');
      } else {
        throw YahooShoppingException(
            'APIエラー: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('YahooShoppingService: エラー発生 - $e');
      if (e is YahooShoppingException) {
        rethrow;
      } else {
        throw YahooShoppingException('商品情報の取得に失敗しました: $e');
      }
    }
  }

  /// APIレスポンスを解析してProductInfoリストに変換
  static Future<List<ProductInfo>> _parseResponse(
      String responseBody, String janCode) async {
    try {
      // デバッグログ（本番環境では無効化）
      // log('YahooShoppingService: レスポンス解析開始');
      // log('YahooShoppingService: レスポンスボディ: $responseBody');

      final jsonData = json.decode(responseBody);
      // log('YahooShoppingService: 解析されたJSON: $jsonData');

      final hits = jsonData['hits'] as List<dynamic>? ?? [];
      log('YahooShoppingService: hits配列の長さ: ${hits.length}');

      if (hits.isEmpty) {
        throw YahooShoppingException('商品が見つかりませんでした');
      }

      final products = <ProductInfo>[];

      for (int i = 0; i < hits.length; i++) {
        try {
          final hit = hits[i];
          // log('YahooShoppingService: 商品データ[$i]: $hit');

          final product = await _parseProduct(hit, janCode);
          if (product.isValid) {
            products.add(product);
            log('YahooShoppingService: 商品[$i]解析成功: ${product.name}');
          } else {
            log('YahooShoppingService: 商品[$i]は無効: ${product.name}');
          }
        } catch (e) {
          log('YahooShoppingService: 商品データ[$i]の解析エラー - $e');
          // 個別の商品解析エラーは無視して続行
        }
      }

      if (products.isEmpty) {
        throw YahooShoppingException('有効な商品情報が見つかりませんでした');
      }

      log('YahooShoppingService: ${products.length}件の商品情報を取得');
      return products;
    } catch (e) {
      log('YahooShoppingService: レスポンス解析エラー - $e');
      throw YahooShoppingException('商品情報の解析に失敗しました: $e');
    }
  }

  /// 個別の商品データをProductInfoに変換
  static Future<ProductInfo> _parseProduct(
      Map<String, dynamic> hit, String janCode) async {
    // 安全な名前取得（int型の場合も考慮）
    String originalName = '';
    final nameValue = hit['name'];
    if (nameValue is String) {
      originalName = nameValue;
    } else if (nameValue is int) {
      originalName = nameValue.toString();
    } else if (nameValue != null) {
      originalName = nameValue.toString();
    }

    // 商品名を要約（GPT-4o-miniを使用）
    String name = originalName;
    if (originalName.length > 20) {
      // 条件を緩和（30文字→20文字）
      try {
        name = await ProductNameSummarizerService.summarizeProductName(
            originalName);
        debugPrint('📝 商品名要約: "$originalName" → "$name"');
      } catch (e) {
        debugPrint('⚠️ 商品名要約エラー: $e');
        // エラーの場合は元の名前を使用
        name = originalName;
      }
    }

    // 参考価格として価格を取得
    final price = _extractPrice(hit);

    // 安全なURL取得
    String? url;
    final urlValue = hit['url'];
    if (urlValue is String) {
      url = urlValue;
    } else if (urlValue != null) {
      url = urlValue.toString();
    }

    // 安全な画像URL取得
    String? imageUrl;
    final imageData = hit['image'];
    if (imageData is Map<String, dynamic>) {
      final mediumValue = imageData['medium'];
      if (mediumValue is String) {
        imageUrl = mediumValue;
      } else if (mediumValue != null) {
        imageUrl = mediumValue.toString();
      }
    }

    // 安全な店舗名取得
    String? storeName;
    final storeData = hit['store'];
    if (storeData is Map<String, dynamic>) {
      final nameValue = storeData['name'];
      if (nameValue is String) {
        storeName = nameValue;
      } else if (nameValue is int) {
        storeName = nameValue.toString();
      } else if (nameValue != null) {
        storeName = nameValue.toString();
      }
    }

    // バーコードスキャンで取得した商品は常に参考価格として扱う
    const isReferencePrice = true;

    return ProductInfo(
      name: name,
      price: price,
      janCode: janCode,
      isReferencePrice: isReferencePrice,
      lastUpdated: DateTime.now(),
      url: url,
      imageUrl: imageUrl,
      storeName: storeName,
    );
  }

  /// JANコードのバリデーション
  static bool _isValidJanCode(String janCode) {
    if (janCode.isEmpty) return false;

    // 数字のみかチェック
    if (!RegExp(r'^\d+$').hasMatch(janCode)) return false;

    // 長さチェック（EAN-13: 13桁、EAN-8: 8桁、UPC-A: 12桁、UPC-E: 8桁）
    final validLengths = [8, 12, 13];
    return validLengths.contains(janCode.length);
  }

  /// 最も安い価格の商品を取得
  static Future<ProductInfo?> getCheapestProduct(String janCode) async {
    try {
      final products = await getProductInfoByJanCode(janCode);
      if (products.isEmpty) return null;

      // 価格の安い順にソートして最初の商品を返す
      products.sort((a, b) => a.price.compareTo(b.price));
      return products.first;
    } catch (e) {
      log('YahooShoppingService: 最安値商品取得エラー - $e');
      return null;
    }
  }

  /// API利用回数の監視
  static int _dailyRequestCount = 0;
  static DateTime? _lastResetDate;
  static const int _maxDailyRequests = 50000; // Yahoo!ショッピングAPIの制限
  static const int _warningThreshold = 45000; // 警告表示の閾値

  /// 商品情報のキャッシュ（将来の実装用）
  static final Map<String, List<ProductInfo>> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// キャッシュから商品情報を取得
  static List<ProductInfo>? getCachedProductInfo(String janCode) {
    final timestamp = _cacheTimestamps[janCode];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      _cache.remove(janCode);
      _cacheTimestamps.remove(janCode);
      return null;
    }

    return _cache[janCode];
  }

  /// 商品情報をキャッシュに保存
  static void cacheProductInfo(String janCode, List<ProductInfo> products) {
    _cache[janCode] = products;
    _cacheTimestamps[janCode] = DateTime.now();
  }

  /// キャッシュをクリア
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// 価格情報を抽出
  static int _extractPrice(Map<String, dynamic> hit) {
    final priceValue = hit['price'];

    // int型の場合
    if (priceValue is int && priceValue > 0) {
      return priceValue;
    }

    // String型の場合
    if (priceValue is String) {
      final cleanPrice = priceValue.replaceAll(RegExp(r'[^\d]'), '');
      final parsedPrice = int.tryParse(cleanPrice);
      if (parsedPrice != null && parsedPrice > 0) {
        return parsedPrice;
      }
    }

    // double型の場合
    if (priceValue is double && priceValue > 0) {
      return priceValue.toInt();
    }

    // その他の型の場合、文字列に変換してから解析
    if (priceValue != null) {
      final priceStr = priceValue.toString();
      final cleanPrice = priceStr.replaceAll(RegExp(r'[^\d]'), '');
      final parsedPrice = int.tryParse(cleanPrice);
      if (parsedPrice != null && parsedPrice > 0) {
        return parsedPrice;
      }
    }

    return 0;
  }

  /// 日次利用回数制限のチェック
  static void _checkDailyRequestLimit() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 日付が変わった場合はカウンターをリセット
    if (_lastResetDate == null || _lastResetDate!.isBefore(today)) {
      _dailyRequestCount = 0;
      _lastResetDate = today;
      log('YahooShoppingService: 日次利用回数カウンターをリセット');
    }

    // 制限チェック
    if (_dailyRequestCount >= _maxDailyRequests) {
      throw YahooShoppingRateLimitException(
          '本日のAPI利用制限（$_maxDailyRequests回）に達しました。明日までお待ちください。');
    }

    // 警告閾値チェック
    if (_dailyRequestCount >= _warningThreshold) {
      log('⚠️ YahooShoppingService: API利用回数が警告閾値に近づいています（$_dailyRequestCount/$_maxDailyRequests）');
    }
  }

  /// リクエスト回数をインクリメント
  static void _incrementRequestCount() {
    _dailyRequestCount++;
    log('YahooShoppingService: API利用回数: $_dailyRequestCount/$_maxDailyRequests');
  }

  /// 現在の利用回数を取得
  static int getCurrentRequestCount() {
    _checkDailyRequestLimit(); // 日付チェックを実行
    return _dailyRequestCount;
  }

  /// 利用制限の残り回数を取得
  static int getRemainingRequests() {
    _checkDailyRequestLimit(); // 日付チェックを実行
    return _maxDailyRequests - _dailyRequestCount;
  }
}

/// Yahoo!ショッピングAPI関連の例外クラス
class YahooShoppingException implements Exception {
  final String message;

  const YahooShoppingException(this.message);

  @override
  String toString() => 'YahooShoppingException: $message';
}

/// Yahoo!ショッピングAPI利用制限例外クラス
class YahooShoppingRateLimitException implements Exception {
  final String message;

  const YahooShoppingRateLimitException(this.message);

  @override
  String toString() => 'YahooShoppingRateLimitException: $message';
}
