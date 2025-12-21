import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connect/connects/notification_service.dart';
import 'package:connect/menupage/mainp.dart';
import 'package:connect/messages/universalfunctions.dart';
class PaymentRequestScreen extends StatefulWidget {
  final String taskTitle;
  final double budget;
  final String receiverId;
  final String senderId;
  final String taskId;
  final String? offerId;
  final double? offerAmount;
  final String? userName;

  const PaymentRequestScreen({
    super.key,
    required this.taskTitle,
    required this.budget,
    required this.receiverId,
    required this.senderId,
    required this.taskId,
    this.offerId,
    this.offerAmount,
    this.userName,
  });

  @override
  State<PaymentRequestScreen> createState() => _PaymentRequestScreenState();
}

class _PaymentRequestScreenState extends State<PaymentRequestScreen> {
  bool _isProcessing = false;
  String userName = '';
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final data = doc.data();
        if (data != null && data.containsKey('fullName')) {
          setState(() {
            userName = data['fullName'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }
Future<void> loadUserData() async {
    final name = await UserService.fetchUserName();
    if (name != null) {
      setState(() => userName = name);
    }
  }
  Future<void> _submitOffer() async {
    setState(() => _isProcessing = true);
    loadUserData();
    try {
      // 1. Update offer status
      if (widget.offerId != null) {
        await FirebaseFirestore.instance
            .collection('service_provider_offers')
            .doc(widget.offerId)
            .update({
          'status': 'submitted',
          'submittedAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Send notification
      await _notificationService.initialize();
      final notificationData = {
        'title': 'New Offer Received',
        'body': '${userName.isNotEmpty ? userName : 'A service provider'} has submitted an offer for your task: ${widget.taskTitle}',
        'taskId': widget.taskId,
        'offerId': widget.offerId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'offer',
        'isRead': false,
        'actionRequired': true,
      };

      // Send to receiver's notifications
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .collection('notifications')
          .add(notificationData);

      // Also store in sender's sent offers
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.senderId)
          .collection('sent_offers')
          .add(notificationData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Offer submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to MenuPage and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MenuPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit offer: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.offerAmount ?? widget.budget;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offer Submission"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.taskTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.currency_rupee,
                      label: "Your Offer",
                      value: "Rs ${amount.toStringAsFixed(2)}",
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.person,
                      label: "Task Poster",
                      value: widget.userName ?? "Task Poster",
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.description,
                      label: "Task ID",
                      value: widget.taskId.substring(0, 8),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Offer Terms
            const Text(
              "Offer Terms",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTermRow("The task poster will review your offer"),
            _buildTermRow("You'll be notified when they respond"),
            _buildTermRow("Payment will be processed upon acceptance"),
            
            const SizedBox(height: 40),
            
            // Terms and Conditions
            const Text(
              "By submitting this offer, you agree to our Terms of Service",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _submitOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7BE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        "Submit Offer",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00C7BE)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isHighlighted ? const Color(0xFF00C7BE) : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTermRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF00C7BE), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}