import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maikago/services/recipe_parser_service.dart';
import 'package:maikago/screens/recipe_confirm_screen.dart';

class RecipeImportBottomSheet extends StatefulWidget {
  const RecipeImportBottomSheet({super.key});

  @override
  State<RecipeImportBottomSheet> createState() =>
      _RecipeImportBottomSheetState();
}

class _RecipeImportBottomSheetState extends State<RecipeImportBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final RecipeParserService _recipeParserService = RecipeParserService();
  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onStartAnalysis() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'レシピテキストを貼り付けてください';
      });
      return;
    }

    if (text.length > 8000) {
      setState(() {
        _errorMessage = '長すぎるため分割してください';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final result = await _recipeParserService.parseRecipe(text);
      if (!mounted) return;

      if (result == null || result.ingredients.isEmpty) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = '抽出できませんでした。文章を短くするか、材料セクションを含めて貼り付けてください。';
        });
      } else {
        // 確認画面へ遷移
        Navigator.pop(context); // ボトムシートを閉じる
        unawaited(Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeConfirmScreen(
              initialIngredients: result.ingredients,
              recipeTitle: result.title,
              sourceText: text,
            ),
          ),
        ));
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'エラーが発生しました: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'レシピを貼り付け',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'レシピのテキストを貼り付けると、材料を買い物リストにまとめます。',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const Text(
                    '材料と作り方が混在していても解析します。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLines: 6, // 8から少し減らしてスクロール時の安全マージンを確保
                    decoration: InputDecoration(
                      hintText: 'ここにレシピの文章を貼り付けてください',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: _errorMessage,
                    ),
                    onChanged: (val) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '文字数: ${_controller.text.length} / 8,000（目安）',
                      style: TextStyle(
                        fontSize: 12,
                        color: _controller.text.length > 8000
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isAnalyzing ? null : _onStartAnalysis,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isAnalyzing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('解析開始',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  if (_isAnalyzing) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        '解析中です...\n材料を整理しています（約数秒）',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
