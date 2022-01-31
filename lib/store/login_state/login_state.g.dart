// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$LoginState on _LoginState, Store {
  final _$emailAtom = Atom(name: '_LoginState.email');

  @override
  String get email {
    _$emailAtom.reportRead();
    return super.email;
  }

  @override
  set email(String value) {
    _$emailAtom.reportWrite(value, super.email, () {
      super.email = value;
    });
  }

  final _$passwordAtom = Atom(name: '_LoginState.password');

  @override
  String get password {
    _$passwordAtom.reportRead();
    return super.password;
  }

  @override
  set password(String value) {
    _$passwordAtom.reportWrite(value, super.password, () {
      super.password = value;
    });
  }

  final _$emailErrorAtom = Atom(name: '_LoginState.emailError');

  @override
  String? get emailError {
    _$emailErrorAtom.reportRead();
    return super.emailError;
  }

  @override
  set emailError(String? value) {
    _$emailErrorAtom.reportWrite(value, super.emailError, () {
      super.emailError = value;
    });
  }

  final _$passwordErrorAtom = Atom(name: '_LoginState.passwordError');

  @override
  String? get passwordError {
    _$passwordErrorAtom.reportRead();
    return super.passwordError;
  }

  @override
  set passwordError(String? value) {
    _$passwordErrorAtom.reportWrite(value, super.passwordError, () {
      super.passwordError = value;
    });
  }

  final _$_LoginStateActionController = ActionController(name: '_LoginState');

  @override
  void validateEmail(dynamic _) {
    final _$actionInfo = _$_LoginStateActionController.startAction(
        name: '_LoginState.validateEmail');
    try {
      return super.validateEmail(_);
    } finally {
      _$_LoginStateActionController.endAction(_$actionInfo);
    }
  }

  @override
  void validatePassword(dynamic _) {
    final _$actionInfo = _$_LoginStateActionController.startAction(
        name: '_LoginState.validatePassword');
    try {
      return super.validatePassword(_);
    } finally {
      _$_LoginStateActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
email: ${email},
password: ${password},
emailError: ${emailError},
passwordError: ${passwordError}
    ''';
  }
}
