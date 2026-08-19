import 'package:shared_preferences/shared_preferences.dart';

import 'tour_storage.dart';

/// A [TourStorage] implementation backed by `shared_preferences`.
class SharedPreferencesTourStorage implements TourStorage {
  /// Creates a storage adapter.
  const SharedPreferencesTourStorage();

  static const _prefix = 'flutter_app_tour.seen.';

  @override
  Future<bool> hasSeen(String tourId) async {
    _validate(tourId);
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('$_prefix$tourId') ?? false;
  }

  @override
  Future<void> markSeen(String tourId) async {
    _validate(tourId);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('$_prefix$tourId', true);
  }

  @override
  Future<void> reset(String tourId) async {
    _validate(tourId);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('$_prefix$tourId');
  }

  static void _validate(String tourId) {
    if (tourId.trim().isEmpty) {
      throw ArgumentError.value(tourId, 'tourId', 'must not be empty');
    }
  }
}
