import 'package:cloud_functions/cloud_functions.dart';
import 'package:maikago/services/debug_service.dart';

/// レシピから抽出された材料のモデル
class RecipeIngredient {
  RecipeIngredient({
    required this.name,
    this.quantity,
    required this.normalizedName,
    this.isExcluded = false,
    this.confidence = 1.0,
    this.notes,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] ?? '',
      quantity: json['quantity'],
      normalizedName: json['normalizedName'] ?? json['name'] ?? '',
      isExcluded: json['isExcluded'] ?? false,
      confidence: (json['confidence'] as num? ?? 1.0).toDouble(),
      notes: json['notes'],
    );
  }

  String name;
  String? quantity;
  String normalizedName;
  bool isExcluded;
  double confidence;
  String? notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'normalizedName': normalizedName,
        'isExcluded': isExcluded,
        'confidence': confidence,
        'notes': notes,
      };
}

/// 解析結果をまとめるクラス
class RecipeParseResult {
  RecipeParseResult({required this.title, required this.ingredients});

  final String title;
  final List<RecipeIngredient> ingredients;
}

class RecipeParserService {
  RecipeParserService();

  /// レシピテキストから材料を抽出する（Cloud Functions経由）
  Future<RecipeParseResult?> parseRecipe(String recipeText) async {
    try {
      DebugService().log('🤖 レシピ解析開始（Cloud Functions経由）...');

      final callable =
          FirebaseFunctions.instance.httpsCallable('parseRecipe');
      final response = await callable.call<Map<String, dynamic>>({
        'recipeText': recipeText,
      }).timeout(const Duration(seconds: 30));

      final data = response.data;

      if (data['success'] == true) {
        final title = data['title']?.toString() ?? 'レシピから取り込み';
        final ingredients = (data['ingredients'] as List? ?? [])
            .map((e) =>
                RecipeIngredient.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        DebugService().log('✅ レシピ解析成功: 「$title」 ${ingredients.length}件の材料を抽出');
        return RecipeParseResult(title: title, ingredients: ingredients);
      } else {
        DebugService().log('❌ レシピ解析失敗: ${data['error']}');
        return null;
      }
    } on FirebaseFunctionsException catch (e) {
      DebugService().log('❌ レシピ解析エラー: [${e.code}] ${e.message}');
      return null;
    } catch (e) {
      DebugService().log('❌ レシピ解析例外: $e');
      return null;
    }
  }

  /// AIを使用して2つの材料が意味的に同一かどうかを判定する（Cloud Functions経由）
  Future<bool> isSameIngredient(String name1, String name2) async {
    // 完全に一致する場合は即座にtrue
    if (name1.trim() == name2.trim()) return true;

    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('checkIngredientSimilarity');
      final response = await callable.call<Map<String, dynamic>>({
        'name1': name1,
        'name2': name2,
      }).timeout(const Duration(seconds: 5));

      final data = response.data;
      return data['isSame'] == true;
    } catch (e) {
      DebugService().log('⚠️ 同一性判定失敗: $e');
      return false;
    }
  }
}
