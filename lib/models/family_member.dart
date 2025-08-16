// ファミリーメンバーを表すモデルクラス
class FamilyMember {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final FamilyRole role;
  final DateTime joinedAt;
  final bool isActive;

  FamilyMember({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
  });

  FamilyMember copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    FamilyRole? role,
    DateTime? joinedAt,
    bool? isActive,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'role': role.name,
    'joinedAt': joinedAt.toIso8601String(),
    'isActive': isActive,
  };

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'role': role.name,
    'joinedAt': joinedAt.toIso8601String(),
    'isActive': isActive,
  };

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id']?.toString() ?? '',
    email: json['email'] ?? '',
    displayName: json['displayName'] ?? '',
    photoUrl: json['photoUrl'],
    role: FamilyRole.values.firstWhere(
      (role) => role.name == json['role'],
      orElse: () => FamilyRole.member,
    ),
    joinedAt: json['joinedAt'] != null
        ? DateTime.parse(json['joinedAt'])
        : DateTime.now(),
    isActive: json['isActive'] ?? true,
  );

  factory FamilyMember.fromMap(Map<String, dynamic> map) => FamilyMember(
    id: map['id']?.toString() ?? '',
    email: map['email'] ?? '',
    displayName: map['displayName'] ?? '',
    photoUrl: map['photoUrl'],
    role: FamilyRole.values.firstWhere(
      (role) => role.name == map['role'],
      orElse: () => FamilyRole.member,
    ),
    joinedAt: map['joinedAt'] != null
        ? DateTime.parse(map['joinedAt'])
        : DateTime.now(),
    isActive: map['isActive'] ?? true,
  );
}

/// ファミリー内での役割
enum FamilyRole {
  owner, // ファミリーオーナー（管理者）
  member, // ファミリーメンバー
}

extension FamilyRoleExtension on FamilyRole {
  String get displayName {
    switch (this) {
      case FamilyRole.owner:
        return 'オーナー';
      case FamilyRole.member:
        return 'メンバー';
    }
  }
}
