import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/services/dio_service.dart';
import '../../../../../core/services/issue_tracking_service.dart';

@injectable
class CreateTodoUseCase {
  final DioService _dioService;
  final IssueTrackingService _issueTrackingService;

  CreateTodoUseCase(this._dioService, this._issueTrackingService);

  /// Returns `null` when the request fails. The caller owns the failure UI,
  /// which is why this reports as handled rather than showing a notice.
  Future<TodoDto?> call(String title) async {
    try {
      return await _dioService.todosProvider.createTodo(
        todoCreateDto: TodoCreateRequestDto(title: title),
      );
    } on DioException catch (e, stackTrace) {
      _issueTrackingService.trackHandledError(
        e,
        stackTrace: stackTrace,
        handlingContext: 'create_todo',
      );
      return null;
    }
  }
}
