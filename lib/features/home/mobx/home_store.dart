import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../core/services/dio_service.dart';
import '../../auth/mobx/auth_store.dart';

part 'home_store.g.dart';

@singleton
class HomeStore = _HomeStoreBase with _$HomeStore;

abstract class _HomeStoreBase with Store {
  final DioService _dioService;
  final AuthStore _authStore;

  _HomeStoreBase(
    this._dioService,
    this._authStore,
  );

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
    } on DioException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
    }
  }

  @action
  Future<void> addTodo(TodoDto todo) async {
    _todos.add(todo);
  }

  @action
  Future<void> logout() async {
    await _authStore.clearSession();
  }
}
