import 'dart:async';

import 'package:mobx/mobx.dart';

class Debounce {
  final int delay;
  Timer? _timer;

  Debounce(this.delay);

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: delay), action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

ReactionDisposer debounceReaction<T>(
  T Function(Reaction) fn,
  void Function(T) effect, {
  String? name,
  required int delay,
  bool? fireImmediately,
  EqualityComparer<T>? equals,
  ReactiveContext? context,
  void Function(Object, Reaction)? onError,
}) {
  final debounceHandler = Debounce(delay);
  final reactionDisposer = reaction<T>(
    fn,
    (x) {
      debounceHandler(() {
        effect(x);
      });
    },
    name: name,
    fireImmediately: fireImmediately,
    equals: equals,
    context: context,
    onError: onError,
  );

  return DebounceReactionDisposer(
    reactionDisposer.reaction,
    debounceHandler,
  );
}

class DebounceReactionDisposer extends ReactionDisposer {
  final Debounce _debounce;

  DebounceReactionDisposer(super.reaction, this._debounce);

  @override
  void call() {
    _debounce.dispose();
    super.call();
  }
}
