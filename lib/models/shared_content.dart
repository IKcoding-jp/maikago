import 'shop.dart';
import 'family_member.dart';

// 共有コンテンツ（リスト・タブ）を表すモデルクラス
class SharedContent {
  final String id;
  final String title;
  final String description;
  final SharedContentType type;
  final String contentId; // 元のShop.id
  final Shop? content; // 実際のコンテンツ
  final String sharedBy; // 共有者のユーザーID
  final String sharedByName; // 共有者の表示名
  final DateTime sharedAt;
  final List<String> sharedWith; // 共有先のユーザーIDリスト
  final bool isActive;

  SharedContent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.contentId,
    this.content,
    required this.sharedBy,
    required this.sharedByName,
    required this.sharedAt,
    required this.sharedWith,
    this.isActive = true,
  });

  SharedContent copyWith({
    String? id,
    String? title,
    String? description,
    SharedContentType? type,
    String? contentId,
    Shop? content,
    String? sharedBy,
    String? sharedByName,
    DateTime? sharedAt,
    List<String>? sharedWith,
    bool? isActive,
  }) {
    return SharedContent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      contentId: contentId ?? this.contentId,
      content: content ?? this.content,
      sharedBy: sharedBy ?? this.sharedBy,
      sharedByName: sharedByName ?? this.sharedByName,
      sharedAt: sharedAt ?? this.sharedAt,
      sharedWith: sharedWith ?? this.sharedWith,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'contentId': contentId,
    'sharedBy': sharedBy,
    'sharedByName': sharedByName,
    'sharedAt': sharedAt.toIso8601String(),
    'sharedWith': sharedWith,
    'isActive': isActive,
  };

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'contentId': contentId,
    'sharedBy': sharedBy,
    'sharedByName': sharedByName,
    'sharedAt': sharedAt.toIso8601String(),
    'sharedWith': sharedWith,
    'isActive': isActive,
  };

  factory SharedContent.fromJson(Map<String, dynamic> json) => SharedContent(
    id: json['id']?.toString() ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    type: SharedContentType.values.firstWhere(
      (type) => type.name == json['type'],
      orElse: () => SharedContentType.list,
    ),
    contentId: json['contentId']?.toString() ?? '',
    sharedBy: json['sharedBy']?.toString() ?? '',
    sharedByName: json['sharedByName'] ?? '',
    sharedAt: json['sharedAt'] != null
        ? DateTime.parse(json['sharedAt'])
        : DateTime.now(),
    sharedWith:
        (json['sharedWith'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    isActive: json['isActive'] ?? true,
  );

  factory SharedContent.fromMap(Map<String, dynamic> map) => SharedContent(
    id: map['id']?.toString() ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    type: SharedContentType.values.firstWhere(
      (type) => type.name == map['type'],
      orElse: () => SharedContentType.list,
    ),
    contentId: map['contentId']?.toString() ?? '',
    sharedBy: map['sharedBy']?.toString() ?? '',
    sharedByName: map['sharedByName'] ?? '',
    sharedAt: map['sharedAt'] != null
        ? DateTime.parse(map['sharedAt'])
        : DateTime.now(),
    sharedWith:
        (map['sharedWith'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    isActive: map['isActive'] ?? true,
  );
}

/// 共有コンテンツの種類
enum SharedContentType {
  list, // リスト（タブ）
  tab, // タブ（Shop）
}

extension SharedContentTypeExtension on SharedContentType {
  String get displayName {
    switch (this) {
      case SharedContentType.list:
        return 'リスト';
      case SharedContentType.tab:
        return 'タブ';
    }
  }
}
