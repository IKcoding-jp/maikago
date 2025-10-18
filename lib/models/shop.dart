import 'list.dart';
import 'sort_mode.dart';

class Shop {
  String id;
  String name;
  List<ListItem> items;
  int? budget;
  DateTime? createdAt;
  SortMode incSortMode;
  SortMode comSortMode;
  // 共有タブ機能のためのフィールド
  List<String> sharedTabs; // 共有するタブのIDリスト
  String? sharedGroupId; // 共有グループのID
  String? sharedGroupIcon; // 共有グループのアイコン名

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
  })  : items = items ?? [],
        incSortMode = incSortMode ?? SortMode.dateNew,
        comSortMode = comSortMode ?? SortMode.dateNew,
        sharedTabs = sharedTabs ?? [];

  /// 不変更新用
  Shop copyWith({
    String? id,
    String? name,
    List<ListItem>? items,
    int? budget,
    DateTime? createdAt,
    bool clearBudget = false, // 予算を削除するかどうか
    SortMode? incSortMode,
    SortMode? comSortMode,
    List<String>? sharedTabs,
    String? sharedGroupId,
    bool clearSharedGroupId = false, // 共有グループIDを削除するかどうか
    String? sharedGroupIcon,
    bool clearSharedGroupIcon = false, // 共有グループアイコンを削除するかどうか
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
        'sharedTabs': sharedTabs,
        'sharedGroupId': sharedGroupId,
        'sharedGroupIcon': sharedGroupIcon,
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
      'sharedTabs': sharedTabs,
      'sharedGroupId': sharedGroupId,
      'sharedGroupIcon': sharedGroupIcon,
    };
  }

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: json['id']?.toString() ?? '',
        name: json['name'],
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => ListItem.fromJson(e))
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

  factory Shop.fromMap(Map<String, dynamic> map) {
    final budget =
        map['budget'] != null ? int.tryParse(map['budget'].toString()) : null;

    return Shop(
      id: map['id']?.toString() ?? '',
      name: map['name'],
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => ListItem.fromMap(e))
              .toList() ??
          [],
      budget: budget,
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      incSortMode: SortMode.values.firstWhere(
        (mode) => mode.name == map['incSortMode'],
        orElse: () => SortMode.dateNew,
      ),
      comSortMode: SortMode.values.firstWhere(
        (mode) => mode.name == map['comSortMode'],
        orElse: () => SortMode.dateNew,
      ),
      sharedTabs: (map['sharedTabs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sharedGroupId: map['sharedGroupId']?.toString(),
      sharedGroupIcon: map['sharedGroupIcon']?.toString(),
    );
  }
}
