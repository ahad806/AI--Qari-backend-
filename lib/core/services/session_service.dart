import 'package:shared_preferences/shared_preferences.dart';

/// Manages the "remember me" session flag in SharedPreferences.
/// On mobile, Firebase always persists the auth token on disk.
/// This service lets us override that by signing the user out on next
/// app launch when they chose NOT to be remembered.
class SessionService {
  static const _keyRememberMe = 'remember_me';

  static late SharedPreferences _prefs;

  /// Must be called once at app startup (before runApp).
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Persist the user's remember-me choice.
  static Future<void> setRememberMe(bool value) async {
    await _prefs.setBool(_keyRememberMe, value);
  }

  /// Returns true if the user previously chose to be remembered, false otherwise.
  static bool getRememberMe() {
    return _prefs.getBool(_keyRememberMe) ?? false;
  }

  /// Clears the session flag (called on logout).
  static Future<void> clear() async {
    await _prefs.remove(_keyRememberMe);
  }
}
