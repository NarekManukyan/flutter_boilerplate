import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/use_cases/open_todo_details_use_case.dart';
import '../mobx/home_store.dart';
import 'use_cases/show_add_todo_modal_use_case.dart';

part 'home_page_state.g.dart';

@injectable
class HomePageState = _HomePageStateBase with _$HomePageState;

abstract class _HomePageStateBase with Store {
  final HomeStore _homeStore;
  final AppNavigator _appNavigator;
  final OpenTodoDetailsUseCase _openTodoDetailsUseCase;
  final ShowAddTodoModalUseCase _showAddTodoModalUseCase;

  _HomePageStateBase(
    this._homeStore,
    this._appNavigator,
    this._openTodoDetailsUseCase,
    this._showAddTodoModalUseCase,
  );

  HomeStore get store => _homeStore;

  Future<void> init() async {
    await _homeStore.loadTodos();
  }

  @action
  Future<void> onTodoTap(String id) async {
    await _openTodoDetailsUseCase(id);
  }

  @action
  Future<void> onAddTodoPressed() async {
    await _showAddTodoModalUseCase();
  }

  @action
  Future<void> onLogoutPressed() async {
    await _homeStore.logout();
    await _appNavigator.pushAndPopAll(const LoginRoute());
  }

  @action
  Future<void> onShowChallengeJoinedPressed() async {
    await _appNavigator.push(const ChallengeJoinedRoute());
  }

  void dispose() {}
}
