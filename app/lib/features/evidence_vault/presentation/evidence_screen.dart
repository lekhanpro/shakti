import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/entities/entities.dart';

final evidenceItemsProvider = FutureProvider.autoDispose<List<EvidenceItem>>(
    (ref) => ref.watch(audioEvidenceServiceProvider).list());

class EvidenceScreen extends ConsumerWidget {
  const EvidenceScreen({super.key});
  Future<void> _share(BuildContext context, WidgetRef ref, EvidenceItem item) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Export decrypted audio?'),
      content: const Text('The recipient will receive a readable audio file. Only share with someone you trust.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Share'))]));
    if (confirmed != true || !context.mounted) return;
    try {
      final result = await ref.read(evidenceExportServiceProvider).share(item.path);
      result.when(ok: (_) {}, err: (message) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      });
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to export this recording.')));
    }
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Evidence vault'), actions: [IconButton(
      tooltip: 'Refresh recordings', onPressed: () => ref.invalidate(evidenceItemsProvider), icon: const Icon(Icons.refresh))]),
    body: ref.watch(evidenceItemsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Recordings could not be loaded.')),
      data: (items) => items.isEmpty ? const Center(child: Text('No encrypted recordings yet.')) : ListView(
        padding: ShaktiSpace.screen, children: [
          const Padding(padding: EdgeInsets.symmetric(vertical: ShaktiSpace.md), child: Text('Encrypted on this phone. Sharing exports a decrypted copy.')),
          for (final item in items) Card(child: ListTile(
            leading: const Icon(Icons.enhanced_encryption_outlined),
            title: Text(item.createdAt.toLocal().toString()),
            subtitle: Text('${(item.sizeBytes / 1024).toStringAsFixed(1)} KB'),
            trailing: IconButton(tooltip: 'Share recording', icon: const Icon(Icons.share_outlined), onPressed: () => _share(context, ref, item)),
          )),
        ]),
    ),
  );
}
