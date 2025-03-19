import 'dart:async';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'models/models.dart';

part 'auth_api_provider.g.dart';

class _Paths {
  static const getUserProfile = '/user/me';
  static const googleLogin = '/auth/google/continue';
  static const appleLogin = '/auth/apple/continue';

  _Paths._();
}

@RestApi()
abstract class AuthProvider {
  factory AuthProvider(Dio dio) = _AuthProvider;

  @GET(_Paths.getUserProfile)
  Future<UserResponseDto> getUserProfile();

  @POST(_Paths.googleLogin)
  Future<AuthResponseDto> googleLogin(@Body() SocialLoginDto socialLoginDto);

  @POST(_Paths.appleLogin)
  Future<AuthResponseDto> appleLogin(@Body() SocialLoginDto socialLoginDto);
}
