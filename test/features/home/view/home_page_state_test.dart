import 'package:auto_route/auto_route.dart';
import 'package:flutter_boilerplate/core/navigation/app_navigator.dart';
import 'package:flutter_boilerplate/core/use_cases/open_todo_details_use_case.dart';
import 'package:flutter_boilerplate/features/home/mobx/home_store.dart';
import 'package:flutter_boilerplate/features/home/view/home_page_state.dart';
import 'package:flutter_boilerplate/features/home/view/use_cases/show_add_todo_modal_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockHomeStore extends Mock implements HomeStore {}

class _MockAppNavigator extends Mock implements AppNavigator {}

class _MockOpenTodoDetailsUseCase extends Mock
    implements OpenTodoDetailsUseCase {}

class _MockShowAddTodoModalUseCase extends Mock
    implements ShowAddTodoModalUseCase {}

// A Fake stand-in for `registerFallbackValue`; it is never compared.
// ignore: avoid_implementing_value_types
class _FakeRouteInfo extends Fake implements PageRouteInfo<dynamic> {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeRouteInfo()));

  late _MockHomeStore store;
  late _MockAppNavigator navigator;
  late _MockOpenTodoDetailsUseCase openTodoDetails;
  late _MockShowAddTodoModalUseCase showAddTodoModal;
  late HomePageState state;

  setUp(() {
    store = _MockHomeStore();
    navigator = _MockAppNavigator();
    openTodoDetails = _MockOpenTodoDetailsUseCase();
    showAddTodoModal = _MockShowAddTodoModalUseCase();
    state = HomePageState(store, navigator, openTodoDetails, showAddTodoModal);
  });

  group('HomePageState', () {
    test('should load todos through the store on init', () async {
      when(store.loadTodos).thenAnswer((_) async {});

      await state.init();

      verify(store.loadTodos).called(1);
    });

    test('should expose the injected store', () {
      expect(state.store, same(store));
    });

    test('should delegate a todo tap to the open-details use case', () async {
      when(() => openTodoDetails('42')).thenAnswer((_) async {});

      await state.onTodoTap('42');

      verify(() => openTodoDetails('42')).called(1);
      verifyNever(() => navigator.push(any()));
    });

    test('should open the add-todo modal through its use case', () async {
      when(showAddTodoModal.call).thenAnswer((_) async {});

      await state.onAddTodoPressed();

      verify(showAddTodoModal.call).called(1);
    });

    test('should clear the session before navigating away on logout', () async {
      when(store.logout).thenAnswer((_) async {});
      when(() => navigator.pushAndPopAll(any())).thenAnswer((_) async {});

      await state.onLogoutPressed();

      verifyInOrder([store.logout, () => navigator.pushAndPopAll(any())]);
    });
  });
}
