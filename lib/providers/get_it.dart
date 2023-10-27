import 'package:get_it/get_it.dart';

import '../constants/flavor_type.dart';
import '../store/connectivity/connectivity_state.dart';
import '../store/store.dart';
import 'flavor_service.dart';

void registerGetIt(Flavor flavorMode) {
  GetIt.I.registerLazySingleton<FlavorService>(
    () => FlavorService(
      flavor: flavorMode,
    ),
  );
  GetIt.I.registerLazySingleton<ConnectivityState>(
    ConnectivityState.new,
  );

  registerStoreGetIt();
}
