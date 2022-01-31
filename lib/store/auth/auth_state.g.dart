// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$AuthState on _AuthState, Store {
  Computed<UserModel?>? _$currentUserComputed;

  @override
  UserModel? get currentUser =>
      (_$currentUserComputed ??= Computed<UserModel?>(() => super.currentUser,
              name: '_AuthState.currentUser'))
          .value;

  final _$_currentUserAtom = Atom(name: '_AuthState._currentUser');

  @override
  UserModel? get _currentUser {
    _$_currentUserAtom.reportRead();
    return super._currentUser;
  }

  @override
  set _currentUser(UserModel? value) {
    _$_currentUserAtom.reportWrite(value, super._currentUser, () {
      super._currentUser = value;
    });
  }

  final _$accessTokenAtom = Atom(name: '_AuthState.accessToken');

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

  final _$getCurrentUserAsyncAction = AsyncAction('_AuthState.getCurrentUser');

  @override
  Future<void> getCurrentUser() {
    return _$getCurrentUserAsyncAction.run(() => super.getCurrentUser());
  }

  final _$registerPushNotificationAsyncAction =
      AsyncAction('_AuthState.registerPushNotification');

  @override
  Future<void> registerPushNotification(String token) {
    return _$registerPushNotificationAsyncAction
        .run(() => super.registerPushNotification(token));
  }

  final _$logoutAsyncAction = AsyncAction('_AuthState.logout');

  @override
  Future<void> logout() {
    return _$logoutAsyncAction.run(() => super.logout());
  }

  @override
  String toString() {
    return '''
accessToken: ${accessToken},
currentUser: ${currentUser}
    ''';
  }
}
