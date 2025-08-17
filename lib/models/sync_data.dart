import 'item.dart';

/// 同期データを表すモデルクラス
class SyncData {
  final String id;
  final String userId;
  final SyncDataType type;
  final String? shopId;
  final String? shopName;
  final List<Item> items;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? appliedAt;
  final List<String> sharedWith;
  final bool isActive;

  SyncData({
    required this.id,
    required this.userId,
    required this.type,
    this.shopId,
    this.shopName,
    required this.items,
    required this.title,
    required this.description,
    required this.createdAt,
    this.appliedAt,
    required this.sharedWith,
    this.isActive = true,
  });

  SyncData copyWith({
    String? id,
    String? userId,
    SyncDataType? type,
    String? shopId,
    String? shopName,
    List<Item>? items,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? appliedAt,
    List<String>? sharedWith,
    bool? isActive,
  }) {
    return SyncData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      items: items ?? this.items,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      appliedAt: appliedAt ?? this.appliedAt,
      sharedWith: sharedWith ?? this.sharedWith,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'shopId': shopId,
      'shopName': shopName,
      'items': items.map((item) => item.toMap()).toList(),
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'appliedAt': appliedAt?.toIso8601String(),
      'sharedWith': sharedWith,
      'isActive': isActive,
    };
  }

  factory SyncData.fromMap(Map<String, dynamic> map) {
    return SyncData(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      type: SyncDataType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => SyncDataType.tab,
      ),
      shopId: map['shopId']?.toString(),
      shopName: map['shopName']?.toString(),
      items:
          (map['items'] as List<dynamic>?)
              ?.map((item) => Item.fromMap(item))
              .toList() ??
          [],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      appliedAt: map['appliedAt'] != null
          ? DateTime.parse(map['appliedAt'])
          : null,
      sharedWith:
          (map['sharedWith'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory SyncData.fromJson(Map<String, dynamic> json) =>
      SyncData.fromMap(json);
}

/// 同期データの種類
enum SyncDataType {
  tab, // タブ（Shop）
  list, // リスト（Item）
}

extension SyncDataTypeExtension on SyncDataType {
  String get displayName {
    switch (this) {
      case SyncDataType.tab:
        return 'タブ';
      case SyncDataType.list:
        return 'リスト';
    }
  }
}
