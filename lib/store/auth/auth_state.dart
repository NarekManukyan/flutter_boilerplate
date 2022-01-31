import 'package:mobx/mobx.dart';

import '../../http/repositories/auth_repository.dart';
import '../../models/user_model/user_model.dart';
import '../../utils/storage_utils.dart';
import '../store.dart';

part 'auth_state.g.dart';

class AuthState = _AuthState with _$AuthState;

abstract class _AuthState with Store {
  @observable
  UserModel? _currentUser;

  @computed
  UserModel? get currentUser => _currentUser;

  @observable
  String? accessToken;

  @computed
  set currentUser(UserModel? user) {
    _currentUser = user;
  }

  @action
  Future<void> getCurrentUser() async {
    _currentUser = await AuthRepository.getCurrentUser();
  }

  @action
  Future<void> registerPushNotification(String token) async {}

  Future<void> _cleanUserData() async {
    await Future.wait([StorageUtils.removeAccessToken()]);

    reRegisterStoreGetIt();
  }

  @action
  Future<void> logout() async {
    await _cleanUserData();
  }
}
