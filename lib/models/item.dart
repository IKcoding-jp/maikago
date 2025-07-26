class Item {
  String id;
  String name;
  int quantity;
  int price;
  double discount;
  bool isChecked;
  DateTime? createdAt;

  Item({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.discount = 0.0,
    this.isChecked = false,
    this.createdAt,
  });

  Item copyWith({
    String? id,
    String? name,
    int? quantity,
    int? price,
    double? discount,
    bool? isChecked,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      isChecked: isChecked ?? this.isChecked,
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
    'createdAt': createdAt?.toIso8601String(),
  };

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'price': price,
    'discount': discount,
    'isChecked': isChecked,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json['id']?.toString() ?? '',
    name: json['name'],
    quantity: json['quantity'],
    price: json['price'],
    discount: (json['discount'] ?? 0).toDouble(),
    isChecked: json['isChecked'] ?? false,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
  );

  factory Item.fromMap(Map<String, dynamic> map) => Item(
    id: map['id']?.toString() ?? '',
    name: map['name'],
    quantity: map['quantity'],
    price: map['price'],
    discount: (map['discount'] ?? 0).toDouble(),
    isChecked: map['isChecked'] ?? false,
    createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
  );
}
