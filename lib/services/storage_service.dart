import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keyBaseCurrency = "howmuch_base_currency";
  static const String keyTargetCurrency = "howmuch_target_currency";

  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
