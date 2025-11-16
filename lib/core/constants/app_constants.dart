/// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Connect';
  static const String appTitle = 'Connect';

  static const String notificationChannelId = 'high_importance_channel';
  static const String notificationChannelName = 'High Importance Notifications';
  static const String notificationChannelDescription =
      'This channel is used for important notifications.';

  static const int ledOnMs = 1000;
  static const int ledOffMs = 500;
  static const String notificationIcon = '@mipmap/ic_launcher';

  static const String envFileName = '.env';
}

