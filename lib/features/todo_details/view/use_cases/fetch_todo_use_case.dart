import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/dio_service.dart';
import '../../../../core/services/issue_tracking_service.dart';

@injectable
class FetchTodoUseCase {
  final DioService _dioService;
  final IssueTrackingService _issueTrackingService;

  FetchTodoUseCase(this._dioService, this._issueTrackingService);

  /// `null` when the todo does not exist or the request failed. The page shows
  /// the same error state for both, so it reports the failure as handled.
  Future<TodoDto?> call(String id) async {
    try {
      final todos = await _dioService.todosProvider.getTodos();
      return todos.where((todo) => todo.id == id).firstOrNull;
    } on DioException catch (e, stackTrace) {
      _issueTrackingService.trackHandledError(
        e,
        stackTrace: stackTrace,
        handlingContext: 'fetch_todo',
      );
      return null;
    }
  }
}
