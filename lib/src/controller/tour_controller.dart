import 'dart:async';

import 'package:flutter/material.dart';

import '../models/tour_id.dart';
import '../models/tour_step.dart';
import '../models/tour_status.dart';
import '../storage/shared_preferences_tour_storage.dart';
import '../storage/tour_storage.dart';
import '../theme/tour_theme.dart';

typedef TourStepCallback = FutureOr<void> Function(TourStep step);
typedef TourLifecycleCallback = FutureOr<void> Function();

/// Coordinates tour state, transitions, target scrolling, and persistence.
class TourController extends ChangeNotifier {
  /// Creates a controller for [steps].
  TourController({
    required List<TourStep> steps,
    this.scrollDuration = const Duration(milliseconds: 350),
    this.scrollCurve = Curves.easeInOut,
    TourTheme? theme,
    this.storage,
    this.onStarted,
    this.onStepChanged,
    this.onCompleted,
    this.onSkipped,
    this.onDismissed,
  }) : _steps = List<TourStep>.unmodifiable(steps),
       _theme = theme;

  /// The duration used for overlay fade and position transitions.
  static const transitionDuration = Duration(milliseconds: 200);

  final List<TourStep> _steps;
  final Map<TourId, GlobalKey> _targetKeys = {};
  int _currentIndex = 0;
  int _transitionId = 0;
  bool _isActive = false;
  bool _isDisposed = false;
  Timer? _pendingFadeTimer;
  TourStatus _status = TourStatus.idle;

  /// The ordered steps displayed by this tour.
  List<TourStep> get steps => _steps;

  /// The duration used when scrolling a target into view.
  final Duration scrollDuration;

  /// The animation curve used when scrolling a target into view.
  final Curve scrollCurve;

  final TourTheme? _theme;

  /// Optional persistence adapter. Persistence is disabled when omitted.
  final TourStorage? storage;

  /// Called after the tour starts successfully.
  final TourLifecycleCallback? onStarted;

  /// Called whenever a step becomes visible.
  final TourStepCallback? onStepChanged;

  /// Called when the final step is completed.
  final TourLifecycleCallback? onCompleted;

  /// Called when the user skips the tour.
  final TourLifecycleCallback? onSkipped;

  /// Called when the tour is dismissed by completion or skipping.
  final TourLifecycleCallback? onDismissed;

  /// Visual configuration used by the overlay.
  ///
  /// The fallback also keeps an existing controller safe during hot reloads
  /// that introduce theme support.
  TourTheme get theme => _theme ?? const TourTheme();

  /// The zero-based index of the currently displayed step.
  int get currentIndex => _currentIndex;

  /// The current step, or `null` when this tour has no steps.
  TourStep? get currentStep =>
      _currentIndex >= 0 && _currentIndex < _steps.length
      ? _steps[_currentIndex]
      : null;

  /// Whether the current step is the first step.
  bool get isFirstStep => _steps.isNotEmpty && _currentIndex == 0;

  /// Whether the current step is the final step.
  bool get isLastStep =>
      _steps.isNotEmpty && _currentIndex == _steps.length - 1;

  /// Whether the tour is currently active.
  bool get isActive => _isActive;

  /// The current lifecycle state of the tour.
  TourStatus get status => _status;

  /// Returns whether [tourId] has been completed or skipped previously.
  static Future<bool> hasSeenTour(String tourId) async {
    return const SharedPreferencesTourStorage().hasSeen(tourId);
  }

  /// Persists that [tourId] has been completed or skipped.
  static Future<void> markTourAsSeen(String tourId) async {
    await const SharedPreferencesTourStorage().markSeen(tourId);
  }

