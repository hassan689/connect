import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import language files
import 'languages/english.dart';
import 'languages/urdu.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  static List<LocalizationsDelegate<dynamic>> get localizationsDelegates => [
    delegate,
  ];
  
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('ur', 'PK'), // Urdu
  ];
  
  // Get the language map based on locale
  Map<String, String> get _languageMap {
    switch (locale.languageCode) {
      case 'ur':
        return urdu;
      default:
        return english;
    }
  }
  
  // Get localized string
  String getString(String key) {
    return _languageMap[key] ?? key;
  }
  
  // Format currency
  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: locale.toString(),
      symbol: locale.languageCode == 'en' ? 'Rs ' : '₨ ',
    );
    return formatter.format(amount);
  }
  
  // Format date
  String formatDate(DateTime date) {
    final formatter = DateFormat.yMMMd(locale.toString());
    return formatter.format(date);
  }
  
  // Format time
  String formatTime(DateTime time) {
    final formatter = DateFormat.Hm(locale.toString());
    return formatter.format(time);
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'ur'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Language selection provider
class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en', 'US');
  
  Locale get currentLocale => _currentLocale;
  
  void setLocale(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }
  
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