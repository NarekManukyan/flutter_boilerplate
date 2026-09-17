import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../core/services/dio_service.dart';
import '../../../core/services/issue_tracking_service.dart';
import '../../auth/mobx/auth_store.dart';

part 'home_store.g.dart';

@singleton
class HomeStore = _HomeStoreBase with _$HomeStore;

abstract class _HomeStoreBase with Store {
  final DioService _dioService;
  final AuthStore _authStore;
  final IssueTrackingService _issueTrackingService;

  _HomeStoreBase(this._dioService, this._authStore, this._issueTrackingService);

  @readonly
  ObservableList<TodoDto> _todos = ObservableList();

  @readonly
  bool _isLoading = false;

  @readonly
  String? _error;

  @action
  Future<void> loadTodos() async {
    _isLoading = true;
    _error = null;
    try {
      final result = await _dioService.todosProvider.getTodos();
      _todos = ObservableList.of(result);
    } catch (e, stackTrace) {
      // Everything, not only DioException: the generated Retrofit client
      // rethrows a response that fails fromJson unchanged, and that must
      // still reach the error state. The page renders [error], so handled.
      _issueTrackingService.trackHandledError(
        e,
        stackTrace: stackTrace,
        handlingContext: 'load_todos',
      );
      _error = e is DioException ? e.message : e.toString();
    } finally {
      _isLoading = false;
    }
  }

  @action
  Future<void> addTodo(TodoDto todo) async {
    _todos.add(todo);
  }

  /// Replaces the todo with the same id, if the list holds it. Screens that
  /// change a todo call this so the Home list does not keep a stale copy.
  @action
  void replaceTodo(TodoDto todo) {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
    }
  }

  @action
  Future<void> logout() async {
    await _authStore.clearSession();
  }
}
