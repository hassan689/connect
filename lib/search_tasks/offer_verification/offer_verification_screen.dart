import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class OfferVerificationScreen extends StatefulWidget {
  final String taskId;
  final String offerAmount;

  const OfferVerificationScreen({
    super.key,
    required this.taskId,
    required this.offerAmount,
  });

  @override
  State<OfferVerificationScreen> createState() => _OfferVerificationScreenState();
}

class _OfferVerificationScreenState extends State<OfferVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLocationSet = false;
  String _currentStep = 'location'; // location, name, confirm
  String? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _fullNameController.text = data['fullName'] ?? '';
          _locationController.text = data['location'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }


  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions are permanently denied', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
        
        setState(() {
          _userLocation = address;
          _locationController.text = address;
          _isLocationSet = true;
          _currentStep = 'name';
        });
        
        _showSnackBar('Location set successfully!');
      }
    } catch (e) {
      _showSnackBar('Failed to get location: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    if (_fullNameController.text.isEmpty) {
      _showSnackBar('Please enter your full name', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('User not authenticated', isError: true);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fullName': _fullNameController.text,
        'location': _locationController.text,
        'phoneNumber': _phoneController.text.isNotEmpty ? _phoneController.text : userDoc.data()?['phoneNumber'] ?? '',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() {
        _currentStep = 'confirm';
      });

      _showSnackBar('Profile updated successfully!');
    } catch (e) {
      _showSnackBar('Failed to save data: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitOffer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('User not authenticated', isError: true);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Get task details for notification
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();

      if (!taskDoc.exists) {
        _showSnackBar('Task not found', isError: true);
        return;
      }

      final taskData = taskDoc.data()!;
      final taskPosterId = taskData['userId'];
      final taskTitle = taskData['title'] ?? 'Task';

      // Submit the offer
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .collection('offers')
          .add({
        'amount': widget.offerAmount,
        'message': 'I can complete this task as requested',
        'userId': user.uid,
        'userName': userDoc.data()?['fullName'] ?? 'Anonymous',
        'profileImageUrl': userDoc.data()?['profileImageUrl'],
        'phoneNumber': _phoneController.text.isNotEmpty ? _phoneController.text : userDoc.data()?['phoneNumber'] ?? '',
        'location': _locationController.text,
        'isPhoneVerified': false, // Phone verification removed
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Send notification to task poster
      await _sendNotificationToTaskPoster(
        taskPosterId: taskPosterId,
        taskTitle: taskTitle,
        offerAmount: widget.offerAmount,
        offererName: userDoc.data()?['fullName'] ?? 'Anonymous',
        taskId: widget.taskId,
      );

      _showSnackBar('Offer submitted successfully!');
      
      // Navigate back to task details
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context); // Go back to task details
      }
    } catch (e) {
      _showSnackBar('Failed to submit offer: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendNotificationToTaskPoster({
    required String taskPosterId,
    required String taskTitle,
    required String offerAmount,
    required String offererName,
    required String taskId,
  }) async {
    try {
      // Add notification to task poster's notifications collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(taskPosterId)
          .collection('notifications')
          .add({
        'title': 'New Offer Received! 🎉',
        'body': '$offererName has submitted an offer of Rs $offerAmount for your task: "$taskTitle"',
        'type': 'offer',
        'taskId': taskId,
        'senderId': FirebaseAuth.instance.currentUser?.uid,
        'senderName': offererName,
        'offerAmount': offerAmount,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'priority': 'high',
      });

      // Update task with offer count
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({
        'offerCount': FieldValue.increment(1),
        'lastOfferAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notification sent to task poster: $taskPosterId');
    } catch (e) {
      print('❌ Error sending notification: $e');
      // Don't fail the offer submission if notification fails
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : const Color(0xFF00C7BE),
        ),
      );
    }
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Step 1: Set Your Location',
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00C7BE),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We need your location for task coordination',
          style: GoogleFonts.roboto(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Your Location',
            hintText: 'Enter your current location',
            prefixIcon: const Icon(Icons.location_on, color: Color(0xFF00C7BE)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00C7BE), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _getCurrentLocation,
            icon: const Icon(Icons.my_location, color: Colors.white),
            label: Text(
              _isLoading ? 'Getting Location...' : 'Use Current Location',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C7BE),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_isLocationSet) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Location set: $_userLocation',
                    style: GoogleFonts.roboto(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Step 2: Confirm Your Name',
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00C7BE),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please confirm your full name for the offer',
          style: GoogleFonts.roboto(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _fullNameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: const Icon(Icons.person, color: Color(0xFF00C7BE)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00C7BE), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C7BE),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Save & Continue',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Step 3: Confirm Offer',
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00C7BE),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your information and submit the offer',
          style: GoogleFonts.roboto(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildInfoRow('Offer Amount', 'Rs ${widget.offerAmount}'),
              const SizedBox(height: 12),
              _buildInfoRow('Full Name', _fullNameController.text),
              const SizedBox(height: 12),
              _buildInfoRow('Location', _locationController.text),
            ],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C7BE),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Submit Offer',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Offer Verification',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildProgressStep('Location', _currentStep == 'location' || _currentStep == 'name' || _currentStep == 'confirm'),
                  _buildProgressLine(_currentStep == 'name' || _currentStep == 'confirm'),
                  _buildProgressStep('Name', _currentStep == 'name' || _currentStep == 'confirm'),
                  _buildProgressLine(_currentStep == 'confirm'),
                  _buildProgressStep('Confirm', _currentStep == 'confirm'),
                ],
              ),
            ),
            
            // Step content
            if (_currentStep == 'location') _buildLocationStep(),
            if (_currentStep == 'name') _buildNameStep(),
            if (_currentStep == 'confirm') _buildConfirmStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(String label, bool isCompleted) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFF00C7BE) : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: isCompleted ? const Color(0xFF00C7BE) : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isCompleted) {
    return Container(
      height: 2,
      width: 20,
      color: isCompleted ? const Color(0xFF00C7BE) : Colors.grey[300],
    );
  }
} 