import 'package:shared_preferences/shared_preferences.dart';

class AlarmAudioService {
  static const _key = 'custom_alarm_audio';

  static Future<void> saveAudioPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);
  }

  static Future<String?> getAudioPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clearAudioPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
