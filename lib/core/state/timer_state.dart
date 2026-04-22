import 'dart:async';

import 'package:mobx/mobx.dart';

part 'timer_state.g.dart';

class TimerState = _TimerState with _$TimerState;

abstract class _TimerState with Store {
  _TimerState(DateTime startTime) {
    _startTime = startTime;
    _secondsLeft = timeRemainingInSeconds;

    startTimer();
  }

  DateTime? _startTime;

  @computed
  int get timeRemainingInSeconds =>
      _startTime!.difference(DateTime.now()).inSeconds;

  @readonly
  int _secondsLeft = 0;

  @observable
  Timer? _timer;

  @action
  void startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_startTime != null) {
          _secondsLeft = _startTime!.difference(DateTime.now()).inSeconds;
        }
        if (_secondsLeft == 0) {
          cancelTimer();
        }
      },
    );
  }

  @action
  void cancelTimer() {
    _secondsLeft = 0;
    _timer?.cancel();
    _timer = null;
    _startTime = null;
  }
}
