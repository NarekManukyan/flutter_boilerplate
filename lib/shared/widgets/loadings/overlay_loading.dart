import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class OverlayEntryLoading extends HookWidget {
  const OverlayEntryLoading({
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.width,
      height: context.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.overlayDefault,
        ),
        child: const LoadingWidget(isLoading: true),
      ),
    );
  }
}
