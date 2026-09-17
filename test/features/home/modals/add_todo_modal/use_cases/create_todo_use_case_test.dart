import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/services/dio_service.dart';
import 'package:flutter_boilerplate/core/services/issue_tracking_service.dart';
import 'package:flutter_boilerplate/features/home/modals/add_todo_modal/use_cases/create_todo_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioService extends Mock implements DioService {}

class _MockTodosApiProvider extends Mock implements TodosApiProvider {}

class _MockIssueTrackingService extends Mock implements IssueTrackingService {}

void main() {
  late _MockTodosApiProvider todosProvider;
  late _MockIssueTrackingService issueTracking;
  late CreateTodoUseCase createTodo;

  setUpAll(() {
    registerFallbackValue(TodoCreateRequestDto(title: ''));
  });

  setUp(() {
    final dioService = _MockDioService();
    todosProvider = _MockTodosApiProvider();
    issueTracking = _MockIssueTrackingService();
    when(() => dioService.todosProvider).thenReturn(todosProvider);
    createTodo = CreateTodoUseCase(dioService, issueTracking);
  });

  group('CreateTodoUseCase', () {
    test('should return the created todo', () async {
      final created = TodoDto(id: '1', title: 'Milk', completed: false);
      when(
        () => todosProvider.createTodo(
          todoCreateDto: any(named: 'todoCreateDto'),
        ),
      ).thenAnswer((_) async => created);

      expect(await createTodo('Milk'), created);
      verify(
        () => todosProvider.createTodo(
          todoCreateDto: TodoCreateRequestDto(title: 'Milk'),
        ),
      ).called(1);
      verifyZeroInteractions(issueTracking);
    });

    test('should return null and report a response it cannot parse', () async {
      // The generated client rethrows fromJson failures unchanged; catching
      // only DioException let them escape the use case.
      final error = TypeError();
      when(
        () => todosProvider.createTodo(
          todoCreateDto: any(named: 'todoCreateDto'),
        ),
      ).thenThrow(error);

      expect(await createTodo('Milk'), isNull);
      verify(
        () => issueTracking.trackHandledError(
          error,
          stackTrace: any(named: 'stackTrace'),
          handlingContext: 'create_todo',
        ),
      ).called(1);
    });

    test('should return null and report the failure as handled', () async {
      final error = DioException(
        requestOptions: RequestOptions(path: '/todos'),
        response: Response(
          requestOptions: RequestOptions(path: '/todos'),
          statusCode: 500,
        ),
      );
      when(
        () => todosProvider.createTodo(
          todoCreateDto: any(named: 'todoCreateDto'),
        ),
      ).thenThrow(error);

      expect(await createTodo('Milk'), isNull);
      // Regression guard: this used to swallow the error without reporting it.
      verify(
        () => issueTracking.trackHandledError(
          error,
          stackTrace: any(named: 'stackTrace'),
          handlingContext: 'create_todo',
        ),
      ).called(1);
    });
  });
}
