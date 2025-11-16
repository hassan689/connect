// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static Future<String?> fetchUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data();
        if (data != null && data.containsKey('fullName')) {
          return data['fullName'] as String;
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }
}
