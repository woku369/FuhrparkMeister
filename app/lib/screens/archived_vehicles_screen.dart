import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/fuhrpark_provider.dart';
import '../widgets/empty_state.dart';
import 'vehicle_detail_screen.dart';

/// Zeigt archivierte Fahrzeuge (verkauft/stillgelegt) getrennt von der
/// aktiven Flotte - Daten und Historie bleiben erhalten, ohne die
/// Hauptliste zu überladen.
class ArchivedVehiclesScreen extends StatelessWidget {
  const ArchivedVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FuhrparkProvider>();
    final archived = provider.vehicles.where((v) => v.archiviert).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Archivierte Fahrzeuge')),
      body: archived.isEmpty
          ? const EmptyState(
              icon: Icons.archive_outlined,
              text: 'Keine archivierten Fahrzeuge.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: archived.length,
              itemBuilder: (context, index) {
                final v = archived[index];
                final subtitleParts = [
                  if (v.marke != null || v.modell != null)
                    [v.marke, v.modell].whereType<String>().join(' '),
                  if (v.kennzeichen != null && v.kennzeichen!.isNotEmpty)
                    v.kennzeichen!,
                ].where((s) => s.isNotEmpty).join(' · ');
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(v.type.icon)),
                    title: Text(v.anzeigename),
                    subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VehicleDetailScreen(vehicleId: v.id),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
