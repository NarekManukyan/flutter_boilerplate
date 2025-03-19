import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/social_provider_enum.dart';
import '../../../gen/locale_keys.g.dart';
import '../../../injectable.dart';
import '../../../shared/widgets/loadings/overlay_loading.dart';
import '../mobx/login_page_state.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<LoginPageState>(
      create: (_) => getIt<LoginPageState>(),
      child: const _LoginPageContent(),
    );
  }
}

class _LoginPageContent extends StatelessWidget {
  const _LoginPageContent();

  @override
  Widget build(BuildContext context) {
    final state = context.read<LoginPageState>();

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Gap(context.topPadding),
              _LoginButtons(
                onSocialLoginTap: state.onSocialLoginTap,
                onEmailTap: state.onEmailTap,
              ),
              const Spacer(),
              _TermsAndPrivacyPolicy(
                openExternalUrl: state.openExternalUrl,
              ),
              Gap(context.bottomSecurePadding),
            ],
          ),
          const _LoginLoading(),
        ],
      ),
    );
  }
}

class _LoginLoading extends StatelessWidget {
  const _LoginLoading();

  @override
  Widget build(BuildContext context) {
    final state = context.read<LoginPageState>();

    return Observer(
      builder: (_) => state.socialLoadingState.isLoading
          ? const OverlayEntryLoading()
          : const SizedBox(),
    );
  }
}

class _LoginButtons extends StatelessWidget {
  const _LoginButtons({
    required this.onSocialLoginTap,
    required this.onEmailTap,
  });

  final Function(SocialProviderEnum) onSocialLoginTap;
  final VoidCallback onEmailTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Gap(kSpacing32px),
        const _ExtrasFreePlan(),
        const Gap(kSpacing16px),
        _SocialButton(
          onSocialLoginTap: onSocialLoginTap,
          socialProvider: SocialProviderEnum.GOOGLE,
        ),
        const Gap(kSpacing12px),
        if (Platform.isIOS) ...[
          _SocialButton(
            onSocialLoginTap: onSocialLoginTap,
            socialProvider: SocialProviderEnum.APPLE,
          ),
        ],
        const Gap(kSpacing24px),
      ],
    ).paddingHorizontal();
  }
}

class _ExtrasFreePlan extends StatelessWidget {
  const _ExtrasFreePlan();

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKeys.loginPage_extrasFreePlan.tr(),
      style: context.labelXLMedium.setColor(context.textNeutralLighter),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onSocialLoginTap,
    required this.socialProvider,
  });

  final ValueChanged<SocialProviderEnum> onSocialLoginTap;
  final SocialProviderEnum socialProvider;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onSocialLoginTap(socialProvider),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          socialProvider.icon.image(),
          const Gap(kSpacing6px),
          Text(
            LocaleKeys.loginPage_continueWith.tr(
              namedArgs: {
                'provider': socialProvider.name.toSentenceCase,
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsAndPrivacyPolicy extends StatelessWidget {
  const _TermsAndPrivacyPolicy({
    required this.openExternalUrl,
  });

  final Function(String) openExternalUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          LocaleKeys.loginPage_termsIntroText.tr(),
          style: context.paragraphMRegular.setColor(context.textNeutral),
        ),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: context.paragraphMRegular.setColor(context.textNeutral),
            children: [
              TextSpan(
                text: LocaleKeys.loginPage_termsOfUse.tr(),
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => openExternalUrl('https://example.com'),
              ),
              TextSpan(
                text: LocaleKeys.loginPage_and.tr(),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => openExternalUrl('https://example.com'),
              ),
              TextSpan(
                text: LocaleKeys.loginPage_privacyPolicy.tr(),
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => openExternalUrl('https://example.com'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
