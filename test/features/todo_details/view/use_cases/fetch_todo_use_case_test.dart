import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/services/dio_service.dart';
import 'package:flutter_boilerplate/core/services/issue_tracking_service.dart';
import 'package:flutter_boilerplate/features/todo_details/view/use_cases/fetch_todo_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioService extends Mock implements DioService {}

class _MockTodosApiProvider extends Mock implements TodosApiProvider {}

class _MockIssueTrackingService extends Mock implements IssueTrackingService {}

void main() {
  late _MockTodosApiProvider todosProvider;
  late _MockIssueTrackingService issueTracking;
  late FetchTodoUseCase fetchTodo;

  setUp(() {
    final dioService = _MockDioService();
    todosProvider = _MockTodosApiProvider();
    issueTracking = _MockIssueTrackingService();
    when(() => dioService.todosProvider).thenReturn(todosProvider);
    fetchTodo = FetchTodoUseCase(dioService, issueTracking);
  });

  group('FetchTodoUseCase', () {
    test('should return the todo with the requested id', () async {
      when(() => todosProvider.getTodos()).thenAnswer(
        (_) async => [
          TodoDto(id: '1', title: 'Milk', completed: false),
          TodoDto(id: '2', title: 'Bread', completed: true),
        ],
      );

      final todo = await fetchTodo('2');

      expect(todo?.title, 'Bread');
      verifyZeroInteractions(issueTracking);
    });

    test(
      'should return null without reporting when the id is unknown',
      () async {
        when(() => todosProvider.getTodos()).thenAnswer(
          (_) async => [TodoDto(id: '1', title: 'Milk', completed: false)],
        );

        expect(await fetchTodo('missing'), isNull);
        // A missing todo is an expected outcome, not a defect.
        verifyZeroInteractions(issueTracking);
      },
    );

    test('should return null and report a failed request as handled', () async {
      final error = DioException(
        requestOptions: RequestOptions(path: '/todos'),
        type: DioExceptionType.badResponse,
      );
      when(() => todosProvider.getTodos()).thenThrow(error);

      expect(await fetchTodo('1'), isNull);
      verify(
        () => issueTracking.trackHandledError(
          error,
          stackTrace: any(named: 'stackTrace'),
          handlingContext: 'fetch_todo',
        ),
      ).called(1);
    });
  });
}
