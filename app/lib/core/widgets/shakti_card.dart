import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'glass_surface.dart';

/// Base surface for grouped content. Tappable when [onTap] is set, in which
/// case [semanticLabel] should describe the action.
class ShaktiCard extends StatelessWidget {
  const ShaktiCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(ShaktiSpace.md),
    this.color,
    this.borderColor,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      color: color,
      borderColor: borderColor,
      radius: ShaktiRadius.card,
      padding: padding,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}
