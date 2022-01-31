import 'package:auto_route/auto_route.dart';
import 'package:url_launcher/url_launcher.dart';

import '../router.gr.dart';

final router = Router();

extension NavigationHelper on Router {
  Future<void> pushAndPopAll(PageRouteInfo page) async {
    await replaceAll([page]);
  }
}

Future<void> openTOSPage() async {
  // TODO get the URL from BE when the endpoint is ready
  const url = 'https://github.com/flutter/gallery/';
  if (await canLaunch(url)) {
    await launch(
      url,
      forceSafariVC: false,
    );
  }
}
