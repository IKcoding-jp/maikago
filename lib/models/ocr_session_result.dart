/// OCRセッション結果のアイテム
class OcrSessionResultItem {
  String id;
  String name;
  int price;
  int quantity;

  OcrSessionResultItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  OcrSessionResultItem copyWith({
    String? id,
    String? name,
    int? price,
    int? quantity,
  }) {
    return OcrSessionResultItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  factory OcrSessionResultItem.fromJson(Map<String, dynamic> json) =>
      OcrSessionResultItem(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        price: json['price'] ?? 0,
        quantity: json['quantity'] ?? 1,
      );

  /// 小計を計算
  int get subtotal => price * quantity;
}

/// OCRセッション結果
/// OCR解析後の商品リストを一時的に保持するモデル
class OcrSessionResult {
  final List<OcrSessionResultItem> items;
  final DateTime createdAt;
  final String? rawOcrText;

  OcrSessionResult({
    required this.items,
    DateTime? createdAt,
    this.rawOcrText,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 合計金額を計算
  int get totalPrice => items.fold(0, (sum, item) => sum + item.subtotal);

  /// 商品数を取得
  int get itemCount => items.length;

  OcrSessionResult copyWith({
    List<OcrSessionResultItem>? items,
    DateTime? createdAt,
    String? rawOcrText,
  }) {
    return OcrSessionResult(
      items: items ?? List.from(this.items),
      createdAt: createdAt ?? this.createdAt,
      rawOcrText: rawOcrText ?? this.rawOcrText,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'rawOcrText': rawOcrText,
      };

  factory OcrSessionResult.fromJson(Map<String, dynamic> json) =>
      OcrSessionResult(
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => OcrSessionResultItem.fromJson(e))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        rawOcrText: json['rawOcrText'],
      );
}

/// 保存結果
class SaveResult {
  final bool isSuccess;
  final String message;
  final String? targetShopId;
  final bool isUpdateMode;

  SaveResult({
    required this.isSuccess,
    required this.message,
    this.targetShopId,
    this.isUpdateMode = false,
  });

  factory SaveResult.success({
    required String message,
    String? targetShopId,
    bool isUpdateMode = false,
  }) =>
      SaveResult(
        isSuccess: true,
        message: message,
        targetShopId: targetShopId,
        isUpdateMode: isUpdateMode,
      );

  factory SaveResult.failure(String message) => SaveResult(
        isSuccess: false,
        message: message,
      );
}
