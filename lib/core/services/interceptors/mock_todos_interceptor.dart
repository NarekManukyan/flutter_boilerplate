import 'dart:async';

import 'package:dio/dio.dart';

/// Scenarios the todos mock can serve.
///
/// E2E flows need to reach the failure and edge branches, and a live backend
/// cannot be asked to fail on demand. See ADR-0015 and the `write-maestro-flow`
/// playbook.
enum MockScenario {
  /// Three seeded todos. The default.
  normal,

  /// `GET /todos` returns an empty list — drives the empty state.
  empty,

  /// Every request returns 500 — drives the error state and the retry path.
  serverError,

  /// Requests hang for 8 s — drives the loading state and timeout handling.
  slow,
}

/// Dev-only mock for the todos endpoints.
///
/// Registered only when the dev flavor is active (see `DioService.initDio`);
/// it must never be installed in production.
///
/// The active scenario can be set two ways:
///  * at build time — `--dart-define=MOCK_SCENARIO=serverError`
///  * at run time — type a `/mock <scenario>` command into the add-todo field.
///    This is what Maestro flows use, because it needs no rebuild.
class MockTodosInterceptor extends Interceptor {
  static const _kCommandPrefix = '/mock ';

  static const _seed = <Map<String, dynamic>>[
    {'id': '1', 'title': 'Buy groceries', 'completed': false},
    {'id': '2', 'title': 'Read a book', 'completed': true},
    {'id': '3', 'title': 'Write Flutter code', 'completed': false},
  ];

  static List<Map<String, dynamic>> _todos = List.of(_seed);
  static int _nextId = 4;

  static MockScenario scenario = _scenarioFromEnvironment();

  static MockScenario _scenarioFromEnvironment() {
    // A build-time scenario is the point of this hook — it lets CI build a
    // variant that starts in a given state without any runtime command.
    // ignore: do_not_use_environment
    const name = String.fromEnvironment('MOCK_SCENARIO');
    return MockScenario.values.firstWhere(
      (s) => s.name == name,
      orElse: () => MockScenario.normal,
    );
  }

  /// Restores the seeded data and the default scenario.
  static void reset() {
    _todos = List.of(_seed);
    _nextId = 4;
    scenario = MockScenario.normal;
  }

  /// Handles a `/mock <scenario>` command typed into the app.
  ///
  /// Returns true when [title] was a command, so the caller skips creating a
  /// todo out of it.
  static bool handleCommand(String title) {
    final trimmed = title.trim();
    if (!trimmed.startsWith(_kCommandPrefix)) {
      return false;
    }
    final arg = trimmed.substring(_kCommandPrefix.length).trim();
    if (arg == 'reset') {
      reset();
      return true;
    }
    for (final s in MockScenario.values) {
      if (s.name.toLowerCase() == arg.toLowerCase()) {
        scenario = s;
        return true;
      }
    }
    return true; // unknown command — still swallowed, never becomes a todo
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.path.contains('/todos')) {
      return handler.next(options);
    }

    await Future<void>.delayed(
      scenario == MockScenario.slow
          ? const Duration(seconds: 8)
          : const Duration(milliseconds: 300),
    );

    final isCommand =
        options.method == 'POST' &&
        options.data is Map &&
        (options.data as Map)['title'] is String &&
        ((options.data as Map)['title'] as String).trim().startsWith('/mock ');

    if (scenario == MockScenario.serverError && !isCommand) {
      return handler.reject(
        DioException(
          requestOptions: options,
          response: Response<dynamic>(requestOptions: options, statusCode: 500),
          type: DioExceptionType.badResponse,
          message: 'Mock server error',
        ),
      );
    }

    if (options.method == 'GET') {
      return handler.resolve(
        Response<List<dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: scenario == MockScenario.empty
              ? const <Map<String, dynamic>>[]
              : List<Map<String, dynamic>>.from(_todos),
        ),
      );
    }

    if (options.method == 'POST') {
      final data = options.data;
      final title = data is Map && data['title'] is String
          ? data['title'] as String
          : '';

      // A `/mock <scenario>` title is a control command, not a todo. Reject it
      // so the caller creates nothing; the scenario is already applied.
      if (handleCommand(title)) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            message: 'Mock command applied: ${title.trim()}',
          ),
        );
      }

      final todo = <String, dynamic>{
        'id': '${_nextId++}',
        'title': title,
        'completed': false,
      };
      _todos.add(todo);
      return handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 201,
          data: todo,
        ),
      );
    }

    return handler.next(options);
  }
}
