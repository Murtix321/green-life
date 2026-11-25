import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Kamera / galeriden fotoğraf alır ve uygulamanın kalıcı klasörüne kopyalar
/// (geçici dosyalar silinse bile büyüme günlüğü fotoğrafları kaybolmaz).
class PhotoService {
  static Future<String?> pick(ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1280, imageQuality: 85);
    if (x == null) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/photos');
      if (!folder.existsSync()) folder.createSync(recursive: true);
      final dest = '${folder.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(x.path).copy(dest);
      return dest;
    } catch (_) {
      return x.path;
    }
  }
}
