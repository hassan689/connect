import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:math';

/// Service for managing engaging notifications to keep users active.
/// 
/// Sends periodic fun content including jokes, tips, and motivational messages
/// to maintain user engagement. Uses local notifications and tracks delivery
/// to avoid spamming users with duplicate content.
class EngagementNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  /// Collection of humorous content for engagement notifications.
  /// 
  /// Contains dino-themed jokes and fun facts to make notifications
  /// entertaining and memorable for users.
  static const List<Map<String, String>> _jokes = [
    {
      'title': '😄 Dino Joke Time!',
      'body': 'Why did the dino go to the doctor? Because he had a "rawr" throat! 🦖',
    },
    {
      'title': '🤣 Connect Humor',
      'body': 'What do you call a task that\'s always late? A "deadline"! 😅',
    },
    {
      'title': '😆 Fun Fact',
      'body': 'Did you know? Helping others releases endorphins - nature\'s way of saying "you\'re awesome!" 🌟',
    },
    {
      'title': '🎉 Motivation Boost',
      'body': 'Remember: Every task completed is a step toward making someone\'s day better! 💪',
    },
    {
      'title': '🦖 Dino Wisdom',
      'body': 'Even dinosaurs had to start somewhere. Your journey to helping others starts with one task! 🚀',
    },
  ];

  /// Collection of helpful tips for using the Connect app effectively.
  /// 
  /// Provides actionable advice on completing profiles, improving ratings,
  /// and maximizing earnings on the platform.
  static const List<Map<String, String>> _tips = [
    {
      'title': '💡 Pro Tip',
      'body': 'Complete your profile to get more task requests! People trust users with complete profiles.',
    },
    {
      'title': '🎯 Task Success',
      'body': 'Clear communication is key! Always ask questions if you\'re unsure about a task.',
    },
    {
      'title': '⭐ Rating Boost',
      'body': 'Deliver quality work and ask for ratings - they help you get more opportunities!',
    },
    {
      'title': '🔍 Smart Searching',
      'body': 'Use filters to find tasks that match your skills and location!',
    },
    {
      'title': '💰 Earn More',
      'body': 'Set competitive prices and provide excellent service to build a loyal client base!',
    },
  ];

  /// Collection of motivational messages to encourage users.
  /// 
  /// Contains positive affirmations and encouragement to keep users
  /// motivated about their work on the platform.
  static const List<Map<String, String>> _motivational = [
    {
      'title': '🌟 You\'re Amazing!',
      'body': 'Every task you complete makes the world a better place. Keep up the great work!',
    },
    {
      'title': '💪 Power Move',
      'body': 'Your skills are valuable. Don\'t underestimate the impact you can make!',
    },
    {
      'title': '🎯 Goal Achiever',
      'body': 'Small steps lead to big changes. Every task is progress toward your goals!',
    },
    {
      'title': '🔥 On Fire!',
      'body': 'You\'re building something amazing - a network of people who trust and value your work!',
    },
    {
      'title': '🚀 Rising Star',
      'body': 'Your dedication to helping others is inspiring. The community needs people like you!',
    },
  ];

  /// Initializes the engagement notification service.
  /// 
  /// Sets up local notifications and schedules engagement notifications
  /// for the current user. Should be called during app initialization.
  Future<void> initialize() async {
    await _initLocalNotifications();
    await _scheduleEngagementNotifications();
  }

  /// Initializes local notification settings for Android.
  /// 
  /// Configures the notification plugin with Android-specific settings
  /// required for displaying engagement notifications.
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings settings = 
        InitializationSettings(android: androidSettings);
    
    await _notificationsPlugin.initialize(settings);
  }

  /// Schedules and sends daily engagement notifications to users.
  /// 
  /// Checks if a notification has already been sent today to avoid spam.
  /// Randomly selects content type (joke, tip, or motivational) and sends
  /// a local notification. Tracks delivery in Firestore.
  /// 
  /// Does nothing if the user has already received a notification today
  /// or if no user is currently authenticated.
  Future<void> _scheduleEngagementNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Check if user has already received notifications today
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final lastNotificationDate = userDoc.data()?['lastEngagementNotification'] as String?;
    
    if (lastNotificationDate == todayString) {
      print('📱 User already received engagement notification today');
      return;
    }

    // Randomly select content type
    final random = Random();
    final contentTypes = ['joke', 'tip', 'motivational'];
    final selectedType = contentTypes[random.nextInt(contentTypes.length)];
    
    Map<String, String> content;
    switch (selectedType) {
      case 'joke':
        content = _jokes[random.nextInt(_jokes.length)];
        break;
      case 'tip':
        content = _tips[random.nextInt(_tips.length)];
        break;
      case 'motivational':
        content = _motivational[random.nextInt(_motivational.length)];
        break;
      default:
        content = _jokes[0];
    }

    // Send local notification
    await _sendLocalNotification(content['title']!, content['body']!);
    
    // Update user's last notification date
    await _firestore.collection('users').doc(user.uid).update({
      'lastEngagementNotification': todayString,
      'engagementNotificationsCount': FieldValue.increment(1),
    });

    print('📱 Engagement notification sent: ${content['title']}');
  }

  /// Sends a local notification with the specified content.
  /// 
  /// Displays a notification using the Flutter Local Notifications plugin
  /// with Android-specific styling including vibration, sound, and app colors.
  /// 
  /// [title] The notification title to display
  /// [body] The notification body message to display
  Future<void> _sendLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'engagement_channel',
      'Engagement Notifications',
      channelDescription: 'Fun notifications to keep you engaged',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00C7BE),
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  /// Sends an immediate engagement notification for testing purposes.
  /// 
  /// Bypasses the once-per-day limitation and immediately sends a randomly
  /// selected engagement notification. Useful for testing notification
  /// delivery and appearance during development.
  Future<void> sendImmediateEngagementNotification() async {
    final random = Random();
    final contentTypes = ['joke', 'tip', 'motivational'];
    final selectedType = contentTypes[random.nextInt(contentTypes.length)];
    
    Map<String, String> content;
    switch (selectedType) {
      case 'joke':
        content = _jokes[random.nextInt(_jokes.length)];
        break;
      case 'tip':
        content = _tips[random.nextInt(_tips.length)];
        break;
      case 'motivational':
        content = _motivational[random.nextInt(_motivational.length)];
        break;
      default:
        content = _jokes[0];
    }

    await _sendLocalNotification(content['title']!, content['body']!);
    print('📱 Immediate engagement notification sent: ${content['title']}');
  }

  /// Schedules a notification to be sent at a specific future time.
  /// 
  /// Creates a scheduled notification record in Firestore that can be
  /// processed by a backend service or cloud function to deliver the
  /// notification at the specified time.
  /// 
  /// [scheduledTime] The DateTime when the notification should be sent
  Future<void> scheduleNotificationForTime(DateTime scheduledTime) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final random = Random();
    final content = _jokes[random.nextInt(_jokes.length)];

    // Create scheduled notification
    await _firestore.collection('scheduled_notifications').add({
      'userId': user.uid,
      'title': content['title'],
      'body': content['body'],
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'sent': false,
      'type': 'engagement',
    });

    print('📅 Notification scheduled for: ${scheduledTime.toString()}');
  }

  /// Retrieves engagement statistics for the current user.
  /// 
  /// Returns information about how many engagement notifications the user
  /// has received and their notification preferences.
  /// 
  /// Returns a Map containing:
  /// - `totalNotifications`: Total count of engagement notifications sent
  /// - `lastNotification`: Date of the last notification or 'Never'
  /// - `notificationPreference`: User's notification preference setting
  Future<Map<String, dynamic>> getUserEngagementStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data() ?? {};

    return {
      'totalNotifications': data['engagementNotificationsCount'] ?? 0,
      'lastNotification': data['lastEngagementNotification'] ?? 'Never',
      'notificationPreference': data['notificationPreference'] ?? 'all',
    };
  }

  /// Updates the user's notification preferences.
  /// 
  /// Allows users to customize which types of engagement notifications
  /// they want to receive (jokes, tips, motivational) and frequency.
  /// 
  /// [jokes] Whether to receive joke notifications
  /// [tips] Whether to receive tip notifications
  /// [motivational] Whether to receive motivational notifications
  /// [daily] Whether to receive daily notifications
  Future<void> updateNotificationPreferences({
    required bool jokes,
    required bool tips,
    required bool motivational,
    required bool daily,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'notificationPreferences': {
        'jokes': jokes,
        'tips': tips,
        'motivational': motivational,
        'daily': daily,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('⚙️ Notification preferences updated');
  }
} 