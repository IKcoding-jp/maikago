import 'package:flutter/foundation.dart';

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
  // デフォルトの除外ワードリスト（商品以外の言葉）
  static const List<String> _defaultExcludedWords = [
    // 形容詞
    '安い', '高い', '安価', '高価', '安いです', '高いです',
    '安いね', '高いね', '安いよ', '高いよ',
    '安いな', '高いな', '安いわ', '高いわ',

    // 感嘆詞・間投詞
    'すごい', 'すごいね', 'すごいよ', 'すごいな', 'すごいわ',
    'すごいです', 'すごいですね', 'すごいですよ',
    'わあ', 'わー', 'うわー', 'おお', 'おー',
    'やった', 'やったー', 'やったね', 'やったよ',
    'いいね', 'いいよ', 'いいな', 'いいわ',
    'いいです', 'いいですね', 'いいですよ',

    // その他の一般的な非商品語
    'あれ', 'これ', 'それ', 'どれ',
    'あそこ', 'ここ', 'そこ', 'どこ',
    'あの', 'この', 'その', 'どの',
    'あいつ', 'こいつ', 'そいつ', 'どいつ',

    // 否定・肯定
    'いいえ', 'いえ', 'いや', 'いやいや',
    'はい', 'うん', 'ううん', 'いえいえ',

    // その他
    'なんか', 'なんだか', 'なんとなく',
    'ちょっと', 'ちょい', 'ちょっとだけ',
    'まあ', 'まあまあ', 'まあね',
  ];

  // 除外ワードリスト（ユーザーが追加したもの + デフォルト）
  static List<String> _excludedWords = List.from(_defaultExcludedWords);

  // 長文除外設定
  static bool _longTextExclusionEnabled = true;
  static int _longTextThreshold = 25; // 25文字以上を長文とする
  static bool _conversationalTextExclusionEnabled = true;

  // 会話文の文末パターン（商品名と誤認されにくいもののみ）
  static const List<String> _conversationalEndings = [
    'なんだろうな',
    'なんだろうね',
    'なんだろうよ',
    'なんだろうなやっぱり',
    'なんだろうねやっぱり',
    'だよね',
    'だよな',
    'だわね',
    'だわよ',
    'でしょうね',
    'でしょうよ',
    'だろうね',
    'だろうよ',
    'そうだよね',
    'そうだよな',
    'そうだわね',
    'そうだわよ',
  ];

  // 商品名らしくない表現パターン（商品名と誤認されにくいもののみ）
  static const List<String> _nonProductPatterns = [
    'なんだろう',
    'なんだろうな',
    'なんだろうね',
    '水不足',
    '高くなってる',
    '安くなってる',
    '天気',
    '気候',
    '経済',
    '政治',
    'ニュース',
    'どうだろう',
    'どうだろうな',
    'どうだろうね',
  ];

  /// 長文除外設定を更新
  static void setLongTextExclusionSettings({
    bool? enabled,
    int? threshold,
    bool? conversationalEnabled,
  }) {
    if (enabled != null) _longTextExclusionEnabled = enabled;
    if (threshold != null) _longTextThreshold = threshold;
    if (conversationalEnabled != null)
      _conversationalTextExclusionEnabled = conversationalEnabled;
  }

  /// 長文除外設定を取得
  static Map<String, dynamic> getLongTextExclusionSettings() {
    return {
      'enabled': _longTextExclusionEnabled,
      'threshold': _longTextThreshold,
      'conversationalEnabled': _conversationalTextExclusionEnabled,
    };
  }

  /// 商品名らしい要素があるかチェック
  static bool _hasProductLikeElements(String text) {
    // 数量表現がある場合
    if (RegExp(r'\d+|[一二三四五六七八九十]+').hasMatch(text)) {
      return true;
    }

    // 価格表現がある場合
    if (RegExp(r'\d+円|\d+¥|[一二三四五六七八九十]+円').hasMatch(text)) {
      return true;
    }

    // 商品単位がある場合
    if (RegExp(r'個|本|つ|コ|こ|枚|パック|袋|箱|瓶|缶').hasMatch(text)) {
      return true;
    }

    // 商品名らしい単語がある場合（食品、日用品など）
    if (RegExp(
      r'米|パン|牛乳|卵|肉|魚|野菜|果物|お菓子|ジュース|お茶|コーヒー|ビール|酒|調味料|洗剤|シャンプー|歯磨き|トイレットペーパー|ティッシュ',
    ).hasMatch(text)) {
      return true;
    }

    // 商品カテゴリを示す単語がある場合
    if (RegExp(r'食品|飲料|日用品|雑貨|衣類|電化製品|本|雑誌|新聞|薬|化粧品').hasMatch(text)) {
      return true;
    }

    return false;
  }

  /// 会話文判定（商品名と誤認されにくいパターンのみ）
  static bool _isConversationalText(String text) {
    if (!_conversationalTextExclusionEnabled) return false;

    final trimmedText = text.trim();

    // 商品名らしい要素がある場合は会話文としない
    if (_hasProductLikeElements(trimmedText)) {
      return false;
    }

    return _conversationalEndings.any((ending) => trimmedText.endsWith(ending));
  }

  /// 商品名らしくない表現を含むか判定
  static bool _containsNonProductPatterns(String text) {
    // 商品名らしい要素がある場合は除外しない
    if (_hasProductLikeElements(text)) {
      return false;
    }

    final lowerText = text.toLowerCase();
    return _nonProductPatterns.any(
      (pattern) => lowerText.contains(pattern.toLowerCase()),
    );
  }

  /// 長文除外判定（商品名を誤って除外しないよう注意）
  static bool _shouldExcludeLongText(String text) {
    if (!_longTextExclusionEnabled) return false;

    final trimmedText = text.trim();

    // 商品名らしい要素がある場合は除外しない
    if (_hasProductLikeElements(trimmedText)) {
      return false;
    }

    // 文字数チェック
    if (trimmedText.length >= _longTextThreshold) {
      // 会話文の特徴がある場合のみ除外
      if (_isConversationalText(trimmedText) ||
          _containsNonProductPatterns(trimmedText)) {
        debugPrint('長文除外: "$text" (会話文パターン)');
        return true;
      }
    }

    return false;
  }

  /// 除外ワードリストを設定
  static void setExcludedWords(List<String> words) {
    _excludedWords = List.from(_defaultExcludedWords)..addAll(words);
  }

  /// 現在の除外ワードリストを取得
  static List<String> getExcludedWords() {
    return List.from(_excludedWords);
  }

  /// デフォルトの除外ワードリストを取得
  static List<String> getDefaultExcludedWords() {
    return List.from(_defaultExcludedWords);
  }

  /// ユーザーが追加した除外ワードのみを取得
  static List<String> getUserExcludedWords() {
    return _excludedWords
        .where((word) => !_defaultExcludedWords.contains(word))
        .toList();
  }

  /// 音声認識テキストから除外ワードを除去
  static String _removeExcludedWords(String text) {
    if (text.trim().isEmpty) return text;

    // 長文除外チェック（商品名を誤って除外しないよう注意）
    if (_shouldExcludeLongText(text)) {
      return '';
    }

    var result = text;
    var previousResult = '';

    // 除外ワードを除去（無限ループを防ぐため、変化がなくなるまで繰り返す）
    while (result != previousResult) {
      previousResult = result;

      for (final word in _excludedWords) {
        if (word.trim().isEmpty) continue;

        // 完全一致の場合
        if (result.trim().toLowerCase() == word.toLowerCase()) {
          return ''; // 除外ワードのみの場合は空文字を返す
        }

        // 部分一致の場合（単語境界を考慮）
        final lowerWord = word.toLowerCase();

        // 単語の前後に空白や区切り文字がある場合のみ除去
        final patterns = [
          ' $lowerWord ',
          ' $lowerWord、',
          ' $lowerWord,',
          '、$lowerWord ',
          '、$lowerWord、',
          '、$lowerWord,',
          ',$lowerWord ',
          ',$lowerWord、',
          ',$lowerWord,',
          '^$lowerWord ',
          '^$lowerWord、',
          '^$lowerWord,',
          ' $lowerWord\$',
          '、$lowerWord\$',
          ',$lowerWord\$',
          '^$lowerWord\$',
        ];

        for (final pattern in patterns) {
          result = result.replaceAll(
            RegExp(pattern, caseSensitive: false),
            ' ',
          );
        }
      }
    }

    // 複数の空白や区切り文字を整理
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    result = result.replaceAll(RegExp(r'[、,]+'), '、');
    result = result.trim();

    return result;
  }

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

    // 除外ワードを除去
    text = _removeExcludedWords(text);

    // 除外ワードのみの場合は空の結果を返す
    if (text.isEmpty) {
      return VoiceParseResult(
        name: '',
        quantity: 1,
        price: 0,
        discount: 0.0,
        action: 'none',
      );
    }

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
    // 削除指示: 「削除」「削除して」「削除してください」などに対応
    final delVerbRe = RegExp(
      r'(?:を)?\s*(?:削除(?:して(?:ください|下さい|ね)?)?|消して|消す|消去|無くして|なくして)',
    );
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
