import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../store/loading_state/loading_state.dart';
import '../../store/login_state/login_state.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({
    Key? key,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final loginState = LoginState();
  final loadingState = LoadingState();
  final phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
