import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../store/connectivity/connectivity_state.dart';

class RetryInterceptor extends Interceptor {
  final DioConnectivityRequestRetrier requestRetrier;

  RetryInterceptor({
    required this.requestRetrier,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldRetry(err)) {
      try {
        log(
          'retrying request: ${err.requestOptions.uri}',
          name: 'RetryInterceptor',
        );
        final res = await requestRetrier.scheduleRequestRetry(
          err.requestOptions,
        );

        return handler.resolve(res);
      } catch (e) {
        // Let any new error from the retrier pass through.
        return handler.reject(err);
      }
    }

    // Let the error pass through if it's not the error we're looking for.
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

  DioConnectivityRequestRetrier({
    required this.dio,
  });

  ConnectivityState get connectivityState => GetIt.I<ConnectivityState>();

  Future<Response> scheduleRequestRetry(RequestOptions requestOptions) {
    late final StreamSubscription streamSubscription;
    final responseCompleter = Completer<Response>();
    streamSubscription =
        connectivityState.connectivity.onConnectivityChanged.listen(
      (connectivityResult) {
        switch (connectivityResult) {
          case ConnectivityResult.bluetooth:
          case ConnectivityResult.none:
            break;
          case ConnectivityResult.wifi:
          case ConnectivityResult.vpn:
          case ConnectivityResult.ethernet:
          case ConnectivityResult.mobile:
          case ConnectivityResult.other:
            streamSubscription.cancel();
            responseCompleter.complete(
              dio.fetch(requestOptions),
            );
            break;
        }
      },
    );

    return responseCompleter.future;
  }
}
