// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loading_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$LoadingState on _LoadingState, Store {
  late final _$isLoadingAtom =
      Atom(name: '_LoadingState.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$_LoadingStateActionController =
      ActionController(name: '_LoadingState', context: context);

  @override
  void startLoading() {
    final _$actionInfo = _$_LoadingStateActionController.startAction(
        name: '_LoadingState.startLoading');
    try {
      return super.startLoading();
    } finally {
      _$_LoadingStateActionController.endAction(_$actionInfo);
    }
  }

  @override
  void stopLoading() {
    final _$actionInfo = _$_LoadingStateActionController.startAction(
        name: '_LoadingState.stopLoading');
    try {
      return super.stopLoading();
    } finally {
      _$_LoadingStateActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading}
    ''';
  }
}
