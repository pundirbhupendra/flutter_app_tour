import 'package:flutter/material.dart';

import '../models/spotlight_shape.dart';

/// The shape used for a highlight cutout.
/// Paints a dimmed scrim with a transparent rectangular or circular cutout.
class HighlightPainter extends CustomPainter {
  const HighlightPainter({
    required this.highlight,
    this.color = Colors.black54,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.shape = SpotlightShape.roundedRectangle,
  });

  /// The screen-space bounds to cut from the scrim.
  final Rect highlight;

  /// The color painted outside the cutout.
  final Color color;

  /// The radius applied to rectangular cutouts.
  final BorderRadius borderRadius;

  /// Whether the cutout is rectangular or circular.
  final SpotlightShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final cutout = Path();
    switch (shape) {
      case SpotlightShape.circle:
        final diameter = highlight.size.longestSide;
        cutout.addOval(
          Rect.fromCenter(
            center: highlight.center,
            width: diameter,
            height: diameter,
          ),
        );
      case SpotlightShape.oval:
        cutout.addOval(highlight);
      case SpotlightShape.rectangle:
        cutout.addRect(highlight);
      case SpotlightShape.roundedRectangle:
        cutout.addRRect(borderRadius.toRRect(highlight));
    }
    canvas.drawPath(
      Path.combine(PathOperation.difference, overlay, cutout),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(HighlightPainter oldDelegate) =>
      highlight != oldDelegate.highlight ||
      color != oldDelegate.color ||
      borderRadius != oldDelegate.borderRadius ||
      shape != oldDelegate.shape;
}
