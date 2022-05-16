import 'package:auto_route/auto_route.dart';

import '../router.gr.dart';

final router = Router();

extension NavigationHelper on Router {
  Future<void> pushAndPopAll(PageRouteInfo page) async {
    await replaceAll([page]);
  }
}
