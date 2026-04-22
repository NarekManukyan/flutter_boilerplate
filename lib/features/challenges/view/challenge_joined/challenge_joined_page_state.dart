import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../../core/navigation/app_navigator.dart';

part 'challenge_joined_page_state.g.dart';

@injectable
class ChallengeJoinedPageState = _ChallengeJoinedPageStateBase
    with _$ChallengeJoinedPageState;

abstract class _ChallengeJoinedPageStateBase with Store {
  final AppNavigator _appNavigator;

  _ChallengeJoinedPageStateBase(this._appNavigator);

  @action
  void init() {}

  @action
  Future<void> onClosePressed() async {
    await _appNavigator.pop();
  }

  @action
  Future<void> onJoinChallengePressed() async {
    await _appNavigator.pushAndPopAll(const HomeRoute());
  }

  void dispose() {}
}
