import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/gate.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/pin_pad.dart';
import '../../../domain/engines/pin_hasher.dart';
import '../../../domain/entities/entities.dart';
import '../../contacts/presentation/contact_form.dart';
import '../../home/application/home_providers.dart';
import '../../../core/widgets/shakti_mark.dart';
import '../../../core/widgets/glass_surface.dart';
import '../application/permission_gateway.dart';

/// Four steps: welcome, permissions, you + a trusted contact, PIN.
/// Steps 3 and 4 are required; permissions can be skipped with a warning.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = ['Welcome', 'Permissions', 'Your circle', 'Your PIN'];

  final _page = PageController();
  final _contactForm = GlobalKey<ContactFormState>();
  final _name = TextEditingController();
  final _nameKey = GlobalKey<FormFieldState<String>>();
  int _index = 0;
  bool _saving = false;

  ContactDraft? _contact;
  String? _pin;
  String? _decoyPin;

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    super.dispose();
  }

  void _go(int i) {
    setState(() => _index = i);
    if (ShaktiMotion.reduced(context)) {
      _page.jumpToPage(i);
    } else {
      _page.animateToPage(
        i,
        duration: ShaktiMotion.navigation,
        curve: ShaktiMotion.curve,
      );
    }
    FocusScope.of(context).unfocus();
  }

  void _next() {
    if (_index == 2) {
      final nameOk = _nameKey.currentState?.validate() ?? false;
      final draft = _contactForm.currentState?.submit();
      if (!nameOk || draft == null) return;
      _contact = draft;
    }
    if (_index < _steps.length - 1) _go(_index + 1);
  }

  Future<void> _finish() async {
    final contact = _contact;
    final pin = _pin;
    if (contact == null || pin == null || _saving) return;
    setState(() => _saving = true);
    try {
      final store = ref.read(secureStoreProvider);
      await store.write(PinKeys.primary, await PinHasher.hash(pin));
      final decoy = _decoyPin;
      if (decoy != null) {
        await store.write(PinKeys.decoy, await PinHasher.hash(decoy));
      } else {
        await store.delete(PinKeys.decoy);
      }
      await ref
          .read(contactRepositoryProvider)
          .upsert(
            EmergencyContact(
              id: const Uuid().v4(),
              name: contact.name,
              phone: contact.phone,
              relationship: contact.relationship,
              priority: 1,
            ),
          );
      final repo = ref.read(settingsRepositoryProvider);
      final current = await repo.load();
      await repo.save(
        current.copyWith(userName: _name.text.trim(), onboardingComplete: true),
      );
      if (!mounted) return;
      ref.read(appGateProvider.notifier).set(AppGate.unlocked);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your setup. Try again. ($e)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _steps.length - 1;

    return Scaffold(
      body: ShaktiBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ShaktiSpace.lg,
                  ShaktiSpace.md,
                  ShaktiSpace.lg,
                  0,
                ),
                child: _Progress(index: _index, steps: _steps),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    const _WelcomeStep(),
                    const _PermissionsStep(),
                    _CircleStep(
                      nameController: _name,
                      nameKey: _nameKey,
                      formKey: _contactForm,
                      initial: _contact,
                    ),
                    _PinStep(
                      onChanged: (pin, decoy) => setState(() {
                        _pin = pin;
                        _decoyPin = decoy;
                      }),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ShaktiSpace.lg,
                  ShaktiSpace.xs,
                  ShaktiSpace.lg,
                  ShaktiSpace.lg,
                ),
                child: _OnboardingActions(
                  back: _index > 0
                      ? TextButton.icon(
                          key: const ValueKey('onb-back'),
                          onPressed: _saving ? null : () => _go(_index - 1),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back'),
                        )
                      : null,
                  next: FilledButton(
                    key: const ValueKey('onb-next'),
                    onPressed: _saving || (last && _pin == null)
                        ? null
                        : (last ? _finish : _next),
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(switch (_index) {
                            0 => 'Get started',
                            3 => 'Finish setup',
                            _ => 'Next',
                          }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({required this.next, this.back});
  final Widget? back;
  final Widget next;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(14) > 20) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (back != null)
            Align(alignment: Alignment.centerLeft, child: back!),
          next,
        ],
      );
    }
    return Row(
      children: [
        ?back,
        const Spacer(),
        Flexible(child: next),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.index, required this.steps});

  final int index;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${index + 1} of ${steps.length}, ${steps[index]}',
      liveRegion: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1} of ${steps.length} · ${steps[index]}',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: ShaktiColors.lilac),
          ),
          const SizedBox(height: ShaktiSpace.sm),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: ShaktiMotion.reduced(context)
                        ? Duration.zero
                        : ShaktiMotion.navigation,
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= index
                          ? ShaktiColors.lilac
                          : ShaktiColors.glassEdge,
                      borderRadius: BorderRadius.circular(ShaktiRadius.pill),
                    ),
                  ),
                ),
                if (i < steps.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ShaktiSpace.lg,
        ShaktiSpace.xl,
        ShaktiSpace.lg,
        ShaktiSpace.lg,
      ),
      children: [
        Semantics(header: true, child: Text(title, style: t.headlineLarge)),
        if (subtitle != null) ...[
          const SizedBox(height: ShaktiSpace.xs),
          Text(
            subtitle!,
            style: t.bodyLarge?.copyWith(color: ShaktiColors.textMid),
          ),
        ],
        const SizedBox(height: ShaktiSpace.lg),
        ...children,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Welcome
// ---------------------------------------------------------------------------

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const features = [
      (
        Icons.people_outline_rounded,
        'Alert your circle',
        'Send your location to the people you trust.',
      ),
      (
        Icons.route_rounded,
        'Walk with company',
        'Set a check-in timer for your journey.',
      ),
      (
        Icons.lock_outline_rounded,
        'Choose what you share',
        'Your PIN protects access. You control permissions.',
      ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        ShaktiSpace.lg,
        ShaktiSpace.xl,
        ShaktiSpace.lg,
        ShaktiSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WelcomeLens(),
          const SizedBox(height: ShaktiSpace.lg),
          Text(
            'Shakti',
            style: t.titleMedium?.copyWith(color: ShaktiColors.lilac),
          ),
          const SizedBox(height: ShaktiSpace.xs),
          Semantics(
            header: true,
            child: Text('Your people.\nWithin reach.', style: t.displaySmall),
          ),
          const SizedBox(height: ShaktiSpace.sm),
          Text(
            'A personal safety network, built around you.',
            style: t.bodyLarge?.copyWith(color: ShaktiColors.textMid),
          ),
          const SizedBox(height: ShaktiSpace.lg),
          GlassSurface(
            padding: const EdgeInsets.all(ShaktiSpace.md),
            child: Column(
              children: [
                for (var i = 0; i < features.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: ShaktiSpace.sm),
                      child: Divider(height: 1),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(features[i].$1, color: ShaktiColors.lilac, size: 24),
                      const SizedBox(width: ShaktiSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(features[i].$2, style: t.titleSmall),
                            const SizedBox(height: ShaktiSpace.xxs),
                            Text(
                              features[i].$3,
                              style: t.bodyMedium?.copyWith(
                                color: ShaktiColors.textMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: ShaktiSpace.md),
          Text(
            'SMS can work without internet. It still needs cellular service, permission and a suitable plan.',
            style: t.bodySmall?.copyWith(color: ShaktiColors.textLo),
          ),
        ],
      ),
    );
  }
}

/// A quiet, static lens: onboarding motion belongs to the page transition.
class _WelcomeLens extends StatelessWidget {
  const _WelcomeLens();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Center(
      child: Container(
        width: 168,
        height: 168,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              ShaktiColors.brand.withValues(alpha: 0.26),
              ShaktiColors.ambient.withValues(alpha: 0.14),
            ],
          ),
          border: Border.all(color: ShaktiColors.lilac.withValues(alpha: 0.12)),
        ),
        child: GlassSurface(
          radius: ShaktiRadius.pill,
          padding: const EdgeInsets.all(28),
          color: ShaktiColors.surfaceHigh,
          child: const ShaktiMark(size: 72, color: ShaktiColors.lilac),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 2. Permissions, one at a time
// ---------------------------------------------------------------------------

class _PermissionsStep extends ConsumerStatefulWidget {
  const _PermissionsStep();

  @override
  ConsumerState<_PermissionsStep> createState() => _PermissionsStepState();
}

class _PermissionsStepState extends ConsumerState<_PermissionsStep> {
  static const _info = {
    AppPermission.location: (
      Icons.location_on_outlined,
      'Location',
      'So your SOS message says where you are. Used only during an SOS, an escort or on the map.',
      'Without it, your SOS says "Location unavailable".',
    ),
    AppPermission.sms: (
      Icons.sms_outlined,
      'SMS',
      'So your SOS reaches contacts from your own SIM, even without internet.',
      'Without it, your contacts get no SMS during an SOS.',
    ),
    AppPermission.microphone: (
      Icons.mic_none_rounded,
      'Microphone',
      'Records 60 seconds of encrypted audio as evidence, and listens for your voice keyword if you turn it on.',
      'Without it, no audio evidence is recorded.',
    ),
    AppPermission.notifications: (
      Icons.notifications_none_rounded,
      'Notifications',
      'Shows that protection is running, and alerts you when a guardian responds.',
      'Without it, Android may stop the power-button trigger in the background.',
    ),
  };

  final Map<AppPermission, PermissionOutcome> _status = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final gw = ref.read(permissionGatewayProvider);
    for (final p in AppPermission.values) {
      final s = await gw.status(p);
      if (!mounted) return;
      setState(() => _status[p] = s);
    }
  }

  Future<void> _grant(AppPermission p) async {
    final gw = ref.read(permissionGatewayProvider);
    if (_status[p] == PermissionOutcome.permanentlyDenied) {
      await gw.openSettings();
      return;
    }
    final s = await gw.request(p);
    if (mounted) setState(() => _status[p] = s);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // The first permission that still needs attention is expanded; the rest
    // are summarised, so she decides one thing at a time.
    final focus = AppPermission.values.firstWhere(
      (p) => _status[p] != PermissionOutcome.granted && !_skipped.contains(p),
      orElse: () => AppPermission.values.last,
    );
    final missing = AppPermission.values
        .where((p) => _status[p] != PermissionOutcome.granted)
        .toList();

    return _StepScaffold(
      title: 'A few permissions',
      subtitle: 'Each one is explained. You can skip any, and change them later in Settings.',
      children: [
        for (final p in AppPermission.values) ...[
          _PermissionTile(
            key: ValueKey('perm-${p.name}'),
            info: _info[p]!,
            status: _status[p],
            expanded: p == focus && _status[p] != PermissionOutcome.granted,
            skipped: _skipped.contains(p),
            onGrant: () => _grant(p),
            onSkip: () => setState(() => _skipped.add(p)),
          ),
          const SizedBox(height: ShaktiSpace.xs),
        ],
        if (missing.isNotEmpty && missing.every(_skipped.contains)) ...[
          const SizedBox(height: ShaktiSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: ShaktiColors.warn,
                size: 20,
              ),
              const SizedBox(width: ShaktiSpace.xs),
              Expanded(
                child: Text(
                  'Some protection is off: ${missing.map((p) => _info[p]!.$2).join(', ')}. You can grant these later from Settings.',
                  style: t.bodyMedium?.copyWith(color: ShaktiColors.warn),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  final Set<AppPermission> _skipped = {};
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.info,
    required this.status,
    required this.expanded,
    required this.skipped,
    required this.onGrant,
    required this.onSkip,
    super.key,
  });

  final (IconData, String, String, String) info;
  final PermissionOutcome? status;
  final bool expanded;
  final bool skipped;
  final VoidCallback onGrant;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (icon, name, why, cost) = info;
    final granted = status == PermissionOutcome.granted;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final (stIcon, stColor, stText) = granted
        ? (Icons.check_circle_rounded, ShaktiColors.safe, 'Allowed')
        : skipped
        ? (Icons.remove_circle_outline_rounded, ShaktiColors.warn, 'Skipped')
        : (
            Icons.radio_button_unchecked_rounded,
            ShaktiColors.textLo,
            'Not yet',
          );

    return AnimatedContainer(
      duration: ShaktiMotion.reduced(context)
          ? Duration.zero
          : ShaktiMotion.navigation,
      padding: const EdgeInsets.all(ShaktiSpace.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            expanded ? ShaktiColors.surfaceHigh : ShaktiColors.surface,
            ShaktiColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(ShaktiRadius.card),
        border: Border.all(
          color: expanded
              ? ShaktiColors.lilac.withValues(alpha: 0.45)
              : ShaktiColors.glassEdge,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: '$name, $stText',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: ShaktiColors.textHi),
                    const SizedBox(width: ShaktiSpace.sm),
                    Expanded(child: Text(name, style: t.titleMedium)),
                    if (!largeText) ...[
                      Icon(stIcon, color: stColor, size: 18),
                      const SizedBox(width: ShaktiSpace.xxs),
                      Text(
                        stText,
                        style: t.labelMedium?.copyWith(color: stColor),
                      ),
                    ],
                  ],
                ),
                if (largeText) ...[
                  const SizedBox(height: ShaktiSpace.xs),
                  Row(
                    children: [
                      Icon(stIcon, color: stColor, size: 18),
                      const SizedBox(width: ShaktiSpace.xxs),
                      Expanded(
                        child: Text(
                          stText,
                          style: t.labelMedium?.copyWith(color: stColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (expanded || (skipped && !granted)) ...[
            const SizedBox(height: ShaktiSpace.xs),
            Text(
              skipped ? cost : why,
              style: t.bodyMedium?.copyWith(
                color: skipped ? ShaktiColors.warn : ShaktiColors.textMid,
              ),
            ),
          ],
          if (expanded || (skipped && !granted)) ...[
            const SizedBox(height: ShaktiSpace.sm),
            Wrap(
              spacing: ShaktiSpace.xs,
              runSpacing: ShaktiSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(
                  onPressed: onGrant,
                  child: Text(
                    status == PermissionOutcome.permanentlyDenied
                        ? 'Open settings'
                        : 'Allow $name',
                  ),
                ),
                if (!skipped)
                  TextButton(onPressed: onSkip, child: const Text('Skip')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Name + first trusted contact
// ---------------------------------------------------------------------------

class _CircleStep extends StatelessWidget {
  const _CircleStep({
    required this.nameController,
    required this.nameKey,
    required this.formKey,
    this.initial,
  });

  final TextEditingController nameController;
  final GlobalKey<FormFieldState<String>> nameKey;
  final GlobalKey<ContactFormState> formKey;
  final ContactDraft? initial;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final init = initial;
    return _StepScaffold(
      title: 'Who should we tell?',
      subtitle:
          'Your SOS goes to this person first. You can add up to 5 later.',
      children: [
        TextFormField(
          key: nameKey,
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'Your name',
            helperText: 'Shown in the SOS message so they know it is you',
            helperMaxLines: 3,
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (v) =>
              (v?.trim().isEmpty ?? true) ? 'Enter your name' : null,
        ),
        const SizedBox(height: ShaktiSpace.lg),
        Semantics(
          header: true,
          child: Text('Trusted contact', style: t.titleMedium),
        ),
        const SizedBox(height: ShaktiSpace.sm),
        ContactForm(
          key: formKey,
          initial: init == null
              ? null
              : EmergencyContact(
                  id: 'draft',
                  name: init.name,
                  phone: init.phone,
                  relationship: init.relationship,
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. PIN (+ optional decoy)
// ---------------------------------------------------------------------------

enum _PinStage { enter, confirm, done, decoyEnter, decoyConfirm }

class _PinStep extends StatefulWidget {
  const _PinStep({required this.onChanged});

  /// Called with the confirmed PIN (or null) and optional decoy PIN.
  final void Function(String? pin, String? decoy) onChanged;

  @override
  State<_PinStep> createState() => _PinStepState();
}

class _PinStepState extends State<_PinStep> {
  final _pad = GlobalKey<PinPadState>();
  _PinStage _stage = _PinStage.enter;
  String? _first;
  String? _pin;
  String? _decoy;
  String? _error;

  void _submit(String v) {
    setState(() {
      _error = null;
      switch (_stage) {
        case _PinStage.enter:
        case _PinStage.decoyEnter:
          if (!PinHasher.isValidPin(v)) {
            _error = 'Too easy to guess. Avoid 1234, 0000 or repeated digits';
          } else if (_stage == _PinStage.decoyEnter && v == _pin) {
            _error = 'The decoy PIN must differ from your real PIN';
          } else {
            _first = v;
            _stage = _stage == _PinStage.enter
                ? _PinStage.confirm
                : _PinStage.decoyConfirm;
          }
        case _PinStage.confirm:
        case _PinStage.decoyConfirm:
          if (v != _first) {
            _error = "PINs don't match. Start again";
            _stage = _stage == _PinStage.confirm
                ? _PinStage.enter
                : _PinStage.decoyEnter;
          } else if (_stage == _PinStage.confirm) {
            _pin = v;
            _stage = _PinStage.done;
          } else {
            _decoy = v;
            _stage = _PinStage.done;
          }
          _first = null;
        case _PinStage.done:
          break;
      }
    });
    _pad.currentState?.clear();
    widget.onChanged(_pin, _decoy);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (_stage == _PinStage.done) {
      return _StepScaffold(
        title: 'PIN set',
        subtitle: 'You need it to open Shakti and to end an SOS.',
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: ShaktiColors.safe),
              SizedBox(width: ShaktiSpace.xs),
              Expanded(child: Text('PIN confirmed')),
            ],
          ),
          const SizedBox(height: ShaktiSpace.lg),
          GlassSurface(
            padding: const EdgeInsets.all(ShaktiSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Decoy PIN (optional)', style: t.titleMedium),
                const SizedBox(height: ShaktiSpace.xxs),
                Text(
                  'If someone forces you to unlock, enter this instead. Shakti opens a plain notes app and silently sends an SOS.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: ShaktiSpace.sm),
                if (_decoy == null)
                  OutlinedButton(
                    key: const ValueKey('onb-add-decoy'),
                    onPressed: () =>
                        setState(() => _stage = _PinStage.decoyEnter),
                    child: const Text('Set a decoy PIN'),
                  )
                else
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: ShaktiColors.safe,
                        size: 20,
                      ),
                      const SizedBox(width: ShaktiSpace.xs),
                      const Expanded(child: Text('Decoy PIN set')),
                      TextButton(
                        onPressed: () {
                          setState(() => _decoy = null);
                          widget.onChanged(_pin, null);
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: ShaktiSpace.md),
          TextButton(
            onPressed: () {
              setState(() {
                _pin = null;
                _decoy = null;
                _stage = _PinStage.enter;
              });
              widget.onChanged(null, null);
            },
            child: const Text('Change PIN'),
          ),
        ],
      );
    }

    final decoy =
        _stage == _PinStage.decoyEnter || _stage == _PinStage.decoyConfirm;
    final confirm =
        _stage == _PinStage.confirm || _stage == _PinStage.decoyConfirm;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ShaktiSpace.lg,
        ShaktiSpace.lg,
        ShaktiSpace.lg,
        ShaktiSpace.md,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            confirm
                ? (decoy ? 'Confirm decoy PIN' : 'Confirm your PIN')
                : (decoy ? 'Choose a decoy PIN' : 'Create a PIN'),
            style: t.headlineLarge,
          ),
        ),
        const SizedBox(height: ShaktiSpace.xs),
        Text(
          confirm
              ? 'Enter it once more.'
              : '4 to 8 digits. Tap the tick when done.',
          style: t.bodyLarge?.copyWith(color: ShaktiColors.textMid),
        ),
        const SizedBox(height: ShaktiSpace.sm),
        Center(
          child: PinPad(
            key: _pad,
            onSubmit: _submit,
            errorText: _error,
            submitLabel: confirm ? 'Confirm PIN' : 'Next',
          ),
        ),
        if (decoy)
          TextButton(
            onPressed: () => setState(() {
              _stage = _PinStage.done;
              _error = null;
            }),
            child: const Text('Skip decoy PIN'),
          ),
      ],
    );
  }
}
