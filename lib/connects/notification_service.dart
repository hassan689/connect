import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for managing Firebase Cloud Messaging (FCM) and local notifications.
/// 
/// Handles FCM token registration, permission requests, and local notification
/// initialization for the Connect app. Integrates with Firestore to store
/// user notification tokens and supports test notifications.
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  /// Initializes the notification service.
  /// 
  /// Requests notification permissions from the user, retrieves and stores
  /// the FCM token to Firestore, and initializes local notifications with
  /// platform-specific settings.
  /// 
  /// This should be called during app initialization, typically in the
  /// main.dart file or on user login.
  Future<void> initialize() async {
    // Request permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and print token (already working for you)
    String? token = await _fcm.getToken();
    print("FCM Token: $token");

    // Save token to user document
    await _saveTokenToFirestore(token);

    // Initialize local notifications
    await _initLocalNotifications();
  }

  /// Saves the FCM token to the user's Firestore document.
  /// 
  /// Stores the device's FCM token in the 'users' collection under the
  /// current user's document. This token is used by the backend to send
  /// push notifications to this specific device.
  /// 
  /// [token] The FCM token to save, or null if token generation failed
  Future<void> _saveTokenToFirestore(String? token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
    }
  }

  /// Initializes local notification settings for Android.
  /// 
  /// Configures the Flutter Local Notifications plugin with Android-specific
  /// settings, including the app launcher icon. This is required before
  /// showing any local notifications on the device.
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings settings = 
        InitializationSettings(android: androidSettings);
    
    await _notificationsPlugin.initialize(settings);
  }

  /// Sends a test notification to the current user's device.
  /// 
  /// Retrieves the current user's FCM token from Firestore and creates
  /// a notification request that can be processed by the backend notification
  /// service. Useful for testing notification delivery and permissions.
  /// 
  /// Does nothing if no user is logged in or if the user has no FCM token.
  Future<void> sendTestNotification() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final token = userDoc.data()?['fcmToken'];
    if (token == null) return;

    // Create a notification request in Firestore
    await FirebaseFirestore.instance.collection('notification_requests').add({
      'receiverToken': token,
      'title': 'Test Notification',
      'body': 'This is a test notification from your app!',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}