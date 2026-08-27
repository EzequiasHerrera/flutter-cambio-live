import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keyFullSettings = 'howmuch_full_settings';

  // Tutorial Keys
  static const String keyHasSeenHomeTutorial = 'howmuch_has_seen_home_tutorial';
  static const String keyHasSeenConverterTutorial = 'howmuch_has_seen_converter_tutorial';
  static const String keyHasSeenCameraTutorial = 'howmuch_has_seen_camera_tutorial';
  static const String keyHasSeenCartTutorial = 'howmuch_has_seen_cart_tutorial';

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyFullSettings, jsonEncode(settings));
  }

  Future<Map<String, dynamic>?> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(keyFullSettings);
    if (data == null) return null;
    return jsonDecode(data);
  }

  // User has seen tutorial already?
  Future<bool> hasSeenTutorial(String tutorialKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(tutorialKey) ?? false;
  }

  // User already saw tutorial SAVE IT
  Future<void> setTutorialAsSeen(String tutorialKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tutorialKey, true);
  }

  // Reset all tutorials
  Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyHasSeenHomeTutorial, false);
    await prefs.setBool(keyHasSeenConverterTutorial, false);
    await prefs.setBool(keyHasSeenCameraTutorial, false);
    await prefs.setBool(keyHasSeenCartTutorial, false);
  }
}
