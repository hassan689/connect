import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connect/core/constants/app_constants.dart';

/// Service for managing local and push notifications
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      final channel = AndroidNotificationChannel(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        description: AppConstants.notificationChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidSettings = AndroidInitializationSettings(
        AppConstants.notificationIcon,
      );

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      debugPrint('Notification payload: ${response.payload}');
    }
  }

  /// Show local notification
  static Future<void> showNotification({
    required int id,
    required String? title,
    required String? body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    try {
      await _plugin.show(
        id,
        title,
        body,
        _getNotificationDetails(),
        payload: payload,
      );
    } catch (e) {
      debugPrint('⚠️ Error showing notification: $e');
    }
  }

  /// Get notification details for Android and iOS
  static NotificationDetails _getNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: Colors.blue,
        ledColor: Colors.blue,
        ledOnMs: AppConstants.ledOnMs,
        ledOffMs: AppConstants.ledOffMs,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Setup Firebase Cloud Messaging
  static Future<void> setupFirebaseMessaging({
    required Future<void> Function(RemoteMessage) backgroundHandler,
  }) async {
    if (kIsWeb) return;

    try {
      FirebaseMessaging.onBackgroundMessage(backgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      await _handleInitialMessage();
      await _requestPermissions();
      await _getFCMToken();

      debugPrint('✅ Firebase Messaging setup complete');
    } catch (e) {
      debugPrint('⚠️ Error setting up Firebase Messaging: $e');
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    try {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        showNotification(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          payload: message.data['route'],
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error handling foreground message: $e');
    }
  }

  /// Handle initial message when app opens from terminated state
  static Future<void> _handleInitialMessage() async {
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          'App opened from terminated state with notification: ${initialMessage.messageId}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error getting initial message: $e');
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      debugPrint('⚠️ Error requesting notification permissions: $e');
    }
  }

  /// Get FCM token
  static Future<void> _getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
      }
    } catch (e) {
      debugPrint('⚠️ Error getting FCM token: $e');
    }
  }
}

