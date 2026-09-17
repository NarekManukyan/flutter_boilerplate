import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../gen/locale_keys.g.dart';
import '../../../injectable.dart';
import '../mobx/connection_wrapper_state.dart';

class ConnectionWrapperPage extends StatelessWidget {
  const ConnectionWrapperPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Provider<ConnectionWrapperState>(
      create: (_) => getIt<ConnectionWrapperState>(),
      dispose: (_, state) => state.dispose(),
      child: _ConnectionWrapperContent(child: child),
    );
  }
}

class _ConnectionWrapperContent extends StatelessWidget {
  const _ConnectionWrapperContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = context.read<ConnectionWrapperState>();
    // The offline page covers the app instead of replacing it. Swapping the
    // router child out unmounted every route on a dropped connection, so the
    // user lost their place and every page state re-initialised on reconnect.
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Observer(
            // An empty SizedBox takes no hits, so taps reach the app below.
            builder: (_) => state.hasConnection
                ? const SizedBox.shrink()
                : const _NoConnectionWidget(),
          ),
        ),
      ],
    );
  }
}

class _NoConnectionWidget extends StatelessWidget {
  const _NoConnectionWidget();

  @override
  Widget build(BuildContext context) {
    final state = context.read<ConnectionWrapperState>();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48),
            const Gap(kSpacing16px),
            Text(
              LocaleKeys.connectionPage_title.tr(),
              style: context.labelXLMedium,
            ),
            const Gap(kSpacing8px),
            Text(
              LocaleKeys.connectionPage_subtitle.tr(),
              style: context.labelXLMedium,
            ),
            const Gap(kSpacing24px),
            ElevatedButton(
              onPressed: state.onSettingsTap,
              child: Text(LocaleKeys.connectionPage_goToSettings.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
