import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keyFullSettings = 'howmuch_full_settings';

  static const String keyHasSeenTutorial = 'howmuch_has_seen_tutorial';

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
  Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyHasSeenTutorial) ?? false;
  }

  // User already saw tutorial SAVE IT
  Future<void> setTutorialAsSeen() async {
    //final prefs = await SharedPreferences.getInstance();
    //await prefs.setBool(keyHasSeenTutorial, true);
  }
}
