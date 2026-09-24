import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/fuhrpark_provider.dart';
import '../services/drive_sync_service.dart';
import '../services/local_backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _service = DriveSyncService.instance;
  GoogleSignInAccount? _account;
  bool _busy = false;
  String? _lastAction;
  String? _backupDirPath;

  @override
  void initState() {
    super.initState();
    _service.signInSilently().then((account) {
      if (mounted) setState(() => _account = account);
    });
    LocalBackupService.backupDirPath().then((path) {
      if (mounted) setState(() => _backupDirPath = path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Cloud-Sync')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lokales Backup (ZIP-Datei)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Funktioniert sofort, ohne Google-Konto-Einrichtung. '
                    'Export erzeugt eine ZIP-Datei mit allen Daten und Fotos '
                    'im App-eigenen Ordner und öffnet zusätzlich die '
                    'Android-Systemfreigabe (Downloads, E-Mail, eine '
                    'Cloud-App, ...). Import liest die neueste ZIP-Datei aus '
                    'genau diesem Ordner und ersetzt den kompletten lokalen '
                    'Stand – eine von einem anderen Gerät empfangene Datei '
                    'also vorher per Datei-Manager dorthin kopieren.',
                  ),
                  if (_backupDirPath != null) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      _backupDirPath!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _exportLocal,
                          icon: const Icon(Icons.ios_share_outlined),
                          label: const Text('Exportieren'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _confirmImportLocal,
                          icon: const Icon(Icons.file_open_outlined),
                          label: const Text('Neuestes importieren'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manuelles Backup über Google Drive',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sichert Fahrzeuge, Termine, Reifen, Vignetten, '
                    'Versicherungen und Dokumente in einen eigenen '
                    '"FuhrparkMeister"-Ordner in deinem Google Drive. '
                    'Es handelt sich um einen vollständigen Schnappschuss: '
                    'Hochladen überschreibt den Cloud-Stand, Wiederherstellen '
                    'überschreibt den lokalen Stand auf diesem Gerät '
                    'vollständig ("letzter Stand gewinnt", kein automatischer '
                    'Merge). Vor dem Gerätewechsel also erst hochladen, auf '
                    'dem Zielgerät dann wiederherstellen.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                _account == null ? Icons.account_circle_outlined : Icons.check_circle,
                color: _account == null ? null : Colors.green,
              ),
              title: Text(
                _account == null ? 'Nicht bei Google angemeldet' : _account!.email,
              ),
              trailing: TextButton(
                onPressed: _busy ? null : _toggleSignIn,
                child: Text(_account == null ? 'Anmelden' : 'Abmelden'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (_busy || _account == null) ? null : _upload,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Backup jetzt hochladen'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: (_busy || _account == null) ? null : _confirmDownload,
            icon: const Icon(Icons.cloud_download_outlined),
            label: const Text('Backup wiederherstellen'),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_lastAction != null) ...[
            const SizedBox(height: 16),
            Text(_lastAction!, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Future<void> _exportLocal() async {
    setState(() {
      _busy = true;
      _lastAction = null;
    });
    try {
      final zipFile = await LocalBackupService.exportToZip();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(zipFile.path)],
          text: 'FuhrparkMeister Backup',
        ),
      );
      setState(
        () => _lastAction = 'Backup exportiert: ${TimeOfDay.now().format(context)}',
      );
    } catch (e) {
      _showError('Export fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmImportLocal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neuestes Backup importieren?'),
        content: Text(
          'Alle lokalen Daten auf diesem Gerät werden durch den Inhalt der '
          'neuesten .zip-Datei in ${_backupDirPath ?? "dem Backup-Ordner"} '
          'ersetzt. Nicht gesicherte lokale Änderungen gehen dabei verloren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Importieren'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _lastAction = null;
    });
    try {
      await LocalBackupService.importLatestFromBackupDir();
      if (mounted) {
        await context.read<FuhrparkProvider>().loadVehicles();
      }
      setState(
        () => _lastAction = 'Backup importiert: ${TimeOfDay.now().format(context)}',
      );
    } catch (e) {
      _showError('Import fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleSignIn() async {
    setState(() => _busy = true);
    try {
      if (_account == null) {
        final account = await _service.signIn();
        setState(() => _account = account);
      } else {
        await _service.signOut();
        setState(() => _account = null);
      }
    } catch (e) {
      _showError('Anmeldung fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    setState(() {
      _busy = true;
      _lastAction = null;
    });
    try {
      await _service.uploadBackup();
      setState(() => _lastAction = 'Backup hochgeladen: ${TimeOfDay.now().format(context)}');
    } catch (e) {
      _showError('Upload fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDownload() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup wiederherstellen?'),
        content: const Text(
          'Alle lokalen Daten auf diesem Gerät werden durch den Stand aus '
          'Google Drive ersetzt. Nicht hochgeladene lokale Änderungen gehen '
          'dabei verloren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Wiederherstellen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _download();
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _lastAction = null;
    });
    try {
      await _service.downloadBackup();
      if (mounted) {
        await context.read<FuhrparkProvider>().loadVehicles();
      }
      setState(() => _lastAction = 'Backup wiederhergestellt: ${TimeOfDay.now().format(context)}');
    } catch (e) {
      _showError('Wiederherstellen fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
