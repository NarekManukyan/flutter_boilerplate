import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/core.dart';

class ModalTopLine extends StatelessWidget {
  const ModalTopLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Gap(kSpacing8px),
        SizedBox(
          height: 5,
          width: 36,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.5),
              // color: context.borderNeutral,
              color: const Color(0x7F7F7F66),
            ),
          ),
        ),
        const Gap(kSpacing12px),
      ],
    );
  }
}
