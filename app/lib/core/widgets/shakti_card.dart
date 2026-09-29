import 'package:flutter/material.dart';

import '../theme/tokens.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(ShaktiRadius.card);
    final card = Material(
      color: color ?? scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor ?? scheme.outline.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (onTap == null) return card;
    return Semantics(button: true, label: semanticLabel, child: card);
  }
}
