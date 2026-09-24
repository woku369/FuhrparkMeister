import 'package:flutter/services.dart';

/// Nimmt eine per Android-Teilen-Dialog ("Teilen über..." / "Öffnen mit...")
/// empfangene Backup-ZIP entgegen. Die eigentliche Datei-Übernahme passiert
/// nativ in MainActivity.kt (siehe dort) - hier wird nur der resultierende,
/// lokale Cache-Dateipfad abgeholt bzw. entgegengenommen.
class ShareImportService {
  static const _channel = MethodChannel('at.kraeutermeister.fuhrparkmeister/import');

  /// Prüft, ob die App gerade über einen Teilen-/Öffnen-mit-Intent
  /// gestartet wurde (App war noch nicht offen). Liefert den lokalen
  /// Dateipfad oder null.
  static Future<String?> consumeInitialSharedZip() async {
    try {
      return await _channel.invokeMethod<String>('consumeSharedZip');
    } catch (_) {
      return null;
    }
  }

  /// Registriert einen Listener für den Fall, dass die App bereits offen
  /// ist und währenddessen eine Datei per Teilen-Dialog hereinkommt.
  static void listenForSharedZip(void Function(String path) onReceived) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedZipReceived' && call.arguments is String) {
        onReceived(call.arguments as String);
      }
    });
  }
}
