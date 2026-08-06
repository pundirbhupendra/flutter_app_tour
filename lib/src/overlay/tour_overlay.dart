import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controller/tour_controller.dart';
import '../models/tour_step.dart';
import '../theme/tour_theme.dart';
import 'highlight_painter.dart';

/// Builds a tooltip widget for a tour step.
///
/// The callback receives the current [step], the active [controller], the
/// target rectangle being highlighted, the available [screenSize], and the
/// active [theme].
typedef TourTooltipBuilder = Widget Function(
  BuildContext context,
  TourStep step,
  TourController controller,
  Rect targetRect,
  Size screenSize,
  TourTheme theme,
);

/// Renders the current tour step in an [OverlayEntry].
class TourOverlay extends StatefulWidget {
  /// Creates an overlay bound to [controller].
  const TourOverlay({
    super.key,
    required this.controller,
    this.tooltipBuilder,
    this.theme,
  });

  /// The controller that supplies the current step and handles actions.
  final TourController controller;

  /// Optional custom tooltip builder.
  final TourTooltipBuilder? tooltipBuilder;

  /// Optional theme override for the overlay.
  final TourTheme? theme;

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay> {
  Size? _lastScreenSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenSize = MediaQuery.sizeOf(context);
    if (_lastScreenSize == screenSize) return;
    _lastScreenSize = screenSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.refreshLayout();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final screenSize = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final step = controller.currentStep;
        if (step == null) return const SizedBox.shrink();

        final targetRect = TourController.rectForKey(step.targetKey) ??
            Rect.fromCenter(
              center: screenSize.center(Offset.zero),
              width: 0,
              height: 0,
            );

        return AnimatedOpacity(
          opacity: controller.isActive ? 1 : 0,
          duration: TourController.transitionDuration,
          curve: Curves.easeInOut,
          child: IgnorePointer(
            ignoring: !controller.isActive,
            child: TweenAnimationBuilder<Rect?>(
              duration: TourController.transitionDuration,
              curve: Curves.easeInOut,
              tween: RectTween(end: targetRect),
              builder: (context, animatedRect, _) {
                final highlight = animatedRect ?? targetRect;
                return Material(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: HighlightPainter(
                            highlight: highlight,
                            color: controller.theme.overlayColor,
                          ),
                        ),
                      ),
                      CustomSingleChildLayout(
                        delegate: _TooltipLayoutDelegate(
                          targetRect: highlight,
                          preferredPosition: step.tooltipPosition,
                          screenSize: screenSize,
                        ),
                        child: _TooltipBubble(
                          step: step,
                          controller: controller,
                          theme: controller.theme,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({
    required this.step,
    required this.controller,
    required this.theme,
  });

  final TourStep step;
  final TourController controller;
  final TourTheme theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxWidth = math.min(320.0, MediaQuery.sizeOf(context).width - 32);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: theme.tooltipBackgroundColor ?? colorScheme.surface,
        borderRadius: theme.tooltipBorderRadius,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: theme.titleTextStyle ?? Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                step.description,
                style: theme.descriptionTextStyle,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: controller.skip,
                    style: theme.skipButtonStyle,
                    child: const Text('Skip'),
                  ),
                  if (!controller.isFirstStep)
                    TextButton(
                      onPressed: () => controller.previous(),
                      style: theme.previousButtonStyle,
                      child: const Text('Previous'),
                    ),
                  FilledButton(
                    onPressed: controller.isLastStep
                        ? controller.finish
                        : () => controller.next(),
                    style: theme.nextButtonStyle,
                    child: Text(controller.isLastStep ? 'Done' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TooltipLayoutDelegate extends SingleChildLayoutDelegate {
  const _TooltipLayoutDelegate({
    required this.targetRect,
    required this.preferredPosition,
    required this.screenSize,
  });

  static const _gap = 12.0;
  static const _margin = 16.0;

  final Rect targetRect;
  final TooltipPosition preferredPosition;
  final Size screenSize;

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final positions = _positionsFor(preferredPosition);
    for (final position in positions) {
      final offset = _offsetFor(position, childSize);
      if (_fits(offset, childSize)) return offset;
    }
    final fallback = _offsetFor(positions.first, childSize);
    return Offset(
      fallback.dx
          .clamp(_margin, size.width - childSize.width - _margin)
          .toDouble(),
      fallback.dy
          .clamp(_margin, size.height - childSize.height - _margin)
          .toDouble(),
    );
  }

  List<TooltipPosition> _positionsFor(TooltipPosition preferred) {
    switch (preferred) {
      case TooltipPosition.top:
        return const [TooltipPosition.top, TooltipPosition.bottom, TooltipPosition.right, TooltipPosition.left];
      case TooltipPosition.left:
        return const [TooltipPosition.left, TooltipPosition.right, TooltipPosition.bottom, TooltipPosition.top];
      case TooltipPosition.right:
        return const [TooltipPosition.right, TooltipPosition.left, TooltipPosition.bottom, TooltipPosition.top];
      case TooltipPosition.bottom:
      case TooltipPosition.auto:
        return const [TooltipPosition.bottom, TooltipPosition.top, TooltipPosition.right, TooltipPosition.left];
    }
  }

  Offset _offsetFor(TooltipPosition position, Size childSize) {
    switch (position) {
      case TooltipPosition.top:
        return Offset(targetRect.center.dx - childSize.width / 2, targetRect.top - childSize.height - _gap);
      case TooltipPosition.left:
        return Offset(targetRect.left - childSize.width - _gap, targetRect.center.dy - childSize.height / 2);
      case TooltipPosition.right:
        return Offset(targetRect.right + _gap, targetRect.center.dy - childSize.height / 2);
      case TooltipPosition.bottom:
      case TooltipPosition.auto:
        return Offset(targetRect.center.dx - childSize.width / 2, targetRect.bottom + _gap);
    }
  }

  bool _fits(Offset offset, Size childSize) =>
      offset.dx >= _margin &&
      offset.dy >= _margin &&
      offset.dx + childSize.width <= screenSize.width - _margin &&
      offset.dy + childSize.height <= screenSize.height - _margin;

  @override
  bool shouldRelayout(_TooltipLayoutDelegate oldDelegate) =>
      targetRect != oldDelegate.targetRect ||
      preferredPosition != oldDelegate.preferredPosition ||
      screenSize != oldDelegate.screenSize;
}
