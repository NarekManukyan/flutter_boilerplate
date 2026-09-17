import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/services/interceptors/auth_interceptor.dart';
import 'package:flutter_boilerplate/features/auth/mobx/auth_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthStore extends Mock implements AuthStore {}

/// Records every request and answers with [statusCode].
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.statusCode = 200});

  final int statusCode;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(<String, Object>{}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _api = 'https://api.example.com';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthStore authStore;

  setUp(() {
    SharedPreferences.setMockInitialValues({'authToken': 't0ken'});
    authStore = _MockAuthStore();
    when(authStore.clearSession).thenAnswer((_) async {});
  });

  Dio dioWith(_RecordingAdapter adapter) => Dio(BaseOptions(baseUrl: _api))
    ..httpClientAdapter = adapter
    ..interceptors.add(AuthInterceptor(authStore, apiBaseUrl: _api));

  group('AuthInterceptor', () {
    test('should send the token to the API host', () async {
      final adapter = _RecordingAdapter();

      await dioWith(adapter).get<Object?>('/todos');

      expect(adapter.requests.single.headers['authorization'], 'bearer t0ken');
    });

    // A request with an absolute URL skips baseUrl; the token must not follow.
    test('should not send the token to another host', () async {
      final adapter = _RecordingAdapter();

      await dioWith(adapter).get<Object?>('https://files.other.org/avatar.png');

      expect(adapter.requests.single.headers['authorization'], isNull);
    });

    // Regression guard: a 401 only reset flags, so the rejected token stayed
    // stored and AuthGuard signed the user straight back in with it.
    test(
      'should clear the session once when several requests get 401',
      () async {
        final dio = dioWith(_RecordingAdapter(statusCode: 401));

        final results = await Future.wait([
          for (var i = 0; i < 3; i++)
            dio
                .get<Object?>('/todos')
                .then<Object?>((r) => r, onError: (Object e) => e),
        ]);

        expect(results, everyElement(isA<DioException>()));
        verify(authStore.clearSession).called(1);
      },
    );
  });
}
