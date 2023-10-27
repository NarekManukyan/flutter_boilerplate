import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import './dio_flutter_transformer.dart';
import '../../../../providers/flavor_service.dart';
import 'interceptors/api_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'repositories/auth_repository/auth_repository.dart';

class DioService {
  late final AuthRepository authRepository;

  // Add other repositories
  late final Dio dio;

  DioService() {
    initDio();
  }

  FlavorService get flavorService => GetIt.I<FlavorService>();

  void initDio() {
    final options = BaseOptions(
      baseUrl: flavorService.config.apiUrl,
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 32),
      receiveTimeout: const Duration(seconds: 32),
    );

    dio = Dio(options)
      ..transformer = FlutterTransformer()
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
    dio.interceptors.addAll(
      [
        RetryInterceptor(
          requestRetrier: DioConnectivityRequestRetrier(
            dio: dio,
          ),
        ),
      ],
    );

    initRepositories();
  }

  /// Init repositories.
  void initRepositories() {
    authRepository = AuthRepository(dio);
  }
}
