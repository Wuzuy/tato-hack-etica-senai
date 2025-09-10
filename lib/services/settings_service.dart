import 'package:shared_preferences/shared_preferences.dart';

const String fontScaleKey = 'fontScale';
const String colorSchemeKey = 'colorScheme';

class SettingsService {
  // Load Methods

  Future<double> loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(fontScaleKey) ?? 1.0;
  }

  Future<String> loadColorScheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(colorSchemeKey) ?? 'Padrão';
  }

  // Save Methods

  Future<void> saveFontScale(double fontScale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(fontScaleKey, fontScale);
  }

  Future<void> saveColorScheme(String colorScheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(colorSchemeKey, colorScheme);
  }
}
