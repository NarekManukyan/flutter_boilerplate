import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/geist_motion.dart';
import '../../../gen/locale_keys.g.dart';
import '../../../injectable.dart';
import 'todo_details_page_state.dart';

@RoutePage()
class TodoDetailsPage extends StatelessWidget {
  const TodoDetailsPage({@PathParam('id') required this.todoId, super.key});

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
    final g = context.geist;
    final state = context.read<TodoDetailsPageState>();

    return Scaffold(
      backgroundColor: g.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _TopNav(
          title: LocaleKeys.todoDetailsPage_title.tr(),
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Observer(
          builder: (_) {
            if (state.isLoading) {
              return const _LoadingBody();
            }
            if (state.error != null || state.todo == null) {
              return _ErrorBody(message: LocaleKeys.todoDetailsPage_error.tr());
            }
            final todo = state.todo!;
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    kSpacing20px,
                    kSpacing24px,
                    kSpacing20px,
                    kSpacing96px + kSpacing24px,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(
                        child: _HeroCard(
                          title: todo.title,
                          completed: todo.completed,
                        ),
                      ),
                      const Gap(kSpacing20px),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: _MetaCard(
                          id: todo.id,
                          completed: todo.completed,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: kSpacing20px,
                  right: kSpacing20px,
                  bottom: kSpacing20px,
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: _ToggleButton(
                      completed: todo.completed,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        state.onToggleCompleted();
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(context.geist.ink),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String message;

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
              Icon(Icons.error_outline_rounded, size: 40, color: g.placeholder),
              const Gap(kSpacing16px),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GeistTextStyles.sectionTitle.copyWith(color: g.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

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
              PressScale(
                onPressed: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(GeistRadius.standard),
                    boxShadow: [g.shadowRingSoft],
                  ),
                  child: Icon(Icons.arrow_back_rounded, size: 16, color: g.ink),
                ),
              ),
              const Gap(kSpacing12px),
              Text(
                title,
                style: GeistTextStyles.navTitle.copyWith(color: g.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.completed});

  final String title;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return AnimatedContainer(
      duration: GeistDuration.base,
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(kSpacing24px),
      decoration: BoxDecoration(
        color: g.surface,
        borderRadius: BorderRadius.circular(GeistRadius.image),
        boxShadow: g.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBadge(completed: completed),
          const Gap(kSpacing16px),
          Text(
            'TASK',
            style: GeistTextStyles.monoLabel.copyWith(color: g.subtle),
          ),
          const Gap(kSpacing8px),
          AnimatedDefaultTextStyle(
            duration: GeistDuration.base,
            style: GeistTextStyles.heading.copyWith(
              color: g.ink,
              decoration: completed
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: g.placeholder,
              decorationThickness: 2,
            ),
            child: Text(title),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final bg = completed ? g.badgeSuccessBg : g.badgeInfoBg;
    final fg = completed ? g.badgeSuccessFg : g.badgeInfoFg;
    final dot = completed ? g.badgeSuccessFg : g.focusBlue;

    return AnimatedSwitcher(
      duration: GeistDuration.base,
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: a, child: c),
      ),
      child: Container(
        key: ValueKey(completed),
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacing10px,
          vertical: kSpacing4px,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(GeistRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulsingDot(color: dot),
            const Gap(kSpacing8px),
            Text(
              completed ? 'Completed' : 'Pending',
              style: GeistTextStyles.badge.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (geistReducedMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15 + 0.25 * t),
                blurRadius: 4 + 4 * t,
                spreadRadius: 1 * t,
              ),
            ],
          ),
          child: const SizedBox(width: 6, height: 6),
        );
      },
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.id, required this.completed});

  final String id;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: g.surface,
        borderRadius: BorderRadius.circular(GeistRadius.comfortable),
        boxShadow: g.ringShadow,
      ),
      child: Column(
        children: [
          _MetaRow(
            label: LocaleKeys.todoDetailsPage_metaId.tr(),
            value: id,
            mono: true,
          ),
          const _MetaDivider(),
          _MetaRow(
            label: LocaleKeys.todoDetailsPage_metaStatus.tr(),
            value: completed
                ? LocaleKeys.todoDetailsPage_statusCompleted.tr()
                : LocaleKeys.todoDetailsPage_statusPending.tr(),
            mono: false,
          ),
        ],
      ),
    );
  }
}

class _MetaDivider extends StatelessWidget {
  const _MetaDivider();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.geist.ringSoft,
      child: const SizedBox(height: 1, width: double.infinity),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.mono,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacing16px,
        vertical: kSpacing14px,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GeistTextStyles.monoLabel.copyWith(color: g.subtle),
          ),
          const Spacer(),
          if (mono)
            Text(
              value,
              style: GeistTextStyles.chip.copyWith(
                color: g.ink,
                fontFamily: 'monospace',
                letterSpacing: 0,
              ),
            )
          else
            AnimatedSwitcher(
              duration: GeistDuration.base,
              child: Text(
                value,
                key: ValueKey(value),
                style: GeistTextStyles.chip.copyWith(color: g.ink),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.completed, required this.onPressed});

  final bool completed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final label = completed ? 'Mark as pending' : 'Mark as completed';
    final icon = completed
        ? Icons.radio_button_unchecked_rounded
        : Icons.check_circle_rounded;

    return PressScale(
      haptic: false,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: GeistDuration.base,
        curve: Curves.easeOut,
        height: 48,
        decoration: BoxDecoration(
          color: completed ? g.surface : g.ink,
          borderRadius: BorderRadius.circular(GeistRadius.comfortable),
          boxShadow: completed ? [g.shadowBorder] : [g.shadowFab],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: GeistDuration.base,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(a),
              child: c,
            ),
          ),
          child: Row(
            key: ValueKey(completed),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: completed ? g.ink : g.surface, size: 16),
              const Gap(kSpacing8px),
              Text(
                label,
                style: GeistTextStyles.button.copyWith(
                  color: completed ? g.ink : g.surface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