  /// Starts the tour. Repeated calls while it is running are ignored.
  /// Starts the tour from its first valid target.
  ///
  /// This activates the controller and advances to the first step that has
  /// a mounted target. It performs any necessary scrolling via the
  /// surrounding UI (through `TourScope`) and notifies listeners to show the
  /// overlay.
  Future<void> start() async {
    if (_steps.isEmpty || _isDisposed || _status == TourStatus.running) return;
    final transitionId = ++_transitionId;
    await _fadeOutIfVisible(transitionId);
    if (!_isCurrentTransition(transitionId)) return;
    _currentIndex = 0;
    _status = TourStatus.running;
    await _activateNextAvailableStep(transitionId);
    if (_isCurrentTransition(transitionId) && _status == TourStatus.running) {
      await _invokeLifecycleCallback(onStarted);
    }
  }

  /// Advances to the next valid target, finishing after the final step.
  ///
  /// If the controller is inactive or disposed this method is a no-op.
  Future<void> next() async {
    if (!_isActive || _isDisposed || _status != TourStatus.running) return;
    final transitionId = ++_transitionId;
    await _fadeOutIfVisible(transitionId);
    if (!_isCurrentTransition(transitionId)) return;
    _currentIndex++;
    await _activateNextAvailableStep(transitionId);
  }

  /// Returns to the previous valid target when one is available.
  ///
  /// If there is no previous step or the controller is inactive this method
  /// does nothing.
  Future<void> previous() async {
    if (!_isActive ||
        isFirstStep ||
        _isDisposed ||
        _status != TourStatus.running)
      return;
    final transitionId = ++_transitionId;
    await _fadeOutIfVisible(transitionId);
    if (!_isCurrentTransition(transitionId)) return;
    _currentIndex--;
    await _activatePreviousAvailableStep(transitionId);
  }

  /// Skips all remaining steps and fades out the overlay.
  void skip() {
    if (_isDisposed || _status != TourStatus.running) return;
    _transitionId++;
    _isActive = false;
    _status = TourStatus.skipped;
    _notifySafely();
    unawaited(_invokeLifecycleCallback(onSkipped));
    unawaited(_invokeLifecycleCallback(onDismissed));
  }

  /// Completes the tour.
  ///
  /// Marks the controller inactive and notifies listeners so the overlay
  /// can hide. Does not persist seen state; callers should use
  /// [markTourAsSeen] when appropriate.
  void complete() {
    if (_isDisposed || _status != TourStatus.running) return;
    _transitionId++;
    _isActive = false;
    _status = TourStatus.completed;
    _notifySafely();
    unawaited(_invokeLifecycleCallback(onCompleted));
    unawaited(_invokeLifecycleCallback(onDismissed));
  }

  /// Completes the tour. Kept as a compatibility alias for [complete].
  void finish() => complete();

  /// Resets the tour to its initial state without invoking lifecycle callbacks.
  void reset() {
    if (_isDisposed) return;
    _transitionId++;
    _isActive = false;
    _currentIndex = 0;
    _status = TourStatus.idle;
    _notifySafely();
  }

  /// Registers [targetKey] as the target identified by [id].
  ///
  /// Targets should call this during their `initState` to make themselves
  /// discoverable by the controller. The `targetKey` is used to compute the
  /// target's global bounds.
  void registerTarget({required TourId id, required GlobalKey targetKey}) {
    _targetKeys[id] = targetKey;
  }

  /// Removes [id] from the target registry.
  ///
  /// If it is the active target, the controller advances gracefully instead of
  /// trying to paint a highlight around a disposed render object.
  void unregisterTarget({required TourId id, required GlobalKey targetKey}) {
    if (_targetKeys[id] == targetKey) _targetKeys.remove(id);
    if (_isActive && currentStep?.id == id) unawaited(_advanceWithoutFade());
  }

  Future<void> _advanceWithoutFade() async {
    if (!_isActive || _isDisposed || _status != TourStatus.running) return;
    final transitionId = ++_transitionId;
    _currentIndex++;
    await _activateNextAvailableStep(transitionId);
  }

  /// Rebuilds the overlay after layout-affecting events such as rotation.
  ///
  /// This method is safe to call from UI code when the layout has changed;
  /// it will advance the tour if the current target is no longer mounted.
  void refreshLayout() {
    if (_isActive && currentStep?.targetKey.currentContext == null) {
      unawaited(next());
      return;
    }
    _notifySafely();
  }

