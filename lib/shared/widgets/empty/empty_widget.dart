import 'package:design_system/design_system.dart';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final AssetGenImage image;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: image.image(
            height: 96,
            width: 96,
          ),
        ),
        const Gap(kSpacing8px),
        Text(
          title,
          style: context.subheaderS2Bold.setColor(context.textNeutral),
        ),
        const Gap(kSpacing8px),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: context.paragraphXLRegular.setColor(context.textNeutral),
        ),
      ],
    );
  }
}
