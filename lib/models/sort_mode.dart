import 'item.dart';

enum SortMode {
  jaAsc('五十音順 昇順'),
  jaDesc('五十音順 降順'),
  enAsc('アルファベット 昇順'),
  enDesc('アルファベット 降順'),
  qtyAsc('個数 少ない順'),
  qtyDesc('個数 多い順'),
  priceAsc('値段 安い順'),
  priceDesc('値段 高い順');

  final String label;
  const SortMode(this.label);
}

Comparator<Item> comparatorFor(SortMode mode) {
  switch (mode) {
    case SortMode.jaAsc:
      return (a, b) => a.name.compareTo(b.name); // 日本語ソートは要工夫
    case SortMode.jaDesc:
      return (a, b) => b.name.compareTo(a.name);
    case SortMode.enAsc:
      return (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
    case SortMode.enDesc:
      return (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase());
    case SortMode.qtyAsc:
      return (a, b) => a.quantity.compareTo(b.quantity);
    case SortMode.qtyDesc:
      return (a, b) => b.quantity.compareTo(a.quantity);
    case SortMode.priceAsc:
      return (a, b) => a.price.compareTo(b.price);
    case SortMode.priceDesc:
      return (a, b) => b.price.compareTo(a.price);
  }
}
