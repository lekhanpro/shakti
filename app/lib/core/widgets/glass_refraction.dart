import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A small, static lens for a control whose ancestor supplies a tight ClipRRect.
///
/// This widget adds no layout, tint, border or clipping. [radius] must match the
/// caller's logical corner radius. Impeller supplies the filter texture bounds;
/// they approximate the clipped control's bounds, rather than a native platform
/// material. Transformed clips and platform views still require device checks.
///
/// Unsupported renderers and shader load failures use a modest blur. Reduced
/// motion also uses blur, with no lens distortion. Accessibility modes bypass
/// the filter entirely so the caller can provide its opaque material.
class GlassRefraction extends StatefulWidget {
  const GlassRefraction({
    required this.child,
    required this.radius,
    this.enabled = true,
    super.key,
  }) : assert(radius >= 0 && radius < double.infinity);

  final Widget child;
  final double radius;
  final bool enabled;

  @override
  State<GlassRefraction> createState() => _GlassRefractionState();
}

class _GlassRefractionState extends State<GlassRefraction> {
  static Future<ui.FragmentProgram?>? _programFuture;
  static final _fallbackBlur = ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7);

  ui.FragmentShader? _shader;
  ui.ImageFilter? _lensFilter;
  bool _loading = false;
  bool _failed = false;

  static Future<ui.FragmentProgram?> _loadProgram() =>
      _programFuture ??= _tryLoadProgram();

  static Future<ui.FragmentProgram?> _tryLoadProgram() async {
    try {
      return await ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag');
    } catch (_) {
      // Cache the failed load too: each glass control must not retry the asset.
      return null;
    }
  }

  bool get _accessibilityBypass {
    final media = MediaQuery.maybeOf(context);
    return (media?.highContrast ?? false) ||
        (media?.accessibleNavigation ?? false);
  }

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureShader();
  }

  @override
  void didUpdateWidget(covariant GlassRefraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureShader();
  }

  void _ensureShader() {
    if (_shader != null ||
        _loading ||
        _failed ||
        !widget.enabled ||
        _accessibilityBypass ||
        _reducedMotion ||
        !ui.ImageFilter.isShaderFilterSupported) {
      return;
    }
    _loading = true;
    unawaited(_createShader());
  }

  Future<void> _createShader() async {
    final program = await _loadProgram();
    if (!mounted) return;
    ui.FragmentShader? shader;
    ui.ImageFilter? filter;
    if (program != null && ui.ImageFilter.isShaderFilterSupported) {
      try {
        shader = program.fragmentShader();
        filter = ui.ImageFilter.shader(shader);
      } catch (_) {
        shader?.dispose();
        shader = null;
      }
    }
    setState(() {
      _shader = shader;
      _lensFilter = filter;
      _failed = filter == null;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _accessibilityBypass) return widget.child;

    final shader = _shader;
    final lens = _lensFilter;
    final useLens =
        shader != null &&
        lens != null &&
        !_reducedMotion &&
        ui.ImageFilter.isShaderFilterSupported;
    if (useLens) {
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
      // Float slots 0/1 (texture size) and image sampler 0 belong to the engine.
      shader.setFloat(2, widget.radius * dpr);
      shader.setFloat(3, dpr);
    }
    return BackdropFilter(
      filter: useLens ? lens : _fallbackBlur,
      child: widget.child,
    );
  }
}
