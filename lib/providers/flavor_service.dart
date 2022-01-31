import 'package:flavorbanner/flavor_config.dart';

import '../environments/development/development.dart';
import '../environments/production/production.dart';
import '../environments/staging/staging.dart';
import '../environments/test/test.dart';
import '../models/config/config.dart';

class FlavorService {
  late final Flavor flavor;
  late final Config config;

  FlavorService({required this.flavor}) {
    switch (flavor) {
      case Flavor.DEV:
        config = Config.fromJson(developmentEnv);
        break;
      case Flavor.PROD:
        config = Config.fromJson(productionEnv);
        break;
      case Flavor.TEST:
        config = Config.fromJson(testEnv);
        break;
      case Flavor.STAGING:
        config = Config.fromJson(stagingEnv);
        break;
    }
  }

  bool get isDevelopment => flavor == Flavor.DEV;

  bool get isProduction => flavor == Flavor.PROD;
}
