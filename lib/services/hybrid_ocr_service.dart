import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:maikago/config.dart';
import 'package:maikago/services/vision_ocr_service.dart';
import 'package:maikago/services/debug_service.dart';

class HybridOcrService {
  final VisionOcrService _visionService = VisionOcrService();

  // キャッシュ用のMap（メモリ内キャッシュ）
  final Map<String, OcrItemResult> _cache = {};
  static const int _maxCacheSize = 100; // 最大キャッシュ数を50から100に増加

  /// Vision API専用OCRサービスの初期化
  Future<void> initialize() async {
    // Cloud Functions OCRサービス初期化
  }

  /// 画像のハッシュ値を計算
  String _calculateImageHash(File image) {
    final bytes = image.readAsBytesSync();
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Cloud Functions経由で商品情報を抽出
  Future<OcrItemResult?> detectItemFromImage(File image,
      {OcrProgressCallback? onProgress}) async {
    try {
      onProgress?.call(OcrProgressStep.initializing, 'OCR解析を初期化中...');

      // キャッシュチェック
      final imageHash = _calculateImageHash(image);
      if (_cache.containsKey(imageHash)) {
        onProgress?.call(OcrProgressStep.completed, 'キャッシュから結果を取得');
        return _cache[imageHash];
      }

      onProgress?.call(OcrProgressStep.imageOptimization, '画像を最適化中...');

      // Cloud Functions経由で実行
      final result = await _visionService
          .detectItemFromImage(image, onProgress: onProgress)
          .timeout(
        const Duration(seconds: cloudFunctionsTimeoutSeconds),
        onTimeout: () {
          DebugService().logError('Cloud Functionsタイムアウト');
          return null;
        },
      );

      if (result != null) {
        onProgress?.call(OcrProgressStep.completed, 'Cloud Functionsで解析完了');
        _addToCache(imageHash, result);
        return result;
      }

      onProgress?.call(OcrProgressStep.failed, '解析に失敗しました');
      return null;
    } catch (e) {
      onProgress?.call(OcrProgressStep.failed, 'エラーが発生しました');
      DebugService().logError('OCR解析エラー: $e');
      return null;
    }
  }

  /// Cloud Functions経由で商品情報を抽出（高速版と同じフローに統合）
  Future<OcrItemResult?> detectItemFromImageFast(File image,
      {OcrProgressCallback? onProgress}) async {
    // Cloud Functions統合後はdetectItemFromImageと同一フロー
    return detectItemFromImage(image, onProgress: onProgress);
  }

  /// キャッシュに結果を追加（LRU方式）
  void _addToCache(String imageHash, OcrItemResult result) {
    // キャッシュサイズ制限チェック
    if (_cache.length >= _maxCacheSize) {
      // 最も古いエントリを削除（簡易的なLRU）
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    _cache[imageHash] = result;
  }

  /// キャッシュをクリア
  void clearCache() {
    _cache.clear();
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
  }
}
