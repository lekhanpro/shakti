import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.trailing, this.padding, super.key});

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(letterSpacing: 1.2);
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            ShaktiSpace.xxs,
            ShaktiSpace.lg,
            ShaktiSpace.xxs,
            ShaktiSpace.xs,
          ),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Expanded(child: Text(title.toUpperCase(), style: style)),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
