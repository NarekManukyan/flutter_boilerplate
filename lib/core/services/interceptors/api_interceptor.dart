
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../flavor_service.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.baseUrl = GetIt.I<FlavorService>().config.apiUrl;

    if (options.data is Map) {
      clearDataRecursively(options.data);
    }
    clearDataRecursively(options.queryParameters);

    return handler.next(options);
  }
}

void clearDataRecursively(Map<String, dynamic> map) {
  for (final value in map.values) {
    if (value is Map<String, dynamic>) {
      clearDataRecursively(value);
    }
  }
  map.removeWhere(
    (key, value) => key == 'runtimeType',
  );
}
