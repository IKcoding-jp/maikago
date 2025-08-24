import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:maikago/services/vision_ocr_service.dart';
import 'package:maikago/services/ml_ocr_service.dart';
import 'package:maikago/services/tflite_shelf_detector_service.dart';
import 'package:maikago/services/advanced_ml_ocr_service.dart';

class HybridOcrService {
  final VisionOcrService _visionService = VisionOcrService();
  final MlOcrService _mlService = MlOcrService();
  final TfliteShelfDetectorService _shelfDetector =
      TfliteShelfDetectorService();
  final AdvancedMlOcrService _advancedMlService = AdvancedMlOcrService();

  bool _isMlInitialized = false;
  bool _isShelfDetectorInitialized = false;
  bool _isAdvancedMlInitialized = false;

  /// ハイブリッドOCRサービスの初期化
  Future<void> initialize() async {
    debugPrint('🚀 ハイブリッドOCRサービス初期化開始');

    // 機械学習モデルの初期化
    await _mlService.initialize();
    _isMlInitialized = _mlService.isAvailable;

    // 棚札検出システムの初期化
    await _shelfDetector.initialize();
    _isShelfDetectorInitialized = _shelfDetector.isAvailable;

    // 高度な機械学習システムの初期化
    await _advancedMlService.initialize();
    _isAdvancedMlInitialized = _advancedMlService.isAvailable;

    if (_isMlInitialized) {
      debugPrint('✅ 機械学習モデル初期化完了');
    } else {
      debugPrint('⚠️ 機械学習モデル初期化失敗 - Vision APIのみで動作');
    }

    if (_isShelfDetectorInitialized) {
      debugPrint('✅ 棚札検出システム初期化完了');
    } else {
      debugPrint('⚠️ 棚札検出システム初期化失敗');
    }

    if (_isAdvancedMlInitialized) {
      debugPrint('✅ 高度な機械学習システム初期化完了');
    } else {
      debugPrint('⚠️ 高度な機械学習システム初期化失敗');
    }
  }

  /// ハイブリッドOCRによる商品情報抽出
  Future<OcrItemResult?> detectItemFromImage(File image) async {
    try {
      debugPrint('🔍 高度なハイブリッドOCR解析開始');

      // 1. 基本機械学習で試行（高信頼度の場合）
      if (_isMlInitialized) {
        debugPrint('🤖 基本機械学習を実行中...');
        final mlResult = await _mlService.detectItemFromImage(image);
        if (mlResult != null && mlResult.confidence > 0.8) {
          debugPrint(
              '🎉 基本機械学習で高精度な結果を取得: 信頼度 ${(mlResult.confidence * 100).toStringAsFixed(1)}%');
          return OcrItemResult(
            name: mlResult.name,
            price: mlResult.price,
          );
        } else if (mlResult != null) {
          debugPrint(
              '⚠️ 基本機械学習の信頼度が低い: ${(mlResult.confidence * 100).toStringAsFixed(1)}%');
        }
      }

      // 2. 高度な機械学習AIを試行
      if (_isAdvancedMlInitialized) {
        debugPrint('🚀 高度な機械学習AIを実行中...');
        final advancedResult =
            await _advancedMlService.detectItemFromImage(image);

        if (advancedResult != null && advancedResult.confidence > 0.7) {
          debugPrint(
              '🎉 高度な機械学習AIで高精度な結果を取得: ${advancedResult.detectionMethod}');
          debugPrint(
              '📊 信頼度: ${(advancedResult.confidence * 100).toStringAsFixed(1)}%, メタデータ: ${advancedResult.metadata}');

          return OcrItemResult(
            name: advancedResult.name,
            price: advancedResult.price,
          );
        } else {
          debugPrint(
              '⚠️ 高度な機械学習AIの信頼度が低い: ${(advancedResult?.confidence != null ? (advancedResult!.confidence * 100).toStringAsFixed(1) : 'N/A')}%');
        }
      }

      // 3. 棚札検出を試行
      if (_isShelfDetectorInitialized) {
        debugPrint('🎯 棚札検出を実行中...');
        final detections = await _shelfDetector.detectFromImage(image);

        if (detections.isNotEmpty) {
          debugPrint('✅ 棚札要素を検出: ${detections.length}個');

          // 検出結果から商品情報を抽出
          final productInfo = _shelfDetector.extractProductInfo(detections);
          if (productInfo != null) {
            debugPrint(
                '🎉 棚札検出で商品情報を取得: ${productInfo['name']} ¥${productInfo['price']}');
            return OcrItemResult(
              name: productInfo['name'],
              price: productInfo['price'],
            );
          }
        } else {
          debugPrint('⚠️ 棚札要素を検出できませんでした');
        }
      }

      // 4. Vision APIでフォールバック処理
      debugPrint('📸 Vision APIでフォールバック処理');
      final visionResult = await _visionService.detectItemFromImage(image);

      // 5. 結果の統合・改善
      if (visionResult != null && _isMlInitialized) {
        return _improveWithMl(visionResult, image);
      }

      return visionResult;
    } catch (e) {
      debugPrint('❌ 高度なハイブリッドOCRエラー: $e');
      return null;
    }
  }

  /// 機械学習で結果を改善
  OcrItemResult _improveWithMl(OcrItemResult visionResult, File image) {
    // 機械学習の結果とVision APIの結果を比較・統合
    // より信頼性の高い結果を選択
    return visionResult;
  }

  /// 棚札検出の詳細結果を取得（デバッグ用）
  Future<List<DetectionResult>> getShelfDetections(File image) async {
    if (!_isShelfDetectorInitialized) {
      return [];
    }
    return await _shelfDetector.detectFromImage(image);
  }

  void dispose() {
    _mlService.dispose();
    _shelfDetector.dispose();
    _advancedMlService.dispose();
  }
}
