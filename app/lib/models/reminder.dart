/// Ein berechneter Termin für die Übersicht - fasst Prüftermine, Vignetten-
/// Ablauf, Versicherungsfälligkeiten, Reifenwechsel und terminierte
/// Wartungs-To-Dos in einer gemeinsamen Liste zusammen.
enum ReminderSource { inspection, vignette, insurance, tire, maintenance }

class Reminder {
  final ReminderSource source;
  final String sourceId;
  final String vehicleId;
  final String vehicleName;
  final String titel;
  final DateTime faelligAm;

  Reminder({
    required this.source,
    required this.sourceId,
    required this.vehicleId,
    required this.vehicleName,
    required this.titel,
    required this.faelligAm,
  });

  int get tageBisFaellig => faelligAm.difference(DateTime.now()).inDays;

  bool get istUeberfaellig => tageBisFaellig < 0;
}
