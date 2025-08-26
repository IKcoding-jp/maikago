// 税率・食品判定のユーティリティ

class TaxUtils {
  // 食品らしい単語の辞書（必要に応じて拡張）
  static const List<String> _foodKeywords = [
    '米',
    'パン',
    '牛乳',
    'ミルク',
    '肉',
    '豚',
    '牛',
    '鶏',
    '鶏肉',
    '魚',
    '刺身',
    '寿司',
    '野菜',
    '果物',
    'フルーツ',
    'お菓子',
    '菓子',
    'スイーツ',
    '弁当',
    '総菜',
    '惣菜',
    'ヨーグルト',
    '卵',
    '豆腐',
    '納豆',
    '米飯',
    'スナック',
    'チョコ',
    'クッキー',
    'ラーメン',
    'うどん',
    'そば',
    'パスタ',
    '麺',
    'カレー',
    'シチュー',
    'パン粉',
    '小麦粉',
    '砂糖',
    '塩',
    '味噌',
    '醤油',
    'みりん',
    '酒',
    'ジュース',
    '飲料',
    '飲み物',
    'アイス',
    '冷凍食品',
    '惣菜',
  ];

  /// 商品名に食品らしい単語が含まれるか判定（辞書ベース）
  static bool isFood(String productName) {
    final normalized = _normalize(productName);
    for (final keyword in _foodKeywords) {
      if (normalized.contains(keyword)) return true;
    }
    return false;
  }

  /// プロダクト名の正規化（前後空白を除去。必要なら小文字化など拡張）
  static String _normalize(String s) {
    return s.replaceAll('\u3000', ' ').trim();
  }
}
