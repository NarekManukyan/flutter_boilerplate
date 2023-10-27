import 'dart:async';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../models/user/user_dto.dart';

part 'auth_repository.g.dart';

class _Paths {
  static const authMe = '/auth/me';

  _Paths._();
}

@RestApi()
abstract class AuthRepository {
  factory AuthRepository(Dio dio) = _AuthRepository;

  @GET(_Paths.authMe)
  Future<UserDto> getCurrentUser();
}
