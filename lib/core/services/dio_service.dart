import 'dart:developer';
import 'dart:io';

import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../features/auth/mobx/auth_store.dart';
import '../constants/timing_constants.dart';
import 'flavor_service.dart';
import 'interceptors/api_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/mock_todos_interceptor.dart';

@lazySingleton
class DioService {
  final FlavorService _flavorService;
  final AuthStore _authStore;
  late final AuthProvider authProvider = AuthProvider(dio);
  late final TodosApiProvider todosProvider = TodosApiProvider(dio);

  // Add other repositories
  late final Dio dio;
  late final Dio uploadImageDio;

  DioService(this._flavorService, this._authStore) {
    initDio();
  }

  void initDio() {
    final options = BaseOptions(
      baseUrl: _flavorService.config.apiUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: TimingConstants.apiConnectTimeout,
      sendTimeout: TimingConstants.apiSendTimeout,
      receiveTimeout: TimingConstants.apiReceiveTimeout,
    );
    final uploadDioOptions = BaseOptions(
      connectTimeout: TimingConstants.apiConnectTimeout,
      sendTimeout: TimingConstants.uploadSendTimeout,
      receiveTimeout: TimingConstants.apiReceiveTimeout,
    )..headers[HttpHeaders.contentTypeHeader] = 'audio/mpeg';

    dio = Dio(options)
      ..interceptors.addAll(<Interceptor>[
        // Dev only — a mock interceptor must never reach production traffic.
        // Must come first so it can short-circuit before auth/logging.
        if (_flavorService.isDev) MockTodosInterceptor(),
        ApiInterceptor(_flavorService),
        AuthInterceptor(_authStore, apiBaseUrl: _flavorService.config.apiUrl),
        // CacheInterceptor(),
        // Never in production: bodies carry user data, and the default
        // header logging would print the bearer token and any cookies.
        if (!_flavorService.isProduction) _logInterceptor(),
      ]);

    uploadImageDio = Dio(uploadDioOptions)
      ..interceptors.addAll(<Interceptor>[
        // Never in production: bodies carry user data, and the default
        // header logging would print the bearer token and any cookies.
        if (!_flavorService.isProduction) _logInterceptor(),
      ]);
  }

  LogInterceptor _logInterceptor() => LogInterceptor(
    requestHeader: false,
    responseHeader: false,
    requestBody: true,
    responseBody: true,
    logPrint: (res) => log(res.toString(), name: 'BE'),
  );
}
