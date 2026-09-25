import 'package:flutter/material.dart';

enum VehicleType { auto, anhaenger, fahrrad, motorrad, wohnwagen, sonstiges }

extension VehicleTypeX on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.auto:
        return 'Auto';
      case VehicleType.anhaenger:
        return 'Anhänger';
      case VehicleType.fahrrad:
        return 'Fahrrad';
      case VehicleType.motorrad:
        return 'Motorrad';
      case VehicleType.wohnwagen:
        return 'Wohnwagen';
      case VehicleType.sonstiges:
        return 'Sonstiges';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleType.auto:
        return Icons.directions_car;
      case VehicleType.anhaenger:
        return Icons.rv_hookup;
      case VehicleType.fahrrad:
        return Icons.pedal_bike;
      case VehicleType.motorrad:
        return Icons.two_wheeler;
      case VehicleType.wohnwagen:
        return Icons.airport_shuttle;
      case VehicleType.sonstiges:
        return Icons.category;
    }
  }
}

class Vehicle {
  final String id;
  VehicleType type;
  String name;
  String? marke;
  String? modell;
  String? kennzeichen;
  String? halter;
  String? fahrgestellnummer;
  int? baujahr;
  String? farbe;
  DateTime? kaufdatum;
  int? kilometerstandBeiAnkauf;
  int? anzahlVorbesitzer;
  String? sollReifendimension;
  String? notizen;
  String? fotoPfad;
  int? leistungKw;
  int? erstzulassungMonat;
  int? erstzulassungJahr;
  bool archiviert;
  String? werkstattId;
  final DateTime createdAt;
  DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.type,
    required this.name,
    this.marke,
    this.modell,
    this.kennzeichen,
    this.halter,
    this.fahrgestellnummer,
    this.baujahr,
    this.farbe,
    this.kaufdatum,
    this.kilometerstandBeiAnkauf,
    this.anzahlVorbesitzer,
    this.sollReifendimension,
    this.notizen,
    this.fotoPfad,
    this.leistungKw,
    this.erstzulassungMonat,
    this.erstzulassungJahr,
    this.archiviert = false,
    this.werkstattId,
    required this.createdAt,
    required this.updatedAt,
  });

  String get anzeigename => name.isNotEmpty
      ? name
      : [marke, modell].where((s) => s != null && s.isNotEmpty).join(' ');

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'marke': marke,
      'modell': modell,
      'kennzeichen': kennzeichen,
      'halter': halter,
      'fahrgestellnummer': fahrgestellnummer,
      'baujahr': baujahr,
      'farbe': farbe,
      'kaufdatum': kaufdatum?.toIso8601String(),
      'kilometerstand_bei_ankauf': kilometerstandBeiAnkauf,
      'anzahl_vorbesitzer': anzahlVorbesitzer,
      'soll_reifendimension': sollReifendimension,
      'notizen': notizen,
      'foto_pfad': fotoPfad,
      'leistung_kw': leistungKw,
      'erstzulassung_monat': erstzulassungMonat,
      'erstzulassung_jahr': erstzulassungJahr,
      'archiviert': archiviert ? 1 : 0,
      'werkstatt_id': werkstattId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, Object?> map) {
    return Vehicle(
      id: map['id'] as String,
      type: VehicleType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => VehicleType.sonstiges,
      ),
      name: map['name'] as String? ?? '',
      marke: map['marke'] as String?,
      modell: map['modell'] as String?,
      kennzeichen: map['kennzeichen'] as String?,
      halter: map['halter'] as String?,
      fahrgestellnummer: map['fahrgestellnummer'] as String?,
      baujahr: map['baujahr'] as int?,
      farbe: map['farbe'] as String?,
      kaufdatum: map['kaufdatum'] != null
          ? DateTime.parse(map['kaufdatum'] as String)
          : null,
      kilometerstandBeiAnkauf: map['kilometerstand_bei_ankauf'] as int?,
      anzahlVorbesitzer: map['anzahl_vorbesitzer'] as int?,
      sollReifendimension: map['soll_reifendimension'] as String?,
      notizen: map['notizen'] as String?,
      fotoPfad: map['foto_pfad'] as String?,
      leistungKw: map['leistung_kw'] as int?,
      erstzulassungMonat: map['erstzulassung_monat'] as int?,
      erstzulassungJahr: map['erstzulassung_jahr'] as int?,
      archiviert: (map['archiviert'] as int? ?? 0) == 1,
      werkstattId: map['werkstatt_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
