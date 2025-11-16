import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MobileVerificationScreen extends StatefulWidget {
  const MobileVerificationScreen({super.key});

  @override
  State<MobileVerificationScreen> createState() => _MobileVerificationScreenState();
}

class _MobileVerificationScreenState extends State<MobileVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSendingCode = false;
  bool _isPhoneValid = false;
  bool _isVerifying = false;
  String? _verificationId;
  int? _resendToken;
  bool _showOtpField = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
  }

  void _validatePhone() {
    final phone = _phoneController.text.trim();
    // Pakistani phone number format: +92XXXXXXXXXX
    final isValid = phone.startsWith('+92') && phone.length == 13;
    
    setState(() {
      _isPhoneValid = isValid;
    });

    // Auto-send OTP when valid Pakistani number is entered
    if (isValid && !_isSendingCode && !_showOtpField) {
      _sendVerificationCode();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    String phone = _phoneController.text.trim();

    setState(() {
      _isSendingCode = true;
      _showOtpField = false;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _verifyPhoneNumberWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _handleVerificationError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _showOtpField = true;
            _isSendingCode = false;
          });
          _showSuccessMessage();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _isSendingCode = false);
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      setState(() => _isSendingCode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit code')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );

      await _verifyPhoneNumberWithCredential(credential);
    } catch (e) {
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _verifyPhoneNumberWithCredential(PhoneAuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);
      await _savePhoneNumber(_phoneController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number verified! Your account is now secure.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(_phoneController.text.trim());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying phone: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _handleVerificationError(FirebaseAuthException e) {
    String errorMessage = 'Verification failed. Please try again.';
    
    switch (e.code) {
      case 'invalid-phone-number':
        errorMessage = 'Please enter a valid Pakistani phone number (+92XXXXXXXXXX)';
        break;
      case 'quota-exceeded':
        errorMessage = 'SMS quota exceeded. Try again later.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many requests. Please wait before trying again.';
        break;
      default:
        errorMessage = 'Error: ${e.message}';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      setState(() => _isSendingCode = false);
    }
  }

  Future<void> _savePhoneNumber(String phone) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'phoneNumber': phone, 
          'phoneVerified': true,
          'lastVerified': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification code sent to your phone number'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          'Phone Verification',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // JazzCash Icon and Title
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C7BE).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 48,
                      color: Color(0xFF00C7BE),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Verify Your Phone Number',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            const Text(
              'Enter your registered phone number',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'This number will be used for sending and receiving payments',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // Phone Input Field
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+92XXXXXXXXXX',
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: _isPhoneValid 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                labelText: 'Phone Number',
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Send Code Button
            if (!_showOtpField) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isPhoneValid && !_isSendingCode ? _sendVerificationCode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPhoneValid && !_isSendingCode
                        ? const Color(0xFF00C7BE)
                        : Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSendingCode
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Send Verification Code'),
                ),
              ),
            ],
            
            // OTP Section
            if (_showOtpField) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Enter the 6-digit verification code',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: '123456',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                autofocus: true,
                onSubmitted: (_) => _verifyOtp(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C7BE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Verify Phone Number'),
                ),
              ),
              TextButton(
                onPressed: _isSendingCode 
                    ? null 
                    : () {
                        _sendVerificationCode();
                        _otpController.clear();
                      },
                child: const Text('Resend Code'),
              ),
            ],
            
            // Benefits Section
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00C7BE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Benefits of Verified Phone Number:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem('Send payments to other users'),
                  _buildBenefitItem('Receive payments for completed tasks'),
                  _buildBenefitItem('Secure and instant transactions'),
                  _buildBenefitItem('No additional fees for transfers'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF00C7BE),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
