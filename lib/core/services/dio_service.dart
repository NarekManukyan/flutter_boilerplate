import 'dart:developer';
import 'dart:io';

import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'flavor_service.dart';
import 'interceptors/api_interceptor.dart';
import 'interceptors/auth_interceptor.dart';

@lazySingleton
class DioService {
  final FlavorService _flavorService;
  late final AuthProvider authProvider = AuthProvider(dio);

  // Add other repositories
  late final Dio dio;
  late final Dio uploadImageDio;

  DioService(
    this._flavorService,
  ) {
    initDio();
  }

  void initDio() {
    final options = BaseOptions(
      baseUrl: _flavorService.config.apiUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 32),
      receiveTimeout: const Duration(seconds: 32),
    );
    final uploadDioOptions = BaseOptions()
      ..headers[HttpHeaders.contentTypeHeader] = 'audio/mpeg';

    dio = Dio(options)
      ..interceptors.addAll(
        <Interceptor>[
          ApiInterceptor(),
          AuthInterceptor(),
          // CacheInterceptor(),
          LogInterceptor(
            requestBody: true,
            responseBody: true,
            logPrint: (res) {
              log(res.toString(), name: 'BE');
            },
          ),
        ],
      );

    uploadImageDio = Dio(uploadDioOptions)
      ..interceptors.addAll([
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (res) {
            log(res.toString(), name: 'BE');
          },
        ),
      ]);
  }
}
