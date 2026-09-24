enum InspectionType {
  pickerl57a,
  anhaengerpruefung,
  service,
  fahrradcheck,
  sonstiges,
}

extension InspectionTypeX on InspectionType {
  String get label {
    switch (this) {
      case InspectionType.pickerl57a:
        return '§57a-Begutachtung (Pickerl)';
      case InspectionType.anhaengerpruefung:
        return 'Anhängerprüfung';
      case InspectionType.service:
        return 'Service';
      case InspectionType.fahrradcheck:
        return 'Fahrrad-Check';
      case InspectionType.sonstiges:
        return 'Sonstiger Termin';
    }
  }
}

class Inspection {
  final String id;
  final String vehicleId;
  InspectionType type;
  DateTime faelligAm;
  DateTime? letztePruefungAm;
  int erinnerungTageVorher;
  bool erledigt;
  String? notizen;

  Inspection({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.faelligAm,
    this.letztePruefungAm,
    this.erinnerungTageVorher = 30,
    this.erledigt = false,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'type': type.name,
      'faellig_am': faelligAm.toIso8601String(),
      'letzte_pruefung_am': letztePruefungAm?.toIso8601String(),
      'erinnerung_tage_vorher': erinnerungTageVorher,
      'erledigt': erledigt ? 1 : 0,
      'notizen': notizen,
    };
  }

  factory Inspection.fromMap(Map<String, Object?> map) {
    return Inspection(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      type: InspectionType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => InspectionType.sonstiges,
      ),
      faelligAm: DateTime.parse(map['faellig_am'] as String),
      letztePruefungAm: map['letzte_pruefung_am'] != null
          ? DateTime.parse(map['letzte_pruefung_am'] as String)
          : null,
      erinnerungTageVorher: map['erinnerung_tage_vorher'] as int? ?? 30,
      erledigt: (map['erledigt'] as int? ?? 0) == 1,
      notizen: map['notizen'] as String?,
    );
  }
}
