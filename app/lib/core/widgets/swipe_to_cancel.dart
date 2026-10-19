import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Drag the thumb to the right to cancel. A plain "Cancel" button sits under
/// the track for screen-reader, switch and tremor users who cannot drag.
class SwipeToCancel extends StatefulWidget {
  const SwipeToCancel({required this.onCancel, this.label = 'Swipe to cancel', super.key});

  final VoidCallback onCancel;
  final String label;

  @override
  State<SwipeToCancel> createState() => _SwipeToCancelState();
}

class _SwipeToCancelState extends State<SwipeToCancel> {
  static const _height = 72.0;
  static const _thumb = 60.0;
  static const _threshold = 0.82;

  double _dx = 0;
  bool _fired = false;

  void _fire() {
    if (_fired) return;
    _fired = true;
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final reduced = ShaktiMotion.reduced(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final travel = (c.maxWidth - _thumb - 12).clamp(1.0, double.infinity);
            final progress = (_dx / travel).clamp(0.0, 1.0);
            return Semantics(
              // The track is draggable only; the button below is the
              // accessible action, so hide the track from assistive tech.
              excludeSemantics: true,
              child: Container(
                height: _height,
                decoration: BoxDecoration(
                  color: ShaktiColors.textHi.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(ShaktiRadius.pill),
                  border: Border.all(color: ShaktiColors.textHi.withValues(alpha: 0.22)),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Center(
                      child: Opacity(
                        opacity: 1 - progress,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.label, style: t.titleMedium?.copyWith(color: ShaktiColors.textHi)),
                            const SizedBox(width: ShaktiSpace.xs),
                            const Icon(Icons.keyboard_double_arrow_right_rounded, color: ShaktiColors.textHi),
                          ],
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: _dx == 0 && !reduced ? ShaktiMotion.base : Duration.zero,
                      curve: ShaktiMotion.curve,
                      left: 6 + _dx.clamp(0.0, travel),
                      child: GestureDetector(
                        key: const ValueKey('swipe-thumb'),
                        onHorizontalDragUpdate: (d) => setState(() => _dx = (_dx + d.delta.dx).clamp(0.0, travel)),
                        onHorizontalDragEnd: (_) {
                          if (_dx / travel >= _threshold) {
                            setState(() => _dx = travel);
                            _fire();
                          } else {
                            setState(() => _dx = 0);
                          }
                        },
                        child: Container(
                          width: _thumb,
                          height: _thumb,
                          decoration: const BoxDecoration(color: ShaktiColors.textHi, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: ShaktiColors.sosDeep, size: 30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: ShaktiSpace.sm),
        Semantics(
          button: true,
          label: 'Cancel SOS',
          onTap: _fire,
          excludeSemantics: true,
          child: TextButton(
            key: const ValueKey('cancel-button'),
            onPressed: _fire,
            style: TextButton.styleFrom(foregroundColor: ShaktiColors.textHi, minimumSize: const Size.fromHeight(ShaktiSize.minTap)),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}
