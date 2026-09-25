import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/fuhrpark_provider.dart';
import '../services/document_storage.dart';
import '../services/local_backup_service.dart';
import '../services/share_import_service.dart';
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
    _setupShareImport();
  }

  Future<void> _loadVersion() async {
    // Liest die tatsächlich installierte Version aus - zeigt also immer den
    // echten versionCode des Geräts, nicht nur den zuletzt gebauten CI-Stand.
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _versionLabel = 'v${info.version} (${info.buildNumber})');
    }
  }

  /// Erlaubt Import per Android-Teilen-Dialog: eine per WhatsApp/Drive/
  /// E-Mail empfangene Backup-ZIP lässt sich direkt "Öffnen mit
  /// FuhrparkMeister" wählen, statt sie manuell per Datei-Manager in den
  /// App-Ordner kopieren zu müssen.
  void _setupShareImport() {
    ShareImportService.consumeInitialSharedZip().then((path) {
      if (path != null) _handleSharedZip(path);
    });
    ShareImportService.listenForSharedZip(_handleSharedZip);
  }

  Future<void> _handleSharedZip(String path) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup importieren?'),
        content: const Text(
          'Eine geteilte Backup-Datei wurde empfangen. Alle lokalen Daten '
          'auf diesem Gerät werden dadurch ersetzt. Nicht gesicherte '
          'lokale Änderungen gehen dabei verloren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Importieren'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await LocalBackupService.importFromZip(path);
      if (!mounted) return;
      await context.read<FuhrparkProvider>().loadVehicles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup importiert')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import fehlgeschlagen: $e')),
      );
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
            child: _GroupedVehicleList(vehicles: provider.vehicles),
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

/// Gruppiert die Fahrzeugliste nach Typ (Auto, Anhänger, Fahrrad, ...) mit
/// Abschnittsüberschriften - bei mehreren Fahrzeugtypen sonst schnell
/// unübersichtlich. Reihenfolge folgt VehicleType.values, leere Kategorien
/// werden ausgeblendet.
class _GroupedVehicleList extends StatelessWidget {
  final List<Vehicle> vehicles;

  const _GroupedVehicleList({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    final grouped = <VehicleType, List<Vehicle>>{};
    for (final v in vehicles) {
      grouped.putIfAbsent(v.type, () => []).add(v);
    }

    final children = <Widget>[];
    for (final type in VehicleType.values) {
      final group = grouped[type];
      if (group == null || group.isEmpty) continue;
      if (children.isNotEmpty) children.add(const SizedBox(height: 20));
      children.add(_CategoryHeader(type: type, count: group.length));
      for (final vehicle in group) {
        children.add(const SizedBox(height: 8));
        children.add(_VehicleCard(vehicle: vehicle));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: children,
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final VehicleType type;
  final int count;

  const _CategoryHeader({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(type.icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            '${type.label} ($count)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
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
