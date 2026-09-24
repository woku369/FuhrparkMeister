import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/inspection.dart';
import '../models/insurance.dart';
import '../models/maintenance_task.dart';
import '../models/reminder.dart';
import '../models/tire_set.dart';
import '../models/vehicle.dart';
import '../models/vehicle_document.dart';
import '../models/vignette.dart';
import '../services/notification_service.dart';

const _uuid = Uuid();
const _vignetteInsuranceReminderTage = 14;

/// Zentraler App-State: hält die Fahrzeugliste und kapselt alle
/// Datenbank-Zugriffe samt Planung der lokalen Erinnerungen.
class FuhrparkProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  List<Vehicle> _vehicles = [];
  bool _loading = true;

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  bool get loading => _loading;

  Future<void> loadVehicles() async {
    _loading = true;
    notifyListeners();
    _vehicles = await _db.getAllVehicles();
    _loading = false;
    notifyListeners();
  }

  // ---------------- Vehicles ----------------

  Future<Vehicle> addVehicle({
    required VehicleType type,
    required String name,
    String? marke,
    String? modell,
    String? kennzeichen,
    String? fahrgestellnummer,
    int? baujahr,
    String? farbe,
    DateTime? kaufdatum,
    int? kilometerstandBeiAnkauf,
    int? anzahlVorbesitzer,
    String? sollReifendimension,
    String? notizen,
    String? fotoPfad,
    int? leistungKw,
    int? erstzulassungMonat,
    int? erstzulassungJahr,
  }) async {
    final now = DateTime.now();
    final vehicle = Vehicle(
      id: _uuid.v4(),
      type: type,
      name: name,
      marke: marke,
      modell: modell,
      kennzeichen: kennzeichen,
      fahrgestellnummer: fahrgestellnummer,
      baujahr: baujahr,
      farbe: farbe,
      kaufdatum: kaufdatum,
      kilometerstandBeiAnkauf: kilometerstandBeiAnkauf,
      anzahlVorbesitzer: anzahlVorbesitzer,
      sollReifendimension: sollReifendimension,
      notizen: notizen,
      fotoPfad: fotoPfad,
      leistungKw: leistungKw,
      erstzulassungMonat: erstzulassungMonat,
      erstzulassungJahr: erstzulassungJahr,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertVehicle(vehicle);
    await loadVehicles();
    return vehicle;
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    vehicle.updatedAt = DateTime.now();
    await _db.updateVehicle(vehicle);
    await loadVehicles();
  }

  Future<void> deleteVehicle(String id) async {
    final inspections = await _db.getInspectionsForVehicle(id);
    final vignettes = await _db.getVignettesForVehicle(id);
    final insurances = await _db.getInsurancesForVehicle(id);
    try {
      for (final i in inspections) {
        await NotificationService.instance.cancelReminder(i.id);
      }
      for (final v in vignettes) {
        await NotificationService.instance.cancelReminder(v.id);
      }
      for (final i in insurances) {
        await NotificationService.instance.cancelReminder(i.id);
      }
    } catch (_) {
      // Erinnerungen sind nur eine Zusatzfunktion - ein Fehler hier darf
      // das Löschen des Fahrzeugs nicht verhindern.
    }
    await _db.deleteVehicle(id);
    await loadVehicles();
  }

  // ---------------- Tire sets ----------------

  Future<List<TireSet>> tireSetsFor(String vehicleId) =>
      _db.getTireSetsForVehicle(vehicleId);

  Future<void> saveTireSet(TireSet tireSet, {required bool isNew}) async {
    if (isNew) {
      await _db.insertTireSet(tireSet);
    } else {
      await _db.updateTireSet(tireSet);
    }
    notifyListeners();
  }

  Future<void> deleteTireSet(String id) async {
    await _db.deleteTireSet(id);
    notifyListeners();
  }

  // ---------------- Inspections ----------------

  Future<List<Inspection>> inspectionsFor(String vehicleId) =>
      _db.getInspectionsForVehicle(vehicleId);

  Future<void> saveInspection(
    Inspection inspection,
    String vehicleName, {
    required bool isNew,
  }) async {
    if (isNew) {
      await _db.insertInspection(inspection);
    } else {
      await _db.updateInspection(inspection);
    }
    await _rescheduleInspection(inspection, vehicleName);
    notifyListeners();
  }

  Future<void> deleteInspection(String id) async {
    await _db.deleteInspection(id);
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {
      // Erinnerung ist nur eine Zusatzfunktion - darf das Löschen nicht blockieren.
    }
    notifyListeners();
  }

  /// Erinnerung neu planen. Bewusst mit try-catch abgesichert: ein Fehler
  /// im Benachrichtigungs-Plugin (z. B. fehlende Berechtigung) darf den
  /// eigentlichen Speichervorgang und damit den Rücksprung im UI (Navigator.pop)
  /// niemals verhindern.
  Future<void> _rescheduleInspection(
    Inspection inspection,
    String vehicleName,
  ) async {
    try {
      await NotificationService.instance.cancelReminder(inspection.id);
      if (inspection.erledigt) return;
      final erinnerungAm = inspection.faelligAm.subtract(
        Duration(days: inspection.erinnerungTageVorher),
      );
      await NotificationService.instance.scheduleReminder(
        sourceId: inspection.id,
        title: '${inspection.type.label} fällig',
        body: '$vehicleName · fällig am ${_formatDate(inspection.faelligAm)}',
        scheduledDate: erinnerungAm,
      );
    } catch (_) {
      // siehe Kommentar oben
    }
  }

  // ---------------- Vignettes ----------------

  Future<List<Vignette>> vignettesFor(String vehicleId) =>
      _db.getVignettesForVehicle(vehicleId);

  Future<void> saveVignette(
    Vignette vignette,
    String vehicleName, {
    required bool isNew,
  }) async {
    if (isNew) {
      await _db.insertVignette(vignette);
    } else {
      await _db.updateVignette(vignette);
    }
    try {
      await NotificationService.instance.cancelReminder(vignette.id);
      final erinnerungAm = vignette.gueltigBis.subtract(
        const Duration(days: _vignetteInsuranceReminderTage),
      );
      await NotificationService.instance.scheduleReminder(
        sourceId: vignette.id,
        title: 'Vignette läuft ab',
        body:
            '$vehicleName · gültig bis ${_formatDate(vignette.gueltigBis)}',
        scheduledDate: erinnerungAm,
      );
    } catch (_) {
      // Erinnerung ist nur eine Zusatzfunktion - darf den Speichervorgang
      // (und damit den Rücksprung im UI) nicht blockieren.
    }
    notifyListeners();
  }

  Future<void> deleteVignette(String id) async {
    await _db.deleteVignette(id);
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {
      // siehe Kommentar in saveVignette
    }
    notifyListeners();
  }

  // ---------------- Insurances ----------------

  Future<List<Insurance>> insurancesFor(String vehicleId) =>
      _db.getInsurancesForVehicle(vehicleId);

  Future<void> saveInsurance(
    Insurance insurance,
    String vehicleName, {
    required bool isNew,
  }) async {
    if (isNew) {
      await _db.insertInsurance(insurance);
    } else {
      await _db.updateInsurance(insurance);
    }
    try {
      await NotificationService.instance.cancelReminder(insurance.id);
      // Erinnerung am nächsten TATSÄCHLICHEN Zahlungstermin planen, nicht an
      // der (oft in der Vergangenheit liegenden) Hauptfälligkeit selbst.
      final naechsteFaelligkeit = insurance.naechsteFaelligkeit;
      if (naechsteFaelligkeit != null) {
        final erinnerungAm = naechsteFaelligkeit.subtract(
          const Duration(days: _vignetteInsuranceReminderTage),
        );
        await NotificationService.instance.scheduleReminder(
          sourceId: insurance.id,
          title: 'Versicherung fällig',
          body:
              '$vehicleName · ${insurance.gesellschaft} · fällig am '
              '${_formatDate(naechsteFaelligkeit)}',
          scheduledDate: erinnerungAm,
        );
      }
    } catch (_) {
      // Erinnerung ist nur eine Zusatzfunktion - darf den Speichervorgang
      // (und damit den Rücksprung im UI) nicht blockieren.
    }
    notifyListeners();
  }

  Future<void> deleteInsurance(String id) async {
    await _db.deleteInsurance(id);
    try {
      await NotificationService.instance.cancelReminder(id);
    } catch (_) {
      // siehe Kommentar in saveInsurance
    }
    notifyListeners();
  }

  // ---------------- Documents ----------------

  Future<List<VehicleDocument>> documentsFor(String vehicleId) =>
      _db.getDocumentsForVehicle(vehicleId);

  Future<void> addDocument(VehicleDocument document) async {
    await _db.insertDocument(document);
    notifyListeners();
  }

  Future<void> deleteDocument(String id) async {
    await _db.deleteDocument(id);
    notifyListeners();
  }

  // ---------------- Wartungs-To-Dos ----------------

  Future<List<MaintenanceTask>> maintenanceTasksFor(String vehicleId) =>
      _db.getMaintenanceTasksForVehicle(vehicleId);

  Future<void> saveMaintenanceTask(
    MaintenanceTask task, {
    required bool isNew,
  }) async {
    if (isNew) {
      await _db.insertMaintenanceTask(task);
    } else {
      await _db.updateMaintenanceTask(task);
    }
    notifyListeners();
  }

  Future<void> deleteMaintenanceTask(String id) async {
    await _db.deleteMaintenanceTask(id);
    notifyListeners();
  }

  // ---------------- Übersicht: anstehende Termine ----------------

  Future<List<Reminder>> getUpcomingReminders() async {
    final vehiclesById = {for (final v in _vehicles) v.id: v};
    final reminders = <Reminder>[];

    final inspections = await _db.getAllOpenInspections();
    for (final i in inspections) {
      final vehicle = vehiclesById[i.vehicleId];
      if (vehicle == null) continue;
      reminders.add(
        Reminder(
          source: ReminderSource.inspection,
          sourceId: i.id,
          vehicleId: vehicle.id,
          vehicleName: vehicle.anzeigename,
          titel: i.type.label,
          faelligAm: i.faelligAm,
        ),
      );
    }

    final vignettes = await _db.getAllVignettes();
    for (final v in vignettes) {
      final vehicle = vehiclesById[v.vehicleId];
      if (vehicle == null) continue;
      reminders.add(
        Reminder(
          source: ReminderSource.vignette,
          sourceId: v.id,
          vehicleId: vehicle.id,
          vehicleName: vehicle.anzeigename,
          titel: 'Vignette ${v.jahr}',
          faelligAm: v.gueltigBis,
        ),
      );
    }

    final insurances = await _db.getAllInsurances();
    for (final i in insurances) {
      final naechsteFaelligkeit = i.naechsteFaelligkeit;
      if (naechsteFaelligkeit == null) continue;
      final vehicle = vehiclesById[i.vehicleId];
      if (vehicle == null) continue;
      reminders.add(
        Reminder(
          source: ReminderSource.insurance,
          sourceId: i.id,
          vehicleId: vehicle.id,
          vehicleName: vehicle.anzeigename,
          titel: 'Versicherung ${i.gesellschaft}',
          faelligAm: naechsteFaelligkeit,
        ),
      );
    }

    reminders.sort((a, b) => a.faelligAm.compareTo(b.faelligAm));
    return reminders;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
