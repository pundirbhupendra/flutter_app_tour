import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../controller/tour_controller.dart';
import '../models/tour_step.dart';
import '../positioning/tooltip_positioner.dart';
import '../theme/tour_theme.dart';
import 'highlight_painter.dart';
import '../animation/animation_controller_layer.dart';
import '../animation/animation_config.dart';

/// Builds a tooltip widget for a tour step.
///
/// The callback receives the current [step], the active [controller], the
/// target rectangle being highlighted, the available [screenSize], and the
/// active [theme].
typedef TourTooltipBuilder =
    Widget Function(
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
        final theme = widget.theme ?? controller.theme;

        final targetRect =
            TourController.rectForKey(step.targetKey) ??
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
                final highlight = _spotlightRect(
                  animatedRect ?? targetRect,
                  step,
                  theme,
                  screenSize,
                );
                final overlayColor = theme.overlayOpacity == null
                    ? theme.overlayColor
                    : theme.overlayColor.withValues(
                        alpha: theme.overlayOpacity,
                      );
                return Stack(
                  children: [
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: theme.overlayBlur,
                          sigmaY: theme.overlayBlur,
                        ),
                        child: Container(color: overlayColor),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: !controller.isActive,
                        child: CustomPaint(
                          painter: HighlightPainter(
                            highlight: highlight,
                            color: overlayColor,
                            shape: step.spotlightShape ?? theme.spotlightShape,
                            borderRadius: BorderRadius.circular(
                              step.spotlightRadius ?? theme.spotlightRadius,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimationControllerLayer(
                      animationConfig:
                          (step.animationConfig ??
                                  TourAnimationConfig.defaultConfig)
                              .copyWith(type: step.animation),
                      targetRect: highlight,
                      child: const SizedBox.shrink(),
                    ),
                    CustomSingleChildLayout(
                      delegate: _TooltipLayoutDelegate(
                        targetRect: highlight,
                        preferredPosition: step.tooltipPosition,
                        screenSize: screenSize,
                      ),
                      child: widget.tooltipBuilder != null
                          ? Builder(
                              builder: (ctx) => widget.tooltipBuilder!(
                                ctx,
                                step,
                                controller,
                                highlight,
                                screenSize,
                                theme,
                              ),
                            )
                          : _FloatingTooltipCard(
                              step: step,
                              controller: controller,
                              theme: theme,
                              targetRect: highlight,
                              screenSize: screenSize,
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Rect _spotlightRect(
    Rect targetRect,
    TourStep step,
    TourTheme theme,
    Size screenSize,
  ) {
    final expanded = targetRect.inflate(
      step.spotlightPadding ?? theme.spotlightPadding,
    );
    return Rect.fromLTRB(
      expanded.left.clamp(0.0, screenSize.width).toDouble(),
      expanded.top.clamp(0.0, screenSize.height).toDouble(),
      expanded.right.clamp(0.0, screenSize.width).toDouble(),
      expanded.bottom.clamp(0.0, screenSize.height).toDouble(),
    );
  }
}

class _FloatingTooltipCard extends StatelessWidget {
  const _FloatingTooltipCard({
    required this.step,
    required this.controller,
    required this.theme,
    required this.targetRect,
    required this.screenSize,
  });

  final TourStep step;
  final TourController controller;
  final TourTheme theme;
  final Rect targetRect;
  final Size screenSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxWidth = math.min(360.0, screenSize.width - 48);
    final bg = theme.tooltipBackgroundColor ?? colorScheme.surface;
    final radius = BorderRadius.circular(theme.tooltipBorderRadius);
    final indicatorColor = theme.indicatorColor ?? colorScheme.primary;

    final progressLine =
        theme.progressIndicatorType == TourProgressIndicatorType.fraction
        ? Text(
            '${controller.currentIndex + 1} / ${controller.steps.length}',
            style:
                theme.descriptionTextStyle ??
                Theme.of(context).textTheme.bodyMedium,
          )
        : _StepDots(
            currentIndex: controller.currentIndex,
            stepCount: controller.steps.length,
            color: indicatorColor,
          );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: bg,
        elevation: theme.elevation,
        shadowColor: theme.shadowColor,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: Padding(
          padding: theme.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style:
                    theme.titleTextStyle ??
                    Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                step.description,
                style:
                    theme.descriptionTextStyle ??
                    Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (theme.showStepIndicator ||
                      theme.progressIndicatorType ==
                          TourProgressIndicatorType.fraction)
                    Expanded(child: progressLine),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (!controller.isFirstStep && theme.showPreviousButton)
                    TextButton(
                      onPressed: controller.previous,
                      style: theme.previousButtonStyle,
                      child: const Text('← Previous'),
                    )
                  else if (theme.showSkipButton)
                    TextButton(
                      onPressed: controller.skip,
                      style: theme.skipButtonStyle,
                      child: const Text('Skip'),
                    ),
                  const Spacer(),
                  if (theme.showNextButton)
                    FilledButton(
                      onPressed: controller.isLastStep
                          ? controller.complete
                          : controller.next,
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

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.currentIndex,
    required this.stepCount,
    required this.color,
  });

  final int currentIndex;
  final int stepCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(stepCount, (index) {
        final bool isActive = index == currentIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Container(
            width: isActive ? 12 : 8,
            height: isActive ? 12 : 8,
            decoration: BoxDecoration(
              color: isActive ? color : color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
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
    return TooltipPositioner.position(
      targetRect: targetRect,
      childSize: childSize,
      screenSize: size,
      preferredPosition: preferredPosition,
      margin: _margin,
      gap: _gap,
    );
  }

  @override
  bool shouldRelayout(_TooltipLayoutDelegate oldDelegate) =>
      targetRect != oldDelegate.targetRect ||
      preferredPosition != oldDelegate.preferredPosition ||
      screenSize != oldDelegate.screenSize;
}
