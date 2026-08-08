import 'package:flutter/widgets.dart';

import '../animation/animation_config.dart';
import '../animation/tour_animation.dart';

import 'tour_id.dart';

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

  /// Lets the tour choose the most suitable position.
  auto,
}

/// Describes one target and its content in an application tour.
class TourStep {
  const TourStep({
    required this.id,
    required this.targetKey,
    required this.title,
    required this.description,
    this.tooltipPosition = TooltipPosition.auto,
    this.animation = TourAnimation.pulse,
    this.animationConfig,
  });

  /// A strongly typed identifier for this step.
  final TourId id;

  /// The key assigned to the target widget this step highlights.
  final GlobalKey targetKey;

  /// The heading displayed for this step.
  final String title;

  /// Supporting text displayed for this step.
  final String description;

  /// The preferred position of this step's tooltip.
  final TooltipPosition tooltipPosition;

  /// The animation applied to the highlight layer when this step becomes active.
  ///
  /// Defaults to [TourAnimation.pulse]. Set to [TourAnimation.none] to disable.
  final TourAnimation animation;

  /// Optional per-step animation configuration. When omitted, sensible
  /// defaults from [TourAnimationConfig.defaultConfig] are used.
  final TourAnimationConfig? animationConfig;
}
