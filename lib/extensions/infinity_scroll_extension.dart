import 'package:flutter/widgets.dart';

const delta = 200.0;

extension InfinitScrollExtension on ScrollController {
  void addInfiniteScrollListener(VoidCallback listener) {
    addListener(() {
      final maxScroll = position.maxScrollExtent;
      final currentScroll = position.pixels;
      if (maxScroll - currentScroll <= delta) {
        listener();
      }
    });
  }
}
