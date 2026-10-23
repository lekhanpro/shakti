import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'glass_refraction.dart';

/// Bounded glass for floating controls. Content groups share the reflective
/// material without a backdrop filter unless [blur] is requested.
class GlassSurface extends StatefulWidget {
  const GlassSurface({
    required this.child,
    this.padding = const EdgeInsets.all(ShaktiSpace.md),
    this.radius = ShaktiRadius.card,
    this.blur = false,
    this.clear = false,
    this.protectText = false,
    this.onTap,
    this.color,
    this.borderColor,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;

  /// Clear glass is for bold controls; text-rich overlays use a stronger veil.
  final bool clear;

  /// A denser central band keeps navigation ink separate from scrolling words.
  final bool protectText;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface> {
  bool _pressed = false;
  Alignment _light = Alignment.topLeft;

  void _touch(Offset point) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    setState(() {
      _pressed = true;
      _light = Alignment(
        (point.dx / box.size.width * 2 - 1).clamp(-1.0, 1.0),
        (point.dy / box.size.height * 2 - 1).clamp(-1.0, 1.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final solid =
        MediaQuery.highContrastOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final base = widget.color ?? context.shakti.surface;
    final edge = widget.borderColor ?? context.shakti.outline;
    final radius = BorderRadius.circular(widget.radius);
    final opaque = Color.alphaBlend(base, context.shakti.surface);
    final glass = widget.blur && !solid;
    final dark = context.shakti.isDark;
    final reduced = ShaktiMotion.reduced(context);
    final veil = widget.clear ? (dark ? 0.76 : 0.57) : 0.88;
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        // A light veil protects ink while the scene still passes through.
        color: glass
            ? (widget.protectText ? null : base.withValues(alpha: veil))
            : opaque,
        gradient: glass && widget.protectText
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  base.withValues(alpha: veil),
                  base.withValues(alpha: 0.94),
                  base.withValues(alpha: 0.94),
                  base.withValues(alpha: veil),
                ],
                stops: const [0, 0.22, 0.8, 1],
              )
            : null,
        border: glass
            ? null
            : Border.all(
                color: _pressed
                    ? context.shakti.accent.withValues(alpha: 0.55)
                    : edge,
              ),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (glass)
            Positioned.fill(
              child: IgnorePointer(
                child: _optics(dark, reduced, foreground: false),
              ),
            ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: radius,
              splashColor: context.shakti.accent.withValues(alpha: 0.08),
              highlightColor: context.shakti.accent.withValues(alpha: 0.06),
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ],
      ),
    );
    if (glass) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: _optics(dark, reduced, foreground: true),
            ),
          ),
        ],
      );
      content = GlassRefraction(radius: widget.radius, child: content);
    }
    return Semantics(
      button: widget.onTap == null ? null : true,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed && widget.onTap != null && !reduced ? 0.985 : 1,
        duration: reduced ? Duration.zero : ShaktiMotion.press,
        curve: ShaktiMotion.curve,
        child: CustomPaint(
          painter: glass
              ? _GlassShadow(
                  radius: widget.radius,
                  color: context.shakti.textHi.withValues(
                    alpha: dark ? 0.12 : 0.10,
                  ),
                )
              : null,
          child: Listener(
            onPointerDown: widget.onTap != null || glass
                ? (event) => _touch(event.localPosition)
                : null,
            onPointerUp: (_) => setState(() => _pressed = false),
            onPointerCancel: (_) => setState(() => _pressed = false),
            child: ClipRRect(borderRadius: radius, child: content),
          ),
        ),
      ),
    );
  }

  Widget _optics(bool dark, bool reduced, {required bool foreground}) =>
      TweenAnimationBuilder<double>(
        tween: Tween(end: _pressed ? 1 : 0),
        duration: reduced ? Duration.zero : ShaktiMotion.press,
        builder: (context, energy, _) => CustomPaint(
          painter: _GlassOptics(
            radius: widget.radius,
            dark: dark,
            ink: context.shakti.textHi,
            light: reduced ? Alignment.topLeft : _light,
            energy: energy,
            foreground: foreground,
          ),
        ),
      );
}

/// Only the cast shadow is painted: a transparent pane must not sample a
/// shadow-filled rectangle behind itself into a second, ghost pane.
class _GlassShadow extends CustomPainter {
  const _GlassShadow({required this.radius, required this.color});
  final double radius;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(40))
      ..addRRect(shape);
    canvas.save();
    canvas.clipPath(outside);
    canvas.drawRRect(
      shape.deflate(4).shift(const Offset(0, 8)),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlassShadow old) =>
      radius != old.radius || color != old.color;
}

/// A curved specular rim and a fingertip light; no continuous repaint loop.
class _GlassOptics extends CustomPainter {
  const _GlassOptics({
    required this.radius,
    required this.dark,
    required this.ink,
    required this.light,
    required this.energy,
    required this.foreground,
  });
  final double radius;
  final bool dark;
  final Color ink;
  final Alignment light;
  final double energy;
  final bool foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(
      rect.deflate(0.7),
      Radius.circular(radius),
    );
    if (!foreground) {
      canvas.drawRRect(
        shape,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: dark ? 0.10 : 0.32),
              Colors.white.withValues(alpha: 0.01),
              Colors.white.withValues(alpha: dark ? 0.03 : 0.10),
            ],
            stops: const [0, 0.55, 1],
          ).createShader(rect),
      );
    }
    if (foreground) {
      canvas.drawRRect(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.25
          ..shader = SweepGradient(
            colors: [
              Colors.white.withValues(alpha: dark ? 0.20 : 0.78),
              ink.withValues(alpha: 0.14),
              Colors.white.withValues(alpha: dark ? 0.45 : 0.95),
              Colors.white.withValues(alpha: 0.04),
              Colors.white.withValues(alpha: dark ? 0.20 : 0.78),
            ],
            stops: const [0, 0.22, 0.53, 0.78, 1],
            transform: const GradientRotation(-0.7),
          ).createShader(rect),
      );
    }
    if (!foreground && energy > 0) {
      canvas.drawRRect(
        shape,
        Paint()
          ..shader = RadialGradient(
            center: light,
            radius: 0.9,
            colors: [
              Colors.white.withValues(alpha: energy * (dark ? 0.06 : 0.38)),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_GlassOptics old) =>
      radius != old.radius ||
      dark != old.dark ||
      ink != old.ink ||
      light != old.light ||
      foreground != old.foreground ||
      energy != old.energy;
}

/// One static ambient field shared by app pages; no background animation ticker.
class ShaktiBackdrop extends StatelessWidget {
  const ShaktiBackdrop({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: context.shakti.bg, child: child);
}

class ShaktiPageHeader extends StatelessWidget {
  const ShaktiPageHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: ShaktiSpace.sm, bottom: ShaktiSpace.lg),
    child: LayoutBuilder(
      builder: (context, box) {
        final compactHeading =
            box.maxWidth < 360 &&
            MediaQuery.textScalerOf(context).scale(28) > 40;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: compactHeading
                          ? Theme.of(context).textTheme.headlineSmall
                          : Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: ShaktiSpace.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: ShaktiSpace.sm),
              trailing!,
            ],
          ],
        );
      },
    ),
  );
}
