import 'item.dart';
import 'sort_mode.dart';

class Shop {
  String id;
  String name;
  List<Item> items;
  int? budget;
  DateTime? createdAt;
  SortMode incSortMode;
  SortMode comSortMode;

  Shop({
    required this.id,
    required this.name,
    List<Item>? items,
    this.budget,
    this.createdAt,
    SortMode? incSortMode,
    SortMode? comSortMode,
  }) : items = items ?? [],
       incSortMode = incSortMode ?? SortMode.dateNew,
       comSortMode = comSortMode ?? SortMode.dateNew;

  /// 不変更新用
  Shop copyWith({
    String? id,
    String? name,
    List<Item>? items,
    int? budget,
    DateTime? createdAt,
    bool clearBudget = false, // 予算を削除するかどうか
    SortMode? incSortMode,
    SortMode? comSortMode,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? List.from(this.items),
      budget: clearBudget
          ? null
          : (budget ?? this.budget), // clearBudgetがtrueの場合はnull、そうでなければ通常の処理
      createdAt: createdAt ?? this.createdAt,
      incSortMode: incSortMode ?? this.incSortMode,
      comSortMode: comSortMode ?? this.comSortMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': items.map((e) => e.toJson()).toList(),
    'budget': budget,
    'createdAt': createdAt?.toIso8601String(),
    'incSortMode': incSortMode.name,
    'comSortMode': comSortMode.name,
  };

  /// Firestore保存用のマップ
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'items': items.map((e) => e.toMap()).toList(),
      'budget': budget,
      'createdAt': createdAt?.toIso8601String(),
      'incSortMode': incSortMode.name,
      'comSortMode': comSortMode.name,
    };
  }

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
    id: json['id']?.toString() ?? '',
    name: json['name'],
    items:
        (json['items'] as List<dynamic>?)
            ?.map((e) => Item.fromJson(e))
            .toList() ??
        [],
    budget: json['budget'] != null
        ? int.tryParse(json['budget'].toString())
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
    incSortMode: SortMode.values.firstWhere(
      (mode) => mode.name == json['incSortMode'],
      orElse: () => SortMode.dateNew,
    ),
    comSortMode: SortMode.values.firstWhere(
      (mode) => mode.name == json['comSortMode'],
      orElse: () => SortMode.dateNew,
    ),
  );

  factory Shop.fromMap(Map<String, dynamic> map) {
    final budget = map['budget'] != null
        ? int.tryParse(map['budget'].toString())
        : null;

    return Shop(
      id: map['id']?.toString() ?? '',
      name: map['name'],
      items:
          (map['items'] as List<dynamic>?)
              ?.map((e) => Item.fromMap(e))
              .toList() ??
          [],
      budget: budget,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      incSortMode: SortMode.values.firstWhere(
        (mode) => mode.name == map['incSortMode'],
        orElse: () => SortMode.dateNew,
      ),
      comSortMode: SortMode.values.firstWhere(
        (mode) => mode.name == map['comSortMode'],
        orElse: () => SortMode.dateNew,
      ),
    );
  }
}
