import 'package:flutter/material.dart';

import '../models/tour_step.dart';

/// Paints a small triangular arrow pointing towards [target].
class ArrowPainter extends CustomPainter {
  ArrowPainter({
    required this.color,
    required this.size,
    required this.position,
    required this.direction,
  });

  final Color color;
  final double size;
  final Offset position;
  final TooltipPosition direction;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()..color = color;
    final path = Path();
    switch (direction) {
      case TooltipPosition.top:
        path.moveTo(position.dx, position.dy);
        path.relativeLineTo(-size, -size);
        path.relativeLineTo(size * 2, 0);
        path.close();
        break;
      case TooltipPosition.bottom:
        path.moveTo(position.dx, position.dy);
        path.relativeLineTo(-size, size);
        path.relativeLineTo(size * 2, 0);
        path.close();
        break;
      case TooltipPosition.left:
        path.moveTo(position.dx, position.dy);
        path.relativeLineTo(-size, -size);
        path.relativeLineTo(0, size * 2);
        path.close();
        break;
      case TooltipPosition.right:
        path.moveTo(position.dx, position.dy);
        path.relativeLineTo(size, -size);
        path.relativeLineTo(0, size * 2);
        path.close();
        break;
      case TooltipPosition.auto:
        // Default to top.
        path.moveTo(position.dx, position.dy);
        path.relativeLineTo(-size, -size);
        path.relativeLineTo(size * 2, 0);
        path.close();
        break;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.size != size ||
        oldDelegate.position != position ||
        oldDelegate.direction != direction;
  }
}
