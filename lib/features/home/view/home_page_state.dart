import 'package:api/api.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/use_cases/open_todo_details_use_case.dart';
import '../mobx/home_store.dart';
import '../models/todo_filter.dart';
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

  // The page reads the store through these, never directly (ADR-0001). MobX
  // tracks through a getter, so an Observer reading them still rebuilds when
  // the store changes.
  List<TodoDto> get todos => _homeStore.todos;

  bool get isLoading => _homeStore.isLoading;

  String? get error => _homeStore.error;

  @readonly
  TodoFilter _filter = TodoFilter.all;

  /// Recomputed when the list or the filter changes, not on every rebuild.
  @computed
  List<TodoDto> get visibleTodos =>
      _homeStore.todos.where(_filter.matches).toList();

  @computed
  int get doneCount => _homeStore.todos.where((todo) => todo.completed).length;

  @action
  void onFilterChanged(TodoFilter filter) => _filter = filter;

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
    // No navigation here: logout resets DI, the app root remounts a fresh
    // router, and SplashPageState sends the signed-out user to login.
    await _homeStore.logout();
  }

  @action
  Future<void> onShowChallengeJoinedPressed() async {
    await _appNavigator.push(const ChallengeJoinedRoute());
  }

  void dispose() {}
}
