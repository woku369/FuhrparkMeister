import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/workshop.dart';
import '../providers/fuhrpark_provider.dart';
import '../widgets/empty_state.dart';

const _uuid = Uuid();

/// Verwaltung der Werkstätten, die für Fahrzeuge zuständig sind - z. B.
/// für Service oder die §57a-Begutachtung. Fahrzeuge (nur PKW) können im
/// Fahrzeugformular einer Werkstatt zugeordnet werden.
class WorkshopsScreen extends StatefulWidget {
  const WorkshopsScreen({super.key});

  @override
  State<WorkshopsScreen> createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends State<WorkshopsScreen> {
  late Future<List<Workshop>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<FuhrparkProvider>().getWorkshops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Werkstätten')),
      body: FutureBuilder<List<Workshop>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final workshops = snapshot.data!;
          if (workshops.isEmpty) {
            return EmptyState(
              icon: Icons.home_repair_service_outlined,
              text: 'Noch keine Werkstätten erfasst.',
              actionLabel: 'Werkstatt hinzufügen',
              onAction: () => _openForm(),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: workshops.length,
              itemBuilder: (context, index) {
                final w = workshops[index];
                final subtitleParts = [
                  if (w.telefon != null && w.telefon!.isNotEmpty) w.telefon!,
                  if (w.adresse != null && w.adresse!.isNotEmpty) w.adresse!,
                  if (w.pruefstelle57a) '§57a-Prüfstelle',
                ];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.home_repair_service_outlined,
                      color: w.pruefstelle57a
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(w.name),
                    subtitle: subtitleParts.isEmpty
                        ? null
                        : Text(subtitleParts.join(' · ')),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _openForm(existing: w);
                        if (v == 'delete') _delete(w);
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

  Future<void> _delete(Workshop w) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Werkstatt löschen?'),
        content: Text(
          '"${w.name}" wird entfernt. Fahrzeuge, die dieser Werkstatt '
          'zugeordnet sind, verlieren die Zuordnung.',
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
    if (confirmed != true || !mounted) return;
    await context.read<FuhrparkProvider>().deleteWorkshop(w.id);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Werkstatt gelöscht')),
    );
  }

  Future<void> _openForm({Workshop? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WorkshopFormSheet(existing: existing),
    );
    if (result == true && mounted) {
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Werkstatt gespeichert')),
      );
    }
  }
}

class _WorkshopFormSheet extends StatefulWidget {
  final Workshop? existing;

  const _WorkshopFormSheet({this.existing});

  @override
  State<_WorkshopFormSheet> createState() => _WorkshopFormSheetState();
}

class _WorkshopFormSheetState extends State<_WorkshopFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _telefon;
  late final TextEditingController _adresse;
  late final TextEditingController _notizen;
  late bool _pruefstelle57a;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _telefon = TextEditingController(text: e?.telefon ?? '');
    _adresse = TextEditingController(text: e?.adresse ?? '');
    _notizen = TextEditingController(text: e?.notizen ?? '');
    _pruefstelle57a = e?.pruefstelle57a ?? false;
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
              widget.existing == null
                  ? 'Werkstatt hinzufügen'
                  : 'Werkstatt bearbeiten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              autofocus: widget.existing == null,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefon,
              decoration: const InputDecoration(labelText: 'Telefon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _adresse,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _pruefstelle57a,
              title: const Text('§57a-Prüfstelle'),
              onChanged: (v) => setState(() => _pruefstelle57a = v),
            ),
            TextField(
              controller: _notizen,
              decoration: const InputDecoration(labelText: 'Notizen'),
              maxLines: 2,
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
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Namen eingeben')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final provider = context.read<FuhrparkProvider>();
      final workshop = Workshop(
        id: widget.existing?.id ?? _uuid.v4(),
        name: _name.text.trim(),
        telefon: _telefon.text.trim().isEmpty ? null : _telefon.text.trim(),
        adresse: _adresse.text.trim().isEmpty ? null : _adresse.text.trim(),
        pruefstelle57a: _pruefstelle57a,
        notizen: _notizen.text.trim().isEmpty ? null : _notizen.text.trim(),
      );
      await provider.saveWorkshop(workshop, isNew: widget.existing == null);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
