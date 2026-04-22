import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/overlay_loading.dart';
import '../../../gen/locale_keys.g.dart';
import '../../../injectable.dart';
import 'todo_details_page_state.dart';

@RoutePage()
class TodoDetailsPage extends StatelessWidget {
  const TodoDetailsPage({
    @PathParam('id') required this.todoId,
    super.key,
  });

  final String todoId;

  @override
  Widget build(BuildContext context) {
    return Provider<TodoDetailsPageState>(
      create: (_) => getIt<TodoDetailsPageState>()..init(todoId),
      dispose: (_, state) => state.dispose(),
      child: const _TodoDetailsContent(),
    );
  }
}

class _TodoDetailsContent extends StatelessWidget {
  const _TodoDetailsContent();

  @override
  Widget build(BuildContext context) {
    final state = context.read<TodoDetailsPageState>();

    return Scaffold(
      backgroundColor: context.backgroundSurface,
      appBar: AppBar(
        title: Text(LocaleKeys.todoDetailsPage_title.tr()),
      ),
      body: Observer(
        builder: (_) {
          if (state.isLoading) {
            return const OverlayEntryLoading();
          }
          if (state.error != null || state.todo == null) {
            return Center(
              child: Text(
                LocaleKeys.todoDetailsPage_error.tr(),
                style:
                    context.paragraphLRegular.setColor(context.textNeutral),
              ),
            );
          }
          final todo = state.todo!;
          return Padding(
            padding: const EdgeInsets.all(kSpacing16px),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style:
                      context.headerH3.setColor(context.textNeutralDarker),
                ),
                const Gap(kSpacing8px),
                Text(
                  '#${todo.id}',
                  style: context.paragraphSRegular
                      .setColor(context.textNeutralLighter),
                ),
                const Gap(kSpacing24px),
                Row(
                  children: [
                    Icon(
                      todo.completed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: todo.completed
                          ? context.backgroundPrimaryDefault
                          : context.textNeutralLighter,
                    ),
                    const Gap(kSpacing8px),
                    Text(
                      todo.completed ? 'Completed' : 'Pending',
                      style: context.paragraphLMedium
                          .setColor(context.textNeutral),
                    ),
                  ],
                ),
                const Gap(kSpacing24px),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.onToggleCompleted,
                    child: Text(
                      LocaleKeys.todoDetailsPage_toggleCompleted.tr(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
