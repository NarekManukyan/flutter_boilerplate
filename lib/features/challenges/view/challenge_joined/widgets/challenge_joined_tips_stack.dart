import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../gen/locale_keys.g.dart';
import 'challenge_joined_tip_card.dart';

class ChallengeJoinedTipsStack extends StatelessWidget {
  const ChallengeJoinedTipsStack({super.key});

  static const double _stackWidth = 335;
  static const double _stackHeight = 320;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _stackWidth,
        height: _stackHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _sparkle(context, left: 18, top: 0),
            _sparkle(context, right: 24, top: 64),
            _sparkle(context, left: 154, top: 132),
            _sparkle(context, left: 26, top: 260),
            Positioned(
              left: 11,
              top: 36,
              child: Transform.rotate(
                angle: -12.69 * math.pi / 180,
                child: ChallengeJoinedTipCard(
                  title: LocaleKeys.challengeJoinedPage_tipPodcastTitle.tr(),
                  participantsLabel: LocaleKeys
                      .challengeJoinedPage_tipPodcastParticipants
                      .tr(args: const ['756']),
                  backgroundColor: context.backgroundAccentPurpleLighter,
                  icon: Icons.headphones_rounded,
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 60,
              child: Transform.rotate(
                angle: 8.06 * math.pi / 180,
                child: ChallengeJoinedTipCard(
                  title: LocaleKeys.challengeJoinedPage_tipMeditateTitle.tr(),
                  participantsLabel: LocaleKeys
                      .challengeJoinedPage_tipMeditateParticipants
                      .tr(args: const ['1670']),
                  backgroundColor: context.backgroundAccentBlueLighter,
                  icon: Icons.self_improvement_rounded,
                ),
              ),
            ),
            Positioned(
              left: 97,
              top: 152,
              child: Transform.rotate(
                angle: 10.67 * math.pi / 180,
                child: ChallengeJoinedTipCard(
                  title: LocaleKeys.challengeJoinedPage_tipWorkOutTitle.tr(),
                  participantsLabel: LocaleKeys
                      .challengeJoinedPage_tipWorkOutParticipants
                      .tr(args: const ['3265']),
                  backgroundColor: context.backgroundWarningDefault,
                  icon: Icons.fitness_center_rounded,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sparkle(
    BuildContext context, {
    double? left,
    double? right,
    double? top,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Icon(
        Icons.auto_awesome,
        size: 14,
        color: context.iconSecondary,
      ),
    );
  }
}
