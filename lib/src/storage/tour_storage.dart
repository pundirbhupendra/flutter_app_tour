/// Persistence abstraction for whether a tour has been seen.
abstract interface class TourStorage {
  /// Returns whether [tourId] has been marked as seen.
  Future<bool> hasSeen(String tourId);

  /// Marks [tourId] as seen.
  Future<void> markSeen(String tourId);

  /// Clears the seen state for [tourId].
  Future<void> reset(String tourId);
}
