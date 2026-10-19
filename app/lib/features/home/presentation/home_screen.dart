import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/sos_button.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/entities.dart';
import '../../panic/application/panic_controller.dart';
import '../../panic/application/panic_view_state.dart';
import '../../panic/application/trigger_hub.dart';
import '../application/home_providers.dart';
import '../application/startup.dart';

/// The Shield tab. One job: make SOS obvious and one tap away, and show
/// honestly whether an SOS would actually reach anyone.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Moves the gate to emergency on countdown / active, back on acknowledge.
    ref.watch(panicGateSyncProvider);
    final settings = ref.watch(liveSettingsProvider).value ?? const SafetySettings();
    final contacts = ref.watch(liveContactsProvider);
    final active = (contacts.value ?? const <EmergencyContact>[]).where((c) => c.isActive).toList();
    final contactsLoaded = contacts.hasValue;
    final phase = ref.watch(panicControllerProvider.select((s) => s.phase));
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: ShaktiSpace.screen.copyWith(top: ShaktiSpace.md, bottom: ShaktiSpace.xl),
          children: [
            Semantics(
              header: true,
              child: Text(_greeting(ref.read(clockProvider).now(), settings.userName), style: t.headlineMedium),
            ),
            const SizedBox(height: ShaktiSpace.xs),
            Align(alignment: Alignment.centerLeft, child: _Status(settings: settings, activeContacts: active.length)),
            if (contactsLoaded && active.isEmpty) ...[
              const SizedBox(height: ShaktiSpace.md),
              const _NoContactsWarning(),
            ],
            const SizedBox(height: ShaktiSpace.md),
            Center(
              child: SosButton(
                key: const ValueKey('sos-button'),
                enabled: phase == PanicPhase.idle,
                onPressed: () => ref.read(panicControllerProvider.notifier).trigger(TriggerSource.hudTap),
              ),
            ),
            Text(
              settings.powerTrigger ? 'Or press the power button 3 times, even when locked.' : 'Tap once. You get ${settings.countdownSeconds} seconds to cancel.',
              textAlign: TextAlign.center,
              style: t.bodyMedium,
            ),
            const SizedBox(height: ShaktiSpace.lg),
            const _QuickActions(),
            const SizedBox(height: ShaktiSpace.lg),
            _ContactsSummary(contacts: active, total: contacts.value?.length ?? 0),
            const SizedBox(height: ShaktiSpace.sm),
            const _Helplines(),
          ],
        ),
      ),
    );
  }

  static String _greeting(DateTime now, String name) {
    final h = now.hour;
    final part = h < 5
        ? 'Stay safe tonight'
        : h < 12
            ? 'Good morning'
            : h < 17
                ? 'Good afternoon'
                : h < 21
                    ? 'Good evening'
                    : 'Stay safe tonight';
    final n = name.trim().split(' ').first;
    return n.isEmpty ? part : '$part, $n';
  }
}

class _Status extends ConsumerWidget {
  const _Status({required this.settings, required this.activeContacts});

  final SafetySettings settings;
  final int activeContacts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(triggerHubProvider);
    final parts = <String>[
      '$activeContacts ${activeContacts == 1 ? 'contact' : 'contacts'}',
      if (settings.powerTrigger) 'Power ×3 on',
      if (settings.shakeTrigger && hub.shake) 'Shake on',
      if (settings.voiceTrigger && hub.voice) 'Voice on',
    ];
    if (activeContacts == 0) return StatusPill.warn('Not protected, ${parts.first}');
    return StatusPill.safe('Protected · ${parts.join(' · ')}');
  }
}

