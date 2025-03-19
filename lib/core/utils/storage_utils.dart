import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class _Preferences {
  _Preferences._();

  static const authToken = 'authToken';
  static const skippedAppVersion = 'skippedAppVersion';
}

class StorageUtils {
  StorageUtils._();
  static Future<SharedPreferences> get sharedInstance =>
      SharedPreferences.getInstance();

  static Future<String?> getAccessToken() async {
    return _getString(_Preferences.authToken);
  }

  static Future<void> setAccessToken(String authToken) async {
    await _setString(_Preferences.authToken, authToken);
  }

  static Future<void> removeAccessToken() async {
    return _remove(_Preferences.authToken);
  }

  static Future<bool> isLoggedIn() async {
    final accessToken = await StorageUtils.getAccessToken();
    return accessToken != null;
  }

  /// New version
  static Future<void> setSkippedAppVersion(String storeVersion) async {
    await _setString(_Preferences.skippedAppVersion, storeVersion);
  }

  static Future<String?> getSkippedAppVersion() {
    return _getString(_Preferences.skippedAppVersion);
  }

  /// Private helper functions
  static Future<T?> _read<T>(String key) async {
    final prefs = await sharedInstance;
    final value = prefs.getString(key);
    return value == null ? null : json.decode(value) as T;
  }

  static Future<void> _save(String key, Object value) async {
    final prefs = await sharedInstance;
    await prefs.setString(key, json.encode(value));
  }

  static Future<void> _remove(String key) async {
    final prefs = await sharedInstance;
    await prefs.remove(key);
  }

  static Future<void> clear() async {
    final prefs = await sharedInstance;
    await prefs.clear();
  }

  // ignore: avoid_positional_boolean_parameters
  static Future<void> _setBool(String key, bool value) async {
    final prefs = await sharedInstance;

    await prefs.setBool(key, value);
  }

  static Future<bool> _getBool(String key) async {
    final prefs = await sharedInstance;
    return prefs.getBool(key) ?? false;
  }

  static Future<void> _setString(String key, String value) async {
    final prefs = await sharedInstance;
    await prefs.setString(key, value);
  }

  static Future<String?> _getString(String key) async {
    final prefs = await sharedInstance;
    return prefs.getString(key);
  }

  static Future<void> _setInt(String key, int value) async {
    final prefs = await sharedInstance;
    await prefs.setInt(key, value);
  }

  static Future<int?> _getInt(String key) async {
    final prefs = await sharedInstance;
    return prefs.getInt(key);
  }
}
