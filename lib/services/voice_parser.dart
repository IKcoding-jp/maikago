class VoiceParseResult {
  final String name;
  final int quantity;
  final int price;
  final double discount; // fraction, e.g. 0.05 for 5%

  VoiceParseResult({
    required this.name,
    required this.quantity,
    required this.price,
    required this.discount,
  });
}

class VoiceParser {
  // Simple kanji digit converter (supports up to 99-ish)
  static int _kanjiToNumber(String s) {
    if (s.isEmpty) return 0;
    final map = {
      '零': 0,
      '〇': 0,
      '一': 1,
      '二': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
      '十': 10,
    };
    if (RegExp(r'^\d+\$').hasMatch(s)) return int.parse(s);
    int result = 0;
    if (s.contains('十')) {
      final parts = s.split('十');
      final tens = parts[0].isEmpty ? 1 : (map[parts[0]] ?? 0);
      final ones = parts.length > 1 && parts[1].isNotEmpty
          ? (map[parts[1]] ?? 0)
          : 0;
      result = tens * 10 + ones;
    } else {
      // single kanji
      result = map[s] ?? 0;
    }
    return result;
  }

  static int _normalizeNumberString(String s) {
    s = s.replaceAll(RegExp(r'[^0-9一二三四五六七八九十〇零]'), '');
    if (s.isEmpty) return 0;
    if (RegExp(r'^[0-9]+$').hasMatch(s)) return int.parse(s);
    return _kanjiToNumber(s);
  }

  static VoiceParseResult parse(String raw) {
    var text = raw.trim();

    // full-width -> half-width
    text = text.replaceAllMapped(RegExp(r'[０-９]'), (m) {
      return String.fromCharCode(m.group(0)!.codeUnitAt(0) - 0xFEE0);
    });

    int quantity = 1;
    int price = 0;
    double discount = 0.0;

    // discount
    final discRe = RegExp(r'(\d+(?:\.\d+)?|[一二三四五六七八九十]+)\s*(%|％|パーセント|パー)');
    final discMatch = discRe.firstMatch(text);
    if (discMatch != null) {
      final numStr = discMatch.group(1) ?? '';
      final n = _normalizeNumberString(numStr);
      discount = n / 100.0;
      text = text.replaceRange(discMatch.start, discMatch.end, '');
    }

    // price (円)
    final priceRe = RegExp(r'(\d+(?:\.\d+)?|[一二三四五六七八九十]+)\s*(円|¥)');
    final priceMatch = priceRe.firstMatch(text);
    if (priceMatch != null) {
      final numStr = priceMatch.group(1) ?? '';
      price = _normalizeNumberString(numStr);
      text = text.replaceRange(priceMatch.start, priceMatch.end, '');
    }

    // quantity: look for explicit words or number+unit
    final qtyRe1 = RegExp(r'(?:個数|数量)\s*[:：]?\s*(\d+|[一二三四五六七八九十]+)');
    final qtyMatch1 = qtyRe1.firstMatch(text);
    if (qtyMatch1 != null) {
      quantity = _normalizeNumberString(qtyMatch1.group(1) ?? '');
      text = text.replaceRange(qtyMatch1.start, qtyMatch1.end, '');
    } else {
      final qtyRe2 = RegExp(r'(\d+|[一二三四五六七八九十]+)\s*(個|個|本|つ|コ|こ|枚)');
      final qtyMatch2 = qtyRe2.firstMatch(text);
      if (qtyMatch2 != null) {
        quantity = _normalizeNumberString(qtyMatch2.group(1) ?? '');
        text = text.replaceRange(qtyMatch2.start, qtyMatch2.end, '');
      }
    }

    // Cleanup name: remove trailing verbs like を追加 etc and punctuation
    var name = text.replaceAll(RegExp(r'を追加|を買ってきて|を買う|を買う。|を買う,'), '');
    name = name.replaceAll(RegExp(r'[、,]'), ' ');
    name = name.trim();
    if (name.isEmpty) name = raw.trim();

    return VoiceParseResult(
      name: name,
      quantity: quantity,
      price: price,
      discount: discount,
    );
  }
}
