import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = Locale('en');
  Locale get locale => _locale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  void _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String languageCode = prefs.getString('languageCode') ?? 'en';
    setLocale(Locale(languageCode));
  }

  void setLocale(Locale locale) {
    if (!['en', 'ar'].contains(locale.languageCode)) return;

    _locale = locale;
    _saveLanguage(locale.languageCode);
    notifyListeners();
  }

  void _saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
  }
}
