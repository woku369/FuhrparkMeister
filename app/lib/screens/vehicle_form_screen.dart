import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/fuhrpark_provider.dart';
import '../services/document_storage.dart';
import '../widgets/date_format_x.dart';

enum _FotoAction { camera, gallery, entfernen }

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
  late final TextEditingController _halter;
  late final TextEditingController _fahrgestellnummer;
  late final TextEditingController _baujahr;
  late final TextEditingController _farbe;
  late final TextEditingController _sollDimension;
  late final TextEditingController _notizen;
  late final TextEditingController _kmBeiAnkauf;
  late final TextEditingController _vorbesitzer;
  late final TextEditingController _leistungKw;
  late final TextEditingController _erstzulassungJahr;
  int? _erstzulassungMonat;
  DateTime? _kaufdatum;
  bool _saving = false;

  final _picker = ImagePicker();
  String? _existingFotoPfad;
  XFile? _neuesFoto;
  bool _fotoEntfernen = false;

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
    _halter = TextEditingController(text: v?.halter ?? '');
    _fahrgestellnummer = TextEditingController(text: v?.fahrgestellnummer ?? '');
    _baujahr = TextEditingController(text: v?.baujahr?.toString() ?? '');
    _farbe = TextEditingController(text: v?.farbe ?? '');
    _sollDimension = TextEditingController(text: v?.sollReifendimension ?? '');
    _notizen = TextEditingController(text: v?.notizen ?? '');
    _kmBeiAnkauf = TextEditingController(text: v?.kilometerstandBeiAnkauf?.toString() ?? '');
    _vorbesitzer = TextEditingController(text: v?.anzahlVorbesitzer?.toString() ?? '');
    _leistungKw = TextEditingController(text: v?.leistungKw?.toString() ?? '');
    _erstzulassungJahr = TextEditingController(text: v?.erstzulassungJahr?.toString() ?? '');
    _erstzulassungMonat = v?.erstzulassungMonat;
    _kaufdatum = v?.kaufdatum;
    _existingFotoPfad = v?.fotoPfad;
  }

  @override
  void dispose() {
    _name.dispose();
    _marke.dispose();
    _modell.dispose();
    _kennzeichen.dispose();
    _halter.dispose();
    _fahrgestellnummer.dispose();
    _baujahr.dispose();
    _farbe.dispose();
    _sollDimension.dispose();
    _notizen.dispose();
    _kmBeiAnkauf.dispose();
    _vorbesitzer.dispose();
    _leistungKw.dispose();
    _erstzulassungJahr.dispose();
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
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 +
                MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickFoto,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 160,
                        height: 120,
                        child: _buildFotoPreview(),
                      ),
                    ),
                    const Positioned(
                      right: 4,
                      bottom: 4,
                      child: CircleAvatar(
                        radius: 14,
                        child: Icon(Icons.edit, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
              controller: _halter,
              decoration: const InputDecoration(labelText: 'Halter'),
              textCapitalization: TextCapitalization.words,
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
            if (_type == VehicleType.auto) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _leistungKw,
                      decoration: const InputDecoration(labelText: 'Leistung (kW)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: DropdownButtonFormField<int>(
                      initialValue: _erstzulassungMonat,
                      decoration: const InputDecoration(labelText: 'EZ Monat'),
                      items: [
                        for (var m = 1; m <= 12; m++)
                          DropdownMenuItem(
                            value: m,
                            child: Text(m.toString().padLeft(2, '0')),
                          ),
                      ],
                      onChanged: (m) => setState(() => _erstzulassungMonat = m),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _erstzulassungJahr,
                      decoration: const InputDecoration(labelText: 'EZ Jahr'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kmBeiAnkauf,
                    decoration: const InputDecoration(
                      labelText: 'Kilometerstand bei Ankauf',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _vorbesitzer,
                    decoration: const InputDecoration(labelText: 'Anzahl Vorbesitzer'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
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

  Widget _buildFotoPreview() {
    if (_neuesFoto != null) {
      return Image.file(File(_neuesFoto!.path), fit: BoxFit.cover);
    }
    final existing = _existingFotoPfad;
    if (!_fotoEntfernen && existing != null) {
      return FutureBuilder<String>(
        future: DocumentStorage.absolutePath(existing),
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          return Image.file(
            File(snap.data!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image_outlined),
          );
        },
      );
    }
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.add_a_photo_outlined, size: 32),
    );
  }

  Future<void> _pickFoto() async {
    final hatFoto =
        _neuesFoto != null || (!_fotoEntfernen && _existingFotoPfad != null);
    final action = await showModalBottomSheet<_FotoAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Foto aufnehmen'),
              onTap: () => Navigator.of(ctx).pop(_FotoAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Aus Galerie wählen'),
              onTap: () => Navigator.of(ctx).pop(_FotoAction.gallery),
            ),
            if (hatFoto)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Foto entfernen'),
                onTap: () => Navigator.of(ctx).pop(_FotoAction.entfernen),
              ),
          ],
        ),
      ),
    );
    if (action == null) return;
    if (action == _FotoAction.entfernen) {
      setState(() {
        _neuesFoto = null;
        _fotoEntfernen = true;
      });
      return;
    }
    final picked = await _picker.pickImage(
      source: action == _FotoAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _neuesFoto = picked;
      _fotoEntfernen = false;
    });
  }

  /// Legt ein neu gewähltes Foto im fahrzeugeigenen Ordner ab (fester
  /// Dateiname "cover<ext>", damit beim Ersetzen kein alter Dateirest
  /// übrig bleibt) und liefert den zu speichernden relativen Pfad - oder
  /// null, wenn das Foto entfernt wurde.
  Future<String?> _persistFoto(String vehicleId, String? currentFotoPfad) async {
    if (_fotoEntfernen) {
      if (currentFotoPfad != null) {
        final oldFile = File(await DocumentStorage.absolutePath(currentFotoPfad));
        if (await oldFile.exists()) await oldFile.delete();
      }
      return null;
    }
    if (_neuesFoto == null) return currentFotoPfad;
    if (currentFotoPfad != null) {
      final oldFile = File(await DocumentStorage.absolutePath(currentFotoPfad));
      if (await oldFile.exists()) await oldFile.delete();
    }
    final targetDir = await DocumentStorage.vehicleDir(vehicleId);
    final ext = p.extension(_neuesFoto!.path);
    final fileName = 'cover$ext';
    final targetPath = p.join(targetDir.path, fileName);
    await File(_neuesFoto!.path).copy(targetPath);
    return '$vehicleId/$fileName';
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
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final provider = context.read<FuhrparkProvider>();

      if (_isEdit) {
        final v = widget.vehicle!;
        v.type = _type;
        v.name = _name.text.trim();
        v.marke = _marke.text.trim().isEmpty ? null : _marke.text.trim();
        v.modell = _modell.text.trim().isEmpty ? null : _modell.text.trim();
        v.kennzeichen =
            _kennzeichen.text.trim().isEmpty ? null : _kennzeichen.text.trim();
        v.halter = _halter.text.trim().isEmpty ? null : _halter.text.trim();
        v.fahrgestellnummer = _fahrgestellnummer.text.trim().isEmpty
            ? null
            : _fahrgestellnummer.text.trim();
        v.baujahr = int.tryParse(_baujahr.text.trim());
        v.farbe = _farbe.text.trim().isEmpty ? null : _farbe.text.trim();
        v.kaufdatum = _kaufdatum;
        v.kilometerstandBeiAnkauf = int.tryParse(_kmBeiAnkauf.text.trim());
        v.anzahlVorbesitzer = int.tryParse(_vorbesitzer.text.trim());
        v.sollReifendimension = _sollDimension.text.trim().isEmpty
            ? null
            : _sollDimension.text.trim();
        v.notizen = _notizen.text.trim().isEmpty ? null : _notizen.text.trim();
        v.leistungKw = _type == VehicleType.auto
            ? int.tryParse(_leistungKw.text.trim())
            : null;
        v.erstzulassungMonat = _type == VehicleType.auto ? _erstzulassungMonat : null;
        v.erstzulassungJahr = _type == VehicleType.auto
            ? int.tryParse(_erstzulassungJahr.text.trim())
            : null;
        v.fotoPfad = await _persistFoto(v.id, v.fotoPfad);
        await provider.updateVehicle(v);
      } else {
        final v = await provider.addVehicle(
          type: _type,
          name: _name.text.trim(),
          marke: _marke.text.trim().isEmpty ? null : _marke.text.trim(),
          modell: _modell.text.trim().isEmpty ? null : _modell.text.trim(),
          kennzeichen:
              _kennzeichen.text.trim().isEmpty ? null : _kennzeichen.text.trim(),
          halter: _halter.text.trim().isEmpty ? null : _halter.text.trim(),
          fahrgestellnummer: _fahrgestellnummer.text.trim().isEmpty
              ? null
              : _fahrgestellnummer.text.trim(),
          baujahr: int.tryParse(_baujahr.text.trim()),
          farbe: _farbe.text.trim().isEmpty ? null : _farbe.text.trim(),
          kaufdatum: _kaufdatum,
          kilometerstandBeiAnkauf: int.tryParse(_kmBeiAnkauf.text.trim()),
          anzahlVorbesitzer: int.tryParse(_vorbesitzer.text.trim()),
          sollReifendimension: _sollDimension.text.trim().isEmpty
              ? null
              : _sollDimension.text.trim(),
          notizen: _notizen.text.trim().isEmpty ? null : _notizen.text.trim(),
          leistungKw: _type == VehicleType.auto
              ? int.tryParse(_leistungKw.text.trim())
              : null,
          erstzulassungMonat: _type == VehicleType.auto ? _erstzulassungMonat : null,
          erstzulassungJahr: _type == VehicleType.auto
              ? int.tryParse(_erstzulassungJahr.text.trim())
              : null,
        );
        final fotoPfad = await _persistFoto(v.id, null);
        if (fotoPfad != null) {
          v.fotoPfad = fotoPfad;
          await provider.updateVehicle(v);
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
