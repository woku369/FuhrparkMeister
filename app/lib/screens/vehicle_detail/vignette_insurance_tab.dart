import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/insurance.dart';
import '../../models/vehicle.dart';
import '../../models/vignette.dart';
import '../../providers/fuhrpark_provider.dart';
import '../../widgets/date_format_x.dart';

const _uuid = Uuid();

class VignetteInsuranceTab extends StatefulWidget {
  final Vehicle vehicle;

  const VignetteInsuranceTab({super.key, required this.vehicle});

  @override
  State<VignetteInsuranceTab> createState() => _VignetteInsuranceTabState();
}

class _VignetteInsuranceTabState extends State<VignetteInsuranceTab> {
  late Future<List<Vignette>> _vignettes;
  late Future<List<Insurance>> _insurances;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final provider = context.read<FuhrparkProvider>();
    _vignettes = provider.vignettesFor(widget.vehicle.id);
    _insurances = provider.insurancesFor(widget.vehicle.id);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(_reload),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _SectionHeader(
            title: 'Vignetten',
            onAdd: () => _openVignetteForm(),
          ),
          FutureBuilder<List<Vignette>>(
            future: _vignettes,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Keine Vignette erfasst.'),
                );
              }
              return Column(
                children: [
                  for (final v in items)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.confirmation_number_outlined),
                        title: Text('Vignette ${v.jahr}${v.digital ? " (digital)" : ""}'),
                        subtitle: Text(
                          'Gültig ${v.gueltigVon.deDate} – ${v.gueltigBis.deDate}'
                          '${v.preisEuro != null ? " · €${v.preisEuro!.toStringAsFixed(2)}" : ""}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (a) {
                            if (a == 'edit') _openVignetteForm(existing: v);
                            if (a == 'delete') _deleteVignette(v);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                            PopupMenuItem(value: 'delete', child: Text('Löschen')),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Versicherungen',
            onAdd: () => _openInsuranceForm(),
          ),
          FutureBuilder<List<Insurance>>(
            future: _insurances,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Keine Versicherung erfasst.'),
                );
              }
              return Column(
                children: [
                  for (final i in items)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.shield_outlined),
                        title: Text('${i.gesellschaft} · ${i.type.label}'),
                        subtitle: Text(
                          'Polizze ${i.polizzennummer}'
                          '${i.faelligkeitJaehrlichAm != null ? " · jährlich fällig am ${i.faelligkeitJaehrlichAm!.deDate}" : ""}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (a) {
                            if (a == 'edit') _openInsuranceForm(existing: i);
                            if (a == 'delete') _deleteInsurance(i);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                            PopupMenuItem(value: 'delete', child: Text('Löschen')),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVignette(Vignette v) async {
    await context.read<FuhrparkProvider>().deleteVignette(v.id);
    setState(_reload);
  }

  Future<void> _deleteInsurance(Insurance i) async {
    await context.read<FuhrparkProvider>().deleteInsurance(i.id);
    setState(_reload);
  }

  Future<void> _openVignetteForm({Vignette? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VignetteFormSheet(
        vehicleId: widget.vehicle.id,
        vehicleName: widget.vehicle.anzeigename,
        existing: existing,
      ),
    );
    if (result == true) setState(_reload);
  }

  Future<void> _openInsuranceForm({Insurance? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InsuranceFormSheet(
        vehicleId: widget.vehicle.id,
        vehicleName: widget.vehicle.anzeigename,
        existing: existing,
      ),
    );
    if (result == true) setState(_reload);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;

  const _SectionHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onAdd),
      ],
    );
  }
}

class _VignetteFormSheet extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;
  final Vignette? existing;

  const _VignetteFormSheet({
    required this.vehicleId,
    required this.vehicleName,
    this.existing,
  });

  @override
  State<_VignetteFormSheet> createState() => _VignetteFormSheetState();
}

