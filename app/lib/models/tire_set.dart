enum TireSeason { sommer, winter, ganzjahr }

extension TireSeasonX on TireSeason {
  String get label {
    switch (this) {
      case TireSeason.sommer:
        return 'Sommer';
      case TireSeason.winter:
        return 'Winter';
      case TireSeason.ganzjahr:
        return 'Ganzjahr';
    }
  }
}

class TireSet {
  final String id;
  final String vehicleId;
  TireSeason season;
  String dimension;
  String? hersteller;
  double? profiltiefeMm;
  bool montiert;
  DateTime? kaufdatum;
  DateTime? wechselFaelligAm;
  String? notizen;

  TireSet({
    required this.id,
    required this.vehicleId,
    required this.season,
    required this.dimension,
    this.hersteller,
    this.profiltiefeMm,
    this.montiert = false,
    this.kaufdatum,
    this.wechselFaelligAm,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'season': season.name,
      'dimension': dimension,
      'hersteller': hersteller,
      'profiltiefe_mm': profiltiefeMm,
      'montiert': montiert ? 1 : 0,
      'kaufdatum': kaufdatum?.toIso8601String(),
      'wechsel_faellig_am': wechselFaelligAm?.toIso8601String(),
      'notizen': notizen,
    };
  }

  factory TireSet.fromMap(Map<String, Object?> map) {
    return TireSet(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      season: TireSeason.values.firstWhere(
        (s) => s.name == map['season'],
        orElse: () => TireSeason.ganzjahr,
      ),
      dimension: map['dimension'] as String? ?? '',
      hersteller: map['hersteller'] as String?,
      profiltiefeMm: (map['profiltiefe_mm'] as num?)?.toDouble(),
      montiert: (map['montiert'] as int? ?? 0) == 1,
      kaufdatum: map['kaufdatum'] != null
          ? DateTime.parse(map['kaufdatum'] as String)
          : null,
      wechselFaelligAm: map['wechsel_faellig_am'] != null
          ? DateTime.parse(map['wechsel_faellig_am'] as String)
          : null,
      notizen: map['notizen'] as String?,
    );
  }
}
