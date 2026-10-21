import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The shared shield-and-flame identity, using the brand master's 256-unit grid.
///
/// [badge] places a white mark on the indigo disc used across the brand kit.
class ShaktiMark extends StatelessWidget {
  const ShaktiMark({this.size = 48, this.color = ShaktiColors.textHi, this.badge = false, super.key});

  final double size;
  final Color color;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(size: Size.square(badge ? size * 0.62 : size), painter: _MarkPainter(badge ? ShaktiColors.textHi : color));
    return Semantics(
      label: 'Shakti',
      image: true,
      child: badge
          ? Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: ShaktiColors.brand),
              child: mark,
            )
          : mark,
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    canvas.scale(s.width / 256, s.height / 256);
    final shield = Path()
      ..moveTo(128, 30)
      ..lineTo(204, 59)
      ..lineTo(204, 120)
      ..cubicTo(204, 169, 169, 205, 128, 226)
      ..cubicTo(87, 205, 52, 169, 52, 120)
      ..lineTo(52, 59)
      ..close();
    canvas.drawPath(
      shield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    final flame = Path()
      ..moveTo(136, 75)
      ..cubicTo(143, 96, 165, 117, 159, 139)
      ..cubicTo(156, 157, 141, 171, 124, 170)
      ..cubicTo(102, 169, 89, 153, 93, 134)
      ..cubicTo(95, 122, 103, 113, 111, 104)
      ..cubicTo(108, 121, 115, 131, 124, 134)
      ..cubicTo(117, 116, 124, 91, 136, 75)
      ..close();
    canvas.drawPath(flame, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}
