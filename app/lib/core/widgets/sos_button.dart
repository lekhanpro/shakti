import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The Shield hero: a 220 dp rose orb with breathing ripple rings.
///
/// A single tap activates it (spec A2). Haptics are owned by the panic
/// controller, not this widget. With reduced motion the rings are drawn
/// statically and the press scale is skipped.
class SosButton extends StatefulWidget {
  const SosButton({required this.onPressed, this.size = ShaktiSize.sosButton, this.enabled = true, super.key});

  final VoidCallback onPressed;
  final double size;
  final bool enabled;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(vsync: this, duration: ShaktiMotion.breathe);
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    if (ShaktiMotion.reduced(context) || !widget.enabled) {
      _breath.stop();
      _breath.value = 0.5;
    } else if (!_breath.isAnimating) {
      _breath.repeat();
    }
  }

  @override
  void didUpdateWidget(SosButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _syncMotion();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ShaktiMotion.reduced(context);
    final size = widget.size;
    // The ripple canvas extends beyond the orb so rings have room to grow.
    final canvas = size * 1.45;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Send SOS',
      hint: 'Starts a 5 second countdown you can cancel',
      onTap: widget.enabled ? widget.onPressed : null,
      excludeSemantics: true,
      child: SizedBox(
        width: canvas,
        height: canvas,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple rings.
            IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _breath,
                  builder: (_, _) => CustomPaint(
                    size: Size.square(canvas),
                    painter: _RipplePainter(
                      t: _breath.value,
                      orbRadius: size / 2,
                      animated: !reduced && widget.enabled,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
              onTapCancel: () => _setPressed(false),
              onTapUp: (_) => _setPressed(false),
              onTap: widget.enabled ? widget.onPressed : null,
              child: AnimatedScale(
                scale: _pressed && !reduced ? 0.94 : 1,
                duration: ShaktiMotion.fast,
                curve: ShaktiMotion.curve,
                child: _Orb(size: size, enabled: widget.enabled),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.enabled});

  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.5,
      duration: ShaktiMotion.base,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.4),
            radius: 1.05,
            colors: [ShaktiColors.sosGlow, ShaktiColors.sos, ShaktiColors.sosDeep],
            stops: [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(color: ShaktiColors.sos.withValues(alpha: 0.45), blurRadius: 48, spreadRadius: 4),
            BoxShadow(color: ShaktiColors.sosDeep.withValues(alpha: 0.6), blurRadius: 12, offset: const Offset(0, 8)),
          ],
        ),
        child: Container(
          // Inner bevel ring gives the orb a pressed-glass depth.
          margin: EdgeInsets.all(size * 0.06),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ShaktiColors.textHi.withValues(alpha: 0.18), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'SOS',
                  maxLines: 1,
                  style: t.displayLarge?.copyWith(
                    color: ShaktiColors.textHi,
                    fontSize: size * 0.25,
                    letterSpacing: size * 0.02,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(height: size * 0.03),
              Text(
                'Tap for help',
                style: t.labelMedium?.copyWith(color: ShaktiColors.textHi.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.t, required this.orbRadius, required this.animated});

  final double t;
  final double orbRadius;
  final bool animated;

  static const _rings = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxGrow = size.width / 2 - orbRadius;
    for (var i = 0; i < _rings; i++) {
      // Static fallback spaces rings evenly; animated rings phase-shift.
      final p = animated ? (t + i / _rings) % 1.0 : (i + 1) / (_rings + 1);
      final r = orbRadius + maxGrow * Curves.easeOut.transform(p);
      final alpha = animated ? (1 - p) * 0.35 : 0.22 - i * 0.05;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ShaktiColors.sosGlow.withValues(alpha: alpha.clamp(0, 1));
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t || old.animated != animated;
}
