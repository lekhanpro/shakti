import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/entities/entities.dart';
import '../../home/application/home_providers.dart';
import '../../lock/application/lock_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsState();
}
class _SettingsState extends ConsumerState<SettingsScreen> {
  bool _busy = false;
  Future<void> _save(SafetySettings value) async {
    setState(() => _busy = true);
    try { await ref.read(settingsRepositoryProvider).save(value);
      await ref.read(nativeGuardServiceProvider).setSecureScreen(value.secureScreen);
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not apply settings.'))); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _edit(String title, String initial, void Function(String) save) async {
    final text = TextEditingController(text: initial);
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title), content: TextField(controller: text, maxLength: 100, decoration: InputDecoration(labelText: title)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, text.text.trim()), child: const Text('Save'))]));
    text.dispose();
    if (value != null && mounted) save(value);
  }
  Widget _toggle(String title, String subtitle, bool value, SafetySettings Function(bool) update) =>
    SwitchListTile(title: Text(title), subtitle: Text(subtitle), value: value, onChanged: _busy ? null : (v) => _save(update(v)));
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Settings')),
    body: ref.watch(liveSettingsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Could not load settings.')),
      data: (s) => ListView(padding: ShaktiSpace.screen, children: [
        ListTile(title: const Text('Your name'), subtitle: Text(s.userName.isEmpty ? 'Not set' : s.userName),
          onTap: _busy ? null : () => _edit('Your name', s.userName, (v) => _save(s.copyWith(userName: v)))),
        for (final item in [(Routes.contacts, 'Trusted contacts'), (Routes.safePlaces, 'Safe places'),
          (Routes.history, 'Incident history'), (Routes.evidence, 'Evidence vault')])
          ListTile(title: Text(item.$2), trailing: const Icon(Icons.chevron_right), onTap: () => context.push(item.$1)),
        const Divider(),
        _toggle('Power trigger', 'Triple screen-toggle detection; test on your device.', s.powerTrigger, (v) => s.copyWith(powerTrigger: v)),
        _toggle('Shake trigger', 'Raise an SOS countdown by shaking the phone.', s.shakeTrigger, (v) => s.copyWith(shakeTrigger: v)),
        _toggle('Volume trigger', 'Requires optional accessibility access.', s.volumeTrigger, (v) => s.copyWith(volumeTrigger: v)),
        if (s.volumeTrigger) ListTile(title: const Text('Configure accessibility access'), onTap: () => ref.read(nativeGuardServiceProvider).openAccessibilitySettings()),
        _toggle('Voice trigger', 'While the app is listening: Shakti help / help me now.', s.voiceTrigger, (v) => s.copyWith(voiceTrigger: v)),
        _toggle('Siren during SOS', 'Draw attention with sound.', s.sirenOnSos, (v) => s.copyWith(sirenOnSos: v)),
        _toggle('Record evidence', 'Record up to 60 seconds; microphone permission required.', s.recordAudio, (v) => s.copyWith(recordAudio: v)),
        _toggle('Silent mode', 'Suppress siren and haptics during SOS.', s.stealthMode, (v) => s.copyWith(stealthMode: v)),
        _toggle('Biometric unlock', 'Use your device biometrics when available.', s.biometricUnlock, (v) => s.copyWith(biometricUnlock: v)),
        _toggle('Cloud alerts', 'Internet and configured backend required.', s.cloudEnabled, (v) => s.copyWith(cloudEnabled: v)),
        ListTile(title: const Text('Telegram group ID'), subtitle: Text(s.telegramChatId.isEmpty ? 'Not configured' : s.telegramChatId),
          onTap: _busy ? null : () => _edit('Telegram group ID', s.telegramChatId, (v) => _save(s.copyWith(telegramChatId: v)))),
        const Padding(padding: EdgeInsets.symmetric(vertical: ShaktiSpace.md), child: Text('Carrier SMS needs cellular service, SMS permission and a suitable mobile plan. Delivery is not guaranteed.')),
        FilledButton.icon(onPressed: () => ref.read(lockControllerProvider.notifier).lockNow(), icon: const Icon(Icons.lock_outline), label: const Text('Lock now')),
        const SizedBox(height: ShaktiSpace.xl),
      ]),
    ));
}
