import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Bounded glass for floating controls. Content groups share the reflective
/// material without a backdrop filter unless [blur] is requested.
class GlassSurface extends StatefulWidget {
  const GlassSurface({
    required this.child,
    this.padding = const EdgeInsets.all(ShaktiSpace.md),
    this.radius = 24,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base =
        widget.color ??
        (dark ? ShaktiColors.surface : ShaktiColors.lightSurface);
    final edge =
        widget.borderColor ??
        (dark ? ShaktiColors.glassEdge : ShaktiColors.lightOutline);
    final radius = BorderRadius.circular(widget.radius);
    final opaque = Color.alphaBlend(
      base,
      dark ? ShaktiColors.surface : ShaktiColors.lightSurface,
    );
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.color != null
              ? [solid ? opaque : base, solid ? opaque : base]
              : [
                  base.withValues(alpha: solid ? 1 : 0.90),
                  base.withValues(alpha: solid ? 1 : 0.70),
                ],
        ),
        border: Border.all(
          color: _pressed ? ShaktiColors.lilac.withValues(alpha: 0.55) : edge,
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
          splashColor: ShaktiColors.lilac.withValues(alpha: 0.08),
          highlightColor: ShaktiColors.lilac.withValues(alpha: 0.06),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
    if (widget.blur && !solid) {
      content = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ShaktiColors.ambient, ShaktiColors.bg, ShaktiColors.bg],
      ),
    ),
    child: child,
  );
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
