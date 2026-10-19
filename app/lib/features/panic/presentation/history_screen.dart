import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/entities/entities.dart';

final incidentHistoryProvider = StreamProvider<List<Incident>>((ref) =>
    ref.watch(incidentRepositoryProvider).watchAll());

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Incident history')),
    body: ref.watch(incidentHistoryProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Could not load incidents. Try reopening this screen.')),
      data: (items) => items.isEmpty
          ? const Center(child: Text('No incidents recorded on this phone.'))
          : ListView.builder(padding: ShaktiSpace.screen, itemCount: items.length,
              itemBuilder: (context, index) {
                final i = items[index];
                return Card(child: Padding(padding: const EdgeInsets.all(ShaktiSpace.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i.source.label, style: Theme.of(context).textTheme.titleMedium),
                    Text('${i.createdAt.toLocal()} - ${i.status.name}'),
                    Text('SMS: ${i.smsDispatched ? "handed off" : "not confirmed"}'),
                    Text('Cloud: ${i.cloudDispatched ? "acknowledged" : "not confirmed"}'),
                    Text(i.synced ? 'Backed up to cloud' : 'Stored locally; sync pending'),
                    if (i.address != null) Text(i.address!),
                  ])));
              }),
    ),
  );
}
