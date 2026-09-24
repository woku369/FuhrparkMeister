import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/fuhrpark_provider.dart';
import '../services/document_storage.dart';
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
  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FuhrparkProvider>().loadVehicles();
    });
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    // Liest die tatsächlich installierte Version aus - zeigt also immer den
    // echten versionCode des Geräts, nicht nur den zuletzt gebauten CI-Stand.
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _versionLabel = 'v${info.version} (${info.buildNumber})');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('FuhrparkMeister'),
            if (_versionLabel != null)
              Text(
                _versionLabel!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
          ],
        ),
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

  Future<void> _openForm(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fahrzeug gespeichert')),
      );
    }
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
        leading: _VehicleThumbnail(vehicle: vehicle),
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

class _VehicleThumbnail extends StatelessWidget {
  final Vehicle vehicle;

  const _VehicleThumbnail({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final fotoPfad = vehicle.fotoPfad;
    if (fotoPfad == null) {
      return CircleAvatar(child: Icon(vehicle.type.icon));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: FutureBuilder<String>(
          future: DocumentStorage.absolutePath(fotoPfad),
          builder: (context, snap) {
            if (!snap.hasData) {
              return CircleAvatar(child: Icon(vehicle.type.icon));
            }
            return Image.file(
              File(snap.data!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  CircleAvatar(child: Icon(vehicle.type.icon)),
            );
          },
        ),
      ),
    );
  }
}
