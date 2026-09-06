import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/services/dio_service.dart';
import 'package:flutter_boilerplate/features/auth/mobx/auth_store.dart';
import 'package:flutter_boilerplate/features/home/mobx/home_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioService extends Mock implements DioService {}

class _MockTodosApiProvider extends Mock implements TodosApiProvider {}

class _MockAuthStore extends Mock implements AuthStore {}

TodoDto _todo(String id, {bool completed = false}) =>
    TodoDto(id: id, title: 'todo $id', completed: completed);

DioException _dioError(String message) => DioException(
  requestOptions: RequestOptions(path: '/todos'),
  message: message,
);

void main() {
  late _MockDioService dioService;
  late _MockTodosApiProvider todosProvider;
  late _MockAuthStore authStore;
  late HomeStore store;

  setUp(() {
    dioService = _MockDioService();
    todosProvider = _MockTodosApiProvider();
    authStore = _MockAuthStore();
    when(() => dioService.todosProvider).thenReturn(todosProvider);
    store = HomeStore(dioService, authStore);
  });

  group('HomeStore', () {
    test('should expose loaded todos and clear loading on success', () async {
      when(
        () => todosProvider.getTodos(),
      ).thenAnswer((_) async => [_todo('1'), _todo('2', completed: true)]);

      await store.loadTodos();

      expect(store.todos, hasLength(2));
      expect(store.isLoading, isFalse);
      expect(store.error, isNull);
    });

    test('should leave todos empty when the server returns nothing', () async {
      when(() => todosProvider.getTodos()).thenAnswer((_) async => []);

      await store.loadTodos();

      expect(store.todos, isEmpty);
      expect(store.error, isNull);
      expect(store.isLoading, isFalse);
    });

    test('should set error and clear loading when the request fails', () async {
      when(() => todosProvider.getTodos()).thenThrow(_dioError('boom'));

      await store.loadTodos();

      expect(store.error, 'boom');
      // Regression guard: a failure must not leave a permanent spinner.
      expect(store.isLoading, isFalse);
      expect(store.todos, isEmpty);
    });

    test('should clear a previous error on a successful retry', () async {
      when(() => todosProvider.getTodos()).thenThrow(_dioError('boom'));
      await store.loadTodos();
      expect(store.error, isNotNull);

      when(
        () => todosProvider.getTodos(),
      ).thenAnswer((_) async => [_todo('1')]);
      await store.loadTodos();

      expect(store.error, isNull);
      expect(store.todos, hasLength(1));
    });

    test('should toggle isLoading around the request', () async {
      final observed = <bool>[];
      when(() => todosProvider.getTodos()).thenAnswer((_) async {
        observed.add(store.isLoading);
        return [_todo('1')];
      });

      expect(store.isLoading, isFalse);
      await store.loadTodos();

      expect(observed, [true]);
      expect(store.isLoading, isFalse);
    });

    test('should append a todo without refetching', () async {
      when(
        () => todosProvider.getTodos(),
      ).thenAnswer((_) async => [_todo('1')]);
      await store.loadTodos();

      await store.addTodo(_todo('2'));

      expect(store.todos.map((t) => t.id), ['1', '2']);
      verify(() => todosProvider.getTodos()).called(1);
    });

    test('should clear the session on logout', () async {
      when(authStore.clearSession).thenAnswer((_) async {});

      await store.logout();

      verify(authStore.clearSession).called(1);
    });
  });
}
