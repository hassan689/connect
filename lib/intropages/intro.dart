import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:linkster/loginpage/loginp.dart';
import 'package:linkster/signuppage/signuppage.dart';
import 'package:linkster/core/utils/responsive.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:linkster/profilepage/profile_check_wrapper.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _pages = [
    {
      "color": const Color(0xFF00C7BE),
      "title": "Connect with Trusted Professionals",
      "description": "Find verified service providers for all your needs",
      "animation": "assets/images/animations/dinodance.json",
    },
    {
      "color": const Color(0xFF00C7BE),
      "title": "Simplify Your Life",
      "description": "Get connected with skilled professionals quickly",
      "animation": "assets/images/animations/dinodance.json",
    },
    {
      "color": const Color(0xFF00C7BE),
      "title": "Quality Services On Demand",
      "description": "Book reliable help with transparent ratings",
      "animation": "assets/images/animations/dinodance.json",
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Check if user is already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthenticationStatus();
    });
    
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _pages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutQuint,
        );
      }
    });
  }

  void _checkAuthenticationStatus() {
    try {
      // Check if Firebase is initialized before accessing Auth
      if (Firebase.apps.isEmpty) {
        // Firebase not initialized yet, skip auth check
        debugPrint('⚠️ Firebase not initialized, skipping auth check');
        return;
      }
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User is authenticated, redirect to profile check wrapper
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileCheckWrapper()),
        );
      }
    } catch (e) {
      // Handle any errors gracefully - app should still work
      debugPrint('⚠️ Error checking authentication status: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: _pages[_currentPage]["color"],
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.value(mobile: 16.0, tablet: 24.0, desktop: 32.0),
                          vertical: responsive.value(mobile: 20.0, tablet: 30.0, desktop: 40.0),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: screenHeight - 200,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Large Dino Animation at the top
                              Container(
                                width: responsive.value(
                                  mobile: screenWidth * 0.8,
                                  tablet: 400,
                                  desktop: 500,
                                ),
                                height: responsive.value(
                                  mobile: screenHeight * 0.25,
                                  tablet: 300,
                                  desktop: 350,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth: 500,
                                  maxHeight: 350,
                                ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 700),
                              child: Lottie.asset(
                                _pages[index]["animation"],
                                key: ValueKey<int>(index),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                              SizedBox(height: responsive.value(mobile: 16.0, tablet: 24.0, desktop: 32.0)),
                              // Text content below the animation
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.value(mobile: 24.0, tablet: 32.0, desktop: 40.0),
                                ),
                                child: Column(
                                  children: [
                                    // Title
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 500),
                                      child: Text(
                                        _pages[index]["title"],
                                        key: ValueKey<int>(index),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: responsive.value(
                                            mobile: screenWidth * 0.05,
                                            tablet: 28.0,
                                            desktop: 32.0,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: responsive.value(mobile: 12.0, tablet: 16.0, desktop: 20.0)),
                                    // Description
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 500),
                                      child: Text(
                                        _pages[index]["description"],
                                        key: ValueKey<int>(index),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: responsive.value(
                                            mobile: screenWidth * 0.035,
                                            tablet: 16.0,
                                            desktop: 18.0,
                                          ),
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.9),
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: responsive.value(mobile: 12.0, tablet: 16.0, desktop: 20.0)),
              SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: const ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: Colors.white,
                  dotColor: Colors.white54,
                  spacing: 10,
                  expansionFactor: 3,
                ),
              ),
              SizedBox(height: responsive.value(mobile: 16.0, tablet: 20.0, desktop: 24.0)),
              Container(
                height: responsive.value(mobile: 250, tablet: 270, desktop: 300),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.value(mobile: 24.0, tablet: 32.0, desktop: 40.0),
                  vertical: responsive.value(mobile: 16.0, tablet: 20.0, desktop: 24.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Ready to get started?",
                      style: GoogleFonts.poppins(
                        fontSize: responsive.value(mobile: 14.0, tablet: 16.0, desktop: 18.0),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C7BE),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            "Log in",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF019992),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            "Sign up",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Or continue with",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: _signInWithGoogle,
                        borderRadius: BorderRadius.circular(50),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          child: Image.asset(
                            'assets/images/google.png',
                            height: 24,
                            width: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      // For web, GoogleSignIn will use the meta tag client_id
      // For other platforms, it uses the default configuration
      final GoogleSignIn googleSignIn = kIsWeb
          ? GoogleSignIn(
              // On web, clientId is read from meta tag, but we can also specify it here
              // Leave empty to use meta tag, or specify your client ID
            )
          : GoogleSignIn();
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Redirect to profile check wrapper after successful sign-in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileCheckWrapper()),
      );
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      
      // Show user-friendly error message
      String errorMessage = "Google Sign-In failed. ";
      
      if (kIsWeb) {
        if (e.toString().contains("ClientID not set") || e.toString().contains("appClientId")) {
          errorMessage += "Google Sign-In Client ID not configured for web.\n\n"
              "To fix: Add your Google OAuth Client ID to web/index.html\n"
              "See FIREBASE_WEB_SETUP.md for instructions";
        } else {
          errorMessage += e.toString();
        }
      } else if (e.toString().contains("ApiException: 10")) {
        errorMessage += "Please configure SHA-1 fingerprint in Firebase Console.\n\n"
            "To fix this:\n"
            "1. Get your SHA-1 fingerprint:\n"
            "   Run: keytool -list -v -keystore %USERPROFILE%\\.android\\debug.keystore -alias androiddebugkey -storepass android -keypass android\n"
            "   Or use: gradlew signingReport\n\n"
            "2. Go to Firebase Console > Project Settings > Your Android App\n"
            "3. Add the SHA-1 fingerprint\n"
            "4. Download the updated google-services.json\n"
            "5. Replace the file in android/app/\n"
            "6. Rebuild the app";
      } else {
        errorMessage += e.toString();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 8),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}