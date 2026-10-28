import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppStorage {
  /// Resolves the safe, authorized external storage directory for the app
  static Future<Directory> _getExternalDir() async {
    // Tries to get the external Android/data/ directory first
    final externalDir = await getExternalStorageDirectory();

    // Falls back to internal documents if external is unavailable
    final baseDir = externalDir ?? await getApplicationDocumentsDirectory();

    final appDir = Directory(p.join(baseDir.path, 'butterfly'));
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  /// Ensures the target directories exist and returns the full path for butterfly.db
  static Future<String> getDatabasePath() async {
    final dir = await _getExternalDir();
    return p.join(dir.path, 'butterfly.db');
  }

  /// Ensures an images subfolder exists and returns a path to save a receipt photo
  static Future<String> getImagePath(String filename) async {
    final baseDir = await _getExternalDir();
    final imagesDir = Directory(p.join(baseDir.path, 'images'));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return p.join(imagesDir.path, filename);
  }
}