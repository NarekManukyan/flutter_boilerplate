import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Motion primitives paired with the [GeistTheme] design system.
/// Tokens live in `design_system` — never hardcode colors/styles here.

bool geistReducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Scale-down press feedback (0.97) — immediate, interruptible.
class PressScale extends HookWidget {
  const PressScale({
    super.key,
    required this.child,
    required this.onPressed,
    this.scale = 0.97,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double scale;
  final bool haptic;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduced = geistReducedMotion(context);
    final targetScale = !reduced && pressed.value ? scale : 1.0;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        if (onPressed != null) {
          pressed.value = true;
        }
      },
      onPointerUp: (_) => pressed.value = false,
      onPointerCancel: (_) => pressed.value = false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed == null
            ? null
            : () {
                if (haptic) {
                  HapticFeedback.selectionClick();
                }
                onPressed!.call();
              },
        child: AnimatedScale(
          scale: targetScale,
          duration: GeistDuration.fast,
          curve: Curves.easeOut,
          child: child,
        ),
      ),
    );
  }
}

/// Entry animation: fade + short upward slide, optionally staggered.
class FadeSlideIn extends HookWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 280),
    this.offset = 0.06,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final reduced = geistReducedMotion(context);
    final controller = useAnimationController(duration: duration);

    useEffect(() {
      if (reduced) {
        controller.value = 1;
        return null;
      }
      final f = Future<void>.delayed(delay, controller.forward);
      return f.ignore;
    }, const []);

    final fade = useMemoized(
      () => CurvedAnimation(parent: controller, curve: Curves.easeOut),
      [controller],
    );
    final slide = useMemoized(
      () => Tween<Offset>(begin: Offset(0, offset), end: Offset.zero).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      ),
      [controller, offset],
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

/// Tween-animate an int with tabular figures to prevent jitter.
/// Uses previous value as tween start so parent rebuilds don't restart from 0.
class AnimatedCount extends HookWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 420),
  });

  final int value;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduced = geistReducedMotion(context);
    final effectiveStyle = useMemoized(
      () => style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      [style],
    );
    final prev = usePrevious(value) ?? value;
    if (reduced) {
      return Text('$value', style: effectiveStyle);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: prev.toDouble(), end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('${v.round()}', style: effectiveStyle),
    );
  }
}
