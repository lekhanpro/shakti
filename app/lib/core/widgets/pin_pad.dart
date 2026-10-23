import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Obscured numeric PIN entry with its own keypad (no system keyboard).
///
/// Digits auto-submit when [maxLength] is reached; between [minLength] and
/// [maxLength] an explicit submit key appears. Call [PinPadState.clear] (via a
/// `GlobalKey`) to reset after a wrong entry, or change [errorText].
class PinPad extends StatefulWidget {
  const PinPad({
    required this.onSubmit,
    this.minLength = 4,
    this.maxLength = 8,
    this.shuffle = false,
    this.errorText,
    this.enabled = true,
    this.submitLabel = 'Unlock',
    this.onChanged,
    super.key,
  }) : assert(minLength >= 4 && maxLength <= 8 && minLength <= maxLength);

  final ValueChanged<String> onSubmit;
  final ValueChanged<String>? onChanged;
  final int minLength;
  final int maxLength;

  /// Randomise digit positions to defeat shoulder-surfing and smudge attacks.
  final bool shuffle;
  final String? errorText;
  final bool enabled;
  final String submitLabel;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _pin = '';
  late List<int> _digits = _layout();

  List<int> _layout() {
    final d = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];
    if (widget.shuffle) d.shuffle(Random.secure());
    return d;
  }

  void clear() {
    setState(() {
      _pin = '';
      if (widget.shuffle) _digits = _layout();
    });
    widget.onChanged?.call(_pin);
  }

  void _tap(int d) {
    if (!widget.enabled || _pin.length >= widget.maxLength) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += '$d');
    widget.onChanged?.call(_pin);
    if (_pin.length == widget.maxLength) _submit();
  }

  void _delete() {
    if (!widget.enabled || _pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
    widget.onChanged?.call(_pin);
  }

  void _submit() {
    if (_pin.length < widget.minLength) return;
    widget.onSubmit(_pin);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hasError = widget.errorText != null;
    final canSubmit =
        _pin.length >= widget.minLength && widget.minLength != widget.maxLength;

    Widget key(
      Widget child, {
      required String label,
      VoidCallback? onTap,
      Key? k,
    }) => Padding(
      padding: const EdgeInsets.all(ShaktiSpace.xs),
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: widget.enabled ? onTap : null,
        child: SizedBox.square(
          dimension: 72,
          child: Material(
            key: k,
            color: onTap == null
                ? Colors.transparent
                : context.shakti.surfaceHigh.withValues(alpha: 0.7),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.enabled ? onTap : null,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );

    Widget digit(int d) => key(
      Text(
        '$d',
        style: t.headlineLarge?.copyWith(color: context.shakti.textHi),
      ),
      label: '$d',
      onTap: () => _tap(d),
      k: ValueKey('pin-$d'),
    );

    final rows = [
      [_digits[0], _digits[1], _digits[2]],
      [_digits[3], _digits[4], _digits[5]],
      [_digits[6], _digits[7], _digits[8]],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          label: '${_pin.length} digits entered',
          excludeSemantics: true,
          child: SizedBox(
            height: 24,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < max(widget.minLength, _pin.length); i++)
                  AnimatedContainer(
                    duration: ShaktiMotion.reduced(context)
                        ? Duration.zero
                        : ShaktiMotion.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length
                          ? (hasError
                                ? context.shakti.sosGlow
                                : context.shakti.textHi)
                          : Colors.transparent,
                      border: Border.all(
                        color: hasError
                            ? context.shakti.sosGlow
                            : context.shakti.textLo,
                        width: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: hasError
                ? Semantics(
                    liveRegion: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: context.shakti.sosGlow,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.errorText!,
                            style: t.bodyMedium?.copyWith(
                              color: context.shakti.sosGlow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
        for (final r in rows)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (final d in r) digit(d)],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            key(
              Icon(
                Icons.check_rounded,
                size: 30,
                color: canSubmit ? context.shakti.safe : Colors.transparent,
              ),
              label: widget.submitLabel,
              onTap: canSubmit ? _submit : null,
              k: const ValueKey('pin-submit'),
            ),
            digit(_digits[9]),
            key(
              Icon(Icons.backspace_outlined, color: context.shakti.textMid),
              label: 'Delete',
              onTap: _pin.isEmpty ? null : _delete,
              k: const ValueKey('pin-delete'),
            ),
          ],
        ),
      ],
    );
  }
}
