import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connect/core/constants/app_constants.dart';
import 'package:connect/core/services/firebase_service.dart';
import 'package:connect/core/services/notification_service.dart';
import 'package:connect/core/theme/app_theme.dart';
import 'package:connect/intropages/intro.dart';
import 'package:connect/l10n/app_localizations.dart';
import 'package:connect/services/engagement_notifications.dart';

/// Background message handler for Firebase Cloud Messaging
/// This runs in a separate isolate, so Firebase needs to be initialized here
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate
  await FirebaseService.ensureInitialized();

  try {
    debugPrint('🔙 Handling background message: ${message.messageId}');
    if (message.notification != null) {
      await NotificationService.showNotification(
        id: message.hashCode,
        title: message.notification?.title,
        body: message.notification?.body,
        payload: message.data['route'],
      );
    }
  } catch (e) {
    debugPrint('⚠️ Error showing notification: $e');
  }
}

/// Main entry point of the application
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnvironmentVariables();

  final firebaseInitialized = await FirebaseService.ensureInitialized();
  if (firebaseInitialized) {
    await FirebaseService.configureAuth();
  }

  await NotificationService.initialize();

  if (!kIsWeb && firebaseInitialized) {
    await NotificationService.setupFirebaseMessaging(
      backgroundHandler: _firebaseMessagingBackgroundHandler,
    );
  }

  if (!kIsWeb && firebaseInitialized) {
    await _initializeEngagementNotifications();
  }

  runApp(const MyApp());
}

/// Load environment variables from .env file
/// If .env file doesn't exist, app will use default/hardcoded values
Future<void> _loadEnvironmentVariables() async {
  try {
    await dotenv.load(fileName: AppConstants.envFileName);
    debugPrint('✅ Environment variables loaded successfully');
  } catch (e) {
    debugPrint(
      'ℹ️ Info: Using default configuration (optional .env file not found)',
    );
  }
}

/// Initialize engagement notifications service
Future<void> _initializeEngagementNotifications() async {
  try {
    final engagementService = EngagementNotificationService();
    await engagementService.initialize();
    debugPrint('📱 Engagement notifications initialized');
  } catch (e) {
    debugPrint('❌ Error initializing engagement notifications: $e');
  }
}

/// The main application widget
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkRedirectResult();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkRedirectResult();
    }
  }

  Future<void> _checkRedirectResult() async {
    if (kIsWeb) return;
    
    try {
      final result = await FirebaseAuth.instance.getRedirectResult();
      if (result.user != null) {
        debugPrint('✅ GitHub OAuth successful: ${result.user!.uid}');
      }
    } catch (e) {
      debugPrint('⚠️ Error checking redirect result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const IntroScreen(),
    );
  }
}