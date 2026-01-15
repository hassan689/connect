import 'package:connect/config/app_config.dart';

/// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Connect';
  static const String appTitle = 'Connect';

  /// Notification channel configuration loaded from AppConfig
  static String get notificationChannelId => AppConfig.notificationChannelId;
  static String get notificationChannelName => AppConfig.notificationChannelName;
  static String get notificationChannelDescription => AppConfig.notificationChannelDescription;

  /// LED timing configuration loaded from AppConfig (in milliseconds)
  static int get ledOnMs => AppConfig.ledOnMs;
  static int get ledOffMs => AppConfig.ledOffMs;
  
  /// Notification icon loaded from AppConfig
  static String get notificationIcon => AppConfig.notificationIcon;

  static const String envFileName = '.env';
}

