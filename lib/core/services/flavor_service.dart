import 'package:injectable/injectable.dart';

import '../configs/environments/development/development.dart';
import '../configs/environments/production/production.dart';
import '../configs/models/config/config.dart';
import '../constants/flavor_type.dart';

/// A service class for managing different flavors of the application.

sealed class FlavorService {
  FlavorService();

  FlavorType get flavor;

  Config get config;

  bool get isDev;

  bool get isProduction;
}

@Singleton(
  env: ['DEVELOPMENT'],
  as: FlavorService,
  order: -1,
)
class FlavorDev implements FlavorService {
  late final FlavorType _flavor = FlavorType.DEVELOPMENT;
  late final Config _config = Config.fromJson(developmentEnv);

  @override
  FlavorType get flavor => _flavor;

  @override
  Config get config => _config;

  @override
  bool get isDev => true;

  @override
  bool get isProduction => false;
}

@Singleton(
  env: ['PROD'],
  as: FlavorService,
  order: -1,
)
class FlavorProd implements FlavorService {
  final FlavorType _flavor = FlavorType.PROD;
  final Config _config = Config.fromJson(productionEnv);

  @override
  FlavorType get flavor => _flavor;

  @override
  Config get config => _config;

  @override
  bool get isDev => false;

  @override
  bool get isProduction => true;
}
