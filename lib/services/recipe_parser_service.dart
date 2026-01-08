import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maikago/services/chatgpt_service.dart';

/// レシピから抽出された材料のモデル
class RecipeIngredient {
  String name;
  String? quantity;
  String normalizedName;
  bool isExcluded;
  double confidence;
  String? notes;

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
      confidence: (json['confidence'] ?? 1.0).toDouble(),
      notes: json['notes'],
    );
  }

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
  final String title;
  final List<RecipeIngredient> ingredients;

  RecipeParseResult({required this.title, required this.ingredients});
}

class RecipeParserService {
  final ChatGptService _chatGptService;

  RecipeParserService({ChatGptService? chatGptService})
      : _chatGptService = chatGptService ?? ChatGptService();

  static const String _recipePromptSystem = '''あなたはレシピから材料を抽出する専門家です。
レシピテキストから「料理名（レシピ名）」と「材料リスト」を抽出し、JSONで返してください。

抽出ルール:
1. title: レシピの料理名を簡潔に抽出する。不明な場合は「レシピから取り込み」とする。
2. ingredients: 材料名と分量を正確に抽出する。
3. 曖昧な分量（「適量」「少々」「ひとつまみ」等）は quantity を null にする。
4. 材料を正規化する（全角半角の統一、余分な空白削除、一般的な表記への統一）。
5. 買い物に不要そうなもの（水、油、塩、胡椒などの基本調味料）は isExcluded を true にする。

出力形式 (JSON):
{
  "title": "肉じゃが",
  "ingredients": [
    {
      "name": "玉ねぎ",
      "quantity": "1個",
      "normalizedName": "玉ねぎ",
      "isExcluded": false,
      "confidence": 1.0,
      "notes": null
    },
    ...
  ]
}
''';

  /// レシピテキストから材料を抽出する
  Future<RecipeParseResult?> parseRecipe(String recipeText) async {
    if (_chatGptService.apiKey.isEmpty) {
      debugPrint('⚠️ OpenAI APIキーが未設定です');
      return null;
    }

    try {
      debugPrint('🤖 レシピ解析開始...');
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

      final body = jsonEncode({
        'model': 'gpt-4o-mini',
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': _recipePromptSystem},
          {
            'role': 'user',
            'content': '以下のレシピテキストから材料を抽出してください:\n\n$recipeText'
          },
        ],
        'temperature': 0.1,
      });

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${_chatGptService.apiKey}',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final jsonMap = jsonDecode(resp.body);
        final content = jsonMap['choices'][0]['message']['content'] as String;
        final data = jsonDecode(content);

        final title = data['title']?.toString() ?? 'レシピから取り込み';
        final ingredients = (data['ingredients'] as List? ?? [])
            .map((e) => RecipeIngredient.fromJson(e))
            .toList();

        debugPrint('✅ レシピ解析成功: 「$title」 ${ingredients.length}件の材料を抽出');
        return RecipeParseResult(title: title, ingredients: ingredients);
      } else {
        debugPrint('❌ レシピ解析エラー: HTTP ${resp.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ レシピ解析例外: $e');
      return null;
    }
  }

  /// AIを使用して2つの材料が意味的に同一かどうかを判定する
  Future<bool> isSameIngredient(String name1, String name2) async {
    // 完全に一致する場合は即座にtrue
    if (name1.trim() == name2.trim()) return true;

    try {
      final body = jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'あなたは買い物リストの整理ヘルパーです。2つの材料が同じ食材を指しているかどうかを判定してください。判定は "true" または "false" のみで返答してください。'
          },
          {'role': 'user', 'content': '「$name1」と「$name2」は同じ食材ですか？'},
        ],
        'temperature': 0,
        'max_tokens': 10,
      });

      final resp = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${_chatGptService.apiKey}',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final jsonMap = jsonDecode(resp.body);
        final content = jsonMap['choices'][0]['message']['content'] as String;
        return content.toLowerCase().contains('true');
      }
    } catch (e) {
      debugPrint('⚠️ 同一性判定失敗: $e');
    }
    return false;
  }
}
