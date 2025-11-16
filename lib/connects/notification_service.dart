import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

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

  Future<void> _saveTokenToFirestore(String? token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings settings = 
        InitializationSettings(android: androidSettings);
    
    await _notificationsPlugin.initialize(settings);
  }

  Future<void> sendTestNotification() async {
    // For testing, send to yourself
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