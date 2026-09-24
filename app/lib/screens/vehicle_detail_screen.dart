import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/fuhrpark_provider.dart';
import 'vehicle_detail/documents_tab.dart';
import 'vehicle_detail/inspections_tab.dart';
import 'vehicle_detail/maintenance_tab.dart';
import 'vehicle_detail/overview_tab.dart';
import 'vehicle_detail/tires_tab.dart';
import 'vehicle_detail/vignette_insurance_tab.dart';
import 'vehicle_form_screen.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FuhrparkProvider>();
    Vehicle? vehicle;
    for (final v in provider.vehicles) {
      if (v.id == vehicleId) vehicle = v;
    }

    if (vehicle == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final v = vehicle;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(v.anzeigename),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => VehicleFormScreen(vehicle: v),
                  ),
                );
                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fahrzeug gespeichert')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, v),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Übersicht'),
              Tab(text: 'Reifen'),
              Tab(text: 'Termine'),
              Tab(text: 'Vignette & Versicherung'),
              Tab(text: 'Dokumente'),
              Tab(text: 'To-Do'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OverviewTab(vehicle: v),
            TiresTab(vehicle: v),
            InspectionsTab(vehicle: v),
            VignetteInsuranceTab(vehicle: v),
            DocumentsTab(vehicle: v),
            MaintenanceTab(vehicle: v),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fahrzeug löschen?'),
        content: Text(
          '${vehicle.anzeigename} und alle zugehörigen Termine, Reifen, '
          'Dokumente sowie Vignetten-/Versicherungsdaten werden entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<FuhrparkProvider>().deleteVehicle(vehicle.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
