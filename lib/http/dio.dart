import 'package:dio/dio.dart';

import 'dio_flutter_transformer.dart';

final options = BaseOptions(
  connectTimeout: 240000,
  receiveTimeout: 240000,
);

final dio = Dio(options)..transformer = FlutterTransformer();

CancelToken cancelToken = CancelToken();
