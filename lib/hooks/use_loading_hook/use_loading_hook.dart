import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../store/loading_state/loading_state.dart';

/// Creates [LoadingState] that will be disposed automatically.
LoadingState useLoadingHook({
  bool initialValue = false,
}) {
  return use(
    _LoadingStateHook(
      initialValue: initialValue,
    ),
  );
}

class _LoadingStateHook extends Hook<LoadingState> {
  const _LoadingStateHook({
    this.initialValue = false,
  }) : super();

  final bool initialValue;

  @override
  HookState<LoadingState, Hook<LoadingState>> createState() =>
      _LoadingStateHookState();
}

class _LoadingStateHookState
    extends HookState<LoadingState, _LoadingStateHook> {
  final loadingState = LoadingState();

  @override
  LoadingState build(BuildContext context) {
    if (hook.initialValue) {
      return loadingState..startLoading();
    }
    return loadingState;
  }

  @override
  void dispose() => loadingState.stopLoading();

  @override
  String get debugLabel => 'useLoadingState';
}
