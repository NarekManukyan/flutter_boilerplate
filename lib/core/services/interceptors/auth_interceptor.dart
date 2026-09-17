import 'dart:io';

import 'package:dio/dio.dart';

import '../../../features/auth/mobx/auth_store.dart';
import '../../utils/storage_utils.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._authStore, {required String apiBaseUrl})
    : _apiHost = Uri.parse(apiBaseUrl).host;

  final AuthStore _authStore;
  final String _apiHost;

  /// Several requests can fail with 401 at once; the session is cleared once.
  bool _clearingSession = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageUtils.getAccessToken();

    options.headers[HttpHeaders.contentTypeHeader] = 'application/json';

    if (options.data is FormData) {
      options.headers[HttpHeaders.contentTypeHeader] = 'multipart/form-data';
    }

    // Only to our own API. A request built with an absolute URL skips
    // baseUrl, and the bearer token must not follow it to another host.
    if (token?.isNotEmpty == true && options.uri.host == _apiHost) {
      options.headers.putIfAbsent(
        HttpHeaders.authorizationHeader,
        () => 'bearer $token',
      );
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    handler.next(err);
    if (err.response?.statusCode != 401 || _clearingSession) {
      return;
    }
    _clearingSession = true;
    // clearSession removes the stored token and resets DI; the app root then
    // rebuilds its router, and the splash state sends the user to login.
    // Resetting flags alone left the rejected token stored, so AuthGuard let
    // the user straight back in with it.
    await _authStore.clearSession();
  }
}
