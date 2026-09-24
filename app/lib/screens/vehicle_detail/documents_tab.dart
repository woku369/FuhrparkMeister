import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/vehicle.dart';
import '../../models/vehicle_document.dart';
import '../../providers/fuhrpark_provider.dart';
import '../../services/document_storage.dart';
import '../../widgets/date_format_x.dart';
import '../../widgets/empty_state.dart';

const _uuid = Uuid();

class DocumentsTab extends StatefulWidget {
  final Vehicle vehicle;

  const DocumentsTab({super.key, required this.vehicle});

  @override
  State<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<DocumentsTab> {
  late Future<List<VehicleDocument>> _future;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<FuhrparkProvider>().documentsFor(widget.vehicle.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<VehicleDocument>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!;
          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.photo_library_outlined,
              text:
                  'Noch keine Dokumente.\nFüge Fotos von Zulassungsschein, '
                  'Polizze & Co. hinzu.',
              actionLabel: 'Foto hinzufügen',
              onAction: _addDocument,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                return GestureDetector(
                  onTap: () => _openViewer(doc),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: FutureBuilder<String>(
                          future: DocumentStorage.absolutePath(doc.dateipfad),
                          builder: (context, snap) {
                            if (!snap.hasData) return const SizedBox.shrink();
                            return Image.file(
                              File(snap.data!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          color: Colors.black54,
                          child: Text(
                            doc.kategorie.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDocument,
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }

  Future<void> _addDocument() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Foto aufnehmen'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Aus Galerie wählen'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    final meta = await showDialog<_DocumentMeta>(
      context: context,
      builder: (_) => const _DocumentMetaDialog(),
    );
    if (meta == null) return;

    final targetDir = await DocumentStorage.vehicleDir(widget.vehicle.id);
    final ext = p.extension(picked.path);
    final fileName = '${_uuid.v4()}$ext';
    final targetPath = p.join(targetDir.path, fileName);
    await File(picked.path).copy(targetPath);

    final document = VehicleDocument(
      id: _uuid.v4(),
      vehicleId: widget.vehicle.id,
      kategorie: meta.kategorie,
      dateipfad: '${widget.vehicle.id}/$fileName',
      titel: meta.titel,
      erstelltAm: DateTime.now(),
    );
    if (!mounted) return;
    await context.read<FuhrparkProvider>().addDocument(document);
    if (mounted) setState(_reload);
  }

  void _openViewer(VehicleDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _DocumentViewer(document: doc)),
    );
  }
}

class _DocumentMeta {
  final DocumentCategory kategorie;
  final String titel;

  _DocumentMeta(this.kategorie, this.titel);
}

class _DocumentMetaDialog extends StatefulWidget {
  const _DocumentMetaDialog();

  @override
  State<_DocumentMetaDialog> createState() => _DocumentMetaDialogState();
}

class _DocumentMetaDialogState extends State<_DocumentMetaDialog> {
  DocumentCategory _kategorie = DocumentCategory.zulassungsschein;
  final _titel = TextEditingController();

  @override
  void dispose() {
    _titel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dokument speichern'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<DocumentCategory>(
            initialValue: _kategorie,
            decoration: const InputDecoration(labelText: 'Kategorie'),
            items: DocumentCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (c) => setState(() => _kategorie = c ?? _kategorie),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titel,
            decoration: const InputDecoration(labelText: 'Titel (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _DocumentMeta(
              _kategorie,
              _titel.text.trim().isEmpty ? _kategorie.label : _titel.text.trim(),
            ),
          ),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

class _DocumentViewer extends StatelessWidget {
  final VehicleDocument document;

  const _DocumentViewer({required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(document.titel),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await context.read<FuhrparkProvider>().deleteDocument(document.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<String>(
              future: DocumentStorage.absolutePath(document.dateipfad),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                return InteractiveViewer(child: Image.file(File(snap.data!)));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${document.kategorie.label} · ${document.erstelltAm.deDate}',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
