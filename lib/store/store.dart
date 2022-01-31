import 'package:get_it/get_it.dart';

import 'auth/auth_state.dart';

void registerStoreGetIt() {
  GetIt.I.registerSingleton(AuthState());
}

void reRegisterStoreGetIt() {
  final authState = GetIt.I<AuthState>();
  GetIt.I.unregister(instance: authState);
  registerStoreGetIt();
}
