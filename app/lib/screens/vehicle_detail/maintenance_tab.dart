import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/maintenance_task.dart';
import '../../models/vehicle.dart';
import '../../providers/fuhrpark_provider.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

const _uuid = Uuid();

/// Laufende Wartungs-To-Dos: Dinge, die auffallen oder geplant sind, aber
/// nicht an eine Prüffrist gebunden sind (dafür der Termine-Tab) - z. B.
/// beim Anhänger "Bremsbeläge prüfen" oder "Kupplung fettet nicht mehr".
class MaintenanceTab extends StatefulWidget {
  final Vehicle vehicle;

  const MaintenanceTab({super.key, required this.vehicle});

  @override
  State<MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<MaintenanceTab> {
  late Future<List<MaintenanceTask>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<FuhrparkProvider>().maintenanceTasksFor(widget.vehicle.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<MaintenanceTask>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.checklist_outlined,
              text:
                  'Noch keine To-Dos.\nHalte hier fest, was dir auffällt oder '
                  'geplant ist - unabhängig von Prüfterminen.',
              actionLabel: 'To-Do hinzufügen',
              onAction: () => _openForm(),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final t = items[index];
                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: t.erledigt,
                      onChanged: (v) => _toggleErledigt(t, v ?? false),
                    ),
                    title: Text(
                      t.titel,
                      style: t.erledigt
                          ? const TextStyle(decoration: TextDecoration.lineThrough)
                          : null,
                    ),
                    subtitle: Text(
                      [
                        if (t.notizen != null && t.notizen!.isNotEmpty) t.notizen!,
                        t.erledigt && t.erledigtAm != null
                            ? 'erledigt am ${t.erledigtAm!.deDate}'
                            : 'angelegt am ${t.erstelltAm.deDate}',
                      ].join(' · '),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _openForm(existing: t);
                        if (v == 'delete') _delete(t);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                        PopupMenuItem(value: 'delete', child: Text('Löschen')),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _toggleErledigt(MaintenanceTask t, bool value) async {
    if (!mounted) return;
    final provider = context.read<FuhrparkProvider>();
    t.erledigt = value;
    t.erledigtAm = value ? DateTime.now() : null;
    await provider.saveMaintenanceTask(t, isNew: false);
    if (mounted) setState(_reload);
  }

  Future<void> _delete(MaintenanceTask t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('To-Do löschen?'),
        content: Text('"${t.titel}" wird entfernt.'),
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
    if (confirmed != true || !mounted) return;
    await context.read<FuhrparkProvider>().deleteMaintenanceTask(t.id);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('To-Do gelöscht')),
    );
  }

  Future<void> _openForm({MaintenanceTask? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MaintenanceFormSheet(
        vehicleId: widget.vehicle.id,
        existing: existing,
      ),
    );
    if (result == true && mounted) {
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To-Do gespeichert')),
      );
    }
  }
}

class _MaintenanceFormSheet extends StatefulWidget {
  final String vehicleId;
  final MaintenanceTask? existing;

  const _MaintenanceFormSheet({required this.vehicleId, this.existing});

  @override
  State<_MaintenanceFormSheet> createState() => _MaintenanceFormSheetState();
}

class _MaintenanceFormSheetState extends State<_MaintenanceFormSheet> {
  late final TextEditingController _titel;
  late final TextEditingController _notizen;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titel = TextEditingController(text: e?.titel ?? '');
    _notizen = TextEditingController(text: e?.notizen ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'To-Do hinzufügen' : 'To-Do bearbeiten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titel,
              autofocus: widget.existing == null,
              decoration: const InputDecoration(
                labelText: 'Was ist zu tun? *',
                hintText: 'z. B. Bremsbeläge Anhänger prüfen',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notizen,
              decoration: const InputDecoration(labelText: 'Notizen'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_titel.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Titel eingeben')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final provider = context.read<FuhrparkProvider>();
      final task = MaintenanceTask(
        id: widget.existing?.id ?? _uuid.v4(),
        vehicleId: widget.vehicleId,
        titel: _titel.text.trim(),
        notizen: _notizen.text.trim().isEmpty ? null : _notizen.text.trim(),
        erledigt: widget.existing?.erledigt ?? false,
        erstelltAm: widget.existing?.erstelltAm ?? DateTime.now(),
        erledigtAm: widget.existing?.erledigtAm,
      );
      await provider.saveMaintenanceTask(task, isNew: widget.existing == null);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
