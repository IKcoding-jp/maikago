import 'package:maikago/models/list.dart';
import 'package:maikago/models/sort_mode.dart';

class Shop {
  Shop({
    required this.id,
    required this.name,
    List<ListItem>? items,
    this.budget,
    this.createdAt,
    SortMode? incSortMode,
    SortMode? comSortMode,
    List<String>? sharedTabs,
    this.sharedGroupId,
    this.sharedGroupIcon,
  })  : items = List.unmodifiable(items ?? const []),
        incSortMode = incSortMode ?? SortMode.dateNew,
        comSortMode = comSortMode ?? SortMode.dateNew,
        sharedTabs = List.unmodifiable(sharedTabs ?? const []);

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => ListItem.fromJson(e as Map<String, dynamic>))
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
        sharedTabs: (json['sharedTabs'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        sharedGroupId: json['sharedGroupId']?.toString(),
        sharedGroupIcon: json['sharedGroupIcon']?.toString(),
      );

  factory Shop.fromMap(Map<String, dynamic> map) => Shop.fromJson(map);

  final String id;
  final String name;
  final List<ListItem> items;
  final int? budget;
  final DateTime? createdAt;
  final SortMode incSortMode;
  final SortMode comSortMode;
  final List<String> sharedTabs;
  final String? sharedGroupId;
  final String? sharedGroupIcon;

  /// 不変更新用
  Shop copyWith({
    String? id,
    String? name,
    List<ListItem>? items,
    int? budget,
    DateTime? createdAt,
    bool clearBudget = false,
    SortMode? incSortMode,
    SortMode? comSortMode,
    List<String>? sharedTabs,
    String? sharedGroupId,
    bool clearSharedGroupId = false,
    String? sharedGroupIcon,
    bool clearSharedGroupIcon = false,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? List.from(this.items),
      budget: clearBudget ? null : (budget ?? this.budget),
      createdAt: createdAt ?? this.createdAt,
      incSortMode: incSortMode ?? this.incSortMode,
      comSortMode: comSortMode ?? this.comSortMode,
      sharedTabs: sharedTabs ?? List.from(this.sharedTabs),
      sharedGroupId:
          clearSharedGroupId ? null : (sharedGroupId ?? this.sharedGroupId),
      sharedGroupIcon: clearSharedGroupIcon
          ? null
          : (sharedGroupIcon ?? this.sharedGroupIcon),
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
        'sharedTabs': sharedTabs.toList(),
        'sharedGroupId': sharedGroupId,
        'sharedGroupIcon': sharedGroupIcon,
      };

  Map<String, dynamic> toMap() => toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shop && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
