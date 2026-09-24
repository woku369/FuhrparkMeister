/// Laufende Wartungs-To-Do: Dinge, die auffallen oder geplant sind, aber
/// nicht an eine gesetzliche Prüffrist (§57a etc.) gebunden sind - z. B.
/// "Bremsbeläge Anhänger prüfen" oder "Anhängerkupplung fettet nicht mehr".
/// Bewusst ohne Fälligkeitsdatum/Erinnerung, dafür siehe Inspection.
class MaintenanceTask {
  final String id;
  final String vehicleId;
  String titel;
  String? notizen;
  bool erledigt;
  final DateTime erstelltAm;
  DateTime? erledigtAm;

  MaintenanceTask({
    required this.id,
    required this.vehicleId,
    required this.titel,
    this.notizen,
    this.erledigt = false,
    required this.erstelltAm,
    this.erledigtAm,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'titel': titel,
      'notizen': notizen,
      'erledigt': erledigt ? 1 : 0,
      'erstellt_am': erstelltAm.toIso8601String(),
      'erledigt_am': erledigtAm?.toIso8601String(),
    };
  }

  factory MaintenanceTask.fromMap(Map<String, Object?> map) {
    return MaintenanceTask(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      titel: map['titel'] as String? ?? '',
      notizen: map['notizen'] as String?,
      erledigt: (map['erledigt'] as int? ?? 0) == 1,
      erstelltAm: DateTime.parse(map['erstellt_am'] as String),
      erledigtAm: map['erledigt_am'] != null
          ? DateTime.parse(map['erledigt_am'] as String)
          : null,
    );
  }
}
