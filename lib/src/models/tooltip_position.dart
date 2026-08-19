/// Controls where a tour tooltip is placed relative to its target.
enum TooltipPosition {
  /// Places the tooltip above the target.
  top,

  /// Places the tooltip below the target.
  bottom,

  /// Places the tooltip to the left of the target.
  left,

  /// Places the tooltip to the right of the target.
  right,

  /// Selects the best position based on available space.
  auto,
}
