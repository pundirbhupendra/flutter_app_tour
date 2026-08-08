import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tour_id.dart';
import '../models/tour_step.dart';
import '../theme/tour_theme.dart';

/// Coordinates tour state, transitions, target scrolling, and persistence.
class TourController extends ChangeNotifier {
  /// Creates a controller for [steps].
   TourController({
    required List<TourStep> steps,
    this.scrollDuration = const Duration(milliseconds: 350),
    this.scrollCurve = Curves.easeInOut,
    this._theme,
  }) : _steps = List<TourStep>.unmodifiable(steps);

  /// The duration used for overlay fade and position transitions.
  static const transitionDuration = Duration(milliseconds: 200);

  static const _seenKeyPrefix = 'flutter_app_tour.seen.';

  final List<TourStep> _steps;
  final Map<TourId, GlobalKey> _targetKeys = {};
  int _currentIndex = 0;
  int _transitionId = 0;
  bool _isActive = false;
  bool _isDisposed = false;
  Timer? _pendingFadeTimer;

  /// The ordered steps displayed by this tour.
  List<TourStep> get steps => _steps;

  /// The duration used when scrolling a target into view.
  final Duration scrollDuration;

  /// The animation curve used when scrolling a target into view.
  final Curve scrollCurve;

  final TourTheme? _theme;

  /// Visual configuration used by the overlay.
  ///
  /// The fallback also keeps an existing controller safe during hot reloads
  /// that introduce theme support.
  TourTheme get theme => _theme ?? const TourTheme();

  /// The zero-based index of the currently displayed step.
  int get currentIndex => _currentIndex;

  /// The current step, or `null` when this tour has no steps.
  TourStep? get currentStep => _steps.isEmpty ? null : _steps[_currentIndex];

  /// Whether the current step is the first step.
  bool get isFirstStep => _steps.isNotEmpty && _currentIndex == 0;

  /// Whether the current step is the final step.
  bool get isLastStep =>
      _steps.isNotEmpty && _currentIndex == _steps.length - 1;

  /// Whether the tour is currently active.
  bool get isActive => _isActive;

  /// Returns whether [tourId] has been completed or skipped previously.
  static Future<bool> hasSeenTour(String tourId) async {
    _validateTourId(tourId);
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('$_seenKeyPrefix$tourId') ?? false;
  }

  /// Persists that [tourId] has been completed or skipped.
  static Future<void> markTourAsSeen(String tourId) async {
    _validateTourId(tourId);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('$_seenKeyPrefix$tourId', true);
  }

  static void _validateTourId(String tourId) {
    if (tourId.trim().isEmpty) {
      throw ArgumentError.value(tourId, 'tourId', 'must not be empty');
    }
  }

  /// Starts the tour from its first valid target.
  ///
  /// This activates the controller and advances to the first step that has
  /// a mounted target. It performs any necessary scrolling via the
  /// surrounding UI (through `TourScope`) and notifies listeners to show the
  /// overlay.
  Future<void> start() async {
    if (_steps.isEmpty || _isDisposed) return;
    final transitionId = ++_transitionId;
    await _fadeOutIfVisible(transitionId);
    if (!_isCurrentTransition(transitionId)) return;
    _currentIndex = 0;
    await _activateNextAvailableStep(transitionId);
  }

  /// Advances to the next valid target, finishing after the final step.
  ///
  /// If the controller is inactive or disposed this method is a no-op.
  Future<void> next() async {
    if (!_isActive || _isDisposed) return;
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
    if (!_isActive || isFirstStep || _isDisposed) return;
    final transitionId = ++_transitionId;
    await _fadeOutIfVisible(transitionId);
    if (!_isCurrentTransition(transitionId)) return;
    _currentIndex--;
    await _activatePreviousAvailableStep(transitionId);
  }

  /// Skips all remaining steps and fades out the overlay.
  void skip() => finish();

  /// Completes the tour.
  ///
  /// Marks the controller inactive and notifies listeners so the overlay
  /// can hide. Does not persist seen state; callers should use
  /// [markTourAsSeen] when appropriate.
  void finish() {
    if (_isDisposed) return;
    _transitionId++;
    _isActive = false;
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
    if (!_isActive || _isDisposed) return;
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
    while (_isCurrentTransition(transitionId) && _currentIndex < _steps.length) {
      if (await _scrollCurrentTargetIntoView(transitionId)) {
        _isActive = true;
        _notifySafely();
        return;
      }
      _currentIndex++;
    }
    if (_isCurrentTransition(transitionId)) finish();
  }

  Future<void> _activatePreviousAvailableStep(int transitionId) async {
    while (_isCurrentTransition(transitionId) && _currentIndex >= 0) {
      if (await _scrollCurrentTargetIntoView(transitionId)) {
        _isActive = true;
        _notifySafely();
        return;
      }
      _currentIndex--;
    }
    if (_isCurrentTransition(transitionId)) finish();
  }

  Future<bool> _scrollCurrentTargetIntoView(int transitionId) async {
    final targetContext = currentStep?.targetKey.currentContext;
    if (targetContext == null) return false;
    if (Scrollable.maybeOf(targetContext) != null) {
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
