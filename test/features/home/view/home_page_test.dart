import 'package:api/api.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_boilerplate/core/navigation/app_navigator.dart';
import 'package:flutter_boilerplate/features/home/mobx/home_store.dart';
import 'package:flutter_boilerplate/features/home/view/home_keys.dart';
import 'package:flutter_boilerplate/features/home/view/home_page.dart';
import 'package:flutter_boilerplate/features/home/view/home_page_state.dart';
import 'package:flutter_boilerplate/injectable.dart';
import 'package:flutter_test/flutter_test.dart';
// `show` is required: mobx also exports `when`, which collides with mocktail's.
import 'package:mobx/mobx.dart' show ObservableList;
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockHomeStore extends Mock implements HomeStore {}

class _MockHomePageState extends Mock implements HomePageState {}

class _MockAppNavigator extends Mock implements AppNavigator {}

TodoDto _todo(String id, {bool completed = false}) =>
    TodoDto(id: id, title: 'todo $id', completed: completed);

/// Stubs one snapshot of the store's observable surface.
void _stubStore(
  _MockHomeStore store, {
  List<TodoDto> todos = const [],
  bool isLoading = false,
  String? error,
}) {
  when(() => store.todos).thenReturn(ObservableList.of(todos));
  when(() => store.isLoading).thenReturn(isLoading);
  when(() => store.error).thenReturn(error);
}

void main() {
  setUpAll(initLocalizationForTests);

  late _MockHomeStore store;
  late _MockHomePageState state;

  setUp(() {
    store = _MockHomeStore();
    state = _MockHomePageState();
    when(() => state.store).thenReturn(store);
    when(state.init).thenAnswer((_) async {});
    when(state.dispose).thenReturn(null);
    when(state.onAddTodoPressed).thenAnswer((_) async {});
    when(state.onLogoutPressed).thenAnswer((_) async {});
    when(state.onShowChallengeJoinedPressed).thenAnswer((_) async {});
    when(() => state.onTodoTap(any())).thenAnswer((_) async {});

    getIt
      ..registerFactory<HomePageState>(() => state)
      ..registerFactory<AppNavigator>(_MockAppNavigator.new);
  });

  tearDown(getIt.reset);

  group('HomePage', () {
    testWidgets('should show the skeleton list while the first load runs', (
      tester,
    ) async {
      _stubStore(store, isLoading: true);

      await tester.pumpApp(const HomePage());

      expect(find.byKey(const Key(HomeKeys.skeletonList)), findsOneWidget);
      expect(find.byKey(const Key(HomeKeys.todoList)), findsNothing);
      expect(find.byKey(const Key(HomeKeys.errorState)), findsNothing);
    });

    testWidgets('should show the error state with a retry affordance', (
      tester,
    ) async {
      _stubStore(store, error: 'boom');

      await tester.pumpApp(const HomePage());

      expect(find.byKey(const Key(HomeKeys.errorState)), findsOneWidget);
      expect(find.byKey(const Key(HomeKeys.errorRetry)), findsOneWidget);
      expect(find.byKey(const Key(HomeKeys.skeletonList)), findsNothing);
    });

    testWidgets('should retry the load when the retry button is tapped', (
      tester,
    ) async {
      _stubStore(store, error: 'boom');

      await tester.pumpApp(const HomePage());
      await tester.tap(find.byKey(const Key(HomeKeys.errorRetry)));
      await tester.pump();

      // once for the Provider's init(), once for the retry
      verify(state.init).called(2);
    });

    testWidgets('should show the empty state when there are no todos', (
      tester,
    ) async {
      _stubStore(store);

      await tester.pumpApp(const HomePage());

      expect(find.byKey(const Key(HomeKeys.emptyState)), findsOneWidget);
      expect(find.byKey(const Key(HomeKeys.todoList)), findsNothing);
      // Also proves the harness really loaded the translations — without them
      // this renders the raw key path 'homePage.empty'.
      expect(find.text('No todos yet'), findsOneWidget);
    });

    testWidgets('should show the list when todos are loaded', (tester) async {
      _stubStore(store, todos: [_todo('1'), _todo('2', completed: true)]);

      await tester.pumpApp(const HomePage());

      expect(find.byKey(const Key(HomeKeys.todoList)), findsOneWidget);
      expect(find.byKey(const Key(HomeKeys.emptyState)), findsNothing);
      expect(find.text('todo 1'), findsOneWidget);
    });

    testWidgets('should open the add-todo modal from the FAB', (tester) async {
      _stubStore(store, todos: [_todo('1')]);

      await tester.pumpApp(const HomePage());
      await tester.tap(find.byKey(const Key(HomeKeys.addTodoFab)));
      await tester.pump();

      verify(state.onAddTodoPressed).called(1);
    });

    testWidgets('should render the list in dark mode too', (tester) async {
      _stubStore(store, todos: [_todo('1')]);

      await tester.pumpApp(const HomePage(), dark: true);

      expect(find.byKey(const Key(HomeKeys.todoList)), findsOneWidget);
    });
  });
}
