import 'package:auto_route/auto_route.dart';

import '../routes/app_router.dart';

final router = AppRouter();

extension ScreenService on AppRouter {
  Future<void> pushAndPopAll(PageRouteInfo page) async {
    await replaceAll([page]);
  }
}
