import 'package:flutter/material.dart';

/// The shape used for a highlight cutout.
enum HighlightShape {
  /// A rounded rectangle matching the highlight bounds.
  roundedRectangle,

  /// A circle inscribed within the highlight bounds.
  circle,
}

/// Paints a dimmed scrim with a transparent rectangular or circular cutout.
class HighlightPainter extends CustomPainter {
  const HighlightPainter({
    required this.highlight,
    this.color = Colors.black54,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.shape = HighlightShape.roundedRectangle,
  });

  /// The screen-space bounds to cut from the scrim.
  final Rect highlight;

  /// The color painted outside the cutout.
  final Color color;

  /// The radius applied to rectangular cutouts.
  final BorderRadius borderRadius;

  /// Whether the cutout is rectangular or circular.
  final HighlightShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final cutout = Path();
    if (shape == HighlightShape.circle) {
      cutout.addOval(highlight);
    } else {
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
