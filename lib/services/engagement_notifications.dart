import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class EngagementNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // Collection of engaging content
  static const List<Map<String, String>> _jokes = [
    {
      'title': '😄 Dino Joke Time!',
      'body': 'Why did the dino go to the doctor? Because he had a "rawr" throat! 🦖',
    },
    {
      'title': '🤣 Linkster Humor',
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

  // Initialize the service
  Future<void> initialize() async {
    await _initLocalNotifications();
    await _scheduleEngagementNotifications();
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings settings = 
        InitializationSettings(android: androidSettings);
    
    await _notificationsPlugin.initialize(settings);
  }

  // Schedule engagement notifications
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

  // Send local notification
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

  // Send immediate engagement notification (for testing)
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

  // Schedule notification for specific time
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

  // Get user engagement statistics
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

  // Update user notification preferences
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