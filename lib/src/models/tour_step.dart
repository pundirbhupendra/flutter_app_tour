import 'package:flutter/widgets.dart';

import '../animation/animation_config.dart';
import '../animation/tour_animation.dart';
import 'spotlight_shape.dart';
import 'tour_id.dart';
import 'tooltip_position.dart';

export 'tooltip_position.dart';

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
    this.spotlightPadding,
    this.spotlightRadius,
    this.spotlightShape,
    this.scrollToTarget = true,
    this.onBeforeShow,
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

  /// Additional space around the highlighted target, in logical pixels.
  final double? spotlightPadding;

  /// Corner radius used when the step uses a rounded-rectangle spotlight.
  final double? spotlightRadius;

  /// Shape used to highlight this step's target.
  final SpotlightShape? spotlightShape;

  /// Whether the controller should scroll this target into view when possible.
  final bool scrollToTarget;

  /// Runs before this step is displayed.
  final Future<void> Function()? onBeforeShow;
}
