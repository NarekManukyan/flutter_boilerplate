import 'package:mobx/mobx.dart';

import '../../http/dio.dart';
import '../../models/user/user_dto.dart';
import '../../utils/storage_utils.dart';
import '../store.dart';

part 'auth_state.g.dart';

class AuthState = _AuthState with _$AuthState;

abstract class _AuthState with Store {
  @observable
  UserDto? _currentUser;

  @computed
  UserDto? get currentUser => _currentUser;

  @observable
  String? accessToken;

  @computed
  set currentUser(UserDto? user) {
    _currentUser = user;
  }

  @action
  Future<void> getCurrentUser() async {
    _currentUser = await dio.authRepository.getCurrentUser();
  }

  Future<void> _cleanUserData() async {
    await Future.wait([StorageUtils.removeAccessToken()]);
    reRegisterStoreGetIt();
  }

  Future<void> logout() async {
    await _cleanUserData();
  }
}
