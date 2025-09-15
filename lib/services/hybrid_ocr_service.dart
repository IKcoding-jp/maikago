import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:maikago/config.dart';
import 'package:maikago/services/vision_ocr_service.dart';

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

  /// Cloud Functions + Vision APIによる商品情報抽出（並列処理版）
  Future<OcrItemResult?> detectItemFromImage(File image,
      {OcrProgressCallback? onProgress,
      bool enableCloudFunctions = false}) async {
    try {
      onProgress?.call(OcrProgressStep.initializing, 'OCR解析を初期化中...');

      if (enableCloudFunctions) {
        debugPrint('🔍 Cloud Functions + Vision API OCR解析開始（並列処理）');
      } else {
        debugPrint('🔍 Vision API OCR解析開始（Cloud Functions無効化）');
      }

      // キャッシュチェック
      final imageHash = _calculateImageHash(image);
      if (_cache.containsKey(imageHash)) {
        onProgress?.call(OcrProgressStep.completed, 'キャッシュから結果を取得');
        debugPrint('⚡ キャッシュから結果を取得');
        return _cache[imageHash];
      }

      onProgress?.call(OcrProgressStep.imageOptimization, '画像を最適化中...');

      OcrItemResult? cfResult;
      OcrItemResult? viResult;

      if (enableCloudFunctions) {
        // 並列処理でCloud FunctionsとVision APIを同時実行（タイムアウト付き）
        final results = await Future.wait([
          _visionService.detectItemFromImageWithCloudFunctions(image,
              onProgress: (step, message) {
            if (step == OcrProgressStep.cloudFunctionsCall) {
              onProgress?.call(step, message);
            }
          }).timeout(
            const Duration(
                seconds: cloudFunctionsTimeoutSeconds), // 設定ファイルからタイムアウト時間を取得
            onTimeout: () {
              debugPrint('⏰ Cloud Functionsタイムアウト');
              return null;
            },
          ),
          _visionService.detectItemFromImage(image,
              onProgress: (step, message) {
            if (step == OcrProgressStep.visionApiCall) {
              onProgress?.call(step, message);
            }
          }).timeout(
            const Duration(
                seconds: visionApiTimeoutSeconds), // 設定ファイルからタイムアウト時間を取得
            onTimeout: () {
              debugPrint('⏰ Vision APIタイムアウト');
              return null;
            },
          ),
        ], eagerError: false);

        cfResult = results.isNotEmpty ? results[0] : null;
        viResult = results.length > 1 ? results[1] : null;
      } else {
        // Vision APIのみ実行（タイムアウト付き）
        viResult = await _visionService
            .detectItemFromImage(image, onProgress: onProgress)
            .timeout(
          const Duration(seconds: visionApiTimeoutSeconds),
          onTimeout: () {
            debugPrint('⏰ Vision APIタイムアウト');
            return null;
          },
        );
      }

      OcrItemResult? selectTaxIncludedPrefer(
          OcrItemResult? a, OcrItemResult? b) {
        if (a == null && b == null) return null;
        if (a != null && b == null) return a;
        if (a == null && b != null) return b;
        if (a == null || b == null) return a ?? b; // 保険

        int pa = a.price;
        int pb = b.price;
        bool approx(int x, int y, int tol) => (x - y).abs() <= tol;

        // 10% または 8% の税込関係とみなせる場合は高い方を選択
        if (pa > pb) {
          if (approx(pa, (pb * 1.10).round(), 2) ||
              approx(pa, (pb * 1.08).round(), 2)) {
            debugPrint('🎯 価格差から税込候補を優先: ${b.price} → ${a.price}');
            return a;
          }
        } else if (pb > pa) {
          if (approx(pb, (pa * 1.10).round(), 2) ||
              approx(pb, (pa * 1.08).round(), 2)) {
            debugPrint('🎯 価格差から税込候補を優先: ${a.price} → ${b.price}');
            return b;
          }
        }

        // 明確でない場合は、Vision API 解析結果（ローカル規則で税込補正済み）を優先
        debugPrint('ℹ️ 税込関係を判定できないためVision結果を優先');
        return b; // b は Vision 結果
      }

      final selected = selectTaxIncludedPrefer(cfResult, viResult);
      if (selected != null) {
        final method =
            (selected == cfResult) ? 'Cloud Functions' : 'Vision API';
        onProgress?.call(OcrProgressStep.completed, '$methodで解析完了');
        debugPrint('✅ $methodで商品情報を採用: ${selected.name} ¥${selected.price}');
        _addToCache(imageHash, selected);
        return selected;
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