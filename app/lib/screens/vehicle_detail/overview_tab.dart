import 'package:flutter/material.dart';

import '../../models/vehicle.dart';
import '../../widgets/date_format_x.dart';

class OverviewTab extends StatelessWidget {
  final Vehicle vehicle;

  const OverviewTab({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('Typ', vehicle.type.label),
      ('Marke', vehicle.marke),
      ('Modell', vehicle.modell),
      ('Kennzeichen', vehicle.kennzeichen),
      ('Fahrgestellnummer', vehicle.fahrgestellnummer),
      ('Baujahr', vehicle.baujahr?.toString()),
      ('Farbe', vehicle.farbe),
      ('Kaufdatum', vehicle.kaufdatum?.deDate),
      ('Benötigte Reifendimension', vehicle.sollReifendimension),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
