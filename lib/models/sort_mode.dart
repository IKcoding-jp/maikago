// 並び替えモードと対応する比較関数
import 'item.dart';

/// 一覧の並び替えモード
enum SortMode {
  qtyAsc('個数 少ない順'),
  qtyDesc('個数 多い順'),
  priceAsc('値段 安い順'),
  priceDesc('値段 高い順'),
  dateNew('追加が新しい順'),
  dateOld('追加が古い順');

  final String label;
  const SortMode(this.label);
}

/// 並び替えモードに応じた比較関数を返す
Comparator<Item> comparatorFor(SortMode mode) {
  switch (mode) {
    case SortMode.qtyAsc:
      return (a, b) => a.quantity.compareTo(b.quantity);
    case SortMode.qtyDesc:
      return (a, b) => b.quantity.compareTo(a.quantity);
    case SortMode.priceAsc:
      return (a, b) => a.price.compareTo(b.price);
    case SortMode.priceDesc:
      return (a, b) => b.price.compareTo(a.price);
    case SortMode.dateNew:
      return (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
        a.createdAt ?? DateTime.now(),
      );
    case SortMode.dateOld:
      return (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
        b.createdAt ?? DateTime.now(),
      );
  }
}
