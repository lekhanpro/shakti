import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/entities.dart';
import '../../home/application/home_providers.dart';
import 'contact_form.dart';

const maxContacts = 5;

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(liveContactsProvider);
    final list = contacts.value ?? const <EmergencyContact>[];
    final canAdd = list.length < maxContacts;

    return Scaffold(
      appBar: AppBar(title: const Text('Trusted contacts')),
      floatingActionButton: canAdd && list.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => showContactSheet(context, ref, existing: list),
              backgroundColor: ShaktiColors.actionDeep,
              foregroundColor: ShaktiColors.textHi,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add contact'),
            )
          : null,
      body: switch (contacts) {
        AsyncValue(:final error?) when list.isEmpty => EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Contacts could not load',
            message: '$error',
          ),
        AsyncValue(isLoading: true) when list.isEmpty => const Center(child: CircularProgressIndicator()),
        _ when list.isEmpty => EmptyState(
            icon: Icons.group_add_outlined,
            title: 'No one will get your SOS yet',
            message: 'Add up to $maxContacts people. They get an SMS with your location when you raise an SOS, even offline.',
            action: FilledButton.icon(
              onPressed: () => showContactSheet(context, ref, existing: list),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add a trusted contact'),
            ),
          ),
        _ => ListView(
            padding: ShaktiSpace.screen.copyWith(bottom: 120),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: ShaktiSpace.xs, bottom: ShaktiSpace.md),
                child: Text(
                  canAdd
                      ? 'SOS messages go to every active contact. ${list.length} of $maxContacts used.'
                      : 'All $maxContacts slots used. Remove someone to add another.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              for (final c in list) ...[
                _ContactTile(contact: c, all: list),
                const SizedBox(height: ShaktiSpace.xs),
              ],
            ],
          ),
      },
    );
  }
}

class _ContactTile extends ConsumerWidget {
  const _ContactTile({required this.contact, required this.all});

  final EmergencyContact contact;
  final List<EmergencyContact> all;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(contactRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.delete(contact.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('${contact.name} removed'),
        action: SnackBarAction(label: 'Undo', onPressed: () => repo.upsert(contact)),
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final c = contact;
    return Dismissible(
      key: ValueKey('contact-${c.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: ShaktiSpace.lg),
        decoration: BoxDecoration(
          color: ShaktiColors.sos.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(ShaktiRadius.card),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.delete_outline_rounded, color: ShaktiColors.sosGlow), SizedBox(width: 6), Text('Remove')],
        ),
      ),
      onDismissed: (_) => _delete(context, ref),
      child: ShaktiCard(
        padding: const EdgeInsets.fromLTRB(ShaktiSpace.md, ShaktiSpace.sm, ShaktiSpace.xs, ShaktiSpace.sm),
        child: Semantics(
          customSemanticsActions: {
            const CustomSemanticsAction(label: 'Edit'): () => showContactSheet(context, ref, existing: all, editing: c),
            const CustomSemanticsAction(label: 'Remove'): () => _delete(context, ref),
          },
          child: Row(
            children: [
              _PriorityBadge(priority: c.priority, active: c.isActive),
              const SizedBox(width: ShaktiSpace.sm),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(ShaktiRadius.sm),
                  onTap: () => showContactSheet(context, ref, existing: all, editing: c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: ShaktiSpace.xxs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: t.titleMedium, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${c.relationship}, ${c.phone}', style: t.bodySmall, overflow: TextOverflow.ellipsis),
                        if (!c.isActive)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('Paused. Won\'t get SOS messages', style: t.bodySmall?.copyWith(color: ShaktiColors.warn)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Semantics(
                label: c.isActive ? 'Receives SOS' : 'Paused',
                child: Switch(
                  value: c.isActive,
                  onChanged: (v) => ref.read(contactRepositoryProvider).upsert(c.copyWith(isActive: v)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority, required this.active});

  final int priority;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? (priority == 1 ? ShaktiColors.safe : ShaktiColors.action) : ShaktiColors.textLo;
    return Semantics(
      label: 'Priority $priority',
      excludeSemantics: true,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Text('$priority', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
      ),
    );
  }
}

/// Add / edit sheet. Also offers "Test SMS" for an existing contact.
Future<void> showContactSheet(
  BuildContext context,
  WidgetRef ref, {
  required List<EmergencyContact> existing,
  EmergencyContact? editing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        ShaktiSpace.lg,
        0,
        ShaktiSpace.lg,
        ShaktiSpace.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(editing == null ? 'Add a trusted contact' : 'Edit ${editing.name}',
                  style: Theme.of(sheetContext).textTheme.headlineSmall),
            ),
            const SizedBox(height: ShaktiSpace.lg),
            ContactForm(
              initial: editing,
              existingPhones: {for (final c in existing) c.phone},
              submitLabel: editing == null ? 'Add contact' : 'Save changes',
              onSubmit: (d) async {
                final repo = ref.read(contactRepositoryProvider);
                final contact = editing?.copyWith(name: d.name, phone: d.phone, relationship: d.relationship) ??
                    EmergencyContact(
                      id: const Uuid().v4(),
                      name: d.name,
                      phone: d.phone,
                      relationship: d.relationship,
                      priority: _nextPriority(existing),
                    );
                await repo.upsert(contact);
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
            if (editing != null) ...[
              const SizedBox(height: ShaktiSpace.sm),
              OutlinedButton.icon(
                onPressed: () => _testSms(sheetContext, ref, editing),
                icon: const Icon(Icons.sms_outlined),
                label: const Text('Send test SMS'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

int _nextPriority(List<EmergencyContact> existing) {
  final used = {for (final c in existing) c.priority};
  for (var p = 1; p <= maxContacts; p++) {
    if (!used.contains(p)) return p;
  }
  return maxContacts;
}

Future<void> _testSms(BuildContext context, WidgetRef ref, EmergencyContact c) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('Send a test SMS?'),
      content: Text('${c.name} gets one message saying this is a test from Shakti. Carrier charges may apply.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Not now')),
        FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Send test')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final settings = await ref.read(settingsRepositoryProvider).load();
  final from = settings.userName.trim().isEmpty ? 'Your contact' : settings.userName.trim();
  final result = await ref.read(smsServiceProvider).sendToAll(
    [c.phone],
    'Test from Shakti: $from added you as a trusted contact. If they ever send an SOS you will get their location here. No action needed.',
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(result.when(ok: (n) => n > 0 ? 'Test SMS sent to ${c.name}' : 'The carrier did not accept the SMS', err: (m) => 'Test SMS failed: $m')),
  ));
}
