/// Application Configuration Template File
/// 
/// ⚠️ COPY THIS FILE TO app_config.dart AND FILL IN YOUR ACTUAL VALUES
/// 
/// This is a template file showing the structure of the configuration.
/// Copy this file to app_config.dart and replace all placeholder values
/// with your actual API keys and sensitive information.

class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // ============================================================================
  // STRIPE PAYMENT CONFIGURATION
  // ============================================================================
  
  /// Stripe Publishable Key (safe to expose in client-side code)
  /// Get this from: https://dashboard.stripe.com/apikeys
  static const String stripePublishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY_HERE';

  /// Stripe Secret Key (NEVER expose this in client-side code)
  /// ⚠️ This should only be used in server-side code (Firebase Functions)
  /// Get this from: https://dashboard.stripe.com/apikeys
  static const String stripeSecretKey = 'YOUR_STRIPE_SECRET_KEY_HERE';

  // ============================================================================
  // FIREBASE CONFIGURATION
  // ============================================================================
  
  /// Firebase Project ID
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';
  
  /// Firebase Messaging Sender ID
  static const String firebaseMessagingSenderId = 'YOUR_MESSAGING_SENDER_ID';
  
  /// Firebase Storage Bucket
  static const String firebaseStorageBucket = 'YOUR_STORAGE_BUCKET';
  
  /// Firebase Auth Domain
  static const String firebaseAuthDomain = 'YOUR_AUTH_DOMAIN';

  // Firebase API Keys (Platform-specific)
  
  /// Firebase Web API Key
  static const String firebaseWebApiKey = 'YOUR_WEB_API_KEY';
  
  /// Firebase Android API Key
  static const String firebaseAndroidApiKey = 'YOUR_ANDROID_API_KEY';
  
  /// Firebase iOS API Key
  static const String firebaseIosApiKey = 'YOUR_IOS_API_KEY';
  
  /// Firebase macOS API Key
  static const String firebaseMacosApiKey = 'YOUR_MACOS_API_KEY';
  
  /// Firebase Windows API Key
  static const String firebaseWindowsApiKey = 'YOUR_WINDOWS_API_KEY';

  // Firebase App IDs (Platform-specific)
  
  /// Firebase Web App ID
  static const String firebaseWebAppId = 'YOUR_WEB_APP_ID';
  
  /// Firebase Android App ID
  static const String firebaseAndroidAppId = 'YOUR_ANDROID_APP_ID';
  
  /// Firebase iOS App ID
  static const String firebaseIosAppId = 'YOUR_IOS_APP_ID';
  
  /// Firebase macOS App ID
  static const String firebaseMacosAppId = 'YOUR_MACOS_APP_ID';
  
  /// Firebase Windows App ID
  static const String firebaseWindowsAppId = 'YOUR_WINDOWS_APP_ID';

  // Firebase Measurement IDs
  
  /// Firebase Web Measurement ID
  static const String firebaseWebMeasurementId = 'YOUR_WEB_MEASUREMENT_ID';
  
  /// Firebase Windows Measurement ID
  static const String firebaseWindowsMeasurementId = 'YOUR_WINDOWS_MEASUREMENT_ID';

  // Firebase iOS Bundle ID
  static const String firebaseIosBundleId = 'YOUR_IOS_BUNDLE_ID';
  static const String firebaseMacosBundleId = 'YOUR_MACOS_BUNDLE_ID';

  // ============================================================================
  // GOOGLE MAPS CONFIGURATION
  // ============================================================================
  
  /// Google Maps API Key
  /// Get this from: https://console.cloud.google.com/google/maps-apis/credentials
  /// Used in AndroidManifest.xml for Google Maps integration
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // ============================================================================
  // OTHER CONFIGURATION
  // ============================================================================
  
  /// Default Notification Channel ID
  static const String defaultNotificationChannelId = 'default_channel';
  
  /// Application Package Name
  static const String appPackageName = 'com.example.linkster';
}




