import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkster/profilepage/profile_check_wrapper.dart';
import 'dart:async';

/// GitHub OAuth WebView Screen
/// Handles GitHub authentication flow using WebView
class GitHubAuthScreen extends StatefulWidget {
  final String authUrl;
  
  const GitHubAuthScreen({
    super.key,
    required this.authUrl,
  });

  @override
  State<GitHubAuthScreen> createState() => _GitHubAuthScreenState();
}

class _GitHubAuthScreenState extends State<GitHubAuthScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  StreamSubscription<User?>? _authStateSubscription;
  bool _isHandlingAuth = false;

  @override
  void initState() {
    super.initState();
    
    // Listen to auth state changes
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && !_isHandlingAuth && mounted) {
        _isHandlingAuth = true;
        debugPrint('GitHub Auth - User authenticated: ${user.uid}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileCheckWrapper(),
          ),
        );
      }
    });
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            
            debugPrint('GitHub Auth - Page Started: $url');
            
            // Check for Firebase auth handler completion
            if (url.contains('__/auth/handler')) {
              _checkAuthResult();
            }
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            
            debugPrint('GitHub Auth - Page Finished: $url');
            
            // Check for Firebase auth handler completion
            if (url.contains('__/auth/handler')) {
              _checkAuthResult();
            }
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              debugPrint('GitHub Auth - URL Changed: ${change.url}');
              if (change.url!.contains('__/auth/handler')) {
                _checkAuthResult();
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthResult() async {
    if (_isHandlingAuth) return;
    
    try {
      // Check if Firebase has completed the authentication
      // Firebase should handle the redirect automatically
      await Future.delayed(const Duration(milliseconds: 500));
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted && !_isHandlingAuth) {
        _isHandlingAuth = true;
        debugPrint('GitHub Auth - Authentication successful: ${user.uid}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileCheckWrapper(),
          ),
        );
      }
    } catch (e) {
      debugPrint('GitHub Auth - Error checking auth result: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GitHub Sign-In',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF24292e),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

