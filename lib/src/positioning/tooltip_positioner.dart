import 'package:flutter/widgets.dart';

import '../models/tooltip_position.dart';

/// Calculates tooltip positions while keeping the tooltip inside the viewport.
class TooltipPositioner {
  /// Returns a position for a tooltip of [childSize].
  static Offset position({
    required Rect targetRect,
    required Size childSize,
    required Size screenSize,
    required TooltipPosition preferredPosition,
    double margin = 16.0,
    double gap = 12.0,
  }) {
    final positions = _positionsFor(preferredPosition);
    for (final position in positions) {
      final offset = _offsetFor(position, targetRect, childSize, gap);
      if (_fits(offset, childSize, screenSize, margin)) return offset;
    }
    final fallback = _offsetFor(positions.first, targetRect, childSize, gap);
    return Offset(
      fallback.dx
          .clamp(margin, screenSize.width - childSize.width - margin)
          .toDouble(),
      fallback.dy
          .clamp(margin, screenSize.height - childSize.height - margin)
          .toDouble(),
    );
  }

  static List<TooltipPosition> _positionsFor(TooltipPosition preferred) {
    switch (preferred) {
      case TooltipPosition.top:
        return const [
          TooltipPosition.top,
          TooltipPosition.bottom,
          TooltipPosition.right,
          TooltipPosition.left,
        ];
      case TooltipPosition.left:
        return const [
          TooltipPosition.left,
          TooltipPosition.right,
          TooltipPosition.bottom,
          TooltipPosition.top,
        ];
      case TooltipPosition.right:
        return const [
          TooltipPosition.right,
          TooltipPosition.left,
          TooltipPosition.bottom,
          TooltipPosition.top,
        ];
      case TooltipPosition.bottom:
      case TooltipPosition.auto:
        return const [
          TooltipPosition.bottom,
          TooltipPosition.top,
          TooltipPosition.right,
          TooltipPosition.left,
        ];
    }
  }

  static Offset _offsetFor(
    TooltipPosition position,
    Rect targetRect,
    Size childSize,
    double gap,
  ) {
    switch (position) {
      case TooltipPosition.top:
        return Offset(
          targetRect.center.dx - childSize.width / 2,
          targetRect.top - childSize.height - gap,
        );
      case TooltipPosition.left:
        return Offset(
          targetRect.left - childSize.width - gap,
          targetRect.center.dy - childSize.height / 2,
        );
      case TooltipPosition.right:
        return Offset(
          targetRect.right + gap,
          targetRect.center.dy - childSize.height / 2,
        );
      case TooltipPosition.bottom:
      case TooltipPosition.auto:
        return Offset(
          targetRect.center.dx - childSize.width / 2,
          targetRect.bottom + gap,
        );
    }
  }

  static bool _fits(
    Offset offset,
    Size childSize,
    Size screenSize,
    double margin,
  ) =>
      offset.dx >= margin &&
      offset.dy >= margin &&
      offset.dx + childSize.width <= screenSize.width - margin &&
      offset.dy + childSize.height <= screenSize.height - margin;
}