class _NoContactsWarning extends StatelessWidget {
  const _NoContactsWarning();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ShaktiCard(
      key: const ValueKey('no-contacts-warning'),
      color: ShaktiColors.warn.withValues(alpha: 0.12),
      borderColor: ShaktiColors.warn.withValues(alpha: 0.6),
      semanticLabel: "Add a trusted contact, or SOS can't send SMS",
      onTap: () => context.push(Routes.contacts),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: ShaktiColors.warn, size: 28),
          const SizedBox(width: ShaktiSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Add a trusted contact, or SOS can't send SMS", style: t.titleMedium),
                const SizedBox(height: 2),
                Text('Takes 20 seconds. Works offline.', style: t.bodySmall?.copyWith(color: ShaktiColors.textMid)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: ShaktiColors.warn),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final fix = await ref.read(locationServiceProvider).currentFix();
    final point = fix.valueOrNull?.point;
    if (point == null) {
      messenger.showSnackBar(const SnackBar(content: Text('No location yet. Step outside or turn on GPS, then try again')));
      return;
    }
    try {
      await SharePlus.instance.share(ShareParams(text: 'My current location: ${point.mapsUrl}', subject: 'My location'));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Sharing is not available on this device')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      (Icons.phone_callback_rounded, 'Fake call', () => context.push(Routes.fakeCall)),
      (Icons.campaign_rounded, 'Siren', () => context.push(Routes.siren)),
      (Icons.directions_walk_rounded, 'Walk with me', () => context.go(Routes.escort)),
      (Icons.share_location_rounded, 'Share location', () => _share(context, ref)),
    ];
    return Row(
      children: [
        for (final (icon, label, onTap) in actions)
          Expanded(
            child: Semantics(
              button: true,
              label: label,
              excludeSemantics: true,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(ShaktiRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: ShaktiSpace.xs),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: ShaktiColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(ShaktiRadius.md),
                        ),
                        child: Icon(icon, color: ShaktiColors.textHi),
                      ),
                      const SizedBox(height: ShaktiSpace.xs),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ContactsSummary extends StatelessWidget {
  const _ContactsSummary({required this.contacts, required this.total});

  final List<EmergencyContact> contacts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final names = contacts.map((c) => c.name.split(' ').first).take(3).join(', ');
    final more = contacts.length > 3 ? ' and ${contacts.length - 3} more' : '';
    return ShaktiCard(
      semanticLabel: 'Trusted contacts. ${contacts.isEmpty ? 'None active' : '$names$more'}. Manage',
      onTap: () => context.push(Routes.contacts),
      child: Row(
        children: [
          const Icon(Icons.group_rounded, color: ShaktiColors.action),
          const SizedBox(width: ShaktiSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trusted contacts', style: t.titleMedium),
                Text(
                  contacts.isEmpty ? (total == 0 ? 'No one added yet' : 'All contacts are paused') : 'SOS goes to $names$more',
                  style: t.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text('${contacts.length}/5', style: t.labelMedium),
          const Icon(Icons.chevron_right_rounded, color: ShaktiColors.textLo),
        ],
      ),
    );
  }
}

class _Helplines extends StatelessWidget {
  const _Helplines();

  static const _lines = [
    ('112', 'Emergency'),
    ('181', 'Women helpline'),
    ('1091', 'Women police'),
    ('1098', 'Child helpline'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ShaktiCard(
      padding: const EdgeInsets.fromLTRB(ShaktiSpace.md, ShaktiSpace.md, ShaktiSpace.md, ShaktiSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text('Helplines', style: t.titleMedium)),
          Text('Free, 24 hours, from any phone', style: t.bodySmall),
          const SizedBox(height: ShaktiSpace.xs),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.6,
            children: [
              for (final (number, name) in _lines)
                Semantics(
                  button: true,
                  label: 'Call $number, $name',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(ShaktiRadius.sm),
                    onTap: () => launchUrl(Uri(scheme: 'tel', path: number)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: ShaktiSpace.xs),
                      child: Row(
                        children: [
                          const Icon(Icons.call_outlined, size: 20, color: ShaktiColors.safe),
                          const SizedBox(width: ShaktiSpace.xs),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(number, style: t.titleMedium?.copyWith(fontFamily: ShaktiFonts.heading)),
                                Text(name, style: t.bodySmall, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
