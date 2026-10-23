import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Bounded glass for floating controls. Content groups share the reflective
/// material without a backdrop filter unless [blur] is requested.
class GlassSurface extends StatefulWidget {
  const GlassSurface({
    required this.child,
    this.padding = const EdgeInsets.all(ShaktiSpace.md),
    this.radius = ShaktiRadius.card,
    this.blur = false,
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
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final solid =
        MediaQuery.highContrastOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final base = widget.color ?? context.shakti.surface;
    final edge = widget.borderColor ?? context.shakti.outline;
    final radius = BorderRadius.circular(widget.radius);
    final opaque = Color.alphaBlend(base, context.shakti.surface);
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: solid || !widget.blur ? opaque : base.withValues(alpha: 0.94),
        border: Border.all(
          color: _pressed
              ? context.shakti.accent.withValues(alpha: 0.55)
              : edge,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: widget.onTap == null
              ? null
              : (value) => setState(() => _pressed = value),
          borderRadius: radius,
          splashColor: context.shakti.accent.withValues(alpha: 0.08),
          highlightColor: context.shakti.accent.withValues(alpha: 0.06),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
    if (widget.blur && !solid) {
      content = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: content,
      );
    }
    return Semantics(
      button: widget.onTap == null ? null : true,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed && !ShaktiMotion.reduced(context) ? 0.985 : 1,
        duration: ShaktiMotion.press,
        curve: ShaktiMotion.curve,
        child: ClipRRect(borderRadius: radius, child: content),
      ),
    );
  }
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
