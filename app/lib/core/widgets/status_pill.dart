import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Compact status indicator. Always pairs colour with an icon and text so the
/// state is never conveyed by colour alone.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.icon,
    required this.color,
    this.wrap = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool wrap;

  const StatusPill.safe(this.label, {this.wrap = false, super.key})
    : icon = Icons.verified_user_rounded,
      color = ShaktiColors.safe;
  const StatusPill.warn(this.label, {this.wrap = false, super.key})
    : icon = Icons.warning_amber_rounded,
      color = ShaktiColors.warn;
  const StatusPill.danger(this.label, {this.wrap = false, super.key})
    : icon = Icons.emergency_share_rounded,
      color = ShaktiColors.sos;
  const StatusPill.info(this.label, {this.wrap = false, super.key})
    : icon = Icons.info_outline_rounded,
      color = ShaktiColors.info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ShaktiSpace.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(ShaktiRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: wrap ? null : TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
