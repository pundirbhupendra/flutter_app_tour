import 'package:flutter/material.dart';

import '../controller/tour_controller.dart';
import '../overlay/tour_overlay.dart';

/// Builds the overlay UI for a [TourController].
///
/// The controller itself remains context-free and manages only tour state
/// and navigation. [TourScope] renders the active overlay when the tour
/// is started.
class TourScope extends StatefulWidget {
  /// Creates a [TourScope] that hosts a tour overlay.
  const TourScope({
    super.key,
    required this.controller,
    required this.child,
    this.tooltipBuilder,
  });

  /// The tour controller that drives navigation and state.
  final TourController controller;

  /// The widget subtree that the tour should decorate.
  final Widget child;

  /// Optional builder used to render a custom tooltip widget.
  final TourTooltipBuilder? tooltipBuilder;

  @override
  State<TourScope> createState() => _TourScopeState();
}

class _TourScopeState extends State<TourScope> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            if (!widget.controller.isActive) {
              return const SizedBox.shrink();
            }

            return TourOverlay(
              controller: widget.controller,
              tooltipBuilder: widget.tooltipBuilder,
              theme: widget.controller.theme,
            );
          },
        ),
      ],
    );
  }
}
