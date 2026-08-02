extension DurationX on Duration {
  String get mmss {
    final int minutes = inMinutes.remainder(60);
    final int seconds = inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
