import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final DioConnectivityRequestRetrier requestRetrier;

  RetryInterceptor({
    required this.requestRetrier,
  });

  @override
  Future onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldRetry(err)) {
      try {
        final res = await requestRetrier.scheduleRequestRetry(
          err.requestOptions,
        );
        return handler.resolve(res);
      } catch (e) {
        // Let any new error from the retrier pass through
        return handler.reject(err);
      }
    }
    // Let the error pass through if it's not the error we're looking for
    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.unknown;
  }
}

class DioConnectivityRequestRetrier {
  final Dio dio;
  final Connectivity connectivity;

  DioConnectivityRequestRetrier({
    required this.dio,
    required this.connectivity,
  });

  Future<Response> scheduleRequestRetry(RequestOptions requestOptions) async {
    late final StreamSubscription streamSubscription;
    final responseCompleter = Completer<Response>();

    streamSubscription = connectivity.onConnectivityChanged.listen(
      (connectivityResult) async {
        if (connectivityResult != ConnectivityResult.none) {
          unawaited(streamSubscription.cancel());
          // Complete the completer instead of returning

          // await Future<void>.delayed(const Duration(seconds: 2));
          responseCompleter.complete(
            dio.fetch<dynamic>(requestOptions),
          );
        }
      },
    );

    return responseCompleter.future;
  }
}
