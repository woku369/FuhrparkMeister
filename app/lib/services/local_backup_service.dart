import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import 'document_storage.dart';

/// Backup als ZIP-Datei auf dem Gerät - unabhängig von Google Drive.
/// Export erzeugt eine Datei, die der Nutzer über die Android-System-
/// freigabe selbst irgendwohin ablegen kann (Downloads, E-Mail, eine
/// andere Cloud-App, ...). Import liest eine solche Datei wieder ein
/// und ersetzt den kompletten lokalen Datenbestand ("letzter Stand
/// gewinnt", wie beim Drive-Backup - kein Merge einzelner Datensätze).
class LocalBackupService {
  static const _dataEntryName = 'backup.json';
  static const _documentsPrefix = 'documents/';

  /// Baut das ZIP im App-Cache-Verzeichnis und gibt die Datei zurück.
  /// Der Aufrufer kümmert sich ums Teilen/Speichern (z. B. via share_plus).
  static Future<File> exportToZip() async {
    final raw = await DatabaseHelper.instance.exportAllRaw();
    final json = jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      ...raw,
    });

    final archive = Archive();
    final jsonBytes = utf8.encode(json);
    archive.addFile(ArchiveFile(_dataEntryName, jsonBytes.length, jsonBytes));

    for (final doc in raw['documents'] ?? const []) {
      final relativePath = doc['dateipfad'] as String?;
      if (relativePath == null) continue;
      final file = File(await DocumentStorage.absolutePath(relativePath));
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      archive.addFile(
        ArchiveFile('$_documentsPrefix$relativePath', bytes.length, bytes),
      );
    }

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw StateError('ZIP-Erstellung fehlgeschlagen.');
    }
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final zipFile = File(
      p.join(tempDir.path, 'fuhrparkmeister_backup_$timestamp.zip'),
    );
    await zipFile.writeAsBytes(zipBytes);
    return zipFile;
  }

  /// Liest eine zuvor exportierte ZIP-Datei ein und ersetzt den
  /// kompletten lokalen Datenbestand (Datenbank + Dokumenten-Fotos).
  static Future<void> importFromZip(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? dataEntry;
    for (final entry in archive) {
      if (entry.isFile && entry.name == _dataEntryName) {
        dataEntry = entry;
        break;
      }
    }
    if (dataEntry == null) {
      throw const FormatException(
        'Keine gültige FuhrparkMeister-Backup-Datei (backup.json fehlt).',
      );
    }

    final decoded =
        jsonDecode(utf8.decode(dataEntry.content as List<int>))
            as Map<String, dynamic>;
    final raw = <String, List<Map<String, Object?>>>{};
    for (final table in DatabaseHelper.backupTables) {
      final list = decoded[table] as List? ?? const [];
      raw[table] =
          list.map((e) => Map<String, Object?>.from(e as Map)).toList();
    }

    for (final entry in archive) {
      if (!entry.isFile || !entry.name.startsWith(_documentsPrefix)) continue;
      final relativePath = entry.name.substring(_documentsPrefix.length);
      final absolutePath = await DocumentStorage.absolutePath(relativePath);
      final file = File(absolutePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.content as List<int>);
    }

    await DatabaseHelper.instance.replaceAllRaw(raw);
  }
}
