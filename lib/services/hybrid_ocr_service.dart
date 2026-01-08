import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:maikago/config.dart';
import 'package:maikago/services/vision_ocr_service.dart';
import 'package:maikago/services/chatgpt_service.dart';

class HybridOcrService {
  final VisionOcrService _visionService = VisionOcrService();

  // キャッシュ用のMap（メモリ内キャッシュ）
  final Map<String, OcrItemResult> _cache = {};
  static const int _maxCacheSize = 100; // 最大キャッシュ数を50から100に増加

  /// Vision API専用OCRサービスの初期化
  Future<void> initialize() async {
    debugPrint('🚀 Vision API専用OCRサービス初期化開始');
    debugPrint('📸 Vision APIによる高精度OCR解析システム');
    debugPrint('🎯 Vision API専用OCRサービス初期化完了');
  }

  /// 画像のハッシュ値を計算
  String _calculateImageHash(File image) {
    final bytes = image.readAsBytesSync();
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Vision APIによる商品情報抽出（シンプル版）
  /// 注意: このメソッドは現在使用されていません。detectItemFromImageFast()を使用してください。
  @Deprecated('detectItemFromImageFast()を使用してください')
  Future<OcrItemResult?> detectItemFromImage(File image,
      {OcrProgressCallback? onProgress}) async {
    try {
      onProgress?.call(OcrProgressStep.initializing, 'OCR解析を初期化中...');
      debugPrint('🔍 Vision API OCR解析開始（シンプル版）');

      // キャッシュチェック
      final imageHash = _calculateImageHash(image);
      if (_cache.containsKey(imageHash)) {
        onProgress?.call(OcrProgressStep.completed, 'キャッシュから結果を取得');
        debugPrint('⚡ キャッシュから結果を取得');
        return _cache[imageHash];
      }

      onProgress?.call(OcrProgressStep.imageOptimization, '画像を最適化中...');

      // Vision APIのみ実行（タイムアウト付き）
      final result = await _visionService
          .detectItemFromImage(image, onProgress: onProgress)
          .timeout(
        const Duration(seconds: visionApiTimeoutSeconds),
        onTimeout: () {
          debugPrint('⏰ Vision APIタイムアウト');
          return null;
        },
      );

      if (result != null) {
        onProgress?.call(OcrProgressStep.completed, 'Vision APIで解析完了');
        debugPrint('✅ Vision APIで商品情報を採用: ${result.name} ¥${result.price}');
        _addToCache(imageHash, result);
        return result;
      }

      onProgress?.call(OcrProgressStep.failed, '解析に失敗しました');
      debugPrint('❌ すべてのOCR解析方法で商品情報の抽出に失敗しました');
      return null;
    } catch (e) {
      onProgress?.call(OcrProgressStep.failed, 'エラーが発生しました');
      debugPrint('❌ OCR解析エラー: $e');
      return null;
    }
  }

  /// 高速化版：Vision API + ChatGPT API直接呼び出し（Cloud Functions不要）
  Future<OcrItemResult?> detectItemFromImageFast(File image,
      {OcrProgressCallback? onProgress}) async {
    try {
      onProgress?.call(
          OcrProgressStep.initializing, 'Vision API + ChatGPT解析を開始中...');
      debugPrint('⚡ Vision API + ChatGPT直接呼び出し開始（シンプル版）');

      // キャッシュチェック
      final imageHash = _calculateImageHash(image);
      if (_cache.containsKey(imageHash)) {
        onProgress?.call(OcrProgressStep.completed, 'キャッシュから結果を取得');
        debugPrint('⚡ キャッシュから結果を取得');
        return _cache[imageHash];
      }

      onProgress?.call(OcrProgressStep.imageOptimization, '画像を最適化中...');

      // OpenAI Vision API直接呼び出し（タイムアウト最適化）
      final chatGpt = ChatGptService();
      final result = await chatGpt.extractProductInfoFromImage(image).timeout(
        const Duration(
            seconds: visionApiTimeoutSeconds + chatGptTimeoutSeconds),
        onTimeout: () {
          debugPrint('⏰ Vision API + ChatGPTタイムアウト');
          return null;
        },
      );

      if (result != null) {
        onProgress?.call(OcrProgressStep.completed, 'Vision API + ChatGPT解析完了');
        debugPrint(
            '✅ Vision API + ChatGPT解析成功: ${result.name} ¥${result.price}');

        // 結果をキャッシュに保存
        _addToCache(imageHash, result);
        return result;
      }

      onProgress?.call(OcrProgressStep.failed, 'Vision API + ChatGPT解析に失敗しました');
      debugPrint('⚠️ Vision API + ChatGPT解析で商品情報を取得できませんでした');
      return null;
    } catch (e) {
      onProgress?.call(OcrProgressStep.failed, 'エラーが発生しました');
      debugPrint('❌ Vision API + ChatGPT解析エラー: $e');
      return null;
    }
  }

  /// キャッシュに結果を追加（LRU方式）
  void _addToCache(String imageHash, OcrItemResult result) {
    // キャッシュサイズ制限チェック
    if (_cache.length >= _maxCacheSize) {
      // 最も古いエントリを削除（簡易的なLRU）
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      debugPrint('🗑️ 古いキャッシュエントリを削除: $oldestKey');
    }

    _cache[imageHash] = result;
    debugPrint('💾 結果をキャッシュに保存: $imageHash');
  }

  /// キャッシュをクリア
  void clearCache() {
    _cache.clear();
    debugPrint('🗑️ OCRキャッシュをクリアしました');
  }

  /// キャッシュ統計を取得
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _cache.length,
      'maxSize': _maxCacheSize,
      'keys': _cache.keys.toList(),
    };
  }

  void dispose() {
    clearCache();
    debugPrint('🗑️ Vision API専用OCRサービスリソースを解放しました');
  }
}
