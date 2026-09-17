/// Non-visual timing. Motion durations come from `GeistDuration` instead
/// (ADR-0013); these are debounce windows and similar, named so a change is
/// one edit and a reviewer can see what each number is for.
abstract final class TimingConstants {
  /// How long connectivity must stay changed before the offline page reacts,
  /// so a network handover does not flash it.
  static const connectivityDebounce = Duration(milliseconds: 200);

  /// Mobile networks fail slowly; a user waiting longer than this for a
  /// connection that will not come has already given up.
  static const apiConnectTimeout = Duration(seconds: 15);

  /// Upload and download budgets for ordinary API calls.
  static const apiSendTimeout = Duration(seconds: 30);
  static const apiReceiveTimeout = Duration(seconds: 30);

  /// Uploads carry files, so they get longer to send.
  static const uploadSendTimeout = Duration(seconds: 120);
}
