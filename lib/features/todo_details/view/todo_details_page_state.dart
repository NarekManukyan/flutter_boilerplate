import 'package:api/api.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../home/mobx/home_store.dart';
import 'use_cases/fetch_todo_use_case.dart';

part 'todo_details_page_state.g.dart';

@injectable
class TodoDetailsPageState = _TodoDetailsPageStateBase
    with _$TodoDetailsPageState;

abstract class _TodoDetailsPageStateBase with Store {
  final FetchTodoUseCase _fetchTodoUseCase;
  final HomeStore _homeStore;
  final AppNavigator _appNavigator;

  _TodoDetailsPageStateBase(
    this._fetchTodoUseCase,
    this._homeStore,
    this._appNavigator,
  );

  @readonly
  TodoDto? _todo;

  @readonly
  bool _isLoading = false;

  @action
  Future<void> init(String id) async {
    _isLoading = true;
    try {
      _todo = await _fetchTodoUseCase(id);
    } finally {
      _isLoading = false;
    }
  }

  @action
  void onToggleCompleted() {
    final current = _todo;
    if (current == null) {
      return;
    }
    final updated = current.copyWith(completed: !current.completed);
    _todo = updated;
    // Keep the Home list in step; it held the old value until a refetch.
    _homeStore.replaceTodo(updated);
  }

  Future<void> onBackPressed() => _appNavigator.pop();

  void dispose() {}
}
