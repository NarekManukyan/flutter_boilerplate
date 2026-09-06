import 'dart:io';

import 'package:dio/dio.dart';

import '../../../features/auth/mobx/auth_store.dart';
import '../../../injectable.dart';
import '../../navigation/app_navigator.dart';
import '../../utils/storage_utils.dart';

class AuthInterceptor extends Interceptor {
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

    if (token?.isNotEmpty == true) {
      options.headers.putIfAbsent(
        HttpHeaders.authorizationHeader,
        () => 'bearer $token',
      );
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      getIt<AuthStore>().logout();
      getIt<AppNavigator>().pushAndPopAll(const LoginRoute());
    }
    return handler.next(err);
  }
}
