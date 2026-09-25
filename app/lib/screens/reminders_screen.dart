import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder.dart';
import '../providers/fuhrpark_provider.dart';
import '../widgets/date_format_x.dart';
import '../widgets/empty_state.dart';
import 'vehicle_detail_screen.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FuhrparkProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Anstehende Termine')),
      body: FutureBuilder<List<Reminder>>(
        future: provider.getUpcomingReminders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reminders = snapshot.data!;
          if (reminders.isEmpty) {
            return const EmptyState(
              icon: Icons.event_available,
              text: 'Keine offenen Termine.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = reminders[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _colorFor(r).withValues(alpha: 0.15),
                    child: Icon(_iconFor(r.source), color: _colorFor(r)),
                  ),
                  title: Text('${r.vehicleName} · ${r.titel}'),
                  subtitle: Text(_subtitleFor(r)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          VehicleDetailScreen(vehicleId: r.vehicleId),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(ReminderSource source) {
    switch (source) {
      case ReminderSource.inspection:
        return Icons.fact_check_outlined;
      case ReminderSource.vignette:
        return Icons.confirmation_number_outlined;
      case ReminderSource.insurance:
        return Icons.shield_outlined;
      case ReminderSource.tire:
        return Icons.tire_repair_outlined;
      case ReminderSource.maintenance:
        return Icons.build_outlined;
    }
  }

  Color _colorFor(Reminder r) {
    if (r.istUeberfaellig) return Colors.red;
    if (r.tageBisFaellig <= 30) return Colors.orange;
    return Colors.green;
  }

  String _subtitleFor(Reminder r) {
    final datum = r.faelligAm.deDate;
    if (r.istUeberfaellig) {
      return 'Überfällig seit $datum';
    }
    return 'Fällig am $datum · in ${r.tageBisFaellig} Tagen';
  }
}
