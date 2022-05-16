import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../providers/screen_service.dart';
import '../../router.dart';
import '../../utils/storage_utils.dart';

class SplashScreenPage extends HookWidget {
  const SplashScreenPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    useEffect(
      () {
        checkSession();
        return;
      },
    );
    return const Scaffold(
      body: Center(
        child: FlutterLogo(
          size: 128,
        ),
      ),
    );
  }

  Future<void> checkSession() async {
    final _token = await StorageUtils.getAccessToken();
    if (_token != null) {
      await router.popAndPush(const LoginRoute());
    } else {
      await router.popAndPush(const DashboardRoute());
    }
  }
}
