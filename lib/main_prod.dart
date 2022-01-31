import 'package:flavorbanner/flavor_config.dart';

import 'main.dart' as app;

Future<void> main() async {
  await app.run(env: Flavor.PROD);
}
