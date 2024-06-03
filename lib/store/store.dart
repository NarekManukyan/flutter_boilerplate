import 'package:get_it/get_it.dart';

import 'auth_store/auth_store.dart';

void registerStoreGetIt() {
  GetIt.I.registerSingleton(AuthStore());
}

void reRegisterStoreGetIt() {
  final authState = GetIt.I<AuthStore>();
  GetIt.I.unregister(instance: authState);
  registerStoreGetIt();
}
