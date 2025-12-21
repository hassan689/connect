import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:connect/firebase_options.dart';

/// Service for managing Firebase initialization and configuration
class FirebaseService {
  FirebaseService._();

  static bool _isInitialized = false;

  /// Ensures Firebase is initialized only once
  /// Returns true if Firebase is successfully initialized or already initialized
  static Future<bool> ensureInitialized() async {
    if (_isInitialized) {
      debugPrint('ℹ️ Firebase already initialized');
      return true;
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        try {
          Firebase.app();
          _isInitialized = true;
          debugPrint('ℹ️ Firebase already initialized');
          return true;
        } catch (e) {
          debugPrint('⚠️ Firebase apps exist but default app not found');
          _isInitialized = true;
          return true;
        }
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      debugPrint('✅ Firebase initialized successfully');
      return true;
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('duplicate-app') ||
          errorString.contains('already exists') ||
          errorString.contains('[default]')) {
        _isInitialized = true;
        debugPrint('ℹ️ Firebase already initialized (duplicate-app handled)');
        return true;
      } else {
        debugPrint('❌ Firebase initialization error: $e');
        return false;
      }
    }
  }

  /// Configure Firebase Auth settings
  /// Should only be called after Firebase is initialized
  static Future<void> configureAuth() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Firebase not initialized. Call ensureInitialized() first.');
      return;
    }

    try {
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: kDebugMode,
      );
      debugPrint('✅ Firebase Auth configured');
    } catch (e) {
      debugPrint('⚠️ Error configuring Firebase Auth settings: $e');
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _isInitialized;
}

