import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../../../core/ui/geist_motion.dart';
import '../../../../../gen/locale_keys.g.dart';
import '../../../../../injectable.dart';
import '../mobx/add_todo_modal_state.dart';

const _kMaxLength = 80;

class AddTodoModal extends StatelessWidget {
  const AddTodoModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<AddTodoModalState>(
      create: (_) => getIt<AddTodoModalState>(),
      dispose: (_, state) => state.dispose(),
      child: const _AddTodoModalContent(),
    );
  }
}

class _AddTodoModalContent extends HookWidget {
  const _AddTodoModalContent();

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final state = context.read<AddTodoModalState>();
    useListenable(state.titleController);
    final trimmedLen = state.titleController.text.trim().length;
    final hasText = trimmedLen > 0;

    return ColoredBox(
      color: g.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModalTopLine(),
          const Gap(kSpacing20px),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpacing24px),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  child: Text(
                    'NEW TASK',
                    style: GeistTextStyles.monoLabel.copyWith(color: g.subtle),
                  ),
                ),
                const Gap(kSpacing8px),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 40),
                  child: Text(
                    LocaleKeys.addTodoModal_title.tr(),
                    style: GeistTextStyles.cardTitle.copyWith(color: g.ink),
                  ),
                ),
                const Gap(kSpacing4px),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    'Keep it short. You can always edit later.',
                    style: GeistTextStyles.bodyS.copyWith(color: g.muted),
                  ),
                ),
                const Gap(kSpacing20px),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: _TitleField(
                    controller: state.titleController,
                    onSubmit: () {
                      if (hasText) {
                        state.onSubmit();
                      }
                    },
                  ),
                ),
                const Gap(kSpacing6px),
                _CounterRow(length: trimmedLen, max: _kMaxLength),
                const Gap(kSpacing16px),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: Observer(
                    builder: (_) {
                      final isLoading = state.loadingState.isLoading;
                      return _PrimaryButton(
                        isLoading: isLoading,
                        label: LocaleKeys.addTodoModal_add.tr(),
                        onPressed: hasText && !isLoading
                            ? () {
                                HapticFeedback.lightImpact();
                                state.onSubmit();
                              }
                            : null,
                      );
                    },
                  ),
                ),
                const Gap(kSpacing8px),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: _GhostButton(
                    label: LocaleKeys.addTodoModal_cancel.tr(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Gap(context.bottomSecurePadding + kSpacing8px),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({required this.length, required this.max});
  final int length;
  final int max;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final warn = length > max * 0.85;
    final color = warn ? g.warn : g.placeholder;
    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedDefaultTextStyle(
        duration: GeistDuration.fast,
        style: GeistTextStyles.monoCounter.copyWith(color: color),
        child: Text('$length / $max'),
      ),
    );
  }
}

class _TitleField extends HookWidget {
  const _TitleField({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final focus = useFocusNode();
    useListenable(focus);
    final isFocused = focus.hasFocus;

    return AnimatedContainer(
      duration: GeistDuration.fast,
      decoration: BoxDecoration(
        color: g.surface,
        borderRadius: BorderRadius.circular(GeistRadius.comfortable),
        border: Border.all(
          color: isFocused ? g.focusBlue : g.hairline,
          width: isFocused ? 2 : 1,
        ),
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
        autofocus: true,
        maxLength: _kMaxLength,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onSubmit(),
        style: GeistTextStyles.bodyL.copyWith(color: g.ink),
        decoration: InputDecoration(
          hintText: LocaleKeys.addTodoModal_titleHint.tr(),
          hintStyle: GeistTextStyles.bodyL.copyWith(color: g.placeholder),
          filled: true,
          fillColor: Colors.transparent,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: kSpacing14px,
            vertical: kSpacing14px,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final enabled = onPressed != null;
    return PressScale(
      haptic: false,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: GeistDuration.base,
        curve: Curves.easeOut,
        height: 48,
        decoration: BoxDecoration(
          color: enabled ? g.ink : g.placeholder,
          borderRadius: BorderRadius.circular(GeistRadius.comfortable),
          boxShadow: enabled ? [g.shadowFab] : null,
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
                      label,
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

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return PressScale(
      haptic: false,
      onPressed: onPressed,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: g.surface,
          borderRadius: BorderRadius.circular(GeistRadius.comfortable),
          boxShadow: [g.shadowRingSoft],
        ),
        child: Text(
          label,
          style: GeistTextStyles.button.copyWith(color: g.ink),
        ),
      ),
    );
  }
}
