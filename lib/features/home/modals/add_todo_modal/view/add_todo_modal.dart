import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../../../gen/locale_keys.g.dart';
import '../../../../../injectable.dart';
import '../mobx/add_todo_modal_state.dart';

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

class _AddTodoModalContent extends StatelessWidget {
  const _AddTodoModalContent();

  @override
  Widget build(BuildContext context) {
    final state = context.read<AddTodoModalState>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ModalTopLine(),
        const Gap(kSpacing16px),
        Text(
          LocaleKeys.addTodoModal_title.tr(),
          style: context.subheaderS1Bold.setColor(context.textNeutralDarker),
          textAlign: TextAlign.center,
        ),
        const Gap(kSpacing16px),
        TextField(
          controller: state.titleController,
          decoration: InputDecoration(
            hintText: LocaleKeys.addTodoModal_titleHint.tr(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        const Gap(kSpacing16px),
        Observer(
          builder: (_) {
            final isLoading = state.loadingState.isLoading;
            return ElevatedButton(
              onPressed: isLoading ? null : state.onSubmit,
              child: Text(LocaleKeys.addTodoModal_add.tr()),
            );
          },
        ),
        const Gap(kSpacing8px),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.addTodoModal_cancel.tr()),
        ),
        Gap(context.bottomSecurePadding),
      ],
    ).paddingOnly(
      left: kSpacing24px,
      right: kSpacing24px,
      top: kSpacing8px,
    );
  }
}
