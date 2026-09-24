import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import 'document_storage.dart';

/// Backup als ZIP-Datei auf dem Gerät - unabhängig von Google Drive, z. B.
/// für einen gemeinsam genutzten Familien-Fuhrpark: eine Person exportiert
/// und teilt die Datei, die anderen importieren sie.
/// Export legt die Datei im App-eigenen externen Ordner ab (sichtbar für
/// Datei-Manager unter Android/data/<paket>/files/, keine Berechtigung
/// nötig) und öffnet zusätzlich die Android-Systemfreigabe. Import geht auf
/// zwei Wegen: entweder liest [importLatestFromBackupDir] die neueste
/// ZIP-Datei aus genau diesem Ordner (Datei manuell per Datei-Manager dort
/// ablegen), oder - der übliche Weg - eine per WhatsApp/Drive/E-Mail
/// empfangene ZIP wird direkt per Android-Teilen-Dialog "Öffnen mit
/// FuhrparkMeister" gewählt (siehe ShareImportService, MainActivity.kt).
/// Bewusst ohne allgemeinen Datei-Dialog (file_picker), weil dessen
/// Android-Abhängigkeiten mit den anderen Plugins dieser App nicht
/// kompilierbar sind (siehe ROADMAP).
/// Import ersetzt den kompletten lokalen Datenbestand ("letzter Stand
/// gewinnt", wie beim Drive-Backup - kein Merge einzelner Datensätze).
class LocalBackupService {
  static const _dataEntryName = 'backup.json';
  static const _documentsPrefix = 'documents/';

  static Future<Directory> _backupDir() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw StateError('Kein externer Speicher verfügbar.');
    }
    return dir;
  }

  /// Ordnerpfad, in dem Backups liegen - zur Anzeige in der UI, damit
  /// der Nutzer weiß, wohin er eine empfangene Datei kopieren muss.
  static Future<String> backupDirPath() async => (await _backupDir()).path;

  /// Baut das ZIP im Backup-Ordner und gibt die Datei zurück. Der
  /// Aufrufer kümmert sich zusätzlich ums Teilen (z. B. via share_plus).
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
    final backupDir = await _backupDir();
    final timestamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final zipFile = File(
      p.join(backupDir.path, 'fuhrparkmeister_backup_$timestamp.zip'),
    );
    await zipFile.writeAsBytes(zipBytes);
    return zipFile;
  }

  /// Sucht die neueste .zip-Datei im Backup-Ordner und importiert sie.
  static Future<void> importLatestFromBackupDir() async {
    final backupDir = await _backupDir();
    final zips = await backupDir
        .list()
        .where((e) => e is File && e.path.toLowerCase().endsWith('.zip'))
        .cast<File>()
        .toList();
    if (zips.isEmpty) {
      throw StateError(
        'Kein Backup gefunden in ${backupDir.path}. Datei dort ablegen und erneut versuchen.',
      );
    }
    zips.sort(
      (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );
    await importFromZip(zips.first.path);
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
