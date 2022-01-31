extension DateTimeExtensions on DateTime {
  DateTime dateWithInterval(int minuteInterval) {
    return add(
      Duration(
        minutes: minuteInterval - minute % minuteInterval,
      ),
    );
  }
}
