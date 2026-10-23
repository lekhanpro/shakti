import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/entities.dart';

final evidenceItemsProvider = FutureProvider.autoDispose<List<EvidenceItem>>(
  (ref) => ref.watch(audioEvidenceServiceProvider).list(),
);

class EvidenceScreen extends ConsumerWidget {
  const EvidenceScreen({super.key});
  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    EvidenceItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Export decrypted audio?'),
        content: const Text(
          'The recipient will receive a readable audio file. Only share with someone you trust.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final result = await ref
          .read(evidenceExportServiceProvider)
          .share(item.path);
      result.when(
        ok: (_) {},
        err: (message) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          }
        },
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to export this recording.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Evidence vault'),
      actions: [
        IconButton(
          tooltip: 'Refresh recordings',
          onPressed: () => ref.invalidate(evidenceItemsProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ShaktiBackdrop(
      child: ref
          .watch(evidenceItemsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Recordings could not be loaded.',
              message: 'Try refreshing the vault. Your recordings stay on this phone.',
              action: OutlinedButton.icon(
                onPressed: () => ref.invalidate(evidenceItemsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ),
            data: (items) => ListView(
              padding: ShaktiSpace.screen.copyWith(bottom: ShaktiSpace.xl),
              children: [
                const ShaktiPageHeader(
                  title: 'Your recordings.',
                  subtitle:
                      'Encrypted on this phone. Shared only when you choose.',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: ShaktiSpace.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.enhanced_encryption_outlined,
                        color: context.shakti.lilac,
                        size: 28,
                      ),
                      const SizedBox(width: ShaktiSpace.sm),
                      Expanded(
                        child: Text(
                          'Sharing exports a decrypted copy. Your original stays encrypted on this phone.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                SectionHeader('Recordings · ${items.length}'),
                if (items.isEmpty)
                  ShaktiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          color: context.shakti.textLo,
                          size: 32,
                        ),
                        const SizedBox(height: ShaktiSpace.sm),
                        Text(
                          'No encrypted recordings yet.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: ShaktiSpace.xs),
                        const Text(
                          'Enable Record evidence in Settings to capture audio during an SOS. Recording requires microphone permission.',
                        ),
                      ],
                    ),
                  ),
                for (final item in items) ...[
                  ShaktiCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.shakti.accentContainer,
                            borderRadius: BorderRadius.circular(
                              ShaktiRadius.md,
                            ),
                          ),
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            color: context.shakti.lilac,
                          ),
                        ),
                        const SizedBox(width: ShaktiSpace.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                MaterialLocalizations.of(context)
                                    .formatShortDate(item.createdAt.toLocal()),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: ShaktiSpace.xxs),
                              Text(
                                MaterialLocalizations.of(context)
                                    .formatTimeOfDay(
                                      TimeOfDay.fromDateTime(
                                        item.createdAt.toLocal(),
                                      ),
                                    ),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '${(item.sizeBytes / 1024).toStringAsFixed(1)} KB · Encrypted',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Share recording',
                          icon: const Icon(Icons.share_outlined),
                          constraints: const BoxConstraints(
                            minWidth: ShaktiSize.minTap,
                            minHeight: ShaktiSize.minTap,
                          ),
                          onPressed: () => _share(context, ref, item),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ShaktiSpace.sm),
                ],
              ],
            ),
          ),
    ),
  );
}
