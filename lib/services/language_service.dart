import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app language and localization preferences.
/// 
/// Implements a singleton pattern to provide global access to language
/// settings. Persists user's language choice using SharedPreferences
/// and notifies listeners when the locale changes.
class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  Locale _currentLocale = const Locale('en', 'US');
  
  /// Gets the current locale setting.
  /// 
  /// Returns the currently selected locale for the app.
  /// Defaults to English (en_US) if no preference is set.
  Locale get currentLocale => _currentLocale;

  /// Initializes the language service by loading saved preferences.
  /// 
  /// Retrieves the user's previously selected language from SharedPreferences
  /// and updates the current locale. Should be called during app startup
  /// before building the UI.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    final countryCode = prefs.getString('country_code') ?? 'US';
    _currentLocale = Locale(languageCode, countryCode);
    notifyListeners();
  }

  /// Sets a new locale for the app.
  /// 
  /// Updates the current locale, saves the preference to SharedPreferences,
  /// and notifies all listeners to rebuild with the new language.
  /// 
  /// [locale] The new locale to set (e.g., Locale('en', 'US'))
  Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    await prefs.setString('country_code', locale.countryCode ?? 'US');
    notifyListeners();
  }

  /// Gets the display name for a language code in English.
  /// 
  /// [languageCode] The ISO language code (e.g., 'en', 'ur')
  /// 
  /// Returns the English name of the language, defaulting to 'English'
  /// for unknown codes
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ur':
        return 'اردو';
      default:
        return 'English';
    }
  }

  /// Gets the native display name for a language code.
  /// 
  /// Returns the language name in its native script (e.g., 'اردو' for Urdu).
  /// 
  /// [languageCode] The ISO language code (e.g., 'en', 'ur')
  /// 
  /// Returns the native name of the language, defaulting to 'English'
  /// for unknown codes
  String getLanguageNativeName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ur':
        return 'اردو';
      default:
        return 'English';
    }
  }
} 