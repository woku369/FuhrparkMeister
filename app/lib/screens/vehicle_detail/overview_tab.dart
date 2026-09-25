import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/vehicle.dart';
import '../../services/document_storage.dart';
import '../../widgets/date_format_x.dart';

class OverviewTab extends StatelessWidget {
  final Vehicle vehicle;

  const OverviewTab({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final erstzulassung = vehicle.erstzulassungMonat != null &&
            vehicle.erstzulassungJahr != null
        ? '${vehicle.erstzulassungMonat!.toString().padLeft(2, '0')}/${vehicle.erstzulassungJahr}'
        : vehicle.erstzulassungJahr?.toString();

    final rows = <(String, String?)>[
      ('Typ', vehicle.type.label),
      ('Marke', vehicle.marke),
      ('Modell', vehicle.modell),
      ('Kennzeichen', vehicle.kennzeichen),
      ('Halter', vehicle.halter),
      ('Fahrgestellnummer', vehicle.fahrgestellnummer),
      ('Baujahr', vehicle.baujahr?.toString()),
      ('Erstzulassung', erstzulassung),
      ('Leistung', vehicle.leistungKw != null ? '${vehicle.leistungKw} kW' : null),
      ('Farbe', vehicle.farbe),
      ('Kaufdatum', vehicle.kaufdatum?.deDate),
      ('Kilometerstand bei Ankauf', vehicle.kilometerstandBeiAnkauf?.toString()),
      ('Anzahl Vorbesitzer', vehicle.anzahlVorbesitzer?.toString()),
      ('Benötigte Reifendimension', vehicle.sollReifendimension),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (vehicle.fotoPfad != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: FutureBuilder<String>(
                future: DocumentStorage.absolutePath(vehicle.fotoPfad!),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  return Image.file(
                    File(snap.data!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        for (final (label, value) in rows)
          if (value != null && value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 180,
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: Text(value)),
                ],
              ),
            ),
        if (vehicle.notizen != null && vehicle.notizen!.isNotEmpty) ...[
          const Divider(height: 32),
          const Text('Notizen', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(vehicle.notizen!),
        ],
      ],
    );
  }
}
