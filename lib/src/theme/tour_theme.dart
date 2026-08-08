import 'package:flutter/material.dart';

/// Styles used for tour progress indicator display.
enum TourProgressIndicatorType {
  /// Displays dot-based step progress.
  dots,

  /// Displays a fraction like `1 / 4`.
  fraction,
}

/// Visual configuration used by the tour overlay.
class TourTheme {
  /// Creates visual configuration for a tour overlay.
  const TourTheme({
    this.overlayColor = const Color(0x99000000),
    this.overlayBlur = 0.0,
    this.tooltipBackgroundColor,
    this.surfaceTint,
    this.titleTextStyle,
    this.descriptionTextStyle,
    this.indicatorColor,
    this.tooltipBorderRadius = 18.0,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(16),
    this.elevation = 8.0,
    this.shadowColor = const Color(0x44000000),
    this.arrowSize = 12.0,
    this.showArrow = true,
    this.showProgressDots = true,
    this.progressIndicatorType = TourProgressIndicatorType.dots,
    this.nextButtonStyle,
    this.skipButtonStyle,
    this.previousButtonStyle,
  });

  /// The scrim color drawn outside the highlighted target.
  final Color overlayColor;

  /// Optional backdrop blur for the overlay.
  final double overlayBlur;

  /// The tooltip background, or the app color scheme surface when omitted.
  final Color? tooltipBackgroundColor;

  /// Optional surface tint color.
  final Color? surfaceTint;

  /// Optional text style for tooltip titles.
  final TextStyle? titleTextStyle;

  /// Optional text style for tooltip descriptions.
  final TextStyle? descriptionTextStyle;

  /// Color used for the progress indicator.
  final Color? indicatorColor;

  /// Tooltip corner radius in logical pixels.
  final double tooltipBorderRadius;

  /// Inner padding for the tooltip content.
  final EdgeInsets padding;

  /// Minimum margin to keep tooltip away from screen edges.
  final EdgeInsets margin;

  /// Elevation for the tooltip card.
  final double elevation;

  /// Shadow color used for the tooltip.
  final Color shadowColor;

  /// Size of the tooltip arrow in logical pixels.
  final double arrowSize;

  /// Whether to show the arrow pointing at the target.
  final bool showArrow;

  /// Whether to show dot-style progress indicator.
  final bool showProgressDots;

  /// The style of progress indicator used in the tooltip.
  final TourProgressIndicatorType progressIndicatorType;

  /// Optional style for the Next and Done button.
  final ButtonStyle? nextButtonStyle;

  /// Optional style for the Skip button.
  final ButtonStyle? skipButtonStyle;

  /// Optional style for the Previous button.
  final ButtonStyle? previousButtonStyle;
}
