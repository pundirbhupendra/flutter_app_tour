import 'package:flutter/widgets.dart';

import '../controller/tour_controller.dart';
import '../models/tour_id.dart';

/// Marks a widget as a target that can be highlighted by a [TourStep].
class TourTarget extends StatefulWidget {
  const TourTarget({
    super.key,
    required this.id,
    required this.controller,
    required this.targetKey,
    required this.child,
  });

  /// The strongly typed identifier used to retrieve this target from [controller].
  final TourId id;

  /// The controller that tracks this target.
  final TourController controller;

  /// The key attached to the wrapped child subtree.
  final GlobalKey targetKey;

  /// The widget to mark as a tour target.
  final Widget child;

  @override
  State<TourTarget> createState() => _TourTargetState();
}

class _TourTargetState extends State<TourTarget> {
  @override
  void initState() {
    super.initState();
    widget.controller.registerTarget(
      id: widget.id,
      targetKey: widget.targetKey,
    );
  }

  @override
  void didUpdateWidget(covariant TourTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.controller != widget.controller ||
        oldWidget.targetKey != widget.targetKey) {
      oldWidget.controller.unregisterTarget(
        id: oldWidget.id,
        targetKey: oldWidget.targetKey,
      );
      widget.controller.registerTarget(
        id: widget.id,
        targetKey: widget.targetKey,
      );
    }
  }

  @override
  void dispose() {
    // Defer unregistration until after the current frame to avoid
    // touching ancestor lookups while the element tree is being unmounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.unregisterTarget(
        id: widget.id,
        targetKey: widget.targetKey,
      );
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: widget.targetKey, child: widget.child);
}
