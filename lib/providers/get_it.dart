import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flavorbanner/flavor_config.dart';
import 'package:get_it/get_it.dart';

import '../http/dio.dart';
import '../http/interceptors/api_interceptor.dart';
import '../http/interceptors/auth_interceptor.dart';
import '../http/interceptors/retry_interceptor.dart';
import '../http/repositories/auth_repository.dart';
import '../store/store.dart';
import 'flavor_service.dart';

void registerGetIt(Flavor flavorMode) {
  dio.interceptors.addAll(
    <Interceptor>[
      RetryInterceptor(
        requestRetrier: DioConnectivityRequestRetrier(
          dio: dio,
          connectivity: Connectivity(),
        ),
      ),
      ApiInterceptor(),
      AuthInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (res) {
          log(res.toString(), name: 'BE');
        },
      ),
    ],
  );
  GetIt.I.registerLazySingleton<FlavorService>(
    () => FlavorService(
      flavor: flavorMode,
    ),
  );

  // Repositories
  GetIt.I.registerSingleton(AuthRepository());

  registerStoreGetIt();
}
