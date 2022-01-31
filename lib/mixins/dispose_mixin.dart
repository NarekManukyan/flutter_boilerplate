import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../http/dio.dart';

mixin DisposeMixin<T extends StatefulWidget> on State<T> {
  @override
  void dispose() {
    cancelToken.cancel();
    cancelToken = CancelToken();
    super.dispose();
  }
}
