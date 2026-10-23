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
    final settings =
        ref.watch(liveSettingsProvider).value ?? const SafetySettings();
    final contacts = ref.watch(liveContactsProvider);
    final active = (contacts.value ?? const <EmergencyContact>[])
        .where((c) => c.isActive)
        .toList();
    final contactsLoaded = contacts.hasValue;
    final phase = ref.watch(panicControllerProvider.select((s) => s.phase));
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: ShaktiSpace.screen.copyWith(
            top: ShaktiSpace.md,
            bottom: ShaktiSpace.dockClearance,
          ),
          children: [
            _BrandBar(onSettings: () => context.go(Routes.settings)),
            const SizedBox(height: ShaktiSpace.md),
            Semantics(
              header: true,
              child: Text(
                _greeting(ref.read(clockProvider).now(), settings.userName),
                style:
                    MediaQuery.sizeOf(context).width < 360 &&
                        MediaQuery.textScalerOf(context).scale(28) > 40
                    ? t.headlineSmall
                    : t.headlineLarge,
              ),
            ),
            const SizedBox(height: ShaktiSpace.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: _Status(settings: settings, activeContacts: active.length),
            ),
            if (contactsLoaded && active.isEmpty) ...[
              const SizedBox(height: ShaktiSpace.md),
              const _NoContactsWarning(),
            ],
            if (active.isNotEmpty) _CirclePreview(contacts: active),
            const SizedBox(height: ShaktiSpace.xs),
            Center(
              child: SosButton(
                key: const ValueKey('sos-button'),
                enabled: phase == PanicPhase.idle,
                onPressed: () => ref
                    .read(panicControllerProvider.notifier)
                    .trigger(TriggerSource.hudTap),
              ),
            ),
            Text(
              settings.powerTrigger
                  ? 'Power ×3 is also enabled. Test this gesture on your phone.'
                  : 'Tap once. You get ${settings.countdownSeconds} seconds to cancel.',
              textAlign: TextAlign.center,
              style: t.bodySmall,
            ),
            const SizedBox(height: ShaktiSpace.md),
            const _QuickActions(),
            const SizedBox(height: ShaktiSpace.lg),
            _Circle(contacts: active, total: contacts.value?.length ?? 0),
            const SizedBox(height: ShaktiSpace.lg),
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

/// Wordmark row: the brand lockup on the left, trigger settings on the right.
class _BrandBar extends StatelessWidget {
  const _BrandBar({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShaktiMark(size: 32, color: context.shakti.lilac),
        const SizedBox(width: ShaktiSpace.xs),
        Expanded(
          child: Text(
            'Shakti',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
        ),
        IconButton(
          tooltip: 'Triggers and privacy settings',
          onPressed: onSettings,
          icon: Icon(Icons.tune_rounded, color: context.shakti.textMid),
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.settings, required this.activeContacts});

  final SafetySettings settings;
  final int activeContacts;

  @override
  Widget build(BuildContext context) {
    final count =
        '$activeContacts ${activeContacts == 1 ? 'contact' : 'contacts'}';
    return activeContacts == 0
        ? StatusPill.warn('Not protected, $count', wrap: true)
        : StatusPill.safe('$count in your circle', wrap: true);
  }
}

/// A real-contact preview remains visible above the emergency control.
class _CirclePreview extends StatelessWidget {
  const _CirclePreview({required this.contacts});
  final List<EmergencyContact> contacts;

  @override
  Widget build(BuildContext context) {
    final names = contacts
        .take(2)
        .map((c) => c.name.trim().split(' ').first)
        .join(' · ');
    final more = contacts.length > 2 ? ' +${contacts.length - 2}' : '';
    return Semantics(
      button: true,
      label: 'Your circle: $names$more. Manage trusted contacts',
      onTap: () => context.push(Routes.contacts),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(Routes.contacts),
        borderRadius: BorderRadius.circular(ShaktiRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ShaktiSize.minTap),
          child: Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 20,
                color: context.shakti.lilac,
              ),
              const SizedBox(width: ShaktiSpace.xs),
              Expanded(
                child: Text(
                  '$names$more',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.shakti.textLo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoContactsWarning extends StatelessWidget {
  const _NoContactsWarning();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ShaktiCard(
      key: const ValueKey('no-contacts-warning'),
      color: context.shakti.warningContainer,
      borderColor: context.shakti.outline,
      semanticLabel: "Add a trusted contact, or SOS can't send SMS",
      onTap: () => context.push(Routes.contacts),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: context.shakti.warn,
            size: 28,
          ),
          const SizedBox(width: ShaktiSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add a trusted contact, or SOS can't send SMS",
                  style: t.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Takes 20 seconds. Works offline.',
                  style: t.bodySmall?.copyWith(color: context.shakti.textMid),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.shakti.warn),
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
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No location yet. Step outside or turn on GPS, then try again',
          ),
        ),
      );
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'My current location: ${point.mapsUrl}',
          subject: 'My location',
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sharing is not available on this device'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final primary = [
      (
        Icons.directions_walk_rounded,
        'Walk with me',
        'A check-in timer',
        () => context.go(Routes.escort),
      ),
      (
        Icons.phone_callback_outlined,
        'Fake call',
        'A reason to leave',
        () => context.push(Routes.fakeCall),
      ),
    ];
    Widget action(
      IconData icon,
      String label,
      String hint,
      VoidCallback onTap,
    ) => Semantics(
      button: true,
      label: label,
      hint: hint,
      onTap: onTap,
      excludeSemantics: true,
      child: GlassSurface(
        blur: true,
        clear: true,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: context.shakti.accent, size: 24),
            const SizedBox(height: ShaktiSpace.sm),
            Text(label, style: t.titleSmall),
            const SizedBox(height: ShaktiSpace.xxs),
            Text(
              hint,
              style: t.bodySmall?.copyWith(color: context.shakti.textHi),
            ),
          ],
        ),
      ),
    );
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final columns =
                box.maxWidth >= 300 &&
                    MediaQuery.textScalerOf(context).scale(14) <= 20
                ? 2
                : 1;
            final width =
                (box.maxWidth - (columns - 1) * ShaktiSpace.sm) / columns;
            return Wrap(
              spacing: ShaktiSpace.sm,
              runSpacing: ShaktiSpace.sm,
              children: [
                for (final (icon, label, hint, onTap) in primary)
                  SizedBox(
                    width: width,
                    child: action(icon, label, hint, onTap),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: ShaktiSpace.xs),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: ShaktiSpace.md,
          children: [
            Semantics(
              label: 'Share location',
              button: true,
              onTap: () => _share(context, ref),
              excludeSemantics: true,
              child: TextButton.icon(
                onPressed: () => _share(context, ref),
                icon: const Icon(Icons.share_location_outlined, size: 20),
                label: const Text('Share location'),
              ),
            ),
            Semantics(
              label: 'Siren',
              button: true,
              onTap: () => context.push(Routes.siren),
              excludeSemantics: true,
              child: TextButton.icon(
                onPressed: () => context.push(Routes.siren),
                icon: const Icon(Icons.campaign_outlined, size: 20),
                label: const Text('Siren'),
              ),
            ),
          ],
        ),
      ],
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
    final names = contacts
        .map((c) => c.name.split(' ').first)
        .take(3)
        .join(', ');
    final more = contacts.length > 3 ? ' and ${contacts.length - 3} more' : '';
    final summary = contacts.isEmpty
        ? (total == 0 ? 'No one added yet' : 'All contacts are paused')
        : 'SOS goes to $names$more';
    return ShaktiCard(
      semanticLabel:
          'Trusted contacts. ${contacts.isEmpty ? 'None active' : '$names$more'}. Manage',
      onTap: () => context.push(Routes.contacts),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: context.shakti.accentContainer,
            foregroundColor: context.shakti.accent,
            child: contacts.isEmpty
                ? const Icon(Icons.people_outline_rounded)
                : Text(
                    _initial(contacts.first.name),
                    style: t.titleMedium?.copyWith(
                      color: context.shakti.accent,
                    ),
                  ),
          ),
          const SizedBox(width: ShaktiSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your circle', style: t.titleMedium),
                const SizedBox(height: 2),
                Text(
                  summary,
                  style: t.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: ShaktiSpace.sm),
                Text(
                  '$total of 5 added · ${contacts.length} active',
                  style: t.labelMedium?.copyWith(color: context.shakti.lilac),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.shakti.textLo),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ShaktiSpace.xxs,
            ShaktiSpace.xs,
            ShaktiSpace.xxs,
            ShaktiSpace.sm,
          ),
          child: Wrap(
            spacing: ShaktiSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Semantics(
                header: true,
                child: Text('Helplines', style: t.titleMedium),
              ),
              Text('Free, 24 hours, from any phone', style: t.bodySmall),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, box) {
            final minWidth =
                80 * MediaQuery.textScalerOf(context).scale(18) / 18;
            final columns = box.maxWidth >= 4 * minWidth + 3 * ShaktiSpace.xs
                ? 4
                : box.maxWidth >= 2 * minWidth + ShaktiSpace.xs
                ? 2
                : 1;
            final width =
                (box.maxWidth - (columns - 1) * ShaktiSpace.xs) / columns;
            return Wrap(
              spacing: ShaktiSpace.xs,
              runSpacing: ShaktiSpace.xs,
              children: [
                for (final (number, name) in _lines)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      button: true,
                      label: 'Call $number, $name',
                      onTap: () => launchUrl(Uri(scheme: 'tel', path: number)),
                      excludeSemantics: true,
                      child: Material(
                        color: context.shakti.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ShaktiRadius.md),
                          side: BorderSide(
                            color: context.shakti.outline.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () =>
                              launchUrl(Uri(scheme: 'tel', path: number)),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 72),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: ShaktiSpace.sm,
                                horizontal: ShaktiSpace.xxs,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    number,
                                    style: t.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    name,
                                    style: t.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
