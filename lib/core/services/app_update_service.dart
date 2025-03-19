import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:new_version_plus/new_version_plus.dart';

import '../../shared/modals/app_update_modal/view/app_update_modal.dart';
import '../constants/app_update_type.dart';
import '../navigation/app_navigator.dart';
import '../utils/storage_utils.dart';
import 'flavor_service.dart';

@injectable
class AppUpdateService {
  final FlavorService _flavorService;
  final AppNavigator _appNavigator;

  AppUpdateService(
    this._flavorService,
    this._appNavigator,
  );

  final country =
      WidgetsBinding.instance.platformDispatcher.locale.countryCode ?? 'us';

  late final _newVersionPlus = NewVersionPlus(
    androidId: _flavorService.config.bundleID,
    iOSId: _flavorService.config.bundleID,
    androidPlayStoreCountry: country,
    iOSAppStoreCountry: country,
  );

  Future<void> checkAppVersion() async {
    try {
      final res = await _newVersionPlus.getVersionStatus();

      if (res == null) {
        return;
      }

      final localeVersion = res.localVersion;
      final storeVersion = res.storeVersion;

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
        builder: (_) => AppUpdateModal(
          updateType: updateType,
          appStoreLink: 'res.appStoreLink',
        ),
        enableDrag: updateType == AppUpdateType.MINOR,
      );

      await StorageUtils.setSkippedAppVersion(res.storeVersion);
    } on Exception catch (error, stackTrace) {
      log('getAppVersionException: $error', stackTrace: stackTrace);
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
