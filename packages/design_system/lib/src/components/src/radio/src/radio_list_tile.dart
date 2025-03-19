import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../../design_system.dart';

class CustomRadioListTile<T> extends StatelessWidget {
  const CustomRadioListTile({
    super.key,
    required this.value,
    required this.label,
    required this.groupValue,
    required this.onChanged,
  });

  final Widget label;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged.call(value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<T>(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(
              horizontal: VisualDensity.minimumDensity,
              vertical: VisualDensity.minimumDensity,
            ),
            splashRadius: 0,
            fillColor: WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(WidgetState.disabled)) {
                  return context.backgroundNeutralPressedLighter;
                }
                if (states.contains(WidgetState.pressed)) {
                  return context.backgroundPrimaryDefault;
                }
                if (states.contains(WidgetState.selected)) {
                  return context.backgroundPrimaryDefault;
                }
                return context.borderNeutral;
              },
            ),
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
          ),
          const Gap(8),
          DefaultTextStyle(
            style: context.labelLMedium.setColor(context.textNeutralDarker),
            child: label,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
