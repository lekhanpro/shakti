import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/entities.dart';

final incidentHistoryProvider = StreamProvider<List<Incident>>(
  (ref) => ref.watch(incidentRepositoryProvider).watchAll(),
);

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Incident history')),
    body: ShaktiBackdrop(
      child: ref
          .watch(incidentHistoryProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => EmptyState(
              icon: Icons.history_rounded,
              title: 'Could not load incidents.',
              message: 'Try loading the records on this phone again.',
              action: OutlinedButton.icon(
                onPressed: () => ref.invalidate(incidentHistoryProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ),
            data: (items) => ListView(
              padding: ShaktiSpace.screen.copyWith(bottom: ShaktiSpace.xl),
              children: [
                const ShaktiPageHeader(
                  title: 'A record of each alert.',
                  subtitle: 'Local incident history and dispatch status.',
                ),
                if (items.isEmpty)
                  ShaktiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 32,
                          color: context.shakti.lilac,
                        ),
                        const SizedBox(height: ShaktiSpace.md),
                        Text(
                          'No incidents recorded on this phone.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: ShaktiSpace.xs),
                        const Text(
                          'When an SOS is activated, its time, trigger and dispatch results appear here.',
                        ),
                      ],
                    ),
                  ),
                for (final incident in items) ...[
                  _IncidentRecord(incident: incident),
                  const SizedBox(height: ShaktiSpace.sm),
                ],
                if (items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: ShaktiSpace.xs),
                    child: Text(
                      'A carrier handoff or cloud acknowledgement does not confirm that a guardian received or read an alert.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
    ),
  );
}

class _IncidentRecord extends StatelessWidget {
  const _IncidentRecord({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final i = incident;
    final local = i.createdAt.toLocal();
    final labels = MaterialLocalizations.of(context);
    final (status, color, icon) = switch (i.status) {
      IncidentStatus.countdown => (
        'Countdown',
        context.shakti.warn,
        Icons.timer_outlined,
      ),
      IncidentStatus.active => (
        'Active',
        context.shakti.sos,
        Icons.emergency_share_outlined,
      ),
      IncidentStatus.resolved => (
        'Resolved',
        context.shakti.safe,
        Icons.check_circle_outline_rounded,
      ),
      IncidentStatus.falseAlarm => (
        'False alarm',
        context.shakti.textMid,
        Icons.check_circle_outline_rounded,
      ),
    };
    return ShaktiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: ShaktiSpace.xs,
            runSpacing: ShaktiSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              Text(status, style: t.labelLarge?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: ShaktiSpace.sm),
          Text(i.source.label, style: t.titleLarge),
          const SizedBox(height: ShaktiSpace.xxs),
          Text(
            '${labels.formatShortDate(local)} · ${labels.formatTimeOfDay(TimeOfDay.fromDateTime(local))}',
            style: t.bodySmall,
          ),
          const Divider(height: ShaktiSpace.lg),
          _DispatchLine(
            icon: Icons.sms_outlined,
            label: 'SMS: ${i.smsDispatched ? "handed off" : "not confirmed"}',
          ),
          const SizedBox(height: ShaktiSpace.xs),
          _DispatchLine(
            icon: Icons.cloud_outlined,
            label:
                'Cloud: ${i.cloudDispatched ? "acknowledged" : "not confirmed"}',
          ),
          const SizedBox(height: ShaktiSpace.sm),
          Text(
            i.synced ? 'Backed up to cloud' : 'Stored locally; sync pending',
            style: t.bodySmall,
          ),
          if (i.address != null) ...[
            const SizedBox(height: ShaktiSpace.sm),
            _DispatchLine(icon: Icons.place_outlined, label: i.address!),
          ],
        ],
      ),
    );
  }
}

class _DispatchLine extends StatelessWidget {
  const _DispatchLine({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: context.shakti.textLo),
      const SizedBox(width: ShaktiSpace.xs),
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}
