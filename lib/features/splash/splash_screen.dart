import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

@RoutePage()
class SplashPage extends HookWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    useEffect(
      () {
        checkSession();

        return;
      },
    );

    return const Material(
      child: Center(
        child: FlutterLogo(
          size: 128,
        ),
      ),
    );
  }

  Future<void> checkSession() async {}
}
