import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/tire_set.dart';
import '../../models/vehicle.dart';
import '../../providers/fuhrpark_provider.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

const _uuid = Uuid();

class TiresTab extends StatefulWidget {
  final Vehicle vehicle;

  const TiresTab({super.key, required this.vehicle});

  @override
  State<TiresTab> createState() => _TiresTabState();
}

class _TiresTabState extends State<TiresTab> {
  late Future<List<TireSet>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<FuhrparkProvider>().tireSetsFor(widget.vehicle.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<TireSet>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sets = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (widget.vehicle.sollReifendimension != null &&
                    widget.vehicle.sollReifendimension!.isNotEmpty)
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.rule),
                      title: const Text('Benötigte Dimension'),
                      subtitle: Text(widget.vehicle.sollReifendimension!),
                    ),
                  ),
                if (sets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: EmptyState(
                      icon: Icons.tire_repair_outlined,
                      text: 'Noch keine Reifensätze erfasst.',
                    ),
                  ),
                for (final t in sets)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        t.montiert ? Icons.check_circle : Icons.inventory_2_outlined,
                        color: t.montiert ? Colors.green : null,
                      ),
                      title: Text('${t.season.label} · ${t.dimension}'),
                      subtitle: Text(_subtitle(t)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) => _handleMenu(v, t),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                          PopupMenuItem(value: 'delete', child: Text('Löschen')),
                        ],
                      ),
                    ),
                  ),
              ],
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

  String _subtitle(TireSet t) {
    final parts = <String>[
      t.montiert ? 'montiert' : 'im Lager',
      if (t.hersteller != null && t.hersteller!.isNotEmpty) t.hersteller!,
      if (t.profiltiefeMm != null) '${t.profiltiefeMm} mm Profil',
      if (t.wechselFaelligAm != null) 'Wechsel ab ${t.wechselFaelligAm!.deDate}',
    ];
    return parts.join(' · ');
  }

  void _handleMenu(String action, TireSet t) {
    if (action == 'edit') _openForm(existing: t);
    if (action == 'delete') _delete(t);
  }

  Future<void> _delete(TireSet t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reifensatz löschen?'),
        content: Text('${t.season.label} · ${t.dimension} wird entfernt.'),
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
    await context.read<FuhrparkProvider>().deleteTireSet(t.id);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reifensatz gelöscht')),
    );
  }

  Future<void> _openForm({TireSet? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TireFormSheet(vehicleId: widget.vehicle.id, existing: existing),
    );
    if (result == true && mounted) {
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reifensatz gespeichert')),
      );
    }
  }
}

class _TireFormSheet extends StatefulWidget {
  final String vehicleId;
  final TireSet? existing;

  const _TireFormSheet({required this.vehicleId, this.existing});

  @override
  State<_TireFormSheet> createState() => _TireFormSheetState();
}

class _TireFormSheetState extends State<_TireFormSheet> {
  late TireSeason _season;
  late final TextEditingController _dimension;
  late final TextEditingController _hersteller;
  late final TextEditingController _profiltiefe;
  late bool _montiert;
  DateTime? _wechselFaelligAm;
  late final TextEditingController _notizen;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _season = e?.season ?? TireSeason.sommer;
    _dimension = TextEditingController(text: e?.dimension ?? '');
    _hersteller = TextEditingController(text: e?.hersteller ?? '');
    _profiltiefe = TextEditingController(text: e?.profiltiefeMm?.toString() ?? '');
    _montiert = e?.montiert ?? false;
    _wechselFaelligAm = e?.wechselFaelligAm;
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
              widget.existing == null ? 'Reifensatz hinzufügen' : 'Reifensatz bearbeiten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TireSeason>(
              initialValue: _season,
              decoration: const InputDecoration(labelText: 'Saison'),
              items: TireSeason.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (s) => setState(() => _season = s ?? _season),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dimension,
              decoration: const InputDecoration(
                labelText: 'Dimension *',
                hintText: 'z. B. 205/55 R16 91V',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hersteller,
              decoration: const InputDecoration(labelText: 'Hersteller'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _profiltiefe,
              decoration: const InputDecoration(labelText: 'Profiltiefe (mm)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _montiert,
              title: const Text('Aktuell montiert'),
              onChanged: (v) => setState(() => _montiert = v),
            ),
            InkWell(
              onTap: () async {
                final result = await showDatePicker(
                  context: context,
                  initialDate: _wechselFaelligAm ?? DateTime.now(),
                  firstDate: DateTime(1970),
                  lastDate: DateTime(2100),
                );
                if (result != null) setState(() => _wechselFaelligAm = result);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Wechsel fällig ab'),
                child: Text(
                  _wechselFaelligAm == null ? '– nicht gesetzt –' : _wechselFaelligAm!.deDate,
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
    if (_saving || _dimension.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final provider = context.read<FuhrparkProvider>();
      final tireSet = TireSet(
        id: widget.existing?.id ?? _uuid.v4(),
        vehicleId: widget.vehicleId,
        season: _season,
        dimension: _dimension.text.trim(),
        hersteller: _hersteller.text.trim().isEmpty ? null : _hersteller.text.trim(),
        profiltiefeMm: double.tryParse(_profiltiefe.text.trim().replaceAll(',', '.')),
        montiert: _montiert,
        kaufdatum: widget.existing?.kaufdatum,
        wechselFaelligAm: _wechselFaelligAm,
        notizen: _notizen.text.trim().isEmpty ? null : _notizen.text.trim(),
      );
      await provider.saveTireSet(tireSet, isNew: widget.existing == null);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
