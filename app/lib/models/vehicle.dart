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
  String? fahrgestellnummer;
  int? baujahr;
  String? farbe;
  DateTime? kaufdatum;
  String? sollReifendimension;
  String? notizen;
  final DateTime createdAt;
  DateTime updatedAt;

  Vehicle({
    required this.id,
    required this.type,
    required this.name,
    this.marke,
    this.modell,
    this.kennzeichen,
    this.fahrgestellnummer,
    this.baujahr,
    this.farbe,
    this.kaufdatum,
    this.sollReifendimension,
    this.notizen,
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
      'fahrgestellnummer': fahrgestellnummer,
      'baujahr': baujahr,
      'farbe': farbe,
      'kaufdatum': kaufdatum?.toIso8601String(),
      'soll_reifendimension': sollReifendimension,
      'notizen': notizen,
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
      fahrgestellnummer: map['fahrgestellnummer'] as String?,
      baujahr: map['baujahr'] as int?,
      farbe: map['farbe'] as String?,
      kaufdatum: map['kaufdatum'] != null
          ? DateTime.parse(map['kaufdatum'] as String)
          : null,
      sollReifendimension: map['soll_reifendimension'] as String?,
      notizen: map['notizen'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
