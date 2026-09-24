enum DocumentCategory { zulassungsschein, polizze, rechnung, foto, sonstiges }

extension DocumentCategoryX on DocumentCategory {
  String get label {
    switch (this) {
      case DocumentCategory.zulassungsschein:
        return 'Zulassungsschein';
      case DocumentCategory.polizze:
        return 'Polizze';
      case DocumentCategory.rechnung:
        return 'Rechnung';
      case DocumentCategory.foto:
        return 'Foto';
      case DocumentCategory.sonstiges:
        return 'Sonstiges';
    }
  }
}

class VehicleDocument {
  final String id;
  final String vehicleId;
  DocumentCategory kategorie;
  String dateipfad;
  String titel;
  final DateTime erstelltAm;
  String? notizen;

  VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.kategorie,
    required this.dateipfad,
    required this.titel,
    required this.erstelltAm,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'kategorie': kategorie.name,
      'dateipfad': dateipfad,
      'titel': titel,
      'erstellt_am': erstelltAm.toIso8601String(),
      'notizen': notizen,
    };
  }

  factory VehicleDocument.fromMap(Map<String, Object?> map) {
    return VehicleDocument(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      kategorie: DocumentCategory.values.firstWhere(
        (c) => c.name == map['kategorie'],
        orElse: () => DocumentCategory.sonstiges,
      ),
      dateipfad: map['dateipfad'] as String,
      titel: map['titel'] as String? ?? '',
      erstelltAm: DateTime.parse(map['erstellt_am'] as String),
      notizen: map['notizen'] as String?,
    );
  }
}
