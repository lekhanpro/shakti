import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // Scrolls so large text (up to 200%) never clips on short screens.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ShaktiSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.shakti.action.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: context.shakti.action),
            ),
            const SizedBox(height: ShaktiSpace.md),
            Text(title, style: t.titleLarge, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: ShaktiSpace.xs),
              Text(message!, style: t.bodyMedium, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: ShaktiSpace.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
