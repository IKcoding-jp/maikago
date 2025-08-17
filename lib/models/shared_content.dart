import 'shop.dart';

// 送信型共有コンテンツ（リスト・タブ）を表すモデルクラス
class SharedContent {
  final String id;
  final String title;
  final String description;
  final SharedContentType type;
  final String contentId; // 元のShop.id
  final Shop? content; // 実際のコンテンツ
  final String sharedBy; // 送信者のユーザーID
  final String sharedByName; // 送信者の表示名
  final DateTime sharedAt;
  final List<String> sharedWith; // 受信者のユーザーIDリスト
  final TransmissionStatus status; // 送信状態
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
    this.status = TransmissionStatus.sent,
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
    TransmissionStatus? status,
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
      status: status ?? this.status,
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
    'status': status.name,
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
    'status': status.name,
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
    content: json['shopData'] != null
        ? Shop.fromMap(Map<String, dynamic>.from(json['shopData']))
        : (json['content'] is Map<String, dynamic>
              ? Shop.fromMap(Map<String, dynamic>.from(json['content']))
              : null),
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
    status: TransmissionStatus.values.firstWhere(
      (status) => status.name == json['status'],
      orElse: () => TransmissionStatus.sent,
    ),
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
    content: map['shopData'] != null
        ? Shop.fromMap(Map<String, dynamic>.from(map['shopData']))
        : (map['content'] is Map<String, dynamic>
              ? Shop.fromMap(Map<String, dynamic>.from(map['content']))
              : null),
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
    status: TransmissionStatus.values.firstWhere(
      (status) => status.name == map['status'],
      orElse: () => TransmissionStatus.sent,
    ),
    isActive: map['isActive'] ?? true,
  );
}

/// 送信状態
enum TransmissionStatus {
  sent, // 送信済み
  received, // 受信済み
  accepted, // 受け取り済み
  deleted, // 削除済み
}

extension TransmissionStatusExtension on TransmissionStatus {
  String get displayName {
    switch (this) {
      case TransmissionStatus.sent:
        return '送信済み';
      case TransmissionStatus.received:
        return '受信済み';
      case TransmissionStatus.accepted:
        return '受け取り済み';
      case TransmissionStatus.deleted:
        return '削除済み';
    }
  }
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

/// 送信履歴を表すモデルクラス
class TransmissionHistory {
  final String id;
  final String contentId; // 送信したコンテンツのID
  final String contentTitle; // 送信したコンテンツのタイトル
  final SharedContentType contentType; // 送信したコンテンツの種類
  final String senderId; // 送信者のユーザーID
  final String senderName; // 送信者の表示名
  final List<String> receiverIds; // 受信者のユーザーIDリスト
  final List<String> receiverNames; // 受信者の表示名リスト
  final DateTime sentAt; // 送信日時
  final DateTime? receivedAt; // 受信日時
  final DateTime? acceptedAt; // 受け取り日時
  final TransmissionStatus status; // 送信状態
  final bool isActive;

  TransmissionHistory({
    required this.id,
    required this.contentId,
    required this.contentTitle,
    required this.contentType,
    required this.senderId,
    required this.senderName,
    required this.receiverIds,
    required this.receiverNames,
    required this.sentAt,
    this.receivedAt,
    this.acceptedAt,
    this.status = TransmissionStatus.sent,
    this.isActive = true,
  });

  TransmissionHistory copyWith({
    String? id,
    String? contentId,
    String? contentTitle,
    SharedContentType? contentType,
    String? senderId,
    String? senderName,
    List<String>? receiverIds,
    List<String>? receiverNames,
    DateTime? sentAt,
    DateTime? receivedAt,
    DateTime? acceptedAt,
    TransmissionStatus? status,
    bool? isActive,
  }) {
    return TransmissionHistory(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      contentTitle: contentTitle ?? this.contentTitle,
      contentType: contentType ?? this.contentType,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverIds: receiverIds ?? this.receiverIds,
      receiverNames: receiverNames ?? this.receiverNames,
      sentAt: sentAt ?? this.sentAt,
      receivedAt: receivedAt ?? this.receivedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contentId': contentId,
    'contentTitle': contentTitle,
    'contentType': contentType.name,
    'senderId': senderId,
    'senderName': senderName,
    'receiverIds': receiverIds,
    'receiverNames': receiverNames,
    'sentAt': sentAt.toIso8601String(),
    'receivedAt': receivedAt?.toIso8601String(),
    'acceptedAt': acceptedAt?.toIso8601String(),
    'status': status.name,
    'isActive': isActive,
  };

  Map<String, dynamic> toMap() => {
    'id': id,
    'contentId': contentId,
    'contentTitle': contentTitle,
    'contentType': contentType.name,
    'senderId': senderId,
    'senderName': senderName,
    'receiverIds': receiverIds,
    'receiverNames': receiverNames,
    'sentAt': sentAt.toIso8601String(),
    'receivedAt': receivedAt?.toIso8601String(),
    'acceptedAt': acceptedAt?.toIso8601String(),
    'status': status.name,
    'isActive': isActive,
  };

  factory TransmissionHistory.fromJson(Map<String, dynamic> json) =>
      TransmissionHistory(
        id: json['id']?.toString() ?? '',
        contentId: json['contentId']?.toString() ?? '',
        contentTitle: json['contentTitle'] ?? '',
        contentType: SharedContentType.values.firstWhere(
          (type) => type.name == json['contentType'],
          orElse: () => SharedContentType.list,
        ),
        senderId: json['senderId']?.toString() ?? '',
        senderName: json['senderName'] ?? '',
        receiverIds:
            (json['receiverIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        receiverNames:
            (json['receiverNames'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        sentAt: json['sentAt'] != null
            ? DateTime.parse(json['sentAt'])
            : DateTime.now(),
        receivedAt: json['receivedAt'] != null
            ? DateTime.parse(json['receivedAt'])
            : null,
        acceptedAt: json['acceptedAt'] != null
            ? DateTime.parse(json['acceptedAt'])
            : null,
        status: TransmissionStatus.values.firstWhere(
          (status) => status.name == json['status'],
          orElse: () => TransmissionStatus.sent,
        ),
        isActive: json['isActive'] ?? true,
      );

  factory TransmissionHistory.fromMap(Map<String, dynamic> map) =>
      TransmissionHistory(
        id: map['id']?.toString() ?? '',
        contentId: map['contentId']?.toString() ?? '',
        contentTitle: map['contentTitle'] ?? '',
        contentType: SharedContentType.values.firstWhere(
          (type) => type.name == map['contentType'],
          orElse: () => SharedContentType.list,
        ),
        senderId: map['senderId']?.toString() ?? '',
        senderName: map['senderName'] ?? '',
        receiverIds:
            (map['receiverIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        receiverNames:
            (map['receiverNames'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        sentAt: map['sentAt'] != null
            ? DateTime.parse(map['sentAt'])
            : DateTime.now(),
        receivedAt: map['receivedAt'] != null
            ? DateTime.parse(map['receivedAt'])
            : null,
        acceptedAt: map['acceptedAt'] != null
            ? DateTime.parse(map['acceptedAt'])
            : null,
        status: TransmissionStatus.values.firstWhere(
          (status) => status.name == map['status'],
          orElse: () => TransmissionStatus.sent,
        ),
        isActive: map['isActive'] ?? true,
      );
}
