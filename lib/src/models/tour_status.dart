/// Describes the lifecycle state of a tour.
enum TourStatus {
  /// The tour has not started or has been reset.
  idle,

  /// The tour is currently displaying a step.
  running,

  /// The tour reached its final step.
  completed,

  /// The user skipped the tour.
  skipped,
}
