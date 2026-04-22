import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../gen/locale_keys.g.dart';
import '../../../../injectable.dart';
import 'challenge_joined_page_state.dart';
import 'widgets/challenge_joined_tips_stack.dart';

@RoutePage()
class ChallengeJoinedPage extends StatelessWidget {
  const ChallengeJoinedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<ChallengeJoinedPageState>(
      create: (_) => getIt<ChallengeJoinedPageState>()..init(),
      dispose: (_, state) => state.dispose(),
      child: const _ChallengeJoinedContent(),
    );
  }
}

class _ChallengeJoinedContent extends StatelessWidget {
  const _ChallengeJoinedContent();

  @override
  Widget build(BuildContext context) {
    final state = context.read<ChallengeJoinedPageState>();

    return Scaffold(
      backgroundColor: context.backgroundSurface,
      body: Stack(
        children: [
          const Positioned.fill(child: _BackgroundGlow()),
          SafeArea(
            child: Column(
              children: [
                _TopBar(onClose: state.onClosePressed),
                const SizedBox(height: kSpacing24px),
                const _Headline(),
                const Expanded(child: ChallengeJoinedTipsStack()),
                _JoinButton(onPressed: state.onJoinChallengePressed),
                const SizedBox(height: kSpacing16px),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Transform.translate(
          offset: const Offset(0, -178),
          child: Container(
            width: 516,
            height: 485,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  context.backgroundAccentOrangeLighter
                      .withValues(alpha: 0.55),
                  context.backgroundSurface.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacing20px,
        vertical: kSpacing16px,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: kSpacing24px,
              minHeight: kSpacing24px,
            ),
            icon: Icon(
              Icons.close_rounded,
              size: kSpacing24px,
              color: context.iconNeutralDarker,
            ),
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing32px),
      child: Column(
        children: [
          Text(
            LocaleKeys.challengeJoinedPage_title.tr(),
            textAlign: TextAlign.center,
            style: context.headerH2.setColor(context.textNeutralDarker),
          ),
          const SizedBox(height: kSpacing8px),
          Text(
            LocaleKeys.challengeJoinedPage_subtitle.tr(),
            textAlign: TextAlign.center,
            style: context.paragraphXLRegular.setColor(context.textNeutral),
          ),
        ],
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing32px),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.backgroundInformationDefaultDarker,
            foregroundColor: context.textInverse,
            shape: const StadiumBorder(),
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: kSpacing24px,
              vertical: kSpacing16px,
            ),
          ),
          child: Text(
            LocaleKeys.challengeJoinedPage_joinChallengeButton.tr(),
            style: context.labelXLMedium.setColor(context.textInverse),
          ),
        ),
      ),
    );
  }
}
