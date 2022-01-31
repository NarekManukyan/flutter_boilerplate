import 'dart:async';

import '../../models/user_model/user_model.dart';
import '../dio.dart';

class AuthRepository {
  static Future<UserModel> getCurrentUser() async {
    final res = await dio.get(
      '/auth/me',
    );
    return UserModel.fromJson(res.data);
  }
}
