import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../core/services/dio_service.dart';

part 'todo_details_page_state.g.dart';

@injectable
class TodoDetailsPageState = _TodoDetailsPageStateBase
    with _$TodoDetailsPageState;

abstract class _TodoDetailsPageStateBase with Store {
  final DioService _dioService;

  _TodoDetailsPageStateBase(this._dioService);

  @readonly
  TodoDto? _todo;

  @readonly
  bool _isLoading = false;

  @readonly
  String? _error;

  @action
  Future<void> init(String id) async {
    _isLoading = true;
    _error = null;
    try {
      final todos = await _dioService.todosProvider.getTodos();
      _todo = todos.firstWhere((t) => t.id == id);
    } on DioException catch (e) {
      _error = e.message;
    } on StateError {
      _error = 'not_found';
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
    _todo = current.copyWith(completed: !current.completed);
  }

  void dispose() {}
}
