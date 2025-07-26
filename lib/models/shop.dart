import 'item.dart';

class Shop {
  String id;
  String name;
  List<Item> items;
  int? budget;
  DateTime? createdAt;

  Shop({
    required this.id, 
    required this.name, 
    List<Item>? items, 
    this.budget,
    this.createdAt,
  }) : items = items ?? [];

  Shop copyWith({
    String? id, 
    String? name, 
    List<Item>? items, 
    int? budget,
    DateTime? createdAt,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? List.from(this.items),
      budget: budget ?? this.budget,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': items.map((e) => e.toJson()).toList(),
    'budget': budget,
    'createdAt': createdAt?.toIso8601String(),
  };

  Map<String, dynamic> toMap() => {
    'name': name,
    'items': items.map((e) => e.toMap()).toList(),
    'budget': budget,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
    id: json['id']?.toString() ?? '',
    name: json['name'],
    items:
        (json['items'] as List<dynamic>?)
            ?.map((e) => Item.fromJson(e))
            .toList() ??
        [],
    budget: json['budget'],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
  );

  factory Shop.fromMap(Map<String, dynamic> map) => Shop(
    id: map['id']?.toString() ?? '',
    name: map['name'],
    items:
        (map['items'] as List<dynamic>?)
            ?.map((e) => Item.fromMap(e))
            .toList() ??
        [],
    budget: map['budget'],
    createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
  );
}
