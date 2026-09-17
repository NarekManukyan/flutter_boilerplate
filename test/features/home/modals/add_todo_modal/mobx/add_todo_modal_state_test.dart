import 'dart:async';

import 'package:api/api.dart';
import 'package:flutter_boilerplate/core/navigation/app_navigator.dart';
import 'package:flutter_boilerplate/features/home/mobx/home_store.dart';
import 'package:flutter_boilerplate/features/home/modals/add_todo_modal/mobx/add_todo_modal_state.dart';
import 'package:flutter_boilerplate/features/home/modals/add_todo_modal/use_cases/create_todo_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateTodoUseCase extends Mock implements CreateTodoUseCase {}

class _MockHomeStore extends Mock implements HomeStore {}

class _MockAppNavigator extends Mock implements AppNavigator {}

void main() {
  late _MockCreateTodoUseCase createTodo;
  late _MockHomeStore homeStore;
  late _MockAppNavigator navigator;
  late AddTodoModalState state;

  setUpAll(
    () => registerFallbackValue(TodoDto(id: '', title: '', completed: false)),
  );

  setUp(() {
    createTodo = _MockCreateTodoUseCase();
    homeStore = _MockHomeStore();
    navigator = _MockAppNavigator();
    when(() => homeStore.addTodo(any())).thenAnswer((_) async {});
    when(() => navigator.pop<Object?>()).thenAnswer((_) async => true);
    state = AddTodoModalState(createTodo, homeStore, navigator)
      ..titleController.text = 'Milk';
  });

  tearDown(() => state.dispose());

  group('AddTodoModalState', () {
    // Regression guard: the submit button and the keyboard's submit action
    // both call onSubmit, and a quick double submit created the todo twice.
    test('should create the todo once when submitted twice quickly', () async {
      final response = Completer<TodoDto?>();
      when(() => createTodo(any())).thenAnswer((_) => response.future);

      final first = state.onSubmit();
      final second = state.onSubmit();
      response.complete(TodoDto(id: '1', title: 'Milk', completed: false));
      await Future.wait([first, second]);

      verify(() => createTodo('Milk')).called(1);
      verify(() => homeStore.addTodo(any())).called(1);
    });

    test(
      'should keep the sheet open and flag the error when creation fails',
      () async {
        when(() => createTodo(any())).thenAnswer((_) async => null);

        await state.onSubmit();

        expect(state.hasError, isTrue);
        expect(state.loadingState.isLoading, isFalse);
        verifyNever(() => navigator.pop<Object?>());
      },
    );
  });
}
