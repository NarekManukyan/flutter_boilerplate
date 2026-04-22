import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class ChallengeJoinedTipCard extends StatelessWidget {
  const ChallengeJoinedTipCard({
    required this.title,
    required this.participantsLabel,
    required this.backgroundColor,
    required this.icon,
    super.key,
  });

  final String title;
  final String participantsLabel;
  final Color backgroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(kSpacing14px),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 75,
            width: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(kBorderRadius12px),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.backgroundWarningDefaultDarker,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: kSpacing32px,
                color: context.textWarning,
              ),
            ),
          ),
          const SizedBox(height: kSpacing4px),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.labelMSemibold.setColor(context.textNeutralDarker),
          ),
          const SizedBox(height: kSpacing2px),
          Text(
            participantsLabel,
            style: context.labelSRegular.setColor(context.textNeutral),
          ),
        ],
      ),
    );
  }
}
