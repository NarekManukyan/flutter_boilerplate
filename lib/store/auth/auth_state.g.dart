// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AuthState on _AuthState, Store {
  Computed<UserDto?>? _$currentUserComputed;

  @override
  UserDto? get currentUser =>
      (_$currentUserComputed ??= Computed<UserDto?>(() => super.currentUser,
              name: '_AuthState.currentUser'))
          .value;

  late final _$_currentUserAtom =
      Atom(name: '_AuthState._currentUser', context: context);

  @override
  UserDto? get _currentUser {
    _$_currentUserAtom.reportRead();
    return super._currentUser;
  }

  @override
  set _currentUser(UserDto? value) {
    _$_currentUserAtom.reportWrite(value, super._currentUser, () {
      super._currentUser = value;
    });
  }

  late final _$accessTokenAtom =
      Atom(name: '_AuthState.accessToken', context: context);

  @override
  String? get accessToken {
    _$accessTokenAtom.reportRead();
    return super.accessToken;
  }

  @override
  set accessToken(String? value) {
    _$accessTokenAtom.reportWrite(value, super.accessToken, () {
      super.accessToken = value;
    });
  }

  late final _$getCurrentUserAsyncAction =
      AsyncAction('_AuthState.getCurrentUser', context: context);

  @override
  Future<void> getCurrentUser() {
    return _$getCurrentUserAsyncAction.run(() => super.getCurrentUser());
  }

  @override
  String toString() {
    return '''
accessToken: ${accessToken},
currentUser: ${currentUser}
    ''';
  }
}
