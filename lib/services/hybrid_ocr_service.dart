import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:maikago/services/vision_ocr_service.dart';

class HybridOcrService {
  final VisionOcrService _visionService = VisionOcrService();

  // キャッシュ用のMap（メモリ内キャッシュ）
  final Map<String, OcrItemResult> _cache = {};
  static const int _maxCacheSize = 50; // 最大キャッシュ数

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

  /// Cloud Functions + Vision APIによる商品情報抽出（並列処理版）
  Future<OcrItemResult?> detectItemFromImage(File image,
      {OcrProgressCallback? onProgress}) async {
    try {
      onProgress?.call(OcrProgressStep.initializing, 'OCR解析を初期化中...');
      debugPrint('🔍 Cloud Functions + Vision API OCR解析開始（並列処理）');

      // キャッシュチェック
      final imageHash = _calculateImageHash(image);
      if (_cache.containsKey(imageHash)) {
        onProgress?.call(OcrProgressStep.completed, 'キャッシュから結果を取得');
        debugPrint('⚡ キャッシュから結果を取得');
        return _cache[imageHash];
      }

      onProgress?.call(OcrProgressStep.imageOptimization, '画像を最適化中...');

      // 並列処理でCloud FunctionsとVision APIを同時実行
      final results = await Future.wait([
        _visionService.detectItemFromImageWithCloudFunctions(image,
            onProgress: (step, message) {
          if (step == OcrProgressStep.cloudFunctionsCall) {
            onProgress?.call(step, message);
          }
        }),
        _visionService.detectItemFromImage(image, onProgress: (step, message) {
          if (step == OcrProgressStep.visionApiCall) {
            onProgress?.call(step, message);
          }
        }),
      ], eagerError: false);

      // 最初に成功した結果を返す
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        if (result != null) {
          final method = i == 0 ? 'Cloud Functions' : 'Vision API';
          onProgress?.call(OcrProgressStep.completed, '$methodで解析完了');
          debugPrint('✅ $methodで商品情報を取得: ${result.name} ¥${result.price}');

          // 結果をキャッシュに保存
          _addToCache(imageHash, result);
          return result;
        }
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

  /// 高速化版：Cloud Functionsのみを試行（フォールバックなし）
  Future<OcrItemResult?> detectItemFromImageFast(File image,
      {OcrProgressCallback? onProgress}) async {
    try {
      onProgress?.call(OcrProgressStep.initializing, '高速OCR解析を開始中...');
      debugPrint('⚡ 高速OCR解析開始（Cloud Functionsのみ）');

      // キャッシュチェック
      final imageHash = _calculateImageHash(image);
      if (_cache.containsKey(imageHash)) {
        onProgress?.call(OcrProgressStep.completed, 'キャッシュから結果を取得');
        debugPrint('⚡ キャッシュから結果を取得（高速版）');
        return _cache[imageHash];
      }

      onProgress?.call(OcrProgressStep.imageOptimization, '画像を最適化中...');

      final result = await _visionService
          .detectItemFromImageWithCloudFunctions(image, onProgress: onProgress);

      if (result != null) {
        onProgress?.call(OcrProgressStep.completed, '高速解析完了');
        debugPrint('✅ 高速解析成功: ${result.name} ¥${result.price}');

        // 結果をキャッシュに保存
        _addToCache(imageHash, result);
        return result;
      }

      onProgress?.call(OcrProgressStep.failed, '高速解析に失敗しました');
      debugPrint('⚠️ 高速解析で商品情報を取得できませんでした');
      return null;
    } catch (e) {
      onProgress?.call(OcrProgressStep.failed, 'エラーが発生しました');
      debugPrint('❌ 高速OCR解析エラー: $e');
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
