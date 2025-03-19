import 'package:design_system/design_system.dart';

enum SocialProviderEnum {
  APPLE,
  GOOGLE,
}

extension SocialProviderEnumHelper on SocialProviderEnum {
  AssetGenImage get icon => switch (this) {
        SocialProviderEnum.APPLE => Assets.icons.apple,
        SocialProviderEnum.GOOGLE => Assets.icons.google,
      };
}
