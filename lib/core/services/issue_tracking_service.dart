import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../gen/locale_keys.g.dart';
import '../navigation/app_navigator.dart';
import '../ui/error_notice.dart';
import 'flavor_service.dart';

/// Who deals with an error, which decides what the user sees and how the
/// report is tagged. See ADR-0020.
enum ErrorType {
  /// Nothing else shows it. The user gets an [ErrorNotice].
  standard,

  /// The caller shows its own UI: an error state, an inline message, a
  /// failure value it branches on. No notice, so the user never sees two.
  handled,

  /// Background work the user is not waiting on. No notice.
  silent,
}

/// The one place a caught error goes. Every `catch` in `lib/` either rethrows
/// or ends here, so a failure the UI recovers from still reaches Sentry.
///
/// Pick the method by who puts the error on screen, not by how bad it is:
/// - [trackIssue]: nobody — this service shows a notice.
/// - [trackHandledError]: the caller does.
/// - [trackSilentError]: nobody should, the user is not waiting on it.
@injectable
class IssueTrackingService {
  IssueTrackingService(this._appNavigator, this._flavorService);

  final AppNavigator _appNavigator;
  final FlavorService _flavorService;

  /// Status codes something else already reacts to. [AuthInterceptor] logs the
  /// user out on a 401, so a notice or a report on top of that is noise.
  static const ignoredStatusCodes = <int>{401};

  /// [notifyOnConnectivityError]: offline and timeout errors normally show no
  /// notice, because the connection page already says the device is offline.
  /// That reasoning holds for a failed load, not for an optimistic change the
  /// app silently undid — a delete that comes back after a 30 s timeout while
  /// online, say. Pass `true` from a rollback path so the user learns the
  /// change did not stick. Connectivity errors are still not reported.
  void trackIssue(
    Object error, {
    StackTrace? stackTrace,
    String? message,
    required String context,
    bool notifyOnConnectivityError = false,
  }) {
    _track(error, stackTrace, ErrorType.standard, context);
    if (!shouldShowNotice(
      error,
      ErrorType.standard,
      notifyOnConnectivityError: notifyOnConnectivityError,
    )) {
      return;
    }
    // A notice without a navigator context (an error during startup, or after
    // the app was torn down) has nowhere to go; the report above still went.
    if (_appNavigator.context == null) {
      return;
    }
    _appNavigator.showScaffoldMessage(
      ErrorNotice(message: message ?? _fallbackMessage(error)),
    );
  }

  void trackHandledError(
    Object error, {
    StackTrace? stackTrace,
    required String handlingContext,
  }) {
    _track(error, stackTrace, ErrorType.handled, handlingContext);
  }

  void trackSilentError(
    Object error, {
    StackTrace? stackTrace,
    required String context,
  }) {
    _track(error, stackTrace, ErrorType.silent, context);
  }

  /// Offline and timeouts. The connection page already tells the user, and a
  /// report per dropped request would bury real defects.
  static bool isConnectivityError(Object error) {
    return error is DioException &&
        switch (error.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.connectionError => true,
          _ => false,
        };
  }

  static bool isCancellation(Object error) {
    return error is DioException && error.type == DioExceptionType.cancel;
  }

  static bool hasIgnoredStatus(Object error) {
    return error is DioException &&
        ignoredStatusCodes.contains(error.response?.statusCode);
  }

  /// Whether the error goes to Sentry. Anything that is not an [Error] or an
  /// [Exception] (a thrown string, say) is logged locally but not reported.
  @visibleForTesting
  static bool shouldReport(Object error) {
    if (error is! Error && error is! Exception) {
      return false;
    }
    return !isCancellation(error) &&
        !isConnectivityError(error) &&
        !hasIgnoredStatus(error);
  }

  @visibleForTesting
  static bool shouldShowNotice(
    Object error,
    ErrorType type, {
    bool notifyOnConnectivityError = false,
  }) {
    return type == ErrorType.standard &&
        !isCancellation(error) &&
        (notifyOnConnectivityError || !isConnectivityError(error)) &&
        !hasIgnoredStatus(error);
  }

  String _fallbackMessage(Object error) {
    // Outside production the raw error is more use to whoever is testing than
    // a generic sentence. Never the stack trace: it does not fit a notice.
    return _flavorService.isProduction
        ? LocaleKeys.errors_generic.tr()
        : error.toString();
  }

  void _track(
    Object error,
    StackTrace? stackTrace,
    ErrorType type,
    String? context,
  ) {
    if (kDebugMode) {
      developer.log(
        '${type.name}${context == null ? '' : ' [$context]'}: $error',
        name: 'IssueTrackingService',
        error: error,
        stackTrace: stackTrace,
      );
    }
    if (!shouldReport(error)) {
      return;
    }
    unawaited(
      Sentry.captureException(
        error,
        stackTrace:
            stackTrace ?? (error is DioException ? error.stackTrace : null),
        withScope: (scope) {
          scope.setTag('error_type', type.name);
          if (context != null) {
            scope.setTag('error_context', context);
          }
          if (error is DioException) {
            // Method, path and status only. Headers carry the bearer token and
            // bodies carry user data; neither belongs in a crash report.
            scope.setContexts('dio_error', {
              'type': error.type.name,
              'method': error.requestOptions.method,
              'path': error.requestOptions.path,
              'status_code': error.response?.statusCode,
            });
          }
        },
      ),
    );
  }
}
