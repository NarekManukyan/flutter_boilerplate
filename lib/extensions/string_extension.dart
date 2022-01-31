extension StringExtension on String {
  String titleCase() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  T? enumFromString<T>(List<T> values) {
    try {
      return values.firstWhere((v) => v.toString().split('.')[1] == this);
    } catch (_) {
      return null;
    }
  }
}
