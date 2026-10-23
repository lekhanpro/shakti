import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/pin_pad.dart';
import '../../../core/widgets/widgets.dart';

/// Bottom sheet that asks for the PIN and resolves `true` once [verify]
/// accepts it. Wrong entries stay in the sheet with an inline error.
Future<bool> showPinCheckSheet(
  BuildContext context, {
  required String title,
  required String message,
  required Future<bool> Function(String pin) verify,
  String submitLabel = 'Confirm',
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PinCheck(title: title, message: message, verify: verify, submitLabel: submitLabel),
  );
  return ok ?? false;
}

class _PinCheck extends StatefulWidget {
  const _PinCheck({required this.title, required this.message, required this.verify, required this.submitLabel});

  final String title;
  final String message;
  final Future<bool> Function(String pin) verify;
  final String submitLabel;

  @override
  State<_PinCheck> createState() => _PinCheckState();
}

class _PinCheckState extends State<_PinCheck> {
  final _pad = GlobalKey<PinPadState>();
  String? _error;
  bool _busy = false;

  Future<void> _submit(String pin) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await widget.verify(pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = 'That PIN is not right. Try again.';
    });
    _pad.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        ShaktiSpace.lg,
        0,
        ShaktiSpace.lg,
        ShaktiSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GlassSurface(
            padding: EdgeInsets.all(ShaktiSpace.sm),
            radius: ShaktiRadius.md,
            child: Icon(Icons.lock_outline_rounded, color: ShaktiColors.lilac),
          ),
          const SizedBox(height: ShaktiSpace.md),
          Semantics(
            header: true,
            child: Text(widget.title, style: t.headlineSmall, textAlign: TextAlign.center),
          ),
          const SizedBox(height: ShaktiSpace.xs),
          Text(widget.message, style: t.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: ShaktiSpace.lg),
          PinPad(key: _pad, onSubmit: _submit, enabled: !_busy, errorText: _error, submitLabel: widget.submitLabel),
        ],
      ),
    );
  }
}
