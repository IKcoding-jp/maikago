// リスト項目（数量・単価・割引・チェック状態）
class ListItem {
  String id;
  String name;
  int quantity;
  int price;
  double discount;
  bool isChecked;

  /// どのショップに属するか
  String shopId; // どのショップに属するかを示す
  DateTime? createdAt;

  // バーコードスキャン関連のフィールド
  /// 参考価格フラグ
  bool isReferencePrice;

  /// JANコード（バーコード）
  String? janCode;

  /// 商品URL
  String? productUrl;

  /// 商品画像URL
  String? imageUrl;

  /// 店舗名
  String? storeName;

  /// タイムスタンプ（追加日時）
  DateTime? timestamp;

  /// 並べ替え順序（手動並び替え用）
  int sortOrder;

  ListItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.discount = 0.0,
    this.isChecked = false,
    required this.shopId,
    this.createdAt,
    this.isReferencePrice = false,
    this.janCode,
    this.productUrl,
    this.imageUrl,
    this.storeName,
    this.timestamp,
    this.sortOrder = 0,
  });

  ListItem copyWith({
    String? id,
    String? name,
    int? quantity,
    int? price,
    double? discount,
    bool? isChecked,
    String? shopId,
    DateTime? createdAt,
    bool? isReferencePrice,
    String? janCode,
    String? productUrl,
    String? imageUrl,
    String? storeName,
    DateTime? timestamp,
    int? sortOrder,
  }) {
    return ListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      isChecked: isChecked ?? this.isChecked,
      shopId: shopId ?? this.shopId,
      createdAt: createdAt ?? this.createdAt,
      isReferencePrice: isReferencePrice ?? this.isReferencePrice,
      janCode: janCode ?? this.janCode,
      productUrl: productUrl ?? this.productUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      storeName: storeName ?? this.storeName,
      timestamp: timestamp ?? this.timestamp,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'price': price,
        'discount': discount,
        'isChecked': isChecked,
        'shopId': shopId,
        'createdAt': createdAt?.toIso8601String(),
        'isReferencePrice': isReferencePrice,
        'janCode': janCode,
        'productUrl': productUrl,
        'imageUrl': imageUrl,
        'storeName': storeName,
        'timestamp': timestamp?.toIso8601String(),
        'sortOrder': sortOrder,
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'price': price,
        'discount': discount,
        'isChecked': isChecked,
        'shopId': shopId,
        'createdAt': createdAt?.toIso8601String(),
        'isReferencePrice': isReferencePrice,
        'janCode': janCode,
        'productUrl': productUrl,
        'imageUrl': imageUrl,
        'storeName': storeName,
        'timestamp': timestamp?.toIso8601String(),
        'sortOrder': sortOrder,
      };

  factory ListItem.fromJson(Map<String, dynamic> json) => ListItem(
        id: json['id']?.toString() ?? '',
        name: json['name'],
        quantity: json['quantity'],
        price: json['price'],
        discount: (json['discount'] ?? 0).toDouble(),
        isChecked: json['isChecked'] ?? false,
        shopId: json['shopId']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        isReferencePrice: json['isReferencePrice'] ?? false,
        janCode: json['janCode'],
        productUrl: json['productUrl'],
        imageUrl: json['imageUrl'],
        storeName: json['storeName'],
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : null,
        sortOrder: json['sortOrder'] ?? 0,
      );

  factory ListItem.fromMap(Map<String, dynamic> map) => ListItem(
        id: map['id']?.toString() ?? '',
        name: map['name'],
        quantity: map['quantity'],
        price: map['price'],
        discount: (map['discount'] ?? 0).toDouble(),
        isChecked: map['isChecked'] ?? false,
        shopId: map['shopId']?.toString() ?? '',
        createdAt:
            map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
        isReferencePrice: map['isReferencePrice'] ?? false,
        janCode: map['janCode'],
        productUrl: map['productUrl'],
        imageUrl: map['imageUrl'],
        storeName: map['storeName'],
        timestamp:
            map['timestamp'] != null ? DateTime.parse(map['timestamp']) : null,
        sortOrder: map['sortOrder'] ?? 0,
      );

  /// 税込み価格（10%）を取得。割引適用後に税を加算。
  int get priceWithTax {
    final discountedPrice = (price * (1 - discount)).round();
    return (discountedPrice * 1.1).round(); // 10%の消費税
  }
}
