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
      body: DecoratedBox(
        // A faint indigo halo behind the SOS area, echoing the brand artwork.
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.35), radius: 0.9, colors: [Color(0x1F4F46E5), Color(0x004F46E5)]),
        ),
        child: SafeArea(
          child: ListView(
            padding: ShaktiSpace.screen.copyWith(top: ShaktiSpace.sm, bottom: ShaktiSpace.xl),
            children: [
              _BrandBar(onSettings: () => context.go(Routes.settings)),
              const SizedBox(height: ShaktiSpace.lg),
              Semantics(header: true, child: Text(_greeting(ref.read(clockProvider).now(), settings.userName), style: t.headlineMedium)),
              const SizedBox(height: ShaktiSpace.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: _Status(settings: settings, activeContacts: active.length),
              ),
              if (contactsLoaded && active.isEmpty) ...[const SizedBox(height: ShaktiSpace.md), const _NoContactsWarning()],
              const SizedBox(height: ShaktiSpace.xs),
              Center(
                child: SosButton(
                  key: const ValueKey('sos-button'),
                  enabled: phase == PanicPhase.idle,
                  onPressed: () => ref.read(panicControllerProvider.notifier).trigger(TriggerSource.hudTap),
                ),
              ),
              Text(
                settings.powerTrigger
                    ? 'Or press the power button 3 times, even when locked.'
                    : 'Tap once. You get ${settings.countdownSeconds} seconds to cancel.',
                textAlign: TextAlign.center,
                style: t.bodyMedium,
              ),
              const SizedBox(height: ShaktiSpace.xl),
              const _QuickActions(),
              const SizedBox(height: ShaktiSpace.md),
              _Circle(contacts: active, total: contacts.value?.length ?? 0),
              const SizedBox(height: ShaktiSpace.md),
              const _Helplines(),
            ],
          ),
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

/// Wordmark row: the brand lockup on the left, trigger settings on the right.
class _BrandBar extends StatelessWidget {
  const _BrandBar({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ShaktiMark(size: 28, color: ShaktiColors.lilac),
        const SizedBox(width: ShaktiSpace.xs),
        Text('Shakti', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const Spacer(),
        IconButton(
          tooltip: 'Triggers and privacy settings',
          onPressed: onSettings,
          icon: const Icon(Icons.tune_rounded, color: ShaktiColors.textMid),
        ),
      ],
    );
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
      (Icons.directions_walk_rounded, 'Walk with me', 'Check-in timer for your walk', () => context.go(Routes.escort)),
      (Icons.phone_callback_rounded, 'Fake call', 'A believable reason to leave', () => context.push(Routes.fakeCall)),
      (Icons.share_location_rounded, 'Share location', 'Send where you are right now', () => _share(context, ref)),
      (Icons.campaign_rounded, 'Siren', 'Loud alarm and flashing light', () => context.push(Routes.siren)),
    ];
    final t = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth - ShaktiSpace.sm) / 2;
        return Wrap(
          spacing: ShaktiSpace.sm,
          runSpacing: ShaktiSpace.sm,
          children: [
            for (final (icon, label, hint, onTap) in actions)
              SizedBox(
                width: width,
                child: Semantics(
                  button: true,
                  label: label,
                  hint: hint,
                  excludeSemantics: true,
                  child: Material(
                    color: ShaktiColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ShaktiRadius.md),
                      side: BorderSide(color: ShaktiColors.outline.withValues(alpha: 0.7)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.all(ShaktiSpace.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: ShaktiColors.brand.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(ShaktiRadius.sm),
                              ),
                              child: Icon(icon, color: ShaktiColors.lilac, size: 20),
                            ),
                            const SizedBox(width: ShaktiSpace.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(label, style: t.titleSmall),
                                  const SizedBox(height: 2),
                                  Text(hint, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The trusted circle, drawn as the brand's guardian network.
class _Circle extends StatelessWidget {
  const _Circle({required this.contacts, required this.total});

  final List<EmergencyContact> contacts;
  final int total;

  static String _initial(String name) {
    final n = name.trim();
    return n.isEmpty ? '?' : n.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final names = contacts.map((c) => c.name.split(' ').first).take(3).join(', ');
    final more = contacts.length > 3 ? ' and ${contacts.length - 3} more' : '';
    final summary = contacts.isEmpty ? (total == 0 ? 'No one added yet' : 'All contacts are paused') : 'SOS goes to $names$more';
    final open = 5 - contacts.length;
    return ShaktiCard(
      semanticLabel: 'Trusted contacts. ${contacts.isEmpty ? 'None active' : '$names$more'}. Manage',
      onTap: () => context.push(Routes.contacts),
      child: Row(
        children: [
          GuardianNetwork(initials: [for (final c in contacts.take(5)) _initial(c.name)], size: 112),
          const SizedBox(width: ShaktiSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your circle', style: t.titleMedium),
                const SizedBox(height: 2),
                Text(summary, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: ShaktiSpace.sm),
                Text(open > 0 ? '${contacts.length} of 5 added' : 'Circle full', style: t.labelMedium?.copyWith(color: ShaktiColors.lilac)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: ShaktiColors.textLo),
        ],
      ),
    );
  }
}

class _Helplines extends StatelessWidget {
  const _Helplines();

  static const _lines = [('112', 'Emergency'), ('181', 'Women helpline'), ('1091', 'Women police'), ('1098', 'Child helpline')];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(ShaktiSpace.xxs, ShaktiSpace.xs, ShaktiSpace.xxs, ShaktiSpace.sm),
          child: Wrap(
            spacing: ShaktiSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Semantics(header: true, child: Text('Helplines', style: t.titleMedium)),
              Text('Free, 24 hours, from any phone', style: t.bodySmall),
            ],
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, (number, name)) in _lines.indexed) ...[
                if (i > 0) const SizedBox(width: ShaktiSpace.xs),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Call $number, $name',
                    excludeSemantics: true,
                    child: Material(
                      color: ShaktiColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ShaktiRadius.md),
                        side: BorderSide(color: ShaktiColors.outline.withValues(alpha: 0.7)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => launchUrl(Uri(scheme: 'tel', path: number)),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 72),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: ShaktiSpace.sm, horizontal: ShaktiSpace.xxs),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(number, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(name, style: t.bodySmall, textAlign: TextAlign.center, maxLines: 2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
