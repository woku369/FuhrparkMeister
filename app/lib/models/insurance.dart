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

enum PaymentInterval { monatlich, vierteljaehrlich, halbjaehrlich, jaehrlich }

extension PaymentIntervalX on PaymentInterval {
  String get label {
    switch (this) {
      case PaymentInterval.monatlich:
        return 'Monatlich';
      case PaymentInterval.vierteljaehrlich:
        return 'Vierteljährlich';
      case PaymentInterval.halbjaehrlich:
        return 'Halbjährlich';
      case PaymentInterval.jaehrlich:
        return 'Jährlich';
    }
  }

  int get monate {
    switch (this) {
      case PaymentInterval.monatlich:
        return 1;
      case PaymentInterval.vierteljaehrlich:
        return 3;
      case PaymentInterval.halbjaehrlich:
        return 6;
      case PaymentInterval.jaehrlich:
        return 12;
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
  PaymentInterval? zahlungsintervall;
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
    this.zahlungsintervall,
    this.praemieEuro,
    this.notizen,
  });

  /// Nächster tatsächlicher Zahlungstermin. [faelligkeitJaehrlichAm] ist nur
  /// die Hauptfälligkeit (z. B. Abschluss-/Erneuerungsdatum des Vertrags) -
  /// die liegt oft schon in der Vergangenheit und ist für sich genommen kein
  /// überfälliger Termin. Von dort aus wird anhand des Zahlungsintervalls
  /// (Standard: jährlich, falls nicht gesetzt) auf den nächsten Termin ab
  /// heute vorgerückt.
  DateTime? get naechsteFaelligkeit {
    final anchor = faelligkeitJaehrlichAm;
    if (anchor == null) return null;
    final monate = (zahlungsintervall ?? PaymentInterval.jaehrlich).monate;
    var next = anchor;
    final now = DateTime.now();
    while (next.isBefore(now)) {
      next = DateTime(next.year, next.month + monate, next.day);
    }
    return next;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'gesellschaft': gesellschaft,
      'polizzennummer': polizzennummer,
      'type': type.name,
      'gueltig_ab': gueltigAb?.toIso8601String(),
      'faelligkeit_jaehrlich_am': faelligkeitJaehrlichAm?.toIso8601String(),
      'zahlungsintervall': zahlungsintervall?.name,
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
      zahlungsintervall: PaymentInterval.values.firstWhereOrNull(
        (i) => i.name == map['zahlungsintervall'],
      ),
      praemieEuro: (map['praemie_euro'] as num?)?.toDouble(),
      notizen: map['notizen'] as String?,
    );
  }
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
