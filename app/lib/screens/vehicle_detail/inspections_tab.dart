import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/inspection.dart';
import '../../models/vehicle.dart';
import '../../providers/fuhrpark_provider.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

const _uuid = Uuid();

class InspectionsTab extends StatefulWidget {
  final Vehicle vehicle;

  const InspectionsTab({super.key, required this.vehicle});

  @override
  State<InspectionsTab> createState() => _InspectionsTabState();
}

class _InspectionsTabState extends State<InspectionsTab> {
  late Future<List<Inspection>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<FuhrparkProvider>().inspectionsFor(widget.vehicle.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Inspection>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.event_note_outlined,
              text: 'Noch keine Prüftermine erfasst.',
              actionLabel: 'Termin hinzufügen',
              onAction: () => _openForm(),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final i = items[index];
                final ueberfaellig =
                    !i.erledigt && i.faelligAm.isBefore(DateTime.now());
                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: i.erledigt,
                      onChanged: (v) => _toggleErledigt(i, v ?? false),
                    ),
                    title: Text(i.type.label),
                    subtitle: Text(
                      i.erledigt
                          ? 'Erledigt'
                          : 'Fällig am ${i.faelligAm.deDate}'
                              '${ueberfaellig ? ' · überfällig' : ''}',
                      style: ueberfaellig
                          ? const TextStyle(color: Colors.red)
                          : null,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _openForm(existing: i);
                        if (v == 'delete') _delete(i);
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

  Future<void> _toggleErledigt(Inspection i, bool value) async {
    i.erledigt = value;
    await context
        .read<FuhrparkProvider>()
        .saveInspection(i, widget.vehicle.anzeigename, isNew: false);
    setState(_reload);
  }

  Future<void> _delete(Inspection i) async {
    await context.read<FuhrparkProvider>().deleteInspection(i.id);
    setState(_reload);
  }

  Future<void> _openForm({Inspection? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InspectionFormSheet(
        vehicleId: widget.vehicle.id,
        vehicleName: widget.vehicle.anzeigename,
        existing: existing,
      ),
    );
    if (result == true) setState(_reload);
  }
}

class _InspectionFormSheet extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;
  final Inspection? existing;

  const _InspectionFormSheet({
    required this.vehicleId,
    required this.vehicleName,
    this.existing,
  });

  @override
  State<_InspectionFormSheet> createState() => _InspectionFormSheetState();
}

class _InspectionFormSheetState extends State<_InspectionFormSheet> {
  late InspectionType _type;
  DateTime _faelligAm = DateTime.now().add(const Duration(days: 30));
  late final TextEditingController _erinnerungTage;
  late final TextEditingController _notizen;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? InspectionType.pickerl57a;
    _faelligAm = e?.faelligAm ?? _faelligAm;
    _erinnerungTage =
        TextEditingController(text: (e?.erinnerungTageVorher ?? 30).toString());
    _notizen = TextEditingController(text: e?.notizen ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Termin hinzufügen' : 'Termin bearbeiten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InspectionType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Art'),
              items: InspectionType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (t) => setState(() => _type = t ?? _type),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final result = await showDatePicker(
                  context: context,
                  initialDate: _faelligAm,
                  firstDate: DateTime(1970),
                  lastDate: DateTime(2100),
                );
                if (result != null) setState(() => _faelligAm = result);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Fällig am *'),
                child: Text(_faelligAm.deDate),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _erinnerungTage,
              decoration: const InputDecoration(
                labelText: 'Erinnerung (Tage vorher)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notizen,
              decoration: const InputDecoration(labelText: 'Notizen'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final provider = context.read<FuhrparkProvider>();
    final inspection = Inspection(
      id: widget.existing?.id ?? _uuid.v4(),
      vehicleId: widget.vehicleId,
      type: _type,
      faelligAm: _faelligAm,
      letztePruefungAm: widget.existing?.letztePruefungAm,
      erinnerungTageVorher: int.tryParse(_erinnerungTage.text.trim()) ?? 30,
      erledigt: widget.existing?.erledigt ?? false,
      notizen: _notizen.text.trim().isEmpty ? null : _notizen.text.trim(),
    );
    await provider.saveInspection(
      inspection,
      widget.vehicleName,
      isNew: widget.existing == null,
    );
    if (mounted) Navigator.of(context).pop(true);
  }
}
