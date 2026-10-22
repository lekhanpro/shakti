import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/entities.dart';
import '../../home/application/home_providers.dart';
import '../../lock/application/lock_controller.dart';

/// Settings grouped by what the user is deciding: who gets alerted, what
/// starts an SOS, what happens during one, and how the app is protected.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _save(SafetySettings value) async {
    setState(() => _busy = true);
    try {
      await ref.read(settingsRepositoryProvider).save(value);
      await ref.read(nativeGuardServiceProvider).setSecureScreen(value.secureScreen);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not apply settings.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(String title, String initial, void Function(String) save) async {
    final text = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: text, maxLength: 100, decoration: InputDecoration(labelText: title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, text.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    text.dispose();
    if (value != null && mounted) save(value);
  }

  Widget _toggle(IconData icon, String title, String subtitle, bool value, SafetySettings Function(bool) update) => SwitchListTile(
        secondary: _TileIcon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: _busy ? null : (v) => _save(update(v)),
      );

  Widget _link(IconData icon, String title, String? subtitle, VoidCallback? onTap) => ListTile(
        leading: _TileIcon(icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded, color: ShaktiColors.textLo),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(liveContactsProvider).value ?? const <EmergencyContact>[];
    final activeCount = contacts.where((c) => c.isActive).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ref.watch(liveSettingsProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Could not load settings.')),
            data: (s) => ListView(
              padding: ShaktiSpace.screen.copyWith(bottom: ShaktiSpace.xl),
              children: [
                _Profile(
                  name: s.userName,
                  onEdit: _busy ? null : () => _edit('Your name', s.userName, (v) => _save(s.copyWith(userName: v))),
                ),
                const SectionHeader('Your safety network'),
                _Group(children: [
                  _link(Icons.group_rounded, 'Trusted contacts', '$activeCount of 5 receive SOS', () => context.push(Routes.contacts)),
                  _link(Icons.place_rounded, 'Safe places', 'Arrival points for Walk with me', () => context.push(Routes.safePlaces)),
                ]),
                const SectionHeader('What starts an SOS'),
                _Group(children: [
                  _toggle(Icons.power_settings_new_rounded, 'Power trigger', 'Triple screen-toggle detection; test on your device.', s.powerTrigger,
                      (v) => s.copyWith(powerTrigger: v)),
                  _toggle(Icons.vibration_rounded, 'Shake trigger', 'Raise an SOS countdown by shaking the phone.', s.shakeTrigger,
                      (v) => s.copyWith(shakeTrigger: v)),
                  _toggle(Icons.mic_rounded, 'Voice trigger', 'While the app is listening: Shakti help / help me now.', s.voiceTrigger,
                      (v) => s.copyWith(voiceTrigger: v)),
                ]),
                const SectionHeader('During an SOS'),
                _Group(children: [
                  _toggle(Icons.campaign_rounded, 'Siren during SOS', 'Draw attention with sound.', s.sirenOnSos, (v) => s.copyWith(sirenOnSos: v)),
                  _toggle(Icons.graphic_eq_rounded, 'Record evidence', 'Record up to 60 seconds; microphone permission required.', s.recordAudio,
                      (v) => s.copyWith(recordAudio: v)),
                  _toggle(Icons.visibility_off_rounded, 'Silent mode', 'Suppress siren and haptics during SOS.', s.stealthMode,
                      (v) => s.copyWith(stealthMode: v)),
                ]),
                const SectionHeader('Cloud alerts'),
                _Group(children: [
                  _toggle(Icons.cloud_outlined, 'Cloud alerts', 'Internet and configured backend required.', s.cloudEnabled,
                      (v) => s.copyWith(cloudEnabled: v)),
                  _link(
                    Icons.send_rounded,
                    'Telegram group ID',
                    s.telegramChatId.isEmpty ? 'Not configured' : s.telegramChatId,
                    _busy ? null : () => _edit('Telegram group ID', s.telegramChatId, (v) => _save(s.copyWith(telegramChatId: v))),
                  ),
                ]),
                const SectionHeader('Privacy and records'),
                _Group(children: [
                  _toggle(Icons.fingerprint_rounded, 'Biometric unlock', 'Use your device biometrics when available.', s.biometricUnlock,
                      (v) => s.copyWith(biometricUnlock: v)),
                  _link(Icons.history_rounded, 'Incident history', null, () => context.push(Routes.history)),
                  _link(Icons.lock_rounded, 'Evidence vault', 'Encrypted on this phone', () => context.push(Routes.evidence)),
                ]),
                const SizedBox(height: ShaktiSpace.lg),
                FilledButton.icon(
                  onPressed: () => ref.read(lockControllerProvider.notifier).lockNow(),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Lock now'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: ShaktiSpace.md, horizontal: ShaktiSpace.xxs),
                  child: Text(
                    'Carrier SMS needs cellular service, SMS permission and a suitable mobile plan. Delivery is not guaranteed.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

/// Identity header: brand badge, the name used in SOS messages, and edit.
class _Profile extends StatelessWidget {
  const _Profile({required this.name, required this.onEdit});

  final String name;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ShaktiCard(
      semanticLabel: 'Your name, ${name.isEmpty ? 'not set' : name}. Edit',
      onTap: onEdit,
      child: Row(
        children: [
          const ShaktiMark(size: 52, badge: true),
          const SizedBox(width: ShaktiSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your name', style: t.bodySmall),
                Text(name.isEmpty ? 'Not set' : name, style: t.titleLarge, overflow: TextOverflow.ellipsis),
                Text('Shown to your circle in SOS messages', style: t.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, color: ShaktiColors.lilac),
        ],
      ),
    );
  }
}

/// One rounded surface per section, with hairline dividers between rows.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ShaktiCard(
      padding: const EdgeInsets.symmetric(vertical: ShaktiSpace.xxs),
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const Divider(indent: 64),
            child,
          ],
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: ShaktiColors.brand.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(ShaktiRadius.sm),
      ),
      child: Icon(icon, color: ShaktiColors.lilac, size: 20),
    );
  }
}
