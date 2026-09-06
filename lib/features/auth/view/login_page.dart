import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/geist_motion.dart';
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

class _LoginPageContent extends HookWidget {
  const _LoginPageContent();

  @override
  Widget build(BuildContext context) {
    final state = context.read<LoginPageState>();
    final g = context.geist;

    return Scaffold(
      backgroundColor: g.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacing24px,
                vertical: kSpacing32px,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Gap(kSpacing40px),
                  const FadeSlideIn(child: _Wordmark()),
                  const Gap(kSpacing40px),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: Text(
                      'Welcome back.',
                      style: GeistTextStyles.displayL.copyWith(color: g.ink),
                    ),
                  ),
                  const Gap(kSpacing12px),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'Sign in to continue. We’ll send a secure link to your inbox.',
                      style: GeistTextStyles.bodyL.copyWith(color: g.muted),
                    ),
                  ),
                  const Gap(kSpacing32px),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: Observer(
                      builder: (_) => _EmailField(
                        controller: state.emailController,
                        errorText: state.emailError == null
                            ? null
                            : LocaleKeys.loginPage_emailHint.tr(),
                      ),
                    ),
                  ),
                  const Gap(kSpacing16px),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: Observer(
                      builder: (_) => _ContinueButton(
                        onPressed: state.onContinuePressed,
                        isLoading: state.loadingState.isLoading,
                      ),
                    ),
                  ),
                  const Gap(kSpacing32px),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 220),
                    child: _Divider(label: LocaleKeys.keywords_or.tr()),
                  ),
                  const Gap(kSpacing24px),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 260),
                    child: Text(
                      LocaleKeys.loginPage_termsText.tr(),
                      textAlign: TextAlign.center,
                      style: GeistTextStyles.bodyXS.copyWith(color: g.subtle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends HookWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final reduced = geistReducedMotion(context);
    final controller = useAnimationController(duration: GeistDuration.breathe);
    useEffect(() {
      if (!reduced) {
        controller.repeat(reverse: true);
      }
      return null;
    }, const []);

    final mark = Center(
      child: Text(
        '▲',
        style: TextStyle(color: g.surface, fontSize: 12, height: 1),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: controller,
          child: mark,
          builder: (_, child) {
            final t = Curves.easeInOut.transform(controller.value);
            final glow = 0.04 + 0.06 * t;
            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: g.ink,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: g.ink.withValues(alpha: glow),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: child,
            );
          },
        ),
        const Gap(kSpacing8px),
        Text(
          'boilerplate',
          style: GeistTextStyles.sectionTitle.copyWith(color: g.ink),
        ),
      ],
    );
  }
}

class _EmailField extends HookWidget {
  const _EmailField({required this.controller, this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final focus = useFocusNode();
    useListenable(focus);
    final isFocused = focus.hasFocus;

    final hasError = errorText != null;
    final Color borderColor;
    if (hasError) {
      borderColor = g.danger;
    } else if (isFocused) {
      borderColor = g.focusBlue;
    } else {
      borderColor = g.hairline;
    }
    final borderWidth = (isFocused || hasError) ? 2.0 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EMAIL',
          style: GeistTextStyles.monoLabelTight.copyWith(color: g.ink),
        ),
        const Gap(kSpacing8px),
        AnimatedContainer(
          duration: GeistDuration.fast,
          decoration: BoxDecoration(
            color: g.surface,
            borderRadius: BorderRadius.circular(GeistRadius.comfortable),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: g.focusBlue.withValues(alpha: g.focusHaloAlpha),
                      spreadRadius: 3,
                    ),
                  ]
                : [g.shadowElevation],
          ),
          child: TextField(
            controller: controller,
            focusNode: focus,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            style: GeistTextStyles.bodyL.copyWith(color: g.ink),
            decoration: InputDecoration(
              hintText: LocaleKeys.loginPage_emailHint.tr(),
              hintStyle: GeistTextStyles.bodyL.copyWith(color: g.placeholder),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: kSpacing14px,
                vertical: kSpacing14px,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        AnimatedSize(
          duration: GeistDuration.base,
          curve: Curves.easeOut,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: kSpacing8px),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: g.danger,
                      ),
                      const Gap(kSpacing6px),
                      Flexible(
                        child: Text(
                          errorText!,
                          style: GeistTextStyles.helperError.copyWith(
                            color: g.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed, required this.isLoading});

  final Future<void> Function() onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return PressScale(
      onPressed: isLoading ? null : () => unawaited(onPressed()),
      haptic: false,
      child: AnimatedContainer(
        duration: GeistDuration.base,
        curve: Curves.easeOut,
        height: 44,
        decoration: BoxDecoration(
          color: g.ink,
          borderRadius: BorderRadius.circular(GeistRadius.comfortable),
          boxShadow: [g.shadowFab],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: GeistDuration.base,
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(g.surface),
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      LocaleKeys.loginPage_continueButton.tr(),
                      style: GeistTextStyles.button.copyWith(color: g.surface),
                    ),
                    const Gap(kSpacing8px),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: g.surface,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return Row(
      children: [
        const Expanded(child: _Hairline()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSpacing12px),
          child: Text(
            label.toUpperCase(),
            style: GeistTextStyles.monoLabelTight.copyWith(
              color: g.placeholder,
            ),
          ),
        ),
        const Expanded(child: _Hairline()),
      ],
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.geist.ringSoft,
      child: const SizedBox(height: 1),
    );
  }
}
