/// See docs/DEVICE_DETECTION.md — decided once per pairing change, never
/// recomputed synchronously on the tap-to-play critical path.
enum PlaybackStrategy {
  /// Cenário A: watch plays locally straight to the Bluetooth speaker.
  direct,

  /// Cenário B: watch sends a lightweight audioId to the phone, which
  /// plays the already-cached clip to the Bluetooth speaker.
  relay,

  /// No compatible watch paired; phone triggers everything.
  phoneOnly,
}

extension PlaybackStrategyX on PlaybackStrategy {
  bool get involvesWatch => this != PlaybackStrategy.phoneOnly;
}
