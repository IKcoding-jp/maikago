/// 商品情報を表すモデルクラス
/// Yahoo!ショッピングAPIから取得した商品データを格納
class ProductInfo {
  /// 商品名
  final String name;

  /// 価格（税込）
  final int price;

  /// JANコード（バーコード）
  final String janCode;

  /// 参考価格フラグ（true: 参考価格、false: 実売価格）
  final bool isReferencePrice;

  /// 最終更新日時
  final DateTime lastUpdated;

  /// 商品URL
  final String? url;

  /// 商品画像URL
  final String? imageUrl;

  /// 店舗名
  final String? storeName;

  const ProductInfo({
    required this.name,
    required this.price,
    required this.janCode,
    required this.isReferencePrice,
    required this.lastUpdated,
    this.url,
    this.imageUrl,
    this.storeName,
  });

  /// JSONからProductInfoオブジェクトを作成
  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      name: json['name'] as String? ?? '',
      price: _parsePrice(json['price']),
      janCode: json['janCode'] as String? ?? '',
      isReferencePrice: json['isReferencePrice'] as bool? ?? false,
      lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '') ??
          DateTime.now(),
      url: json['url'] as String?,
      imageUrl: json['imageUrl'] as String?,
      storeName: json['storeName'] as String?,
    );
  }

  /// ProductInfoオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'janCode': janCode,
      'isReferencePrice': isReferencePrice,
      'lastUpdated': lastUpdated.toIso8601String(),
      'url': url,
      'imageUrl': imageUrl,
      'storeName': storeName,
    };
  }

  /// 価格を適切な形式でパース
  static int _parsePrice(dynamic price) {
    if (price is int) return price;
    if (price is double) return price.round();
    if (price is String) {
      // カンマや円マークを除去して数値に変換
      final cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(cleanPrice) ?? 0;
    }
    return 0;
  }

  /// バリデーション
  bool get isValid {
    // バーコードスキャン商品（参考価格）の場合は価格0でも有効
    if (isReferencePrice) {
      return name.isNotEmpty && janCode.isNotEmpty;
    }
    // 通常の商品（実売価格）の場合は価格が0より大きい必要がある
    return name.isNotEmpty && janCode.isNotEmpty && price > 0;
  }

  /// 価格をフォーマットした文字列で取得
  String get formattedPrice {
    return '¥${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  /// 参考価格かどうかを示す文字列
  String get priceTypeText {
    return isReferencePrice ? '参考価格' : '実売価格';
  }

  /// コピーを作成（一部のフィールドを変更）
  ProductInfo copyWith({
    String? name,
    int? price,
    String? janCode,
    bool? isReferencePrice,
    DateTime? lastUpdated,
    String? url,
    String? imageUrl,
    String? storeName,
  }) {
    return ProductInfo(
      name: name ?? this.name,
      price: price ?? this.price,
      janCode: janCode ?? this.janCode,
      isReferencePrice: isReferencePrice ?? this.isReferencePrice,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      storeName: storeName ?? this.storeName,
    );
  }

  @override
  String toString() {
    return 'ProductInfo(name: $name, price: $formattedPrice, janCode: $janCode, isReferencePrice: $isReferencePrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductInfo &&
        other.name == name &&
        other.price == price &&
        other.janCode == janCode &&
        other.isReferencePrice == isReferencePrice &&
        other.lastUpdated == lastUpdated &&
        other.url == url &&
        other.imageUrl == imageUrl &&
        other.storeName == storeName;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      price,
      janCode,
      isReferencePrice,
      lastUpdated,
      url,
      imageUrl,
      storeName,
    );
  }
}
