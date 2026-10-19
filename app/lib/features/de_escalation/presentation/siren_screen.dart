import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/services/services.dart';

class SirenScreen extends ConsumerStatefulWidget {
  const SirenScreen({super.key});
  @override
  ConsumerState<SirenScreen> createState() => _SirenState();
}
class _SirenState extends ConsumerState<SirenScreen> {
  bool _on = false, _flash = false, _busy = false;
  late SirenService _siren;
  late StrobeService _strobe;
  @override
  void initState() { super.initState(); _siren = ref.read(sirenServiceProvider); _strobe = ref.read(strobeServiceProvider); }
  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      if (_on) { await _siren.stop(); await _strobe.stop(); }
      else { await _siren.start(); if (_flash) await _strobe.start(); }
      if (mounted) setState(() => _on = !_on);
    } catch (_) {
      try { await _siren.stop(); await _strobe.stop(); } catch (_) {}
      if (mounted) { setState(() => _on = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio or flashlight is unavailable.'))); }
    } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _stop() async { try { await _siren.stop(); await _strobe.stop(); } catch (_) {} }
  @override
  void dispose() { if (_on) unawaited(_stop()); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Siren')),
    body: ListView(padding: ShaktiSpace.screen, children: [
      const SizedBox(height: ShaktiSpace.xl),
      const Text('Draw attention with a loud alert. This does not send an SOS message.'),
      SwitchListTile(title: const Text('Flashlight strobe'), subtitle: const Text('Flashing light may affect people with photosensitivity.'),
        value: _flash, onChanged: _on || _busy ? null : (v) => setState(() => _flash = v)),
      const SizedBox(height: ShaktiSpace.lg),
      FilledButton.icon(onPressed: _busy ? null : _toggle,
        icon: Icon(_on ? Icons.stop : Icons.volume_up), label: Text(_on ? 'Stop siren' : 'Start siren')),
    ]));
}
