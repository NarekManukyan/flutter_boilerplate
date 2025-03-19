import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'core/constants/flavor_type.dart';
import 'core/services/flavor_service.dart';
import 'injectable.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // default
)
void configureDependencies(FlavorType flavorType) {
  getIt.init(environment: flavorType.name);
}

Future<void> resetDependencies() async {
  final flavorType = getIt<FlavorService>().flavor;
  await getIt.reset();
  configureDependencies(flavorType);
}
