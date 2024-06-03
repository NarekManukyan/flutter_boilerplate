import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../store/auth_store/auth_store.dart';
import '../../utils/storage_utils.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageUtils.getAccessToken();

    if (options.data is FormData) {
      options.headers[HttpHeaders.contentTypeHeader] = 'multipart/form-data';
    }

    if (token?.isNotEmpty == true) {
      options.headers
          .putIfAbsent(HttpHeaders.authorizationHeader, () => 'bearer $token');
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      unawaited(GetIt.I<AuthStore>().logout());
    }
    return handler.next(err);
  }
}
