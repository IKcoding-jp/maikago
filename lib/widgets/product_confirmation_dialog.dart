import 'package:flutter/material.dart';
import 'package:maikago/models/product_info.dart';

/// バーコードスキャン後の商品確認ダイアログ
class ProductConfirmationDialog extends StatefulWidget {
  final ProductInfo productInfo;

  const ProductConfirmationDialog({
    super.key,
    required this.productInfo,
  });

  @override
  State<ProductConfirmationDialog> createState() =>
      _ProductConfirmationDialogState();
}

class _ProductConfirmationDialogState extends State<ProductConfirmationDialog> {
  int quantity = 1;
  int price = 0;
  double discount = 0.0;

  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: quantity.toString());
    _priceController = TextEditingController(text: ''); // 空文字列で初期化
    _discountController = TextEditingController(text: ''); // 空文字列で初期化
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ヘッダー
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '商品が見つかりました',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 商品画像
              if (widget.productInfo.imageUrl != null)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.productInfo.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // 商品名
              Text(
                widget.productInfo.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // 入力フィールド
              _buildInputFields(),
              const SizedBox(height: 16),

              // 合計金額表示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '合計:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '¥${(price * quantity * (1 - discount)).round()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // クレジット表示
              Text(
                '商品情報提供: Yahoo!ショッピング',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),

              // ボタン
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text(
                        'キャンセル',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop({
                        'quantity': quantity,
                        'price': price,
                        'discount': discount,
                      }),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'リストに追加',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    // コントローラーの値を更新
    _quantityController.text = quantity > 0 ? quantity.toString() : '';
    // 価格と割引率は空文字列の場合は更新しない（ユーザーが入力中の場合）
    if (price > 0) {
      _priceController.text = price.toString();
    }
    if (discount > 0) {
      _discountController.text = (discount * 100).round().toString();
    }

    return Column(
      children: [
        // 個数入力欄
        TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '個数',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() => quantity = 0);
            } else {
              final newQuantity = int.tryParse(value);
              if (newQuantity != null &&
                  newQuantity >= 0 &&
                  newQuantity <= 999) {
                setState(() => quantity = newQuantity);
              }
            }
          },
        ),
        const SizedBox(height: 16),
        // 単価入力欄
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '単価 (円)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final newPrice = int.tryParse(value) ?? 0;
            if (newPrice >= 0 && newPrice <= 999999) {
              setState(() => price = newPrice);
            }
          },
        ),
        const SizedBox(height: 16),
        // 割引率入力欄
        TextField(
          controller: _discountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '割引率 (%)',
            border: OutlineInputBorder(),
            suffixText: '%',
          ),
          onChanged: (value) {
            final newDiscount = int.tryParse(value) ?? 0;
            if (newDiscount >= 0 && newDiscount <= 100) {
              setState(() => discount = newDiscount / 100);
            }
          },
        ),
      ],
    );
  }
}
