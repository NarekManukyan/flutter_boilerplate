import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/core.dart';
import '../../../../theme/theme.dart';
import 'modal_top_line.dart';

class ModalHeader extends StatelessWidget {
  const ModalHeader({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ModalTopLine(),
        const Gap(kSpacing2px),
        _ModalTitle(title: title),
        const Gap(kSpacing10px),
      ],
    );
  }
}

class _ModalTitle extends StatelessWidget {
  const _ModalTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: context.labelLBold.setColor(context.textNeutral));
  }
}
