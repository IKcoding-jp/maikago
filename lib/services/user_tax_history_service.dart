import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// ユーザーが手動で修正した税率を商品名単位で保存/取得する簡易履歴サービス
/// - 永続化には SharedPreferences を使用
/// - キーは 'tax_rate_overrides:<normalized_name>'、値は double (0.08/0.10)
class UserTaxHistoryService {
  static String _keyFor(String productName) {
    final normalized = _normalize(productName);
    return 'tax_rate_overrides:$normalized';
  }

  static String _normalize(String s) {
    return s.replaceAll('\u3000', ' ').trim();
  }

  /// 税率を保存（0.08 または 0.10 など）。null で削除
  static Future<void> saveTaxRate(String productName, double? taxRate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyFor(productName);
      if (taxRate == null) {
        await prefs.remove(key);
        debugPrint('🗑️ 税率上書きを削除: $productName');
      } else {
        await prefs.setDouble(key, taxRate);
        debugPrint('💾 税率上書きを保存: $productName = $taxRate');
      }
    } catch (e) {
      debugPrint('❌ 税率上書きの保存に失敗: $e');
    }
  }

  /// 税率を取得（なければ null）
  static Future<double?> getTaxRate(String productName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyFor(productName);
      if (!prefs.containsKey(key)) return null;
      return prefs.getDouble(key);
    } catch (e) {
      debugPrint('❌ 税率上書きの取得に失敗: $e');
      return null;
    }
  }
}
