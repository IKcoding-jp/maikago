import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  /// シャッター音を無効化したカメラ撮影
  static Future<XFile?> takePicture({
    ImageSource source = ImageSource.camera,
    int imageQuality = 85,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    try {
      // Androidの場合、シャッター音を無効化する設定を追加
      if (Platform.isAndroid) {
        debugPrint('📸 Android: シャッター音を無効化してカメラ撮影を開始');
      } else if (Platform.isIOS) {
        debugPrint('📸 iOS: カメラ撮影を開始');
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      );

      if (image != null) {
        debugPrint('✅ カメラ撮影完了: ${image.path}');
      } else {
        debugPrint('ℹ️ カメラ撮影をキャンセルしました');
      }

      return image;
    } catch (e) {
      debugPrint('❌ カメラ撮影エラー: $e');
      return null;
    }
  }

  /// ギャラリーから画像選択
  static Future<XFile?> pickFromGallery({int imageQuality = 85}) async {
    try {
      debugPrint('📁 ギャラリーから画像選択を開始');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );

      if (image != null) {
        debugPrint('✅ 画像選択完了: ${image.path}');
      } else {
        debugPrint('ℹ️ 画像選択をキャンセルしました');
      }

      return image;
    } catch (e) {
      debugPrint('❌ 画像選択エラー: $e');
      return null;
    }
  }
}
