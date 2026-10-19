import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Amber countdown arc with a huge centred number.
///
/// The arc tweens smoothly from one whole second to the next, so the ring
/// drains continuously even though [secondsLeft] only changes once a second.
/// Each second is announced through a live region.
class CountdownRing extends StatelessWidget {
  const CountdownRing({required this.secondsLeft, required this.total, this.size = 260, super.key});

  final int secondsLeft;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reduced = ShaktiMotion.reduced(context);
    final fraction = total <= 0 ? 0.0 : (secondsLeft / total).clamp(0.0, 1.0);
    final t = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      label: '$secondsLeft ${secondsLeft == 1 ? 'second' : 'seconds'} left',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fraction),
          duration: reduced ? Duration.zero : const Duration(milliseconds: 950),
          curve: Curves.linear,
          builder: (context, value, child) => CustomPaint(
            painter: _RingPainter(value),
            child: child,
          ),
          child: Center(
            child: Text(
              '$secondsLeft',
              key: const ValueKey('countdown-number'),
              style: t.displayLarge?.copyWith(
                fontSize: size * 0.42,
                height: 1,
                color: ShaktiColors.textHi,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = ShaktiColors.textHi.withValues(alpha: 0.10),
    );

    if (fraction <= 0) return;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = ShaktiColors.warn,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}
