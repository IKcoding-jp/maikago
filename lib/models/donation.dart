/// 寄付情報を管理するモデルクラス
class Donation {
  final String id;
  final int amount;
  final DateTime dateTime;
  final String productId;
  final String? transactionId;

  Donation({
    required this.id,
    required this.amount,
    required this.dateTime,
    required this.productId,
    this.transactionId,
  });

  /// JSONからDonationオブジェクトを作成
  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] as String,
      amount: json['amount'] as int,
      dateTime: DateTime.parse(json['dateTime'] as String),
      productId: json['productId'] as String,
      transactionId: json['transactionId'] as String?,
    );
  }

  /// DonationオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'dateTime': dateTime.toIso8601String(),
      'productId': productId,
      'transactionId': transactionId,
    };
  }

  /// コピーして新しいオブジェクトを作成
  Donation copyWith({
    String? id,
    int? amount,
    DateTime? dateTime,
    String? productId,
    String? transactionId,
  }) {
    return Donation(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      productId: productId ?? this.productId,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

/// 寄付統計情報を管理するモデルクラス
class DonationStats {
  final int totalAmount;
  final int totalCount;
  final DateTime? firstDonationDate;
  final DateTime? lastDonationDate;
  final List<Donation> donations;

  DonationStats({
    required this.totalAmount,
    required this.totalCount,
    this.firstDonationDate,
    this.lastDonationDate,
    required this.donations,
  });

  /// JSONからDonationStatsオブジェクトを作成
  factory DonationStats.fromJson(Map<String, dynamic> json) {
    return DonationStats(
      totalAmount: json['totalAmount'] as int,
      totalCount: json['totalCount'] as int,
      firstDonationDate: json['firstDonationDate'] != null
          ? DateTime.parse(json['firstDonationDate'] as String)
          : null,
      lastDonationDate: json['lastDonationDate'] != null
          ? DateTime.parse(json['lastDonationDate'] as String)
          : null,
      donations: (json['donations'] as List<dynamic>?)
              ?.map((e) => Donation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// DonationStatsオブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'totalAmount': totalAmount,
      'totalCount': totalCount,
      'firstDonationDate': firstDonationDate?.toIso8601String(),
      'lastDonationDate': lastDonationDate?.toIso8601String(),
      'donations': donations.map((e) => e.toJson()).toList(),
    };
  }

  /// コピーして新しいオブジェクトを作成
  DonationStats copyWith({
    int? totalAmount,
    int? totalCount,
    DateTime? firstDonationDate,
    DateTime? lastDonationDate,
    List<Donation>? donations,
  }) {
    return DonationStats(
      totalAmount: totalAmount ?? this.totalAmount,
      totalCount: totalCount ?? this.totalCount,
      firstDonationDate: firstDonationDate ?? this.firstDonationDate,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      donations: donations ?? this.donations,
    );
  }
}
