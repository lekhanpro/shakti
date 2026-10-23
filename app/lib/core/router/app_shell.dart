import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import '../widgets/glass_surface.dart';

const _tabs = [
  (Icons.shield_outlined, Icons.shield_rounded, 'Shield'),
  (Icons.map_outlined, Icons.map_rounded, 'Map'),
  (Icons.directions_walk_outlined, Icons.directions_walk_rounded, 'Escort'),
  (Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'Guardian'),
  (Icons.tune_outlined, Icons.tune_rounded, 'Settings'),
];

/// Existing branch state stays alive. The glass dock yields to the keyboard.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});
  final StatefulNavigationShell shell;
  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth >= 760) {
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(ShaktiSpace.md),
                  child: GlassSurface(
                    padding: EdgeInsets.zero,
                    child: NavigationRail(
                      backgroundColor: Colors.transparent,
                      selectedIndex: shell.currentIndex,
                      onDestinationSelected: _select,
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final (icon, selected, label) in _tabs)
                          NavigationRailDestination(
                            icon: Icon(icon),
                            selectedIcon: Icon(selected),
                            label: Text(label),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: shell),
              ],
            ),
          ),
        );
      }
      return Scaffold(
        extendBody: true,
        body: shell,
        bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
            ? null
            : SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(
                  ShaktiSpace.md,
                  0,
                  ShaktiSpace.md,
                  ShaktiSpace.sm,
                ),
                child: ShaktiDock(
                  selectedIndex: shell.currentIndex,
                  onSelected: _select,
                ),
              ),
      );
    },
  );
}

/// One bounded filter, one gliding lens. Navigation does not await animation.
class ShaktiDock extends StatelessWidget {
  const ShaktiDock({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => GlassSurface(
    blur: true,
    radius: 32,
    padding: const EdgeInsets.all(6),
    color: ShaktiColors.surfaceHigh.withValues(alpha: 0.76),
    child: LayoutBuilder(
      builder: (context, box) {
        final labels = MediaQuery.textScalerOf(context).scale(11) <= 15;
        final height = labels ? 64.0 : 56.0;
        final width = box.maxWidth / _tabs.length;
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: selectedIndex.toDouble(),
                  end: selectedIndex.toDouble(),
                ),
                duration: ShaktiMotion.reduced(context)
                    ? Duration.zero
                    : ShaktiMotion.navigation,
                curve: ShaktiMotion.curve,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ShaktiColors.lilac.withValues(alpha: 0.26),
                          ShaktiColors.lilac.withValues(alpha: 0.10),
                        ],
                      ),
                      border: Border.all(
                        color: ShaktiColors.lilac.withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                ),
                builder: (_, value, child) => Transform.translate(
                  offset: Offset(value * width, 0),
                  child: child,
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: Semantics(
                        label: _tabs[i].$3,
                        button: true,
                        selected: selectedIndex == i,
                        onTap: () => onSelected(i),
                        excludeSemantics: true,
                        child: Tooltip(
                          message: _tabs[i].$3,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(26),
                            onTap: () => onSelected(i),
                            child: SizedBox(
                              height: height,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedSwitcher(
                                    duration: ShaktiMotion.reduced(context)
                                        ? Duration.zero
                                        : ShaktiMotion.press,
                                    child: Icon(
                                      selectedIndex == i
                                          ? _tabs[i].$2
                                          : _tabs[i].$1,
                                      key: ValueKey('$i-${selectedIndex == i}'),
                                      size: 24,
                                      color: selectedIndex == i
                                          ? ShaktiColors.textHi
                                          : ShaktiColors.textLo,
                                    ),
                                  ),
                                  if (labels) ...[
                                    const SizedBox(height: ShaktiSpace.xxs),
                                    Text(
                                      _tabs[i].$3,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontWeight: selectedIndex == i
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: selectedIndex == i
                                                ? ShaktiColors.textHi
                                                : ShaktiColors.textLo,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
