import 'item.dart';
import 'package:flutter/foundation.dart';
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

  Map<String, dynamic> toMap() {
    debugPrint('Shop.toMap 呼び出し'); // デバッグ用
    debugPrint('保存する予算: $budget'); // デバッグ用

    final map = {
      'id': id,
      'name': name,
      'items': items.map((e) => e.toMap()).toList(),
      'budget': budget,
      'createdAt': createdAt?.toIso8601String(),
      'incSortMode': incSortMode.name,
      'comSortMode': comSortMode.name,
    };

    debugPrint('toMap結果: $map'); // デバッグ用
    return map;
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
    debugPrint('Shop.fromMap 呼び出し'); // デバッグ用
    debugPrint('map[\'budget\'] の値: ${map['budget']}'); // デバッグ用
    debugPrint('map[\'budget\'] の型: ${map['budget']?.runtimeType}'); // デバッグ用

    final budget = map['budget'] != null
        ? int.tryParse(map['budget'].toString())
        : null;
    debugPrint('変換後の budget: $budget'); // デバッグ用

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
