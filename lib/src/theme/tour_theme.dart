import 'package:flutter/material.dart';

/// Visual configuration used by the tour overlay.
class TourTheme {
  /// Creates visual configuration for a tour overlay.
  const TourTheme({
    this.overlayColor = Colors.black54,
    this.tooltipBackgroundColor,
    this.titleTextStyle,
    this.descriptionTextStyle,
    this.tooltipBorderRadius = const BorderRadius.all(Radius.circular(12)),
    this.nextButtonStyle,
    this.skipButtonStyle,
    this.previousButtonStyle,
  });

  /// The scrim color drawn outside the highlighted target.
  final Color overlayColor;

  /// The tooltip background, or the app color scheme surface when omitted.
  final Color? tooltipBackgroundColor;

  /// Optional text style for tooltip titles.
  final TextStyle? titleTextStyle;

  /// Optional text style for tooltip descriptions.
  final TextStyle? descriptionTextStyle;

  /// The shape of the tooltip bubble.
  final BorderRadius tooltipBorderRadius;

  /// Optional style for the Next and Done button.
  final ButtonStyle? nextButtonStyle;

  /// Optional style for the Skip button.
  final ButtonStyle? skipButtonStyle;

  /// Optional style for the Previous button.
  final ButtonStyle? previousButtonStyle;
}
