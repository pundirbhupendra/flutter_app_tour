/// Describes the shape cut out around a tour target.
enum SpotlightShape {
  /// A rectangular cutout.
  rectangle,

  /// A rectangle with rounded corners.
  roundedRectangle,

  /// A circle sized to contain the target bounds.
  circle,

  /// An oval matching the target bounds.
  oval,
}
