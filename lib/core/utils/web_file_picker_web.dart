import 'dart:async';
import 'dart:html' as html;

Future<String?> pickWebImage() async {
  final completer = Completer<String?>();
  try {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((e) {
          completer.complete(reader.result as String?);
        });
      } else {
        completer.complete(null);
      }
    });

    Future.delayed(const Duration(seconds: 30), () {
      if (!completer.isCompleted) completer.complete(null);
    });
  } catch (_) {
    completer.complete(null);
  }
  return completer.future;
}
