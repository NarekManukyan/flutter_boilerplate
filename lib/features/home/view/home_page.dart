import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/overlay_loading.dart';
import '../../../gen/locale_keys.g.dart';
import '../../../injectable.dart';
import 'home_page_state.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<HomePageState>(
      create: (_) => getIt<HomePageState>()..init(),
      dispose: (_, state) => state.dispose(),
      child: const _HomePageContent(),
    );
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    final state = context.read<HomePageState>();

    return Scaffold(
      backgroundColor: context.backgroundSurface,
      appBar: AppBar(
        title: Text(LocaleKeys.homePage_title.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.celebration_outlined),
            onPressed: state.onShowChallengeJoinedPressed,
            tooltip: 'Challenge joined preview',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: state.onLogoutPressed,
            tooltip: LocaleKeys.homePage_logout.tr(),
          ),
        ],
      ),
      body: Observer(
        builder: (_) {
          final store = state.store;
          if (store.isLoading && store.todos.isEmpty) {
            return const OverlayEntryLoading();
          }
          if (store.error != null) {
            return Center(
              child: Text(
                LocaleKeys.homePage_errorLoading.tr(),
                style:
                    context.paragraphLRegular.setColor(context.textNeutral),
              ),
            );
          }
          if (store.todos.isEmpty) {
            return Center(
              child: Text(
                LocaleKeys.homePage_empty.tr(),
                style:
                    context.paragraphLRegular.setColor(context.textNeutral),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: kSpacing8px),
            itemCount: store.todos.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final todo = store.todos[index];
              return _TodoTile(
                todoId: todo.id,
                title: todo.title,
                completed: todo.completed,
                onTap: state.onTodoTap,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.onAddTodoPressed,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    required this.todoId,
    required this.title,
    required this.completed,
    required this.onTap,
  });

  final String todoId;
  final String title;
  final bool completed;
  final Future<void> Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        completed ? Icons.check_circle : Icons.radio_button_unchecked,
        color: completed
            ? context.backgroundPrimaryDefault
            : context.textNeutralLighter,
      ),
      title: Text(title),
      onTap: () => onTap(todoId),
    );
  }
}
