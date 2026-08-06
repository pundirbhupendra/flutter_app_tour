import 'package:flutter/foundation.dart';

/// A strongly typed identifier used by tour steps and targets.
@immutable
class TourId {
  /// Creates a tour identifier from a non-empty string.
   TourId(this.value) : assert(value.trim().isNotEmpty, 'TourId must not be empty.');

  /// The underlying identifier value.
  final String value;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TourId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TourId($value)';
}
