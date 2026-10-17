import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'web_file_picker_stub.dart'
    if (dart.library.html) 'web_file_picker_web.dart';

class ImagePickerHelper {
  static Future<String?> pickImage(ImageSource source) async {
    if (kIsWeb) {
      final webDataUrl = await pickWebImage();
      if (webDataUrl != null) return webDataUrl;
    }

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          return 'data:image/png;base64,${base64Encode(bytes)}';
        }
        return image.path;
      }
    } catch (_) {
      if (kIsWeb) {
        return await pickWebImage();
      }
    }
    return null;
  }
}
