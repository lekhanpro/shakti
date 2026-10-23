import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/glass_surface.dart';
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
  void initState() {
    super.initState();
    _siren = ref.read(sirenServiceProvider);
    _strobe = ref.read(strobeServiceProvider);
  }

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      if (_on) {
        await _siren.stop();
        await _strobe.stop();
      } else {
        await _siren.start();
        if (_flash) await _strobe.start();
      }
      if (mounted) setState(() => _on = !_on);
    } catch (_) {
      try {
        await _siren.stop();
        await _strobe.stop();
      } catch (_) {}
      if (mounted) {
        setState(() => _on = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio or flashlight is unavailable.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    try {
      await _siren.stop();
      await _strobe.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_on) unawaited(_stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Siren')),
      body: ShaktiBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(ShaktiSpace.lg),
          children: [
            const ShaktiPageHeader(
              title: 'Make yourself heard.',
              subtitle: 'Draw attention with a loud alert. This does not send an SOS message.',
            ),
            Center(
              child: ExcludeSemantics(
                child: AnimatedContainer(
                  duration: ShaktiMotion.reduced(context)
                      ? Duration.zero
                      : ShaktiMotion.press,
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _on
                        ? ShaktiColors.sosDeep.withValues(alpha: 0.22)
                        : ShaktiColors.surfaceHigh,
                    border: Border.all(
                      color: _on
                          ? ShaktiColors.sosGlow.withValues(alpha: 0.5)
                          : ShaktiColors.glassEdge,
                    ),
                  ),
                  child: Icon(
                    _on ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                    size: 64,
                    color: _on ? ShaktiColors.sosGlow : ShaktiColors.lilac,
                  ),
                ),
              ),
            ),
            const SizedBox(height: ShaktiSpace.lg),
            Semantics(
              liveRegion: true,
              child: Text(
                _on ? 'Siren is sounding' : 'Ready when you need it',
                textAlign: TextAlign.center,
                style: text.titleLarge,
              ),
            ),
            const SizedBox(height: ShaktiSpace.xl),
            GlassSurface(
              padding: const EdgeInsets.symmetric(vertical: ShaktiSpace.xs),
              child: SwitchListTile(
                title: const Text('Flashlight strobe'),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: ShaktiSpace.xs),
                  child: Text(
                    'Flashing light may affect people with photosensitivity.',
                  ),
                ),
                value: _flash,
                onChanged: _on || _busy
                    ? null
                    : (value) => setState(() => _flash = value),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ShaktiSpace.lg,
            ShaktiSpace.sm,
            ShaktiSpace.lg,
            ShaktiSpace.md,
          ),
          child: FilledButton.icon(
            style: _on
                ? FilledButton.styleFrom(
                    backgroundColor: ShaktiColors.sos,
                    foregroundColor: ShaktiColors.textHi,
                  )
                : null,
            onPressed: _busy ? null : _toggle,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_on ? Icons.stop_rounded : Icons.volume_up_rounded),
            label: Text(_on ? 'Stop siren' : 'Start siren'),
          ),
        ),
      ),
    );
  }
}
