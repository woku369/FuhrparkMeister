import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../database/database_helper.dart';
import 'document_storage.dart';

/// Manuelles Backup/Restore über Google Drive (Scope `drive.file`, App
/// sieht nur eigene Dateien in einem eigenen "FuhrparkMeister"-Ordner).
///
/// Bewusst einfach gehalten: kein automatischer Hintergrund-Sync, kein
/// Merge einzelner Datensätze - ein Upload überschreibt den kompletten
/// Cloud-Stand, ein Download überschreibt den kompletten lokalen Stand
/// ("letzter Stand gewinnt"). Für mehrere Geräte bedeutet das: nach
/// Änderungen hochladen, bevor man am anderen Gerät weiterarbeitet, dort
/// vorher herunterladen.
class DriveSyncService {
  DriveSyncService._();
  static final DriveSyncService instance = DriveSyncService._();

  static const _driveFileScope = 'https://www.googleapis.com/auth/drive.file';
  static const _folderName = 'FuhrparkMeister';
  static const _dataFileName = 'fuhrparkmeister_backup.json';
  static const _apiBase = 'https://www.googleapis.com/drive/v3/files';
  static const _uploadBase =
      'https://www.googleapis.com/upload/drive/v3/files';

  final _googleSignIn = GoogleSignIn(scopes: const [_driveFileScope]);

  GoogleSignInAccount? _account;
  GoogleSignInAccount? get currentAccount => _account;

  Future<GoogleSignInAccount?> signIn() async {
    _account = await _googleSignIn.signIn();
    return _account;
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    _account = await _googleSignIn.signInSilently();
    return _account;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
  }

  Future<Map<String, String>> _authHeaders() async {
    final account = _account ?? await _googleSignIn.signInSilently();
    if (account == null) {
      throw StateError('Nicht bei Google angemeldet.');
    }
    _account = account;
    return account.authHeaders;
  }

  void _checkOk(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException('Drive-API-Fehler ${resp.statusCode}: ${resp.body}');
    }
  }

  Future<String> _getOrCreateFolderId() async {
    final headers = await _authHeaders();
    final query = Uri.encodeComponent(
      "mimeType='application/vnd.google-apps.folder' and "
      "name='$_folderName' and trashed=false",
    );
    final listResp = await http.get(
      Uri.parse('$_apiBase?q=$query&spaces=drive&fields=files(id,name)'),
      headers: headers,
    );
    _checkOk(listResp);
    final files =
        (jsonDecode(listResp.body)['files'] as List).cast<Map<String, dynamic>>();
    if (files.isNotEmpty) return files.first['id'] as String;

    final createResp = await http.post(
      Uri.parse(_apiBase),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': _folderName,
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );
    _checkOk(createResp);
    return jsonDecode(createResp.body)['id'] as String;
  }

  Future<String?> _findFileId(String folderId, String name) async {
    final headers = await _authHeaders();
    final query = Uri.encodeComponent(
      "'$folderId' in parents and name='$name' and trashed=false",
    );
    final resp = await http.get(
      Uri.parse('$_apiBase?q=$query&spaces=drive&fields=files(id,name)'),
      headers: headers,
    );
    _checkOk(resp);
    final files =
        (jsonDecode(resp.body)['files'] as List).cast<Map<String, dynamic>>();
    return files.isEmpty ? null : files.first['id'] as String;
  }

  Future<String> _createFileMetadata(String folderId, String name) async {
    final headers = await _authHeaders();
    final resp = await http.post(
      Uri.parse(_apiBase),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'parents': [folderId],
      }),
    );
    _checkOk(resp);
    return jsonDecode(resp.body)['id'] as String;
  }

  Future<void> _uploadOrUpdate(
    String folderId,
    String name,
    List<int> bytes,
    String mimeType,
  ) async {
    final headers = await _authHeaders();
    final fileId =
        await _findFileId(folderId, name) ?? await _createFileMetadata(folderId, name);

    final uploadResp = await http.patch(
      Uri.parse('$_uploadBase/$fileId?uploadType=media'),
      headers: {...headers, 'Content-Type': mimeType},
      body: bytes,
    );
    _checkOk(uploadResp);
  }

  Future<List<int>?> _download(String folderId, String name) async {
    final fileId = await _findFileId(folderId, name);
    if (fileId == null) return null;
    final headers = await _authHeaders();
    final resp = await http.get(
      Uri.parse('$_apiBase/$fileId?alt=media'),
      headers: headers,
    );
    _checkOk(resp);
    return resp.bodyBytes;
  }

  /// Lädt Datenbank-Snapshot (als JSON) und alle Dokumenten-Fotos in den
  /// App-Ordner auf Google Drive hoch. Überschreibt vorhandene Dateien
  /// gleichen Namens vollständig.
  Future<void> uploadBackup() async {
    final folderId = await _getOrCreateFolderId();

    final raw = await DatabaseHelper.instance.exportAllRaw();
    final json = jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      ...raw,
    });
    await _uploadOrUpdate(
      folderId,
      _dataFileName,
      utf8.encode(json),
      'application/json',
    );

    for (final doc in raw['documents'] ?? const []) {
      final relativePath = doc['dateipfad'] as String?;
      if (relativePath == null) continue;
      final file = File(await DocumentStorage.absolutePath(relativePath));
      if (!await file.exists()) continue;
      await _uploadOrUpdate(
        folderId,
        _driveNameFor(relativePath),
        await file.readAsBytes(),
        'image/jpeg',
      );
    }
  }

  /// Ersetzt den kompletten lokalen Datenbestand (Datenbank + Fotos) durch
  /// den auf Google Drive gespeicherten Stand.
  Future<void> downloadBackup() async {
    final folderId = await _getOrCreateFolderId();
    final bytes = await _download(folderId, _dataFileName);
    if (bytes == null) {
      throw StateError('Kein Backup auf Google Drive gefunden.');
    }
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

    final raw = <String, List<Map<String, Object?>>>{};
    for (final table in DatabaseHelper.backupTables) {
      final list = decoded[table] as List? ?? const [];
      raw[table] = list.map((e) => Map<String, Object?>.from(e as Map)).toList();
    }

    for (final doc in raw['documents'] ?? const []) {
      final relativePath = doc['dateipfad'] as String?;
      if (relativePath == null) continue;
      final photoBytes = await _download(folderId, _driveNameFor(relativePath));
      if (photoBytes == null) continue;
      final file = File(await DocumentStorage.absolutePath(relativePath));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(photoBytes);
    }

    await DatabaseHelper.instance.replaceAllRaw(raw);
  }

  String _driveNameFor(String relativeDocumentPath) =>
      relativeDocumentPath.replaceAll('/', '__');
}
