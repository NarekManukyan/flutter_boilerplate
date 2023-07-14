import 'package:dio/dio.dart';

import 'dio_flutter_transformer.dart';

final options = BaseOptions(
  connectTimeout: const Duration(seconds: 32),
  receiveTimeout: const Duration(seconds: 32),
);

final dio = Dio(options)..transformer = FlutterTransformer();

CancelToken cancelToken = CancelToken();
