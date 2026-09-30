import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // حفظ تقدم الأذكار
  static Future<void> saveAdhkarProgress(
    String category,
    int index,
    int remaining,
  ) async {
    await _prefs.setInt('adhkar_${category}_$index', remaining);
  }

  static int getAdhkarProgress(String category, int index) {
    return _prefs.getInt('adhkar_${category}_$index') ?? 0;
  }

  // حفظ آخر صفحة قرآن
  static Future<void> setLastQuranPage(int page) async {
    await _prefs.setInt('last_quran_page', page);
  }

  static int getLastQuranPage() {
    return _prefs.getInt('last_quran_page') ?? 1;
  }

  // العلامات المرجعية
  static Future<void> toggleBookmark(int page) async {
    final list = getBookmarks();
    if (list.contains(page)) {
      list.remove(page);
    } else {
      list.add(page);
    }
    list.sort();
    await _prefs.setStringList(
      'bookmarks',
      list.map((e) => e.toString()).toList(),
    );
  }

  static List<int> getBookmarks() {
    final list = _prefs.getStringList('bookmarks') ?? [];
    return list.map((e) => int.tryParse(e) ?? 1).toList();
  }

  // الإعدادات
  static Future<void> setDarkMode(bool value) async {
    await _prefs.setBool('dark_mode', value);
  }

  static bool getDarkMode() {
    return _prefs.getBool('dark_mode') ?? false;
  }

  // إحصائيات يومية
  static Future<void> saveDaily(String key, int value) async {
    await _prefs.setInt('daily_$key', value);
  }

  static int getDaily(String key) {
    return _prefs.getInt('daily_$key') ?? 0;
  }

  static Future<void> clearDaily() async {
    final keys = _prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith('daily_')) {
        await _prefs.remove(key);
      }
    }
  }
}
