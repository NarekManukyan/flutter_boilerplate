import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_update_type.dart';
import '../../../../core/navigation/app_navigator.dart';

part 'app_update_modal_state.g.dart';

@injectable
class AppUpdateModalState = _AppUpdateModalStateBase with _$AppUpdateModalState;

abstract class _AppUpdateModalStateBase with Store {
  final AppNavigator _appNavigator;

  _AppUpdateModalStateBase(this._appNavigator);

  @readonly
  AppUpdateType _updateType = AppUpdateType.OPTIONAL;

  @readonly
  String _appStoreLink = '';

  Future<void> init({
    required AppUpdateType updateType,
    required String appStoreLink,
  }) async {
    _updateType = updateType;
    _appStoreLink = appStoreLink;
  }

  void onOpenStoreLink() {
    launchUrl(
      Uri.parse(_appStoreLink),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> onNotNow() => _appNavigator.pop();
}
