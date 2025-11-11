import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'flavor_service.dart';

const _googlePublicScopes = [
    'profile',
    'email',
    'openid',
];

@injectable
class SocialAuthService {
  final FlavorService _flavorService;

  SocialAuthService(this._flavorService);

  Future<String?> signInByGoogle() async {
    try {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}

      try {
        await GoogleSignIn.instance.initialize(
          serverClientId: _flavorService.config.google.serverClientId,
        );
      } catch (_) {}

      final serverAuth = await GoogleSignIn.instance.authorizationClient
          .authorizeServer(_googlePublicScopes);

      return serverAuth?.serverAuthCode;
    } catch (_) {
      return null;
    } finally {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
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
