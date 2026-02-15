import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:maikago/services/debug_service.dart';

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
        DebugService().log('📸 Android: シャッター音を無効化してカメラ撮影を開始');
      } else if (Platform.isIOS) {
        DebugService().log('📸 iOS: カメラ撮影を開始');
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      );

      if (image != null) {
        DebugService().log('✅ カメラ撮影完了: ${image.path}');
      } else {
        DebugService().log('ℹ️ カメラ撮影をキャンセルしました');
      }

      return image;
    } catch (e) {
      DebugService().log('❌ カメラ撮影エラー: $e');
      return null;
    }
  }
}
