import 'dart:io';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:maikago/config.dart';
import 'package:image/image.dart' as img;

class OcrItemResult {
  final String name;
  final int price;
  OcrItemResult({required this.name, required this.price});
}

/// OCR処理の進行状況を表す列挙型
enum OcrProgressStep {
  initializing,
  imageOptimization,
  cloudFunctionsCall,
  visionApiCall,
  textExtraction,
  dataProcessing,
  completed,
  failed,
}

/// OCR処理の進行状況コールバック
typedef OcrProgressCallback = void Function(
    OcrProgressStep step, String message);

class VisionOcrService {
  VisionOcrService();

  /// Cloud Functions経由で画像解析（Vision API + ChatGPT）
  Future<OcrItemResult?> detectItemFromImage(File image,
      {OcrProgressCallback? onProgress}) async {
    try {
      onProgress?.call(OcrProgressStep.imageOptimization, '画像を最適化中...');

      // 画像を前処理＋リサイズしてファイルサイズを削減
      final resizedBytes = await _resizeImage(image);
      final b64 = base64Encode(resizedBytes);

      debugPrint(
          '📸 Cloud Functionsへリクエスト送信中... (画像サイズ: ${resizedBytes.length} bytes)');

      onProgress?.call(
          OcrProgressStep.cloudFunctionsCall, 'Cloud Functionsで解析中...');

      // Cloud Functions経由でVision API + ChatGPTを呼び出し
      final callable =
          FirebaseFunctions.instance.httpsCallable('analyzeImage');
      final response = await callable.call<Map<String, dynamic>>({
        'imageUrl': b64,
        'timestamp': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: cloudFunctionsTimeoutSeconds));

      final data = response.data;

      if (data['success'] == true) {
        final name = data['name'] as String? ?? '';
        final price = data['price'] as int? ?? 0;

        if (name.isNotEmpty && price > 0) {
          onProgress?.call(OcrProgressStep.completed, '解析完了');
          debugPrint('✅ Cloud Functions解析成功: name=$name, price=$price');
          return OcrItemResult(name: name, price: price);
        }
      }

      // success: false の場合
      final error = data['error'] as String? ?? '商品情報の抽出に失敗しました';
      onProgress?.call(OcrProgressStep.failed, error);
      debugPrint('⚠️ Cloud Functions解析失敗: $error');
      return null;
    } on FirebaseFunctionsException catch (e) {
      String message;
      switch (e.code) {
        case 'unauthenticated':
          message = '認証が必要です。ログインしてください。';
          break;
        case 'deadline-exceeded':
          message = '解析がタイムアウトしました。画像サイズを小さくして再試行してください。';
          break;
        case 'invalid-argument':
          message = '画像データが不正です。';
          break;
        default:
          message = 'サーバーエラーが発生しました。';
      }
      onProgress?.call(OcrProgressStep.failed, message);
      debugPrint('❌ Cloud Functionsエラー: [${e.code}] ${e.message}');
      return null;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        onProgress?.call(
            OcrProgressStep.failed, 'タイムアウト: ネットワーク接続を確認してください');
        debugPrint('⏰ Cloud Functionsタイムアウト');
      } else {
        onProgress?.call(OcrProgressStep.failed, 'ネットワークエラーが発生しました');
        debugPrint('❌ Cloud Functionsエラー: $e');
      }
      return null;
    }
  }

  /// 画像を前処理＋リサイズして最適化（精度向上版）
  Future<Uint8List> _resizeImage(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        debugPrint('⚠️ 画像のデコードに失敗しました');
        return bytes;
      }

      // EXIFの向きを反映してから処理
      img.Image working = img.bakeOrientation(originalImage);

      // グレースケール化 + コントラスト強調 + 軽いシャープ処理
      try {
        working = img.grayscale(working);
        // コントラストをやや強める（1.0 = 無変化）
        // image 4.x の adjustColor を想定
        working = img.adjustColor(working, contrast: 1.15);
        // シャープ処理は環境差異が大きいためスキップ（必要なら別実装に差し替え）
      } catch (_) {
        // ランタイム差異でAPIが存在しない場合はそのまま進行
      }

      // より積極的なリサイズで処理速度とOCR安定性を両立
      const maxSize = maxImageSize; // 設定ファイルから取得
      const quality = imageQuality; // 設定ファイルから取得

      if (working.width > maxSize || working.height > maxSize) {
        // アスペクト比を保持してリサイズ
        final aspectRatio = working.width / working.height;
        int newWidth, newHeight;

        if (aspectRatio > 1) {
          // 横長画像
          newWidth = maxSize;
          newHeight = (maxSize / aspectRatio).round();
        } else {
          // 縦長画像
          newHeight = maxSize;
          newWidth = (maxSize * aspectRatio).round();
        }

        final resizedImage = img.copyResize(
          working,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );

        final resizedBytes = img.encodeJpg(resizedImage, quality: quality);
        debugPrint(
            '📏 画像を最適化（前処理＋リサイズ）: ${originalImage.width}x${originalImage.height} → ${resizedImage.width}x${resizedImage.height} (${bytes.length} → ${resizedBytes.length} bytes)');
        return resizedBytes;
      }

      // 元画像が小さい場合でも品質を最適化
      if (bytes.length > 500000) {
        // 500KB以上の場合
        final optimizedBytes = img.encodeJpg(working, quality: quality);
        debugPrint(
            '📏 画像品質を最適化: ${bytes.length} → ${optimizedBytes.length} bytes');
        return optimizedBytes;
      }

      // 前処理のみ反映
      final preprocessed = img.encodeJpg(working, quality: quality);
      return preprocessed;
    } catch (e) {
      debugPrint('⚠️ 画像リサイズエラー: $e');
      return await image.readAsBytes();
    }
  }
}
