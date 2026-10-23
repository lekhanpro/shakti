import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'shakti_mark.dart';

/// The brand's network motif drawn from real data: the shield sits at the
/// centre and each trusted contact is a node on the orbit. Empty slots are
/// drawn as hollow rings so the gap is visible, not hidden.
class GuardianNetwork extends StatelessWidget {
  const GuardianNetwork({
    required this.initials,
    this.slots = 5,
    this.size = 168,
    super.key,
  });

  /// One entry per active contact, highest priority first.
  final List<String> initials;
  final int slots;
  final double size;

  @override
  Widget build(BuildContext context) {
    final count = math.max(slots, initials.length);
    final node = size * 0.2;
    final orbit = size / 2 - node / 2 - 2;
    final centre = size / 2;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _OrbitPainter(
                  count: count,
                  filled: initials.length,
                  orbit: orbit,
                  accent: context.shakti.accent,
                ),
              ),
            ),
            Positioned(
              left: centre - size * 0.19,
              top: centre - size * 0.19,
              child: ShaktiMark(size: size * 0.38, badge: true),
            ),
            for (var i = 0; i < count; i++)
              Positioned(
                left: centre + orbit * math.cos(_angle(i, count)) - node / 2,
                top: centre + orbit * math.sin(_angle(i, count)) - node / 2,
                child: _Node(
                  size: node,
                  label: i < initials.length ? initials[i] : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static double _angle(int i, int count) =>
      -math.pi / 2 + i * 2 * math.pi / count;
}

class _Node extends StatelessWidget {
  const _Node({required this.size, this.label});

  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final filled = label != null;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? context.shakti.surfaceHigh : context.shakti.bg,
        border: Border.all(
          color: filled ? context.shakti.lilac : context.shakti.outline,
          width: filled ? 1.5 : 1,
        ),
      ),
      child: filled
          ? Text(
              label!,
              style: TextStyle(
                fontFamily: ShaktiFonts.heading,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.38,
                color: context.shakti.textHi,
                height: 1,
              ),
            )
          : Icon(
              Icons.add_rounded,
              size: size * 0.45,
              color: context.shakti.textLo,
            ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.count,
    required this.filled,
    required this.orbit,
    required this.accent,
  });

  final int count;
  final int filled;
  final double orbit;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.16);
    canvas.drawCircle(c, orbit, ring);
    canvas.drawCircle(
      c,
      orbit * 0.62,
      ring..color = accent.withValues(alpha: 0.1),
    );

    // Spokes only to connected guardians: the line is the connection.
    final spoke = Paint()
      ..strokeWidth = 1.5
      ..color = accent.withValues(alpha: 0.45);
    for (var i = 0; i < filled && i < count; i++) {
      final a = GuardianNetwork._angle(i, count);
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * orbit, spoke);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.count != count ||
      old.filled != filled ||
      old.orbit != orbit ||
      old.accent != accent;
}
