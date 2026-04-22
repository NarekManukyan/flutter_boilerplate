import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/services/dio_service.dart';

@injectable
class CreateTodoUseCase {
  final DioService _dioService;

  CreateTodoUseCase(this._dioService);

  Future<TodoDto?> call(String title) async {
    try {
      final response = await _dioService.todosProvider.createTodo(
        todoCreateDto: TodoCreateRequestDto(title: title),
      );
      return response;
    } on DioException {
      return null;
    }
  }
}
