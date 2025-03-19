// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';

part 'notifications_store.g.dart';

@singleton
class NotificationsStore = _NotificationsStoreBase with _$NotificationsStore;

abstract class _NotificationsStoreBase with Store {
  // final _messaging = FirebaseMessaging.instance;

  @readonly
  bool _isPermissionGranted = false;

  @action
  void setIsPermissionGranted({bool value = false}) {
    _isPermissionGranted = value;
  }

  Future<void> init() async {
    await checkPermission();
    await _getToken();
    await _setupInteractedMessage();
  }

  Future<bool> checkPermission() async {
    // try {
    // final res = await _messaging.requestPermission();
    //   final isPermissionGranted = [
    //     AuthorizationStatus.authorized,
    //     AuthorizationStatus.provisional,
    //   ].contains(res.authorizationStatus);
    //
    //   setIsPermissionGranted(value: isPermissionGranted);
    //
    //   return isPermissionGranted;
    // } catch (_) {
    //   return false;
    // }
    return true;
  }

  Future<void> _getToken() async {
    // if (!_isPermissionGranted) {
    //   return;
    // }
    //
    // final apnsToken = await _messaging.getAPNSToken();
    // if (apnsToken == null && Platform.isIOS) {
    //   return;
    // }
    //
    // try {
    //   final userToken = await _messaging.getToken();
    //   if (userToken == null) {
    //     return;
    //   }
    //
    //   /// subscribe
    // } catch (e) {
    //   log(
    //     'Failed to update user token: $e',
    //     stackTrace: StackTrace.current,
    //     error: e,
    //   );
    // }
  }

  Future<void> _setupInteractedMessage() async {
    // final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    //
    // if (initialMessage != null) {
    //   _onOpenedApp(initialMessage);
    // }
    // FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedApp);
    // FirebaseMessaging.onMessage.listen(_onMessage);
  }

  // void _onOpenedApp(RemoteMessage message) {
    /// to be implemented
  // }

  void _onMessage(notification) {
    /// to be implemented
  }

  void showToast(notification) {
    /// to be implemented
  }
}
