import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/overlay_loading.dart';
import '../../../gen/locale_keys.g.dart';
import '../../../injectable.dart';
import 'login_page_state.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<LoginPageState>(
      create: (_) => getIt<LoginPageState>(),
      dispose: (_, state) => state.dispose(),
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
      backgroundColor: context.backgroundSurface,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const Gap(kSpacing32px),
                Text(
                  LocaleKeys.loginPage_title.tr(),
                  style: context.headerH2.setColor(context.textNeutral),
                ).paddingHorizontal(),
                const Gap(kSpacing24px),
                _EmailField(controller: state.emailController),
                const Gap(kSpacing16px),
                _ContinueButton(onPressed: state.onContinuePressed),
                const Spacer(),
                Text(
                  LocaleKeys.loginPage_termsText.tr(),
                  textAlign: TextAlign.center,
                  style:
                      context.paragraphMRegular.setColor(context.textNeutral),
                ).paddingHorizontal(),
                const Gap(kSpacing16px),
              ],
            ),
          ),
          const _LoginLoading(),
        ],
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: LocaleKeys.loginPage_emailHint.tr(),
      ),
    ).paddingHorizontal();
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(LocaleKeys.loginPage_continueButton.tr()),
      ),
    ).paddingHorizontal();
  }
}

class _LoginLoading extends StatelessWidget {
  const _LoginLoading();

  @override
  Widget build(BuildContext context) {
    final state = context.read<LoginPageState>();
    return Observer(
      builder: (_) => state.loadingState.isLoading
          ? const OverlayEntryLoading()
          : const SizedBox(),
    );
  }
}
