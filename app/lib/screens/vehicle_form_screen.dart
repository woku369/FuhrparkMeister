import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/fuhrpark_provider.dart';
import '../widgets/date_format_x.dart';

class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late VehicleType _type;
  late final TextEditingController _name;
  late final TextEditingController _marke;
  late final TextEditingController _modell;
  late final TextEditingController _kennzeichen;
  late final TextEditingController _fahrgestellnummer;
  late final TextEditingController _baujahr;
  late final TextEditingController _farbe;
  late final TextEditingController _sollDimension;
  late final TextEditingController _notizen;
  DateTime? _kaufdatum;

  bool get _isEdit => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _type = v?.type ?? VehicleType.auto;
    _name = TextEditingController(text: v?.name ?? '');
    _marke = TextEditingController(text: v?.marke ?? '');
    _modell = TextEditingController(text: v?.modell ?? '');
    _kennzeichen = TextEditingController(text: v?.kennzeichen ?? '');
    _fahrgestellnummer = TextEditingController(text: v?.fahrgestellnummer ?? '');
    _baujahr = TextEditingController(text: v?.baujahr?.toString() ?? '');
    _farbe = TextEditingController(text: v?.farbe ?? '');
    _sollDimension = TextEditingController(text: v?.sollReifendimension ?? '');
    _notizen = TextEditingController(text: v?.notizen ?? '');
    _kaufdatum = v?.kaufdatum;
  }

  @override
  void dispose() {
    _name.dispose();
    _marke.dispose();
    _modell.dispose();
    _kennzeichen.dispose();
    _fahrgestellnummer.dispose();
    _baujahr.dispose();
    _farbe.dispose();
    _sollDimension.dispose();
    _notizen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Fahrzeug bearbeiten' : 'Fahrzeug hinzufügen'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<VehicleType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Typ'),
              items: VehicleType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (t) => setState(() => _type = t ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name / Spitzname *',
                hintText: 'z. B. "Der Praktische" oder "Familienauto"',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Bitte Namen eingeben' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _marke,
                    decoration: const InputDecoration(labelText: 'Marke'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modell,
                    decoration: const InputDecoration(labelText: 'Modell'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kennzeichen,
              decoration: const InputDecoration(labelText: 'Kennzeichen'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fahrgestellnummer,
              decoration: const InputDecoration(labelText: 'Fahrgestellnummer'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _baujahr,
                    decoration: const InputDecoration(labelText: 'Baujahr'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _farbe,
                    decoration: const InputDecoration(labelText: 'Farbe'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickKaufdatum,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Kaufdatum'),
                child: Text(
                  _kaufdatum == null ? '– nicht gesetzt –' : _kaufdatum!.deDate,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sollDimension,
              decoration: const InputDecoration(
                labelText: 'Benötigte Reifendimension',
                hintText: 'z. B. 205/55 R16 91V',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notizen,
              decoration: const InputDecoration(labelText: 'Notizen'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickKaufdatum() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _kaufdatum ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (result != null) setState(() => _kaufdatum = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<FuhrparkProvider>();

    if (_isEdit) {
      final v = widget.vehicle!;
      v.type = _type;
      v.name = _name.text.trim();
      v.marke = _marke.text.trim().isEmpty ? null : _marke.text.trim();
      v.modell = _modell.text.trim().isEmpty ? null : _modell.text.trim();
      v.kennzeichen =
          _kennzeichen.text.trim().isEmpty ? null : _kennzeichen.text.trim();
      v.fahrgestellnummer = _fahrgestellnummer.text.trim().isEmpty
          ? null
          : _fahrgestellnummer.text.trim();
      v.baujahr = int.tryParse(_baujahr.text.trim());
      v.farbe = _farbe.text.trim().isEmpty ? null : _farbe.text.trim();
      v.kaufdatum = _kaufdatum;
      v.sollReifendimension =
          _sollDimension.text.trim().isEmpty ? null : _sollDimension.text.trim();
      v.notizen = _notizen.text.trim().isEmpty ? null : _notizen.text.trim();
      await provider.updateVehicle(v);
    } else {
      await provider.addVehicle(
        type: _type,
        name: _name.text.trim(),
        marke: _marke.text.trim().isEmpty ? null : _marke.text.trim(),
        modell: _modell.text.trim().isEmpty ? null : _modell.text.trim(),
        kennzeichen:
            _kennzeichen.text.trim().isEmpty ? null : _kennzeichen.text.trim(),
        fahrgestellnummer: _fahrgestellnummer.text.trim().isEmpty
            ? null
            : _fahrgestellnummer.text.trim(),
        baujahr: int.tryParse(_baujahr.text.trim()),
        farbe: _farbe.text.trim().isEmpty ? null : _farbe.text.trim(),
        kaufdatum: _kaufdatum,
        sollReifendimension: _sollDimension.text.trim().isEmpty
            ? null
            : _sollDimension.text.trim(),
        notizen: _notizen.text.trim().isEmpty ? null : _notizen.text.trim(),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }
}
