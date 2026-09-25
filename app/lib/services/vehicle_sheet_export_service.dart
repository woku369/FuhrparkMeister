import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../database/database_helper.dart';
import '../models/inspection.dart';
import '../models/insurance.dart';
import '../models/tire_set.dart';
import '../models/vehicle.dart';
import '../models/vignette.dart';
import '../widgets/date_format_x.dart';
import 'document_storage.dart';

/// Baut ein einseitiges DIN-A4-Datenblatt (PDF) mit allen erfassten Daten
/// eines Fahrzeugs - gedacht zum Ausdrucken und Ablegen im physischen
/// KFZ-Ordner. Bewusst ohne Dokumente/Fotos aus der Dokumenten-Galerie
/// (die liegen ja bereits im Papierordner) - nur das Fahrzeugfoto selbst
/// wird zur Wiedererkennung mit abgedruckt.
class VehicleSheetExportService {
  static Future<File> exportPdfFor(Vehicle vehicle) async {
    final db = DatabaseHelper.instance;
    final inspections = await db.getInspectionsForVehicle(vehicle.id);
    inspections.sort((a, b) => a.faelligAm.compareTo(b.faelligAm));
    final tireSets = await db.getTireSetsForVehicle(vehicle.id);
    final vignettes = await db.getVignettesForVehicle(vehicle.id);
    final insurances = await db.getInsurancesForVehicle(vehicle.id);

    Uint8List? photoBytes;
    final fotoPfad = vehicle.fotoPfad;
    if (fotoPfad != null) {
      final file = File(await DocumentStorage.absolutePath(fotoPfad));
      if (await file.exists()) photoBytes = await file.readAsBytes();
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'FuhrparkMeister · erstellt am ${DateTime.now().deDate} · '
            'Seite ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          _buildHeader(vehicle, photoBytes),
          pw.SizedBox(height: 16),
          _buildSectionTitle('Stammdaten'),
          _buildStammdaten(vehicle),
          if (inspections.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _buildSectionTitle('Prüftermine'),
            _buildInspectionsTable(inspections),
          ],
          if (tireSets.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _buildSectionTitle('Reifen'),
            _buildTiresTable(tireSets),
          ],
          if (vignettes.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _buildSectionTitle('Vignetten'),
            _buildVignettesTable(vignettes),
          ],
          if (insurances.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _buildSectionTitle('Versicherungen'),
            _buildInsurancesTable(insurances),
          ],
          if (vehicle.notizen != null && vehicle.notizen!.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _buildSectionTitle('Notizen'),
            pw.Text(vehicle.notizen!, style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );

    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw StateError('Kein externer Speicher verfügbar.');
    }
    final timestamp = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final safeName =
        vehicle.anzeigename.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File(
      p.join(dir.path, 'Datenblatt_${safeName}_$timestamp.pdf'),
    );
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static pw.Widget _buildHeader(Vehicle v, Uint8List? photoBytes) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                v.anzeigename,
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                [
                  v.type.label,
                  if (v.marke != null || v.modell != null)
                    [v.marke, v.modell].whereType<String>().join(' '),
                ].join(' · '),
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        if (photoBytes != null)
          pw.Image(
            pw.MemoryImage(photoBytes),
            width: 100,
            height: 72,
            fit: pw.BoxFit.cover,
          ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 3),
      margin: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildStammdaten(Vehicle v) {
    final erstzulassung =
        v.erstzulassungMonat != null && v.erstzulassungJahr != null
            ? '${v.erstzulassungMonat!.toString().padLeft(2, '0')}/${v.erstzulassungJahr}'
            : v.erstzulassungJahr?.toString();
    final rows = <(String, String?)>[
      ('Kennzeichen', v.kennzeichen),
      ('Halter', v.halter),
      ('Fahrgestellnummer', v.fahrgestellnummer),
      ('Baujahr', v.baujahr?.toString()),
      ('Erstzulassung', erstzulassung),
      ('Leistung', v.leistungKw != null ? '${v.leistungKw} kW' : null),
      ('Farbe', v.farbe),
      ('Kaufdatum', v.kaufdatum?.deDate),
      ('km bei Ankauf', v.kilometerstandBeiAnkauf?.toString()),
      ('Vorbesitzer', v.anzahlVorbesitzer?.toString()),
      ('Reifendimension (Soll)', v.sollReifendimension),
    ].where((r) => r.$2 != null && r.$2!.isNotEmpty).toList();

    return pw.Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        for (final (label, value) in rows)
          pw.SizedBox(width: 220, child: _buildKv(label, value!)),
      ],
    );
  }

  static pw.Widget _buildKv(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  static pw.Widget _buildInspectionsTable(List<Inspection> inspections) {
    return _buildTable(
      ['Art', 'Fällig am', 'Letzte Prüfung', 'Status'],
      [
        for (final i in inspections)
          [
            i.type.label,
            i.faelligAm.deDate,
            i.letztePruefungAm?.deDate ?? '–',
            i.erledigt ? 'Erledigt' : 'Offen',
          ],
      ],
    );
  }

  static pw.Widget _buildTiresTable(List<TireSet> tireSets) {
    return _buildTable(
      ['Saison', 'Dimension', 'Hersteller', 'Status', 'Profiltiefe', 'Wechsel fällig'],
      [
        for (final t in tireSets)
          [
            t.season.label,
            t.dimension,
            t.hersteller ?? '–',
            t.montiert ? 'Montiert' : 'Im Lager',
            t.profiltiefeMm != null ? '${t.profiltiefeMm} mm' : '–',
            t.wechselFaelligAm?.deDate ?? '–',
          ],
      ],
    );
  }

  static pw.Widget _buildVignettesTable(List<Vignette> vignettes) {
    return _buildTable(
      ['Jahr', 'Gültig von', 'Gültig bis', 'Digital', 'Preis'],
      [
        for (final v in vignettes)
          [
            v.jahr.toString(),
            v.gueltigVon.deDate,
            v.gueltigBis.deDate,
            v.digital ? 'Ja' : 'Nein',
            v.preisEuro != null ? '€${v.preisEuro!.toStringAsFixed(2)}' : '–',
          ],
      ],
    );
  }

  static pw.Widget _buildInsurancesTable(List<Insurance> insurances) {
    return _buildTable(
      ['Gesellschaft', 'Art', 'Polizze', 'Hauptfälligkeit', 'Intervall', 'Nächste Zahlung'],
      [
        for (final i in insurances)
          [
            i.gesellschaft,
            i.type.label,
            i.polizzennummer.isEmpty ? '–' : i.polizzennummer,
            i.faelligkeitJaehrlichAm?.deDate ?? '–',
            (i.zahlungsintervall ?? PaymentInterval.jaehrlich).label,
            i.naechsteFaelligkeit?.deDate ?? '–',
          ],
      ],
    );
  }

  static pw.Widget _buildTable(List<String> headers, List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [for (final h in headers) _cell(h, bold: true)],
        ),
        for (final row in rows)
          pw.TableRow(children: [for (final c in row) _cell(c)]),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
}
