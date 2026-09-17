import 'package:flutter_boilerplate/core/navigation/app_navigator.dart';
import 'package:flutter_boilerplate/features/auth/mobx/auth_store.dart';
import 'package:flutter_boilerplate/features/splash/view/splash_page_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthStore extends Mock implements AuthStore {}

class _MockAppNavigator extends Mock implements AppNavigator {}

void main() {
  late _MockAuthStore authStore;
  late _MockAppNavigator navigator;
  late SplashPageState state;

  setUpAll(() => registerFallbackValue(const LoginRoute()));

  setUp(() {
    authStore = _MockAuthStore();
    navigator = _MockAppNavigator();
    when(authStore.getAccessToken).thenAnswer((_) async {});
    when(() => navigator.pushAndPopAll(any())).thenAnswer((_) async {});
    state = SplashPageState(authStore, navigator);
  });

  group('SplashPageState', () {
    // Regression guard: the splash route sat behind AuthGuard, so a signed-in
    // user landed on the splash page and nothing navigated on.
    test('should go home when a session is stored', () async {
      when(() => authStore.isAuthed).thenReturn(true);

      await state.init();

      final route = verify(
        () => navigator.pushAndPopAll(captureAny()),
      ).captured.single;
      expect(route, isA<HomeRoute>());
    });

    test('should go to login when there is no session', () async {
      when(() => authStore.isAuthed).thenReturn(false);

      await state.init();

      final route = verify(
        () => navigator.pushAndPopAll(captureAny()),
      ).captured.single;
      expect(route, isA<LoginRoute>());
    });
  });
}
