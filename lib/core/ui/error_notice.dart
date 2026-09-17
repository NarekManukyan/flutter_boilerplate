import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../gen/locale_keys.g.dart';
import 'error_notice_keys.dart';
import 'test_id.dart';

/// The bottom notice `IssueTrackingService.trackIssue` shows for an error that
/// nothing else put on screen. Callers with their own error UI never see it:
/// they report through `trackHandledError` instead.
class ErrorNotice extends StatelessWidget {
  const ErrorNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    return TestId(
      ErrorNoticeKeys.notice,
      child: SafeArea(
        top: false,
        child: Semantics(
          liveRegion: true,
          label: LocaleKeys.errors_noticeA11y.tr(),
          child: Container(
            margin: const EdgeInsets.all(kSpacing16px),
            padding: const EdgeInsets.symmetric(
              horizontal: kSpacing16px,
              vertical: kSpacing12px,
            ),
            decoration: BoxDecoration(
              color: g.ink,
              borderRadius: BorderRadius.circular(GeistRadius.comfortable),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: g.danger),
                const Gap(kSpacing12px),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GeistTextStyles.bodyM.copyWith(color: g.surface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
