import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'animation_config.dart';
import 'tour_animation.dart';

/// A rendering-only widget that paints and animates the highlight layer.
///
/// This widget is independent from the overlay content and only repaints the
/// animated layer to avoid rebuilding the tooltip or the rest of the overlay.
class AnimationControllerLayer extends StatefulWidget {
  const AnimationControllerLayer({
    super.key,
    required this.animationConfig,
    required this.targetRect,
    required this.child,
    this.onDispose,
  });

  final TourAnimationConfig animationConfig;
  final Rect targetRect;
  final Widget child;
  final VoidCallback? onDispose;

  @override
  State<AnimationControllerLayer> createState() =>
      _AnimationControllerLayerState();
}

class _AnimationControllerLayerState extends State<AnimationControllerLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationConfig.duration,
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: widget.animationConfig.curve,
    );

    if (widget.animationConfig.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimationControllerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationConfig.duration != widget.animationConfig.duration ||
        oldWidget.animationConfig.curve != widget.animationConfig.curve) {
      _controller.duration = widget.animationConfig.duration;
      _controller.reset();
      if (widget.animationConfig.repeat) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          return CustomPaint(
            painter: _LayerPainter(
              progress: _progress.value,
              animationConfig: widget.animationConfig,
              targetRect: widget.targetRect,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _LayerPainter extends CustomPainter {
  _LayerPainter({
    required this.progress,
    required this.animationConfig,
    required this.targetRect,
  });

  final double progress;
  final TourAnimationConfig animationConfig;
  final Rect targetRect;

  @override
  void paint(Canvas canvas, Size size) {
    // For now, implement pulse as a scalable outline. Other animations will
    // be handled by other painters or branches kept minimal.
    switch (animationConfig.type) {
      case TourAnimation.none:
        break;
      case TourAnimation.pulse:
        _paintPulse(canvas, size);
        break;
      case TourAnimation.glow:
        _paintGlow(canvas, size);
        break;
      case TourAnimation.ripple:
        _paintRipple(canvas, size);
        break;
      case TourAnimation.bounce:
        _paintBounce(canvas, size);
        break;
      case TourAnimation.floating:
        _paintFloating(canvas, size);
        break;
    }
  }

  void _paintPulse(Canvas canvas, Size size) {
    final center = targetRect.center;
    final radius =
        (targetRect.shortestSide / 2) *
        (1 + 0.08 * math.sin(progress * 2 * math.pi));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.7 * (1 - progress));
    canvas.drawCircle(center, radius, paint);
  }

  void _paintGlow(Canvas canvas, Size size) {
    final center = targetRect.center;
    final baseRadius = targetRect.shortestSide / 2 + 8.0;
    final radius = baseRadius + 12.0 * progress;
    final paint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * (0.5 + progress))
      ..color = const Color(
        0xFF42A5F5,
      ).withValues(alpha: 0.25 + 0.5 * (1 - (progress - 0.5).abs()));
    canvas.drawCircle(center, radius, paint);
  }

  void _paintRipple(Canvas canvas, Size size) {
    final center = targetRect.center;
    final maxRadius = math.max(size.width, size.height);
    final radius = progress * maxRadius;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF42A5F5).withValues(alpha: 1 - progress);
    canvas.drawCircle(center, radius, paint);
  }

  void _paintBounce(Canvas canvas, Size size) {
    // Bounce visualized as a pulsating shadow offset.
    final center = targetRect.center;
    final offset = Offset(0, -8 * (1 - (progress * 2 - 1).abs()));
    final r = targetRect.shortestSide / 2 + 6;
    final paint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.3);
    canvas.drawCircle(center + offset, r, paint);
  }

  void _paintFloating(Canvas canvas, Size size) {
    final center =
        targetRect.center + Offset(0, math.sin(progress * 2 * math.pi) * 6);
    final r = targetRect.shortestSide / 2 + 4;
    final paint = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.25);
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(covariant _LayerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationConfig != animationConfig ||
        oldDelegate.targetRect != targetRect;
  }
}
