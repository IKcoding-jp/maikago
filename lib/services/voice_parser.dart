class VoiceParseResult {
  final String name;
  final int quantity;
  final int price;
  final double discount; // fraction, e.g. 0.05 for 5%
  final String action; // 'none' or 'delete_item'

  VoiceParseResult({
    required this.name,
    required this.quantity,
    required this.price,
    required this.discount,
    this.action = 'none',
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

    // パターン: 「名前はN個」「名前はN円」などの曖昧表現を早期に検出
    final nameIsRe = RegExp(
      r'(.+?)は\s*(\d+|[一二三四五六七八九十]+)\s*(円|¥|個|本|つ|コ|こ|枚)?',
    );
    final nameIsMatch = nameIsRe.firstMatch(text);
    if (nameIsMatch != null) {
      final namePart = nameIsMatch.group(1)!.trim();
      final numStr = nameIsMatch.group(2) ?? '';
      final unit = nameIsMatch.group(3);
      if (unit != null && (unit == '円' || unit == '¥')) {
        price = _normalizeNumberString(numStr);
      } else {
        quantity = _normalizeNumberString(numStr);
      }
      // マッチ部分を名前に置換して以降のクリーンアップで名前が残るようにする
      text = text.replaceRange(nameIsMatch.start, nameIsMatch.end, namePart);
    }

    // discount
    // パーセント表現の後に『引き』等が続く場合も含めてマッチさせる
    final discRe = RegExp(
      r'(\d+(?:\.\d+)?|[一二三四五六七八九十]+)\s*(%|％|パーセント|パー)(?:\s*(?:引き|引|オフ))?',
    );
    final discMatch = discRe.firstMatch(text);
    if (discMatch != null) {
      final numStr = discMatch.group(1) ?? '';
      final n = _normalizeNumberString(numStr);
      discount = n / 100.0;
      text = text.replaceRange(discMatch.start, discMatch.end, '');
    }

    // price (円) — also support patterns like "120にして" or "120円にして"
    final priceNiRe = RegExp(
      r'(\d+(?:\.\d+)?|[一二三四五六七八九十]+)\s*(?:円|¥)?\s*(?:にして(?:ください|下さい|ね)?|にして。|にして,|にして)',
    );
    final priceNiMatch = priceNiRe.firstMatch(text);
    if (priceNiMatch != null) {
      final numStr = priceNiMatch.group(1) ?? '';
      price = _normalizeNumberString(numStr);
      text = text.replaceRange(priceNiMatch.start, priceNiMatch.end, '');
    } else {
      // fallback: explicit 円/¥
      final priceRe = RegExp(r'(\d+(?:\.\d+)?|[一二三四五六七八九十]+)\s*(円|¥)');
      final priceMatch = priceRe.firstMatch(text);
      if (priceMatch != null) {
        final numStr = priceMatch.group(1) ?? '';
        price = _normalizeNumberString(numStr);
        text = text.replaceRange(priceMatch.start, priceMatch.end, '');
      }
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

    // Cleanup name: remove trailing verbs like を追加/にして/etc and punctuation
    var name = text.replaceAll(
      RegExp(
        r'を追加|を買ってきて|を買って|を買う|を買う。|を買う,|引き|引|にして(?:ください|下さい|ね)?|にして。|にして,',
      ),
      '',
    );
    // Remove common leftover particles that may remain (e.g. を/に)
    name = name.replaceAll(RegExp(r'[をに]'), '');
    // Normalize punctuation and whitespace
    name = name.replaceAll(RegExp(r'[、,]'), ' ');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.isEmpty) name = raw.trim();

    // action 検出（削除 / 購入）
    String action = 'none';
    final delVerbRe = RegExp(r'(?:を)?\s*(?:削除|消して|消す|消去|無くして|なくして)');
    final buyVerbRe = RegExp(r'(?:を)?\s*(?:購入|買った|買いました|買ってきて|買っておいて|買って|買う)');
    final negBuyVerbRe = RegExp(
      r'(?:を)?\s*(?:買ってない|買っていない|未購入|買わなかった|買わない|買ってないよ|買っていないよ)',
    );

    // 優先度: 否定形（未購入） -> 購入指示 -> 削除指示
    if (negBuyVerbRe.hasMatch(text) || negBuyVerbRe.hasMatch(raw)) {
      action = 'mark_unpurchased';
      name = name.replaceAll(negBuyVerbRe, '').trim();
    } else if (buyVerbRe.hasMatch(text) || buyVerbRe.hasMatch(raw)) {
      action = 'mark_purchased';
      name = name.replaceAll(buyVerbRe, '').trim();
    } else if (delVerbRe.hasMatch(text) || delVerbRe.hasMatch(raw)) {
      action = 'delete_item';
      name = name.replaceAll(delVerbRe, '').trim();
    }

    return VoiceParseResult(
      name: name,
      quantity: quantity,
      price: price,
      discount: discount,
      action: action,
    );
  }
}
