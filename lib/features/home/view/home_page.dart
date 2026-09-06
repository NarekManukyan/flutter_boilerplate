import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/geist_motion.dart';
import '../../../core/ui/test_id.dart';
import '../../../gen/locale_keys.g.dart';
import '../../../injectable.dart';
import 'home_keys.dart';
import 'home_page_state.dart';

enum _TodoFilter { all, active, done }

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

class _HomePageContent extends HookWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final state = context.read<HomePageState>();
    final filter = useState(_TodoFilter.all);
    final scrollController = useScrollController();
    final fabVisible = useState(true);

    useEffect(() {
      void onScroll() {
        final dir = scrollController.position.userScrollDirection;
        if (dir == ScrollDirection.reverse && fabVisible.value) {
          fabVisible.value = false;
        } else if (dir == ScrollDirection.forward && !fabVisible.value) {
          fabVisible.value = true;
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    return Scaffold(
      backgroundColor: g.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _TopNav(
          onChallenge: state.onShowChallengeJoinedPressed,
          onLogout: state.onLogoutPressed,
        ),
      ),
      body: Observer(
        builder: (_) {
          final store = state.store;

          if (store.isLoading && store.todos.isEmpty) {
            return const _TodoSkeletonList().withTestId(HomeKeys.skeletonList);
          }
          if (store.error != null) {
            return _ErrorState(
              onRetry: state.init,
            ).withTestId(HomeKeys.errorState);
          }

          final total = store.todos.length;
          final done = store.todos.where((t) => t.completed).length;

          if (total == 0) {
            return const _EmptyState().withTestId(HomeKeys.emptyState);
          }

          final filtered = store.todos.where((t) {
            switch (filter.value) {
              case _TodoFilter.all:
                return true;
              case _TodoFilter.active:
                return !t.completed;
              case _TodoFilter.done:
                return t.completed;
            }
          }).toList();

          return RefreshIndicator(
            color: g.ink,
            backgroundColor: g.surface,
            onRefresh: state.init,
            child: CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Hero(total: total, done: done),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterHeaderDelegate(
                    background: g.surface,
                    child: _FilterBar(
                      current: filter.value,
                      total: total,
                      active: total - done,
                      done: done,
                      onChanged: (v) => filter.value = v,
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _FilterEmptyState(
                      filter: filter.value,
                    ).withTestId(HomeKeys.filterEmptyState),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      kSpacing20px,
                      kSpacing8px,
                      kSpacing20px,
                      kSpacing96px,
                    ),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Gap(kSpacing8px),
                      itemBuilder: (_, index) {
                        final todo = filtered[index];
                        return _TodoCard(
                          key: ValueKey(todo.id),
                          index: index,
                          todoId: todo.id,
                          title: todo.title,
                          completed: todo.completed,
                          onTap: state.onTodoTap,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ).withTestId(HomeKeys.todoList);
        },
      ),
      floatingActionButton: _NewTodoFab(
        visible: fabVisible.value,
        onPressed: state.onAddTodoPressed,
      ).withTestId(HomeKeys.addTodoFab),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({required this.onChallenge, required this.onLogout});

  final VoidCallback onChallenge;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: g.surface,
        border: Border(bottom: BorderSide(color: g.ringSoft)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacing20px,
            vertical: kSpacing10px,
          ),
          child: Row(
            children: [
              const _BrandMark(),
              const Gap(kSpacing12px),
              Text(
                LocaleKeys.homePage_title.tr(),
                style: GeistTextStyles.navTitle.copyWith(color: g.ink),
              ),
              const Spacer(),
              _GhostIconButton(
                icon: Icons.celebration_outlined,
                tooltip: LocaleKeys.homePage_challengePreview.tr(),
                onPressed: onChallenge,
              ),
              const Gap(kSpacing8px),
              _GhostIconButton(
                icon: Icons.logout_rounded,
                tooltip: LocaleKeys.homePage_logout.tr(),
                onPressed: onLogout,
              ).withTestId(HomeKeys.logoutButton),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: g.ink, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '▲',
        style: TextStyle(color: g.surface, fontSize: 10, height: 1),
      ),
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return Tooltip(
      message: tooltip ?? '',
      child: PressScale(
        onPressed: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GeistRadius.standard),
            boxShadow: [g.shadowRingSoft],
          ),
          child: Icon(icon, size: 16, color: g.ink),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final progress = total == 0 ? 0.0 : done / total;
    final remaining = total - done;
    final pct = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kSpacing20px,
        kSpacing24px,
        kSpacing20px,
        kSpacing16px,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MonoLabel('TASKS / OVERVIEW'),
          const Gap(kSpacing12px),
          AnimatedSwitcher(
            duration: GeistDuration.base,
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
                child: c,
              ),
            ),
            child: Text(
              remaining == 0
                  ? LocaleKeys.homePage_allDone.tr()
                  : LocaleKeys.homePage_remainingTasks.plural(remaining),
              key: ValueKey(remaining == 0),
              style: GeistTextStyles.displayM.copyWith(color: g.ink),
            ),
          ),
          const Gap(kSpacing8px),
          DefaultTextStyle.merge(
            style: GeistTextStyles.bodyM.copyWith(
              color: g.muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            child: Row(
              children: [
                AnimatedCount(
                  value: done,
                  style: GeistTextStyles.bodyM.copyWith(
                    color: g.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(kSpacing4px),
                Text(
                  LocaleKeys.homePage_progressSummary.tr(
                    namedArgs: {'total': '$total', 'pct': '$pct'},
                  ),
                ),
              ],
            ),
          ),
          const Gap(kSpacing16px),
          _ProgressTrack(progress: progress),
        ],
      ),
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, value, _) => ClipRRect(
        borderRadius: BorderRadius.circular(GeistRadius.subtle),
        child: Stack(
          children: [
            Container(height: 4, color: g.ringSoft),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(height: 4, color: g.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonoLabel extends StatelessWidget {
  const _MonoLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GeistTextStyles.monoLabel.copyWith(color: context.geist.subtle),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FilterHeaderDelegate({required this.child, required this.background});

  final Widget child;
  final Color background;

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: ColoredBox(
        color: background,
        child: Align(child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.background != background;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.current,
    required this.total,
    required this.active,
    required this.done,
    required this.onChanged,
  });

  final _TodoFilter current;
  final int total;
  final int active;
  final int done;
  final ValueChanged<_TodoFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing20px),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterChip(
            label: LocaleKeys.homePage_filterAll.tr(),
            count: total,
            selected: current == _TodoFilter.all,
            onTap: () => onChanged(_TodoFilter.all),
          ).withTestId(HomeKeys.filterAll),
          const Gap(kSpacing6px),
          _FilterChip(
            label: LocaleKeys.homePage_filterActive.tr(),
            count: active,
            selected: current == _TodoFilter.active,
            onTap: () => onChanged(_TodoFilter.active),
          ).withTestId(HomeKeys.filterActive),
          const Gap(kSpacing6px),
          _FilterChip(
            label: LocaleKeys.homePage_filterDone.tr(),
            count: done,
            selected: current == _TodoFilter.done,
            onTap: () => onChanged(_TodoFilter.done),
          ).withTestId(HomeKeys.filterDone),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final bg = selected ? g.ink : g.surface;
    final fg = selected ? g.surface : g.ink;
    final countBg = selected
        ? g.surface.withValues(alpha: 0.16)
        : g.badgeInfoBg;
    final countFg = selected ? g.surface : g.badgeInfoFg;

    return PressScale(
      scale: 0.96,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: GeistDuration.base,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacing12px,
          vertical: kSpacing8px,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(GeistRadius.standard),
          boxShadow: selected ? [g.shadowFab] : [g.shadowRingSoft],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: GeistDuration.base,
              style: GeistTextStyles.chip.copyWith(color: fg),
              child: Text(label),
            ),
            const Gap(kSpacing6px),
            AnimatedContainer(
              duration: GeistDuration.base,
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: kSpacing6px,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: countBg,
                borderRadius: BorderRadius.circular(GeistRadius.pill),
              ),
              child: AnimatedCount(
                value: count,
                duration: const Duration(milliseconds: 280),
                style: GeistTextStyles.chipCount.copyWith(color: countFg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoCard extends HookWidget {
  const _TodoCard({
    required this.todoId,
    required this.title,
    required this.completed,
    required this.onTap,
    required this.index,
    super.key,
  });

  final String todoId;
  final String title;
  final bool completed;
  final Future<void> Function(String) onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final reduced = geistReducedMotion(context);
    final delay = Duration(milliseconds: reduced ? 0 : 30 * index.clamp(0, 10));

    return FadeSlideIn(
      delay: delay,
      child: PressScale(
        onPressed: () => onTap(todoId),
        child: Container(
          decoration: BoxDecoration(
            color: g.surface,
            borderRadius: BorderRadius.circular(GeistRadius.comfortable),
            boxShadow: g.cardShadow,
          ),
          padding: const EdgeInsets.fromLTRB(
            kSpacing14px,
            kSpacing12px,
            kSpacing12px,
            kSpacing12px,
          ),
          child: Row(
            children: [
              _AnimatedCheckbox(completed: completed),
              const Gap(kSpacing12px),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: GeistDuration.base,
                  style: GeistTextStyles.listRow.copyWith(
                    color: completed ? g.placeholder : g.ink,
                    decoration: completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: g.placeholder,
                    decorationThickness: 2,
                  ),
                  child: Text(title),
                ),
              ),
              const Gap(kSpacing8px),
              Icon(Icons.chevron_right_rounded, size: 18, color: g.placeholder),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCheckbox extends StatelessWidget {
  const _AnimatedCheckbox({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: completed ? g.ink : g.surface,
        borderRadius: BorderRadius.circular(GeistRadius.subtle),
        boxShadow: [
          BoxShadow(color: completed ? g.ink : g.ringSoft, spreadRadius: 1),
        ],
      ),
      child: AnimatedSwitcher(
        duration: GeistDuration.base,
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: anim,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: completed
            ? Icon(
                Icons.check_rounded,
                key: const ValueKey('checked'),
                color: g.surface,
                size: 14,
              )
            : const SizedBox.shrink(key: ValueKey('unchecked')),
      ),
    );
  }
}

class _NewTodoFab extends StatelessWidget {
  const _NewTodoFab({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.6),
      duration: GeistDuration.base,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: GeistDuration.fast,
        child: PressScale(
          haptic: false,
          onPressed: () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kSpacing16px,
              vertical: kSpacing12px,
            ),
            decoration: BoxDecoration(
              color: g.ink,
              borderRadius: BorderRadius.circular(GeistRadius.comfortable),
              boxShadow: [g.shadowFab],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: g.surface, size: 16),
                const Gap(kSpacing6px),
                Text(
                  LocaleKeys.keywords_newTodo.tr(),
                  style: GeistTextStyles.button.copyWith(color: g.surface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return FadeSlideIn(
      child: Padding(
        padding: const EdgeInsets.all(kSpacing32px),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: g.surface,
                  borderRadius: BorderRadius.circular(GeistRadius.image),
                  boxShadow: g.cardShadow,
                ),
                child: Icon(Icons.checklist_rounded, size: 28, color: g.ink),
              ),
              const Gap(kSpacing20px),
              Text(
                LocaleKeys.homePage_empty.tr(),
                style: GeistTextStyles.subheading.copyWith(color: g.ink),
              ),
              const Gap(kSpacing8px),
              Text(
                LocaleKeys.homePage_emptySubtitle.tr(),
                textAlign: TextAlign.center,
                style: GeistTextStyles.bodyM.copyWith(color: g.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterEmptyState extends StatelessWidget {
  const _FilterEmptyState({required this.filter});

  final _TodoFilter filter;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final msg = switch (filter) {
      _TodoFilter.active => LocaleKeys.homePage_filterEmptyActive.tr(),
      _TodoFilter.done => LocaleKeys.homePage_filterEmptyDone.tr(),
      _TodoFilter.all => LocaleKeys.homePage_filterEmptyAll.tr(),
    };
    return FadeSlideIn(
      child: Padding(
        padding: const EdgeInsets.all(kSpacing32px),
        child: Center(
          child: Text(
            msg,
            textAlign: TextAlign.center,
            style: GeistTextStyles.bodyS.copyWith(color: g.subtle),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return FadeSlideIn(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(kSpacing32px),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 40, color: g.placeholder),
              const Gap(kSpacing16px),
              Text(
                LocaleKeys.homePage_errorLoading.tr(),
                textAlign: TextAlign.center,
                style: GeistTextStyles.sectionTitle.copyWith(color: g.ink),
              ),
              const Gap(kSpacing16px),
              PressScale(
                haptic: false,
                // ignore: unnecessary_lambdas
                onPressed: () {
                  onRetry();
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: kSpacing16px),
                  decoration: BoxDecoration(
                    color: g.ink,
                    borderRadius: BorderRadius.circular(GeistRadius.standard),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 16, color: g.surface),
                      const Gap(kSpacing6px),
                      Text(
                        LocaleKeys.keywords_retry.tr(),
                        style: GeistTextStyles.button.copyWith(
                          color: g.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ).withTestId(HomeKeys.errorRetry),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoSkeletonList extends HookWidget {
  const _TodoSkeletonList();

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final reduced = geistReducedMotion(context);
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    );
    useEffect(() {
      if (!reduced) {
        controller.repeat(reverse: true);
      }
      return null;
    }, const []);

    final row = DecoratedBox(
      decoration: BoxDecoration(
        color: g.skeletonBase,
        borderRadius: BorderRadius.circular(GeistRadius.comfortable),
        boxShadow: g.ringShadow,
      ),
      child: const SizedBox(height: 56, width: double.infinity),
    );
    final opacity = Tween<double>(
      begin: 0.6,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    return ListView.separated(
      padding: const EdgeInsets.all(kSpacing20px),
      itemCount: 6,
      separatorBuilder: (_, _) => const Gap(kSpacing8px),
      itemBuilder: (_, _) => FadeTransition(opacity: opacity, child: row),
    );
  }
}
