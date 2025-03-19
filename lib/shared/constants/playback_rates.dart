enum PlaybackRate {
  x0_75,
  x1_0,
  x1_25,
  x1_5,
  x2_0;

  double get value {
    return switch (this) {
      PlaybackRate.x0_75 => 0.75,
      PlaybackRate.x1_0 => 1.0,
      PlaybackRate.x1_25 => 1.25,
      PlaybackRate.x1_5 => 1.5,
      PlaybackRate.x2_0 => 2.0,
    };
  }

  String get label {
    return switch (this) {
      PlaybackRate.x0_75 => '0.75x',
      PlaybackRate.x1_0 => '1x',
      PlaybackRate.x1_25 => '1.25x',
      PlaybackRate.x1_5 => '1.5x',
      PlaybackRate.x2_0 => '2x',
    };
  }

  double get fontSize {
    return switch (this) {
      PlaybackRate.x0_75 => 14,
      PlaybackRate.x1_0 => 16,
      PlaybackRate.x1_25 => 14,
      PlaybackRate.x1_5 => 16,
      PlaybackRate.x2_0 => 16,
    };
  }
}
