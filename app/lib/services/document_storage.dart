import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Fotos werden geräteunabhängig als relativer Pfad
/// ("<vehicleId>/<dateiname>") in der Datenbank abgelegt und erst zur
/// Anzeige/zum Sync in einen absoluten, geräteeigenen Pfad aufgelöst.
/// Das ist Voraussetzung dafür, dass ein Backup auf einem anderen Gerät
/// wiederhergestellt werden kann.
class DocumentStorage {
  static const _rootFolder = 'fuhrparkmeister_docs';

  static Future<Directory> vehicleDir(String vehicleId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, _rootFolder, vehicleId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> absolutePath(String relativePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, _rootFolder, relativePath);
  }
}
