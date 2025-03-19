import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_update_type.dart';
import '../../../../gen/locale_keys.g.dart';
import '../../../../injectable.dart';
import '../mobx/app_update_modal_state.dart';

class AppUpdateModal extends StatelessWidget {
  const AppUpdateModal({
    super.key,
    required this.updateType,
    required this.appStoreLink,
  });

  final AppUpdateType updateType;
  final String appStoreLink;

  @override
  Widget build(BuildContext context) {
    return Provider<AppUpdateModalState>(
      create: (_) => getIt<AppUpdateModalState>()
        ..init(
          updateType: updateType,
          appStoreLink: appStoreLink,
        ),
      child: const _AppUpdateModalContent(),
    );
  }
}

class _AppUpdateModalContent extends StatelessWidget {
  const _AppUpdateModalContent();

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppUpdateModalState>();

    return PopScope(
      canPop: state.updateType == AppUpdateType.MINOR,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ModalTopLine(),
          const Gap(kSpacing16px),
          const Icon(
            Icons.update,
            size: 102,
          ),
          const Gap(24),
          Text(
            state.updateType.titleTranslationKey.tr(),
            style: context.subheaderS1Bold.setColor(context.textNeutralDarker),
            textAlign: TextAlign.center,
          ),
          const Gap(12),
          Text(
            state.updateType.subtitleTranslationKey.tr(),
            style:
                context.paragraphLRegular.setColor(context.textNeutralDarker),
            textAlign: TextAlign.center,
          ),
          const Gap(32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: state.onOpenStoreLink,
                  child: Text(LocaleKeys.keywords_updateNow.tr()),
                ),
              ),
            ],
          ),
          const Gap(16),
          if (state.updateType == AppUpdateType.MINOR) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.onNotNow,
                    child: Text(LocaleKeys.keywords_updateLater.tr()),
                  ),
                ),
              ],
            ),
            const Gap(16),
          ],
        ],
      ).paddingOnly(
        left: 24,
        right: 24,
        bottom: context.bottomSecurePadding,
      ),
    );
  }
}
