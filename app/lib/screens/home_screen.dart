import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/fuhrpark_provider.dart';
import '../widgets/empty_state.dart';
import 'backup_screen.dart';
import 'reminders_screen.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FuhrparkProvider>().loadVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FuhrparkMeister'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Anstehende Termine',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RemindersScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_outlined),
            tooltip: 'Backup & Cloud-Sync',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<FuhrparkProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.vehicles.isEmpty) {
            return EmptyState(
              icon: Icons.directions_car_outlined,
              text:
                  'Noch keine Fahrzeuge angelegt.\nFüge dein erstes Auto, '
                  'Motorrad, Fahrrad oder deinen Anhänger hinzu.',
              actionLabel: 'Fahrzeug hinzufügen',
              onAction: () => _openForm(context),
            );
          }
          return RefreshIndicator(
            onRefresh: provider.loadVehicles,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: provider.vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final vehicle = provider.vehicles[index];
                return _VehicleCard(vehicle: vehicle);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      if (vehicle.marke != null || vehicle.modell != null)
        [vehicle.marke, vehicle.modell].whereType<String>().join(' '),
      if (vehicle.kennzeichen != null && vehicle.kennzeichen!.isNotEmpty)
        vehicle.kennzeichen!,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(vehicle.type.icon)),
        title: Text(vehicle.anzeigename),
        subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VehicleDetailScreen(vehicleId: vehicle.id),
          ),
        ),
      ),
    );
  }
}
