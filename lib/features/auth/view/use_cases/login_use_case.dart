import 'package:injectable/injectable.dart';

import '../../mobx/auth_store.dart';

@injectable
class LoginUseCase {
  final AuthStore _authStore;

  LoginUseCase(this._authStore);

  Future<bool> call(String email) async {
    await _authStore.login(email);
    return true;
  }
}
