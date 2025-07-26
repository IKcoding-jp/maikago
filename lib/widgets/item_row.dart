import 'package:flutter/material.dart';
import '../models/item.dart';

class ItemRow extends StatelessWidget {
  final Item item;
  final ValueChanged<bool> onCheckToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showEdit;

  const ItemRow({
    super.key,
    required this.item,
    required this.onCheckToggle,
    this.onEdit,
    this.onDelete,
    this.showEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Checkbox(
                value: item.isChecked,
                onChanged: (v) => onCheckToggle(v ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: item.isChecked
                            ? Colors.grey
                            : Theme.of(context).colorScheme.onSurface,
                        decoration: item.isChecked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '×${item.quantity}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '¥${item.price}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (item.discount > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '-${(item.discount * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showEdit && onEdit != null)
                IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
              if (onDelete != null)
                IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}
 