class _VignetteFormSheetState extends State<_VignetteFormSheet> {
  late final TextEditingController _jahr;
  DateTime _gueltigVon = DateTime(DateTime.now().year, 12, 1);
  DateTime _gueltigBis = DateTime(DateTime.now().year + 1, 1, 31);
  late final TextEditingController _preis;
  bool _digital = true;
  late final TextEditingController _notizen;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _jahr = TextEditingController(text: (e?.jahr ?? DateTime.now().year).toString());
    _gueltigVon = e?.gueltigVon ?? _gueltigVon;
    _gueltigBis = e?.gueltigBis ?? _gueltigBis;
    _preis = TextEditingController(text: e?.preisEuro?.toString() ?? '');
    _digital = e?.digital ?? true;
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
              widget.existing == null ? 'Vignette hinzufügen' : 'Vignette bearbeiten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jahr,
              decoration: const InputDecoration(labelText: 'Jahr'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Gültig von',
              value: _gueltigVon,
              onPick: (d) => setState(() => _gueltigVon = d),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Gültig bis',
              value: _gueltigBis,
              onPick: (d) => setState(() => _gueltigBis = d),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _preis,
              decoration: const InputDecoration(labelText: 'Preis (€)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _digital,
              title: const Text('Digitale Vignette'),
              onChanged: (v) => setState(() => _digital = v),
            ),
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
    final vignette = Vignette(
      id: widget.existing?.id ?? _uuid.v4(),
      vehicleId: widget.vehicleId,
      jahr: int.tryParse(_jahr.text.trim()) ?? DateTime.now().year,
      gueltigVon: _gueltigVon,
      gueltigBis: _gueltigBis,
      kaufdatum: widget.existing?.kaufdatum,
      preisEuro: double.tryParse(_preis.text.trim().replaceAll(',', '.')),
      digital: _digital,
      notizen: _notizen.text.trim().isEmpty ? null : _notizen.text.trim(),
    );
    await provider.saveVignette(
      vignette,
      widget.vehicleName,
      isNew: widget.existing == null,
    );
    if (mounted) Navigator.of(context).pop(true);
  }
}

class _InsuranceFormSheet extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;
  final Insurance? existing;

  const _InsuranceFormSheet({
    required this.vehicleId,
    required this.vehicleName,
    this.existing,
  });

  @override
  State<_InsuranceFormSheet> createState() => _InsuranceFormSheetState();
}

class _InsuranceFormSheetState extends State<_InsuranceFormSheet> {
  late final TextEditingController _gesellschaft;
  late final TextEditingController _polizzennummer;
  late InsuranceType _type;
  DateTime? _faelligkeitJaehrlichAm;
  late final TextEditingController _praemie;
  late final TextEditingController _notizen;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _gesellschaft = TextEditingController(text: e?.gesellschaft ?? '');
    _polizzennummer = TextEditingController(text: e?.polizzennummer ?? '');
    _type = e?.type ?? InsuranceType.haftpflicht;
    _faelligkeitJaehrlichAm = e?.faelligkeitJaehrlichAm;
    _praemie = TextEditingController(text: e?.praemieEuro?.toString() ?? '');
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
              widget.existing == null
                  ? 'Versicherung hinzufügen'
                  : 'Versicherung bearbeiten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gesellschaft,
              decoration: const InputDecoration(labelText: 'Gesellschaft *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _polizzennummer,
              decoration: const InputDecoration(labelText: 'Polizzennummer *'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InsuranceType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Art'),
              items: InsuranceType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (t) => setState(() => _type = t ?? _type),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Jährlich fällig am',
              value: _faelligkeitJaehrlichAm,
              onPick: (d) => setState(() => _faelligkeitJaehrlichAm = d),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _praemie,
              decoration: const InputDecoration(labelText: 'Prämie (€/Jahr)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
    if (_gesellschaft.text.trim().isEmpty || _polizzennummer.text.trim().isEmpty) {
      return;
    }
    final provider = context.read<FuhrparkProvider>();
    final insurance = Insurance(
      id: widget.existing?.id ?? _uuid.v4(),
      vehicleId: widget.vehicleId,
      gesellschaft: _gesellschaft.text.trim(),
      polizzennummer: _polizzennummer.text.trim(),
      type: _type,
      gueltigAb: widget.existing?.gueltigAb,
      faelligkeitJaehrlichAm: _faelligkeitJaehrlichAm,
      praemieEuro: double.tryParse(_praemie.text.trim().replaceAll(',', '.')),
      notizen: _notizen.text.trim().isEmpty ? null : _notizen.text.trim(),
    );
    await provider.saveInsurance(
      insurance,
      widget.vehicleName,
      isNew: widget.existing == null,
    );
    if (mounted) Navigator.of(context).pop(true);
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  const _DateField({required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1970),
          lastDate: DateTime(2100),
        );
        if (result != null) onPick(result);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value == null ? '– nicht gesetzt –' : value!.deDate),
      ),
    );
  }
}
