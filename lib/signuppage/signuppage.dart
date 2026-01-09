import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:connect/firebase/fb.dart';
import 'package:connect/profilepage/complete_profile_screen.dart';
import 'package:connect/menupage/mainp.dart';
import 'package:connect/loginpage/loginp.dart'; // Added import for LoginPage
import 'package:connect/config/app_config.dart';
import 'dart:async'; // Added for Timer

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FirebaseAuthService _auth = FirebaseAuthService();

  bool _agree = false;
  bool _passwordInvalid = false;
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  bool _emailAvailable = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _emailCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Dinosaur Animation
                SizedBox(
                  height: 150,
                  child: Lottie.asset(
                    'assets/images/animations/dinodance.json',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 12),

                // Heading
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sign up',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Create an account to get started',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 10),

                // Name Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Name',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration("Enter your name"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Email Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email Address',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                                     decoration: _inputDecoration(
                     "example@gmail.com",
                     isError: !_emailAvailable,
                     suffixIcon: _isCheckingEmail
                         ? const SizedBox(
                             width: 20,
                             height: 20,
                             child: Padding(
                               padding: EdgeInsets.all(8.0),
                               child: CircularProgressIndicator(
                                 strokeWidth: 2,
                                 color: Color(0xFF00C7BE),
                               ),
                             ),
                           )
                         : _emailController.text.isNotEmpty && !_isCheckingEmail
                             ? Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Icon(
                                     _emailAvailable ? Icons.check_circle : Icons.error,
                                     color: _emailAvailable ? Colors.green : Colors.red,
                                     size: 20,
                                   ),
                                   if (!_emailAvailable) ...[
                                     const SizedBox(width: 4),
                                     GestureDetector(
                                       onTap: () async {
                                         setState(() {
                                           _isCheckingEmail = true;
                                         });
                                         
                                         bool isAvailable = await _checkEmailAvailability(_emailController.text.trim());
                                         
                                         if (mounted) {
                                           setState(() {
                                             _isCheckingEmail = false;
                                             _emailAvailable = isAvailable;
                                           });
                                           
                                           ScaffoldMessenger.of(context).showSnackBar(
                                             SnackBar(
                                               content: Text(isAvailable 
                                                 ? '✅ Email is now available!' 
                                                 : '❌ Email is still registered'),
                                               backgroundColor: isAvailable ? Colors.green : Colors.red,
                                               duration: Duration(seconds: 2),
                                             ),
                                           );
                                         }
                                       },
                                       child: Icon(
                                         Icons.refresh,
                                         color: Colors.blue,
                                         size: 16,
                                       ),
                                     ),
                                   ],
                                 ],
                               )
                             : null,
                   ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    _checkEmailAvailabilityRealTime(value.trim());
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address';
                    }
                    if (!_emailAvailable && value.trim().isNotEmpty) {
                      return 'This email is already registered';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Password',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration(
                    "Create a password",
                    isError: _passwordInvalid,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      if (_formKey.currentState!.validate()) {
                        if (_agree) {
                          signUp();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please agree to the Terms and Conditions',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7BE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            'Sign up',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Terms and Privacy Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agree,
                      onChanged: (value) {
                        setState(() {
                          _agree = value ?? false;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(
                              text: 'I\'ve read and agree with the ',
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = () {
                                      // Open terms
                                    },
                            ),
                            const TextSpan(text: ' and the '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = () {
                                      // Open privacy policy
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {bool isError = false, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      hintStyle: GoogleFonts.inter(
        textStyle: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontWeight: FontWeight.bold,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isError ? Colors.red : Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isError ? Colors.red : Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isError ? Colors.red : const Color(0xFF00C7BE),
          width: 2,
        ),
      ),
    );
  }

  // Real-time email availability check with debouncing
  Timer? _emailCheckTimer;
  void _checkEmailAvailabilityRealTime(String email) {
    // Cancel previous timer
    _emailCheckTimer?.cancel();
    
    // Reset state
    setState(() {
      _isCheckingEmail = false;
      _emailAvailable = true;
    });

    // Don't check if email is empty or invalid
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return;
    }

    // Set loading state
    setState(() {
      _isCheckingEmail = true;
    });

    // Debounce the check for 500ms
    _emailCheckTimer = Timer(const Duration(milliseconds: 500), () async {
      if (email == _emailController.text.trim()) {
        bool isAvailable = await _checkEmailAvailability(email);
        if (mounted) {
          setState(() {
            _isCheckingEmail = false;
            _emailAvailable = isAvailable;
          });
        }
      }
    });
  }


  void signUp() async {
    setState(() {
      _isLoading = true;
      _passwordInvalid = false;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();

    try {
      // First, check if email is already registered
      bool isEmailAvailable = await _checkEmailAvailability(email);
      
      if (!isEmailAvailable) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error dialog for existing email
        _showEmailExistsDialog(email);
        return;
      }

      User? user = await _auth.signUpwithEmailAndPassword(email, password);

      if (user != null) {
        setState(() {
          _passwordInvalid = false;
        });

        // Show loading dialog for email verification
        _showVerificationDialog(user, name, email, password);

        // Save basic user info in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'isProfileVerified': false,
          'isMobileVerified': false,
          'taskCount': 0,
          'taskCompletionRate': 0,
          'hasSeenWelcome': false, // New users haven't seen welcome dialog yet
          'hasSeenDinoGuide': false, // New users haven't seen dino guide yet
          'points': {
            'balance': 0.0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          'fcmToken': await FirebaseMessaging.instance.getToken(),
        });

        setState(() {
          _isLoading = false;
        });

      } else {
        setState(() {
          _isLoading = false;
          _passwordInvalid = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _passwordInvalid = true;
      });
    }
  }

  // Check if email is already registered in Firestore
  Future<bool> _checkEmailAvailability(String email) async {
    try {
      // Query Firestore to check if email already exists
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return false; // Email exists in Firestore
      }
      
      // Also check Firebase Auth
      try {
        List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        
        if (signInMethods.isNotEmpty) {
          return false; // Email exists in Firebase Auth
        }
      } catch (authError) {
        // Continue with Firestore result
      }
      
      return true; // Email is available
    } catch (e) {
      // In case of error, assume email is available to not block signup
      return true;
    }
  }

  // Show dialog when email already exists
  void _showEmailExistsDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.email,
                  color: Colors.red[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Email Already Exists',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'An account with this email already exists:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please try a different email address or sign in if you already have an account.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear the email field
                _emailController.clear();
                // Focus on email field
                FocusScope.of(context).requestFocus(_emailFocusNode);
              },
              child: Text(
                'Try Different Email',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00C7BE),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to login page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C7BE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign In Instead',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getSignupErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password.';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'An error occurred during signup. Please try again.';
    }
  }

  void _showVerificationDialog(User user, String name, String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Account Created Successfully!',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 60,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to Connect, $name!',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We\'ve sent a verification email to:\n$email',
                style: GoogleFonts.poppins(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C7BE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00C7BE)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF00C7BE),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please check your email and click the verification link to activate your account.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF00C7BE),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '💡 Tip: Check your spam/junk folder if you don\'t see the email in your inbox.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await user.sendEmailVerification(
                    ActionCodeSettings(
                      url: AppConfig.firebaseAuthActionUrl,
                      handleCodeInApp: true,
                      androidPackageName: AppConfig.appPackageName,
                      androidInstallApp: true,
                      androidMinimumVersion: '12',
                      iOSBundleId: AppConfig.firebaseIosBundleId,
                    ),
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification email sent again! Please check your inbox and spam folder.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send verification email: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                'Resend Email',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00C7BE),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Check if email is verified before proceeding
                try {
                  // Reload user to get latest verification status
                  await user.reload();
                  User? updatedUser = FirebaseAuth.instance.currentUser;
                  
                  if (updatedUser != null && updatedUser.emailVerified) {
                    Navigator.of(context).pop();
                    _showDinoEmailVerifiedDialog(name, email, password);
                  } else {
                    // Show dialog with troubleshooting options
                    _showTroubleshootingDialog(user, email, password);
                  }
                } catch (e) {
                  // Show troubleshooting dialog if there's an error
                  _showTroubleshootingDialog(user, email, password);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C7BE),
              ),
              child: Text(
                'I\'ve Verified My Email',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTroubleshootingDialog(User user, String email, String password) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Email Verification Troubleshooting',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'If you haven\'t received the verification email:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildTroubleshootingItem('📧 Check your spam/junk folder'),
              _buildTroubleshootingItem('⏰ Wait a few minutes (emails can be delayed)'),
              _buildTroubleshootingItem('✅ Make sure you entered the correct email'),
              _buildTroubleshootingItem('🔄 Try resending the verification email'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  'Email: $email',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await user.sendEmailVerification(
                    ActionCodeSettings(
                      url: AppConfig.firebaseAuthActionUrl,
                      handleCodeInApp: true,
                      androidPackageName: AppConfig.appPackageName,
                      androidInstallApp: true,
                      androidMinimumVersion: '12',
                      iOSBundleId: AppConfig.firebaseIosBundleId,
                    ),
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification email sent! Please check your inbox and spam folder.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send verification email: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C7BE),
              ),
              child: Text(
                'Resend Email',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTroubleshootingItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showDinoWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dino Animation
                Container(
                  height: 120,
                  width: 120,
                  child: Lottie.asset(
                    'assets/images/animations/dinodance.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Welcome Text
                Text(
                  'Welcome to Connect! 🎉',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00C7BE),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                Text(
                  'Your profile is now complete!\nYou can start connecting with others.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to main app
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const MenuPage()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7BE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Let\'s Get Started! 🚀',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDinoEmailVerifiedDialog(String name, String email, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dino Animation
                Container(
                  height: 120,
                  width: 120,
                  child: Lottie.asset(
                    'assets/images/animations/done.json',
                    fit: BoxFit.contain,
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Success Text
                Text(
                  'Email Verified! ✅',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                Text(
                  'Great job, $name!\nYour email has been verified successfully.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to profile completion
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompleteProfileScreen(
                            name: name,
                            email: email,
                            password: password,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7BE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Complete Your Profile 📝',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
