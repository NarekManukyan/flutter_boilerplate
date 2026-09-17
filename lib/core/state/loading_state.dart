import 'package:mobx/mobx.dart';

part 'loading_state.g.dart';

/// A reusable loading flag composed into screen states. Read [isLoading];
/// change it only through [startLoading] / [stopLoading], and stop in a
/// `finally` so a failure never leaves a permanent spinner.
class LoadingState = _LoadingState with _$LoadingState;

abstract class _LoadingState with Store {
  @readonly
  bool _isLoading = false;

  @action
  void startLoading() {
    _isLoading = true;
  }

  @action
  void stopLoading() {
    _isLoading = false;
  }
}
