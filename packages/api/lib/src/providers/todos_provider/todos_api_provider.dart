import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'models/models.dart';

part 'todos_api_provider.g.dart';

class _Paths {
  static const getTodos = '/todos';
  static const createTodo = '/todos';

  _Paths._();
}

@RestApi()
abstract class TodosApiProvider {
  factory TodosApiProvider(Dio dio) = _TodosApiProvider;

  @GET(_Paths.getTodos)
  Future<List<TodoDto>> getTodos();

  @POST(_Paths.createTodo)
  Future<TodoDto> createTodo({
    @Body() required TodoCreateRequestDto todoCreateDto,
  });
}
