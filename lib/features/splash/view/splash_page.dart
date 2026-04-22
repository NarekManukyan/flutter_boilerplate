import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../gen/locale_keys.g.dart';

@RoutePage()
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SplashPageContent();
  }
}

class _SplashPageContent extends StatelessWidget {
  const _SplashPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundSurface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingWidget(isLoading: true),
            const SizedBox(height: kSpacing16px),
            Text(
              LocaleKeys.splashPage_loading.tr(),
              style: context.labelLMedium.setColor(context.textNeutral),
            ),
          ],
        ),
      ),
    );
  }
}
