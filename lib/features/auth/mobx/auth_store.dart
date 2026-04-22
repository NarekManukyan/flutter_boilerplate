import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../core/utils/storage_utils.dart';
import '../../../injectable.dart';

part 'auth_store.g.dart';

@singleton
class AuthStore = _AuthStoreBase with _$AuthStore;

abstract class _AuthStoreBase with Store {
  @readonly
  bool _isAuthed = false;

  @readonly
  String? _email;

  @action
  Future<void> login(String email) async {
    _email = email;
    _isAuthed = true;
  }

  @action
  void logout() {
    _isAuthed = false;
    _email = null;
  }

  @action
  Future<void> getAccessToken() async {
    final token = await StorageUtils.getAccessToken();
    if (token != null) {
      _isAuthed = true;
    }
  }

  @action
  Future<void> setAccessToken(String token) async {
    await StorageUtils.setAccessToken(token);
    _isAuthed = true;
  }

  Future<void> clearSession() async {
    await StorageUtils.removeAccessToken();
    await resetDependencies();
  }
}
