import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:linkster/menupage/mainp.dart';
import 'package:linkster/profilepage/complete_profile_screen.dart';
import 'package:linkster/loginpage/loginp.dart';

class ProfileCheckWrapper extends StatefulWidget {
  const ProfileCheckWrapper({super.key});

  @override
  State<ProfileCheckWrapper> createState() => _ProfileCheckWrapperState();
}

class _ProfileCheckWrapperState extends State<ProfileCheckWrapper> {
  bool _isLoading = true;
  bool _isProfileComplete = false;
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        // User not logged in, go to login
        _navigateToLogin();
        return;
      }

      // Check if user's profile is complete
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // User document doesn't exist, go to login
        _navigateToLogin();
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final isProfileComplete = userData['isProfileComplete'] ?? false;
      final userName = userData['name'] ?? '';
      final userEmail = userData['email'] ?? '';

      setState(() {
        _isProfileComplete = isProfileComplete;
        _userName = userName;
        _userEmail = userEmail;
        _isLoading = false;
      });

      if (!isProfileComplete) {
        // Profile not complete, navigate to profile completion
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(
                name: userName,
                email: userEmail,
                password: '', // We don't need password for profile completion
              ),
            ),
          );
        });
      }
    } catch (e) {
      print('Error checking profile status: $e');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00C7BE),
          ),
        ),
      );
    }

    // If profile is complete, show main app
    if (_isProfileComplete) {
      return const MenuPage();
    }

    // This should not be reached as we navigate to profile completion above
    return const Scaffold(
      body: Center(
        child: Text('Redirecting to profile completion...'),
      ),
    );
  }
} 