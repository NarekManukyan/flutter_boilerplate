import 'package:api/api.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

import '../../../core/constants/social_provider_enum.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../injectable.dart';
import '../../state/loading_state/loading_state.dart';

part 'auth_store.g.dart';

@singleton
class AuthStore = AuthStoreBase with _$AuthStore;

abstract class AuthStoreBase with Store {
  final DioService _dio;
  late final AuthProvider _authProvider = _dio.authProvider;
  final _userLoadingState = LoadingState()..startLoading();

  AuthStoreBase(this._dio);

  @readonly
  UserResponseDto? _currentUser;
  @readonly
  String? _accessToken;
  @readonly
  bool _isUserLoaded = false;

  @computed
  bool get isLoggedIn => _accessToken != null;

  @computed
  bool get isUserLoading => _userLoadingState.isLoading;

  @action
  Future<void> getCurrentUser({
    bool updateUserLoaded = false,
  }) async {
    _userLoadingState.startLoading();
    _currentUser = await _authProvider.getUserProfile();
    if (updateUserLoaded) {
      _isUserLoaded = true;
    }
    _userLoadingState.stopLoading();
  }

  @action
  Future<void> getAccessToken() async {
    final token = await StorageUtils.getAccessToken();
    if (token != null) {
      await setAccessToken(token);
    }
  }

  @action
  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    await StorageUtils.setAccessToken(token);
  }

  Future<AuthResponseDto> socialLogin(
    String code,
    SocialProviderEnum provider,
  ) async {
    final res = switch (provider) {
      SocialProviderEnum.GOOGLE => await _authProvider
          .googleLogin(SocialLoginDto(code: code, lang: 'en-US')),
      SocialProviderEnum.APPLE => await _authProvider
          .appleLogin(SocialLoginDto(code: code, lang: 'en-US')),
    };

    return res;
  }

  Future<void> _cleanUserData() async {
    await StorageUtils.removeAccessToken();
  }

  Future<void> logout() async {
    await _cleanUserData();
    await resetDependencies();
  }
}
