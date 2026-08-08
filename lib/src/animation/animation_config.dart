import 'package:flutter/animation.dart';

import 'tour_animation.dart';

/// Configuration for a highlight animation.
class TourAnimationConfig {
  const TourAnimationConfig({
    this.type = TourAnimation.pulse,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeInOut,
    this.repeat = false,
  });

  /// Default config used when none is provided.
  static const defaultConfig = TourAnimationConfig();

  final TourAnimation type;
  final Duration duration;
  final Curve curve;
  final bool repeat;

  /// Returns a copy of this config with some fields replaced.
  TourAnimationConfig copyWith({
    TourAnimation? type,
    Duration? duration,
    Curve? curve,
    bool? repeat,
  }) {
    return TourAnimationConfig(
      type: type ?? this.type,
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      repeat: repeat ?? this.repeat,
    );
  }
}