  /// Returns the global bounds of the target registered under [id], if mounted.
  ///
  /// Returns `null` when the target is not currently mounted in the tree.
  Rect? targetRect(TourId id) => rectForKey(_targetKeys[id]);

  /// Returns global bounds for [targetKey], or `null` when it is not mounted.
  ///
  /// This is a convenience helper used by the overlay to position highlights
  /// and tooltips.
  static Rect? rectForKey(GlobalKey? targetKey) {
    RenderBox? renderBox;
    try {
      renderBox = targetKey?.currentContext?.findRenderObject() as RenderBox?;
    } catch (_) {
      // The element may be inactive (being unmounted). Treat as not mounted.
      return null;
    }
    if (renderBox == null || !renderBox.hasSize) return null;
    return renderBox.localToGlobal(Offset.zero) & renderBox.size;
  }

  Future<void> _activateNextAvailableStep(int transitionId) async {
    while (_isCurrentTransition(transitionId) &&
        _currentIndex < _steps.length) {
      if (!await _prepareCurrentStep(transitionId)) {
        _currentIndex++;
        continue;
      }
      if (await _scrollCurrentTargetIntoView(transitionId)) {
        _isActive = true;
        _status = TourStatus.running;
        _notifySafely();
        await _invokeStepCallback(onStepChanged, currentStep);
        return;
      }
      _currentIndex++;
    }
    if (_isCurrentTransition(transitionId)) complete();
  }

  Future<void> _activatePreviousAvailableStep(int transitionId) async {
    while (_isCurrentTransition(transitionId) && _currentIndex >= 0) {
      if (!await _prepareCurrentStep(transitionId)) {
        _currentIndex--;
        continue;
      }
      if (await _scrollCurrentTargetIntoView(transitionId)) {
        _isActive = true;
        _status = TourStatus.running;
        _notifySafely();
        await _invokeStepCallback(onStepChanged, currentStep);
        return;
      }
      _currentIndex--;
    }
    if (_isCurrentTransition(transitionId)) complete();
  }

  Future<bool> _prepareCurrentStep(int transitionId) async {
    if (!_isCurrentTransition(transitionId)) return false;
    final callback = currentStep?.onBeforeShow;
    if (callback == null) return true;
    try {
      await callback();
      return _isCurrentTransition(transitionId);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _scrollCurrentTargetIntoView(int transitionId) async {
    final targetContext = currentStep?.targetKey.currentContext;
    if (targetContext == null) return false;
    if (currentStep?.scrollToTarget == true &&
        Scrollable.maybeOf(targetContext) != null) {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.5,
        duration: scrollDuration,
        curve: scrollCurve,
      );
      await WidgetsBinding.instance.endOfFrame;
    }
    return _isCurrentTransition(transitionId) &&
        currentStep?.targetKey.currentContext != null;
  }

  Future<void> _fadeOutIfVisible(int transitionId) async {
    if (!_isActive) return;
    _isActive = false;
    _notifySafely();
    final completer = Completer<void>();
    _pendingFadeTimer = Timer(transitionDuration, () {
      _pendingFadeTimer = null;
      completer.complete();
    });
    await completer.future;
    if (!_isCurrentTransition(transitionId)) return;
  }

  bool _isCurrentTransition(int transitionId) =>
      !_isDisposed && transitionId == _transitionId;

  Future<void> _invokeLifecycleCallback(TourLifecycleCallback? callback) async {
    if (callback == null) return;
    try {
      await callback();
    } catch (_) {
      // Lifecycle hooks must not break tour navigation.
    }
  }

  Future<void> _invokeStepCallback(
    TourStepCallback? callback,
    TourStep? step,
  ) async {
    if (callback == null || step == null) return;
    try {
      await callback(step);
    } catch (_) {
      // Lifecycle hooks must not break tour navigation.
    }
  }

  void _notifySafely() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _transitionId++;
    _pendingFadeTimer?.cancel();
    _pendingFadeTimer = null;
    super.dispose();
  }
}
