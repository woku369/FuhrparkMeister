import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/inspection.dart';
import '../../models/vehicle.dart';
import '../../providers/fuhrpark_provider.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

const _uuid = Uuid();

const _monatsnamen = [
  'Jänner',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];

/// Letzter Tag des angegebenen Monats (Tag 0 des Folgemonats).
DateTime _letzterTagDesMonats(int jahr, int monat) => DateTime(jahr, monat + 1, 0);

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
                      [
                        if (i.type == InspectionType.pickerl57a)
                          'Plakette bis ${_monatsnamen[i.faelligAm.month - 1]} ${i.faelligAm.year}'
                        else
                          'Fällig am ${i.faelligAm.deDate}',
                        if (!i.erledigt && ueberfaellig) 'überfällig',
                        if (i.erledigt && i.letztePruefungAm != null)
                          'geprüft am ${i.letztePruefungAm!.deDate}'
                        else if (i.erledigt)
                          'erledigt',
                      ].join(' · '),
                      style: ueberfaellig && !i.erledigt
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
    if (!mounted) return;
    final provider = context.read<FuhrparkProvider>();
    i.erledigt = value;
    await provider.saveInspection(i, widget.vehicle.anzeigename, isNew: false);
    if (mounted) setState(_reload);
  }

  Future<void> _delete(Inspection i) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Termin löschen?'),
        content: Text('${i.type.label} vom ${i.faelligAm.deDate} wird entfernt.'),
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
    final provider = context.read<FuhrparkProvider>();
    await provider.deleteInspection(i.id);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Termin gelöscht')),
    );
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
    if (result == true && mounted) {
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Termin gespeichert')),
      );
    }
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
  late int _plakettenMonat;
  late int _plakettenJahr;
  DateTime? _letztePruefungAm;
  late final TextEditingController _erinnerungTage;
  late final TextEditingController _notizen;
  bool _saving = false;

  bool get _istPickerl => _type == InspectionType.pickerl57a;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? InspectionType.pickerl57a;
    _faelligAm = e?.faelligAm ?? _faelligAm;
    _plakettenMonat = (e?.faelligAm ?? _faelligAm).month;
    _plakettenJahr = (e?.faelligAm ?? _faelligAm).year;
    _letztePruefungAm = e?.letztePruefungAm;
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
              widget.existing == null ? 'Termin hinzufügen' : 'Termin bearbeiten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InspectionType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Art'),
              items: InspectionType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (t) => setState(() => _type = t ?? _type),
            ),
            const SizedBox(height: 12),
            if (_istPickerl) ...[
              Text(
                'Plakette (Monat/Jahr der Lochung)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      initialValue: _plakettenMonat,
                      decoration: const InputDecoration(labelText: 'Monat'),
                      items: [
                        for (var m = 1; m <= 12; m++)
                          DropdownMenuItem(value: m, child: Text(_monatsnamen[m - 1])),
                      ],
                      onChanged: (m) =>
                          setState(() => _plakettenMonat = m ?? _plakettenMonat),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      initialValue: _plakettenJahr,
                      decoration: const InputDecoration(labelText: 'Jahr'),
                      items: [
                        for (var j = DateTime.now().year - 1;
                            j <= DateTime.now().year + 6;
                            j++)
                          DropdownMenuItem(value: j, child: Text('$j')),
                      ],
                      onChanged: (j) =>
                          setState(() => _plakettenJahr = j ?? _plakettenJahr),
                    ),
                  ),
                ],
              ),
            ] else
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
            InkWell(
              onTap: () async {
                final result = await showDatePicker(
                  context: context,
                  initialDate: _letztePruefungAm ?? DateTime.now(),
                  firstDate: DateTime(1970),
                  lastDate: DateTime(2100),
                );
                if (result != null) setState(() => _letztePruefungAm = result);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tatsächliche Prüfung am',
                  helperText: 'Nach der Begutachtung hier eintragen',
                ),
                child: Text(
                  _letztePruefungAm == null ? '– noch nicht geprüft –' : _letztePruefungAm!.deDate,
                ),
              ),
            ),
            const SizedBox(height: 12),
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
    setState(() => _saving = true);
    try {
      final provider = context.read<FuhrparkProvider>();
      final faelligAm = _istPickerl
          ? _letzterTagDesMonats(_plakettenJahr, _plakettenMonat)
          : _faelligAm;
      final inspection = Inspection(
        id: widget.existing?.id ?? _uuid.v4(),
        vehicleId: widget.vehicleId,
        type: _type,
        faelligAm: faelligAm,
        letztePruefungAm: _letztePruefungAm,
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
