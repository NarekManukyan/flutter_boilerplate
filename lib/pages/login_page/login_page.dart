import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'login_state.dart';

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<LoginState>(
      create: (_) => LoginState(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
        ),
        body: const _LoginPageContent(),
      ),
    );
  }
}

class _LoginPageContent extends StatelessWidget {
  const _LoginPageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _EmailField(),
          Gap(16),
          _PasswordField(),
          Gap(16),
          _LoginButton(),
        ],
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField();

  @override
  Widget build(BuildContext context) {
    final state = context.read<LoginState>();

    return Observer(
      builder: (context) {
        return TextField(
          onChanged: state.setEmail,
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: state.emailError,
          ),
        );
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField();

  @override
  Widget build(BuildContext context) {
    final state = context.read<LoginState>();

    return Observer(
      builder: (context) {
        return TextField(
          onChanged: state.setPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: state.passwordError,
          ),
        );
      },
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton();

  @override
  Widget build(BuildContext context) {
    final state = context.read<LoginState>();
    return ElevatedButton(
      onPressed: state.isLoading ? null : state.onLogin,
      child: state.isLoading
          ? const CupertinoActivityIndicator()
          : const Text('Login'),
    );
  }
}
