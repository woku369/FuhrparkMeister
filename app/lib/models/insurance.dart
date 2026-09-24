enum InsuranceType { haftpflicht, teilkasko, vollkasko, sonstiges }

extension InsuranceTypeX on InsuranceType {
  String get label {
    switch (this) {
      case InsuranceType.haftpflicht:
        return 'Haftpflicht';
      case InsuranceType.teilkasko:
        return 'Teilkasko';
      case InsuranceType.vollkasko:
        return 'Vollkasko';
      case InsuranceType.sonstiges:
        return 'Sonstige';
    }
  }
}

class Insurance {
  final String id;
  final String vehicleId;
  String gesellschaft;
  String polizzennummer;
  InsuranceType type;
  DateTime? gueltigAb;
  DateTime? faelligkeitJaehrlichAm;
  double? praemieEuro;
  String? notizen;

  Insurance({
    required this.id,
    required this.vehicleId,
    required this.gesellschaft,
    required this.polizzennummer,
    required this.type,
    this.gueltigAb,
    this.faelligkeitJaehrlichAm,
    this.praemieEuro,
    this.notizen,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'gesellschaft': gesellschaft,
      'polizzennummer': polizzennummer,
      'type': type.name,
      'gueltig_ab': gueltigAb?.toIso8601String(),
      'faelligkeit_jaehrlich_am': faelligkeitJaehrlichAm?.toIso8601String(),
      'praemie_euro': praemieEuro,
      'notizen': notizen,
    };
  }

  factory Insurance.fromMap(Map<String, Object?> map) {
    return Insurance(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      gesellschaft: map['gesellschaft'] as String? ?? '',
      polizzennummer: map['polizzennummer'] as String? ?? '',
      type: InsuranceType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => InsuranceType.sonstiges,
      ),
      gueltigAb: map['gueltig_ab'] != null
          ? DateTime.parse(map['gueltig_ab'] as String)
          : null,
      faelligkeitJaehrlichAm: map['faelligkeit_jaehrlich_am'] != null
          ? DateTime.parse(map['faelligkeit_jaehrlich_am'] as String)
          : null,
      praemieEuro: (map['praemie_euro'] as num?)?.toDouble(),
      notizen: map['notizen'] as String?,
    );
  }
}
