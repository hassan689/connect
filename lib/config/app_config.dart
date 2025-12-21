import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application Configuration File
/// 
/// This file loads sensitive configuration data from .env file (optional).
/// If .env file doesn't exist, uses default/hardcoded values.
/// 
/// ⚠️ IMPORTANT: 
/// - The .env file should NEVER be committed to version control
/// - Copy .env.example to .env and fill in your actual values (optional)
/// - Make sure .env is in .gitignore
/// 
/// To use this file:
/// 1. (Optional) Create .env file in root directory
/// 2. Import it in your code: import 'package:connect/config/app_config.dart';
/// 3. Access values: AppConfig.stripePublishableKey

class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // Helper to safely get env values
  static String _getEnv(String key, String defaultValue) {
    try {
      return dotenv.env[key] ?? defaultValue;
    } catch (e) {
      // dotenv not loaded, return default
      return defaultValue;
    }
  }

  // ============================================================================
  // STRIPE PAYMENT CONFIGURATION
  // ============================================================================
  
  /// Stripe Publishable Key (safe to expose in client-side code)
  /// Get this from: https://dashboard.stripe.com/apikeys
  static String get stripePublishableKey => 
      _getEnv('STRIPE_PUBLISHABLE_KEY', '');

  /// Stripe Secret Key (NEVER expose this in client-side code)
  /// ⚠️ This should only be used in server-side code (Firebase Functions)
  /// Get this from: https://dashboard.stripe.com/apikeys
  static String get stripeSecretKey => 
      _getEnv('STRIPE_SECRET_KEY', '');

  // ============================================================================
  // FIREBASE CONFIGURATION
  // ============================================================================
  
  /// Firebase Project ID
  static String get firebaseProjectId => 
      _getEnv('FIREBASE_PROJECT_ID', '');
  
  /// Firebase Messaging Sender ID
  static String get firebaseMessagingSenderId => 
      _getEnv('FIREBASE_MESSAGING_SENDER_ID', '');
  
  /// Firebase Storage Bucket
  static String get firebaseStorageBucket => 
      _getEnv('FIREBASE_STORAGE_BUCKET', '');
  
  /// Firebase Auth Domain
  static String get firebaseAuthDomain => 
      _getEnv('FIREBASE_AUTH_DOMAIN', '');

  // Firebase API Keys (Platform-specific)
  
  /// Firebase Web API Key
  static String get firebaseWebApiKey => 
      _getEnv('FIREBASE_WEB_API_KEY', '');
  
  /// Firebase Android API Key
  static String get firebaseAndroidApiKey => 
      _getEnv('FIREBASE_ANDROID_API_KEY', '');
  
  /// Firebase iOS API Key
  static String get firebaseIosApiKey => 
      _getEnv('FIREBASE_IOS_API_KEY', '');
  
  /// Firebase macOS API Key
  static String get firebaseMacosApiKey => 
      _getEnv('FIREBASE_MACOS_API_KEY', '');
  
  /// Firebase Windows API Key
  static String get firebaseWindowsApiKey => 
      _getEnv('FIREBASE_WINDOWS_API_KEY', '');

  // Firebase App IDs (Platform-specific)
  
  /// Firebase Web App ID
  static String get firebaseWebAppId => 
      _getEnv('FIREBASE_WEB_APP_ID', '');
  
  /// Firebase Android App ID
  static String get firebaseAndroidAppId => 
      _getEnv('FIREBASE_ANDROID_APP_ID', '');
  
  /// Firebase iOS App ID
  static String get firebaseIosAppId => 
      _getEnv('FIREBASE_IOS_APP_ID', '');
  
  /// Firebase macOS App ID
  static String get firebaseMacosAppId => 
      _getEnv('FIREBASE_MACOS_APP_ID', '');
  
  /// Firebase Windows App ID
  static String get firebaseWindowsAppId => 
      _getEnv('FIREBASE_WINDOWS_APP_ID', '');

  // Firebase Measurement IDs
  
  /// Firebase Web Measurement ID
  static String get firebaseWebMeasurementId => 
      _getEnv('FIREBASE_WEB_MEASUREMENT_ID', '');
  
  /// Firebase Windows Measurement ID
  static String get firebaseWindowsMeasurementId => 
      _getEnv('FIREBASE_WINDOWS_MEASUREMENT_ID', '');

  // Firebase iOS Bundle ID
  static String get firebaseIosBundleId => 
      _getEnv('FIREBASE_IOS_BUNDLE_ID', 'com.example.connect');
  static String get firebaseMacosBundleId => 
      _getEnv('FIREBASE_MACOS_BUNDLE_ID', 'com.example.connect');

  // ============================================================================
  // GOOGLE MAPS CONFIGURATION
  // ============================================================================
  
  /// Google Maps API Key
  /// Get this from: https://console.cloud.google.com/google/maps-apis/credentials
  /// Used in AndroidManifest.xml for Google Maps integration
  static String get googleMapsApiKey => 
      _getEnv('GOOGLE_MAPS_API_KEY', '');

  // ============================================================================
  // OPENAI CONFIGURATION
  // ============================================================================
  
  /// OpenAI API Key
  /// Get this from: https://platform.openai.com/api-keys
  /// ⚠️ NEVER commit this key to version control
  static String get openAiApiKey => 
      _getEnv('OPENAI_API_KEY', '');

  /// OpenAI API Base URL
  static String get openAiBaseUrl => 
      _getEnv('OPENAI_BASE_URL', 'https://api.openai.com/v1/chat/completions');

  // ============================================================================
  // HUGGING FACE CONFIGURATION
  // ============================================================================
  
  /// Hugging Face API Token
  /// Get this from: https://huggingface.co/settings/tokens
  /// ⚠️ NEVER commit this token to version control
  static String get huggingFaceApiToken => 
      _getEnv('HUGGINGFACE_API_TOKEN', '');

  /// Hugging Face API Base URL
  static String get huggingFaceBaseUrl => 
      _getEnv('HUGGINGFACE_BASE_URL', 'https://api-inference.huggingface.co/models');

  // ============================================================================
  // OTHER CONFIGURATION
  // ============================================================================
  
  /// Default Notification Channel ID
  static String get defaultNotificationChannelId => 
      _getEnv('DEFAULT_NOTIFICATION_CHANNEL_ID', 'default_channel');
  
  /// Application Package Name
  static String get appPackageName => 
      _getEnv('APP_PACKAGE_NAME', 'com.example.connect');

  // ============================================================================
  // POINTS SYSTEM CONFIGURATION
  // ============================================================================
  
  /// Platform Commission Rate (as decimal, e.g., 0.10 for 10%)
  static double get platformCommissionRate {
    try {
      return double.tryParse(_getEnv('PLATFORM_COMMISSION_RATE', '0.10')) ?? 0.10;
    } catch (e) {
      return 0.10;
    }
  }
  
  /// Provider Payout Rate (as decimal, e.g., 0.90 for 90%)
  static double get providerPayoutRate {
    try {
      return double.tryParse(_getEnv('PROVIDER_PAYOUT_RATE', '0.90')) ?? 0.90;
    } catch (e) {
      return 0.90;
    }
  }
}
