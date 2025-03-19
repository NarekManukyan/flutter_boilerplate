import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'flavor_service.dart';

@injectable
class SocialAuthService {
  final FlavorService _flavorService;

  SocialAuthService(this._flavorService);

  Future<String?> signInByGoogle() async {
    final googleClient = GoogleSignIn(
      scopes: [
        'profile',
        'email',
        'openid',
      ],
      serverClientId: _flavorService.config.google.serverClientId,
    );

    await googleClient.signOut();

    final res = await googleClient.signIn();

    final code = res?.serverAuthCode;

    if (code == null) {
      return null;
    }

    return code;
  }

  Future<String?> signInByApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    return credential.authorizationCode;
  }
}
