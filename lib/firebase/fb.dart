import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<User?> signUpwithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print("Attempting to create user with email: $email");
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("User created successfully: ${credential.user?.uid}");

      if (credential.user != null) {
        print("Sending email verification...");
        try {
          await credential.user!.sendEmailVerification(
            ActionCodeSettings(
              url: 'https://linkster-ad331.firebaseapp.com/__/auth/action',
              handleCodeInApp: true,
              androidPackageName: 'com.example.linkster',
              androidInstallApp: true,
              androidMinimumVersion: '12',
              iOSBundleId: 'com.example.linkster',
            ),
          );
          print("Email verification sent successfully to: $email");
        } catch (verificationError) {
          print("Error sending verification email: $verificationError");
        }
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Sign-up FirebaseAuthException: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("Unexpected sign-up error: $e");
      rethrow;
    }
  }

  Future<User?> signinwithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print("Attempting to sign in with email: $email");
      
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
      
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      
      print("Sign in successful: ${userCredential.user?.uid}");
      print("Email verified: ${userCredential.user?.emailVerified}");
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Login FirebaseAuthException: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'invalid-credential':
          errorMessage = 'Invalid email or password. Please check your credentials.';
          break;
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }
      
      throw FirebaseAuthException(
        code: e.code,
        message: errorMessage,
      );
    } catch (e) {
      print('Unexpected login error: $e');
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print("User signed out successfully");
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print("Sending password reset email to: $email");
      await _auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent successfully");
    } on FirebaseAuthException catch (e) {
      print('Password reset FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected password reset error: $e');
      rethrow;
    }
  }

  Future<void> resendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        print("Resending email verification to: ${user.email}");
        try {
          await user.sendEmailVerification(
            ActionCodeSettings(
              url: 'https://linkster-ad331.firebaseapp.com/__/auth/action',
              handleCodeInApp: true,
              androidPackageName: 'com.example.linkster',
              androidInstallApp: true,
              androidMinimumVersion: '12',
              iOSBundleId: 'com.example.linkster',
            ),
          );
          print("Email verification resent successfully to: ${user.email}");
        } catch (verificationError) {
          print("Error resending verification email: $verificationError");
          rethrow;
        }
      } else {
        print("User is null or email already verified");
      }
    } on FirebaseAuthException catch (e) {
      print('Email verification FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected email verification error: $e');
      rethrow;
    }
  }

  void checkFirebaseConfig() {
    print("Firebase Auth Instance: $_auth");
    print("Current User: ${_auth.currentUser}");
    print("Auth State Changes: ${_auth.authStateChanges()}");
  }
}
