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
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      );

      return image;
    } catch (e) {
      DebugService().logError('カメラ撮影エラー: $e');
      return null;
    }
  }
}
