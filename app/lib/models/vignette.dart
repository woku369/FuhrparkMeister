class Vignette {
  final String id;
  final String vehicleId;
  int jahr;
  DateTime gueltigVon;
  DateTime gueltigBis;
  DateTime? kaufdatum;
  double? preisEuro;
  bool digital;
  String? notizen;

  Vignette({
    required this.id,
    required this.vehicleId,
    required this.jahr,
    required this.gueltigVon,
    required this.gueltigBis,
    this.kaufdatum,
    this.preisEuro,
    this.digital = true,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'jahr': jahr,
      'gueltig_von': gueltigVon.toIso8601String(),
      'gueltig_bis': gueltigBis.toIso8601String(),
      'kaufdatum': kaufdatum?.toIso8601String(),
      'preis_euro': preisEuro,
      'digital': digital ? 1 : 0,
      'notizen': notizen,
    };
  }

  factory Vignette.fromMap(Map<String, Object?> map) {
    return Vignette(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      jahr: map['jahr'] as int,
      gueltigVon: DateTime.parse(map['gueltig_von'] as String),
      gueltigBis: DateTime.parse(map['gueltig_bis'] as String),
      kaufdatum: map['kaufdatum'] != null
          ? DateTime.parse(map['kaufdatum'] as String)
          : null,
      preisEuro: (map['preis_euro'] as num?)?.toDouble(),
      digital: (map['digital'] as int? ?? 1) == 1,
      notizen: map['notizen'] as String?,
    );
  }
}
