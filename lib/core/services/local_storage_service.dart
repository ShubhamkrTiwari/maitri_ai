import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class LocalStorageService {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.chatCacheBox);
    await Hive.openBox(AppConstants.userPrefsBox);
  }

  static Box get chatCache => Hive.box(AppConstants.chatCacheBox);
  static Box get userPrefs => Hive.box(AppConstants.userPrefsBox);

  static Future<void> saveString(String key, String value) async {
    await userPrefs.put(key, value);
  }

  static String? getString(String key) {
    return userPrefs.get(key) as String?;
  }

  static Future<void> saveBool(String key, bool value) async {
    await userPrefs.put(key, value);
  }

  static bool getBool(String key, {bool defaultValue = false}) {
    return (userPrefs.get(key) as bool?) ?? defaultValue;
  }

  static Future<void> clearAll() async {
    await chatCache.clear();
    await userPrefs.clear();
  }
}
