import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:maikago/services/vision_ocr_service.dart';

class HybridOcrService {
  final VisionOcrService _visionService = VisionOcrService();

  /// Vision API専用OCRサービスの初期化
  Future<void> initialize() async {
    debugPrint('🚀 Vision API専用OCRサービス初期化開始');
    debugPrint('📸 Vision APIによる高精度OCR解析システム');
    debugPrint('🎯 Vision API専用OCRサービス初期化完了');
  }

  /// Cloud Functions + Vision APIによる商品情報抽出
  Future<OcrItemResult?> detectItemFromImage(File image) async {
    try {
      debugPrint('🔍 Cloud Functions + Vision API OCR解析開始');

      // 1. まずCloud Functionsで画像解析を試行
      final cloudResult =
          await _visionService.detectItemFromImageWithCloudFunctions(image);

      if (cloudResult != null) {
        debugPrint(
            '✅ Cloud Functionsで商品情報を取得: ${cloudResult.name} ¥${cloudResult.price}');
        return cloudResult;
      }

      debugPrint('⚠️ Cloud Functionsで商品情報を取得できませんでした');
      debugPrint('🔄 Vision APIにフォールバック');

      // 2. フォールバック: Vision APIで商品情報を抽出
      final visionResult = await _visionService.detectItemFromImage(image);

      if (visionResult != null) {
        debugPrint(
            '✅ Vision APIで商品情報を取得: ${visionResult.name} ¥${visionResult.price}');
        return visionResult;
      } else {
        debugPrint('⚠️ Vision APIで商品情報を取得できませんでした');
      }

      debugPrint('❌ 商品情報の抽出に失敗しました');
      return null;
    } catch (e) {
      debugPrint('❌ OCR解析エラー: $e');
      return null;
    }
  }

  void dispose() {
    debugPrint('🗑️ Vision API専用OCRサービスリソースを解放しました');
  }
}
