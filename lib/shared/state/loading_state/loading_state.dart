import 'package:mobx/mobx.dart';

part 'loading_state.g.dart';

class LoadingState = _LoadingState with _$LoadingState;

abstract class _LoadingState with Store {
  @observable
  bool isLoading = false;

  @action
  void startLoading() {
    isLoading = true;
  }

  @action
  void stopLoading() {
    isLoading = false;
  }
}
