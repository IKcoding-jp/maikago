class Item {
  String id;
  String name;
  int quantity;
  int price;
  double discount;
  bool isChecked;
  String shopId; // どのショップに属するかを示す
  DateTime? createdAt;

  Item({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.discount = 0.0,
    this.isChecked = false,
    required this.shopId,
    this.createdAt,
  });

  Item copyWith({
    String? id,
    String? name,
    int? quantity,
    int? price,
    double? discount,
    bool? isChecked,
    String? shopId,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      isChecked: isChecked ?? this.isChecked,
      shopId: shopId ?? this.shopId,
      createdAt: createdAt ?? this.createdAt,
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
  };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
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
  );

  factory Item.fromMap(Map<String, dynamic> map) => Item(
    id: map['id']?.toString() ?? '',
    name: map['name'],
    quantity: map['quantity'],
    price: map['price'],
    discount: (map['discount'] ?? 0).toDouble(),
    isChecked: map['isChecked'] ?? false,
    shopId: map['shopId']?.toString() ?? '',
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : null,
  );
}
