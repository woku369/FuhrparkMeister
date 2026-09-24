import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/inspection.dart';
import '../models/vehicle.dart';

/// Baut eine lesbare Wartungshistorie aus erledigten Prüfterminen und
/// To-Dos - gedacht als Merkliste/Nachweis, z. B. beim Fahrzeugverkauf.
/// Kein PDF (spart eine weitere native Abhängigkeit), reiner Text -
/// lässt sich trotzdem problemlos teilen, ausdrucken oder in eine
/// E-Mail einfügen.
class HistoryExportService {
  static Future<File> exportTextFor(Vehicle vehicle) async {
    final db = DatabaseHelper.instance;
    final inspections = await db.getInspectionsForVehicle(vehicle.id);
    final tasks = await db.getMaintenanceTasksForVehicle(vehicle.id);

    final pruefungen = inspections.where((i) => i.letztePruefungAm != null).toList()
      ..sort((a, b) => a.letztePruefungAm!.compareTo(b.letztePruefungAm!));
    final wartungen = tasks.where((t) => t.erledigt && t.erledigtAm != null).toList()
      ..sort((a, b) => a.erledigtAm!.compareTo(b.erledigtAm!));

    final buffer = StringBuffer();
    buffer.writeln('Wartungshistorie – ${vehicle.anzeigename}');
    final stammdaten = [
      if (vehicle.marke != null || vehicle.modell != null)
        [vehicle.marke, vehicle.modell].whereType<String>().join(' '),
      if (vehicle.kennzeichen != null && vehicle.kennzeichen!.isNotEmpty)
        'Kennzeichen: ${vehicle.kennzeichen}',
      if (vehicle.baujahr != null) 'Baujahr: ${vehicle.baujahr}',
      if (vehicle.fahrgestellnummer != null && vehicle.fahrgestellnummer!.isNotEmpty)
        'Fahrgestellnummer: ${vehicle.fahrgestellnummer}',
      if (vehicle.kilometerstandBeiAnkauf != null)
        'Kilometerstand bei Ankauf: ${vehicle.kilometerstandBeiAnkauf} km',
      if (vehicle.anzahlVorbesitzer != null)
        'Vorbesitzer: ${vehicle.anzahlVorbesitzer}',
    ];
    if (stammdaten.isNotEmpty) buffer.writeln(stammdaten.join(' · '));
    buffer.writeln('Erstellt am ${_deDate(DateTime.now())} mit FuhrparkMeister');
    buffer.writeln();

    buffer.writeln('=== Prüfungen ===');
    if (pruefungen.isEmpty) {
      buffer.writeln('Keine abgeschlossenen Prüfungen erfasst.');
    } else {
      for (final i in pruefungen) {
        buffer.writeln('${_deDate(i.letztePruefungAm!)}  ${i.type.label}');
        if (i.notizen != null && i.notizen!.isNotEmpty) {
          buffer.writeln('  Notiz: ${i.notizen}');
        }
      }
    }
    buffer.writeln();

    buffer.writeln('=== Wartungsarbeiten ===');
    if (wartungen.isEmpty) {
      buffer.writeln('Keine abgeschlossenen Wartungsarbeiten erfasst.');
    } else {
      for (final t in wartungen) {
        buffer.writeln('${_deDate(t.erledigtAm!)}  ${t.titel}');
        if (t.notizen != null && t.notizen!.isNotEmpty) {
          buffer.writeln('  Notiz: ${t.notizen}');
        }
      }
    }

    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw StateError('Kein externer Speicher verfügbar.');
    }
    final timestamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final safeName = vehicle.anzeigename.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File(
      p.join(dir.path, 'Wartungshistorie_${safeName}_$timestamp.txt'),
    );
    await file.writeAsString(buffer.toString());
    return file;
  }

  static String _deDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
