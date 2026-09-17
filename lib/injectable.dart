import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'core/constants/flavor_type.dart';
import 'core/services/flavor_service.dart';
import 'injectable.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  preferRelativeImports: true, // default
)
void configureDependencies(FlavorType flavorType) {
  getIt.init(environment: flavorType.name);
}

/// Bumped by [resetDependencies]. After a reset every singleton is a new
/// instance, `AppNavigator` and its router included, so the app root keys its
/// router subtree on this value: the new router gets mounted, and page states
/// created afterwards navigate on a router that is actually on screen. Without
/// it, logging in again after a logout went nowhere.
final dependencyGeneration = ValueNotifier<int>(0);

Future<void> resetDependencies() async {
  final flavorType = getIt<FlavorService>().flavor;
  await getIt.reset();
  configureDependencies(flavorType);
  dependencyGeneration.value++;
}
