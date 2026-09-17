import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:upgrader/upgrader.dart';

import '../../features/app/modals/app_update_modal/view/app_update_modal.dart';
import '../constants/app_update_type.dart';
import '../navigation/app_navigator.dart';
import '../utils/storage_utils.dart';
import 'issue_tracking_service.dart';

@injectable
class AppUpdateService {
  final AppNavigator _appNavigator;
  final IssueTrackingService _issueTrackingService;

  AppUpdateService(this._appNavigator, this._issueTrackingService);

  final country =
      WidgetsBinding.instance.platformDispatcher.locale.countryCode ?? 'us';

  Future<void> checkAppVersion() async {
    // Only the store lookup is used, not upgrader's own alert, so the instance
    // is created per check and disposed: initialize() registers an app
    // lifecycle observer that would otherwise outlive the check.
    final upgrader = Upgrader(countryCode: country, checkOnResume: false);
    try {
      await upgrader.initialize();
      final info = upgrader.state.versionInfo;
      final localeVersion =
          info?.installedVersion?.toString() ??
          upgrader.state.packageInfo?.version;
      final storeVersion = info?.appStoreVersion?.toString();
      final appStoreLink = info?.appStoreListingURL;

      if (localeVersion == null ||
          storeVersion == null ||
          appStoreLink == null) {
        return;
      }

      final skippedUpdateVersion = await StorageUtils.getSkippedAppVersion();
      final updateType = _getUpdateType(
        localeVersion: localeVersion,
        storeVersion: storeVersion,
      );

      if (skippedUpdateVersion == storeVersion ||
          updateType == AppUpdateType.OPTIONAL) {
        return;
      }

      await _appNavigator.showModal(
        builder: (_) =>
            AppUpdateModal(updateType: updateType, appStoreLink: appStoreLink),
        enableDrag: updateType == AppUpdateType.MINOR,
      );

      await StorageUtils.setSkippedAppVersion(storeVersion);
    } on Exception catch (error, stackTrace) {
      // A store lookup that fails leaves the user on their current version;
      // they are not waiting on it, so it is reported without a notice.
      _issueTrackingService.trackSilentError(
        error,
        stackTrace: stackTrace,
        context: 'check_app_version',
      );
    } finally {
      upgrader.dispose();
    }
  }

  AppUpdateType _getUpdateType({
    required String localeVersion,
    required String storeVersion,
  }) {
    final parsedLocaleVersion = localeVersion.split('.').map(int.tryParse);
    final parsedStoreVersion = storeVersion.split('.').map(int.tryParse);

    // check if app version is invalid
    if (parsedLocaleVersion.contains(null) ||
        parsedStoreVersion.contains(null)) {
      return AppUpdateType.OPTIONAL;
    }

    if (parsedLocaleVersion.length > 2 && parsedStoreVersion.length > 2) {
      if (parsedStoreVersion.first! > parsedLocaleVersion.first!) {
        return AppUpdateType.MAJOR;
      }

      if (parsedStoreVersion.elementAt(0)! ==
              parsedLocaleVersion.elementAt(0)! &&
          parsedStoreVersion.elementAt(1)! >
              parsedLocaleVersion.elementAt(1)!) {
        return AppUpdateType.MINOR;
      }
    }

    return AppUpdateType.OPTIONAL;
  }
}
