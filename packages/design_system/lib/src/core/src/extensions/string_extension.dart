extension StringExtension on String {
  String get toSentenceCase => '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  String get withStartingLine => ' - $this';
}
