import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:linkster/connects/address.dart';
import 'package:linkster/connects/bankaccount.dart';
import 'package:linkster/connects/dateofbirth.dart';
import 'package:linkster/connects/notification_service.dart';
import 'package:linkster/connects/phone_no.dart';
import 'package:linkster/connects/request.dart';

class ConnectScreen extends StatefulWidget {
  final String taskId;

  const ConnectScreen({super.key, required this.taskId});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final Map<String, dynamic> userData = {};
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveUserDataToFirestore() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set(userData, SetOptions(merge: true));
  }

  Future<void> _navigateAndStore(BuildContext context, Widget screen, String fieldKey) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    if (result != null && mounted) {
      setState(() {
        userData[fieldKey] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRequiredFieldsCompleted = [
      'bankAccount',
      'billingAddress',
      'dateOfBirth',
      'phoneNumber',
    ].every((field) => userData.containsKey(field)) && 
    _amountController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm your offer"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input Field
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Your Offer Amount (Rs)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.currency_rupee),
                  suffixIcon: _amountController.text.isNotEmpty
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            
            // Required Information Sections
            _buildOption(
              icon: Icons.account_balance,
              text: "Provide bank account",
              onTap: () => _navigateAndStore(context, const AddBankAccountScreen(), 'bankAccount'),
              isCompleted: userData.containsKey('bankAccount'),
            ),
            _buildOption(
              icon: Icons.location_on,
              text: "Provide a billing address",
              onTap: () => _navigateAndStore(context, const BillingAddressScreen(), 'billingAddress'),
              isCompleted: userData.containsKey('billingAddress'),
            ),
            _buildOption(
              icon: Icons.calendar_today,
              text: "Provide a date of birth",
              onTap: () => _navigateAndStore(context, const DateOfBirthScreen(), 'dateOfBirth'),
              isCompleted: userData.containsKey('dateOfBirth'),
            ),
            _buildOption(
              icon: Icons.phone,
              text: "Provide your mobile number",
              onTap: () => _navigateAndStore(context, MobileVerificationScreen(), 'phoneNumber'),
              isCompleted: userData.containsKey('phoneNumber'),
            ),
            
            const SizedBox(height: 20),
            if (!allRequiredFieldsCompleted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Please complete all required fields to send your offer',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: !_isLoading && allRequiredFieldsCompleted
              ? () async {
                  setState(() => _isLoading = true);
                  final currentUser = FirebaseAuth.instance.currentUser;
                  final notificationService = NotificationService();
                  await notificationService.initialize();
                  
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You must be logged in.')),
                    );
                    setState(() => _isLoading = false);
                    return;
                  }

                  try {
                    // 1. Save user info to Firestore
                    await _saveUserDataToFirestore();

                    // 2. Get task document
                    final taskDoc = await FirebaseFirestore.instance
                        .collection('tasks')
                        .doc(widget.taskId)
                        .get();

                    if (!taskDoc.exists || !taskDoc.data()!.containsKey('userId')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task data is incomplete.')),
                      );
                      setState(() => _isLoading = false);
                      return;
                    }

                    final taskData = taskDoc.data()!;
                    final taskPosterId = taskData['userId'];
                    final String taskTitle = taskData['title'] ?? 'No Title';
                    final double budget =
                        double.tryParse(taskData['budget'] ?? '0') ?? 0.0;
                    final double offerAmount = double.tryParse(_amountController.text) ?? 0.0;

                    // 3. Save offer to service_provider_offers collection
                    final offerRef = await FirebaseFirestore.instance
                        .collection('service_provider_offers')
                        .add({
                      'taskId': widget.taskId,
                      'senderId': currentUser.uid,
                      'receiverId': taskPosterId,
                      'amount': offerAmount,
                      'timestamp': FieldValue.serverTimestamp(),
                      'status': 'pending',
                      'senderBankAccount': userData['bankAccount'],
                      'senderBillingAddress': userData['billingAddress'],
                      'senderPhone': userData['phoneNumber'],
                    });

                    // 4. Send notification
                    await notificationService.sendTestNotification();
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(taskPosterId)
                        .collection('notifications')
                        .add({
                          'title': 'New Offer Received',
                          'body': 'You have received a new offer of Rs $offerAmount for your task: $taskTitle',
                          'taskId': widget.taskId,
                          'offerId': offerRef.id,
                          'senderId': currentUser.uid,
                          'timestamp': FieldValue.serverTimestamp(),
                          'type': 'offer',
                          'isRead': false,
                          'route': '/offer?taskId=${widget.taskId}&offerId=${offerRef.id}',
                        });

                    // 5. Navigate to Payment
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentRequestScreen(
                            taskTitle: taskTitle,
                            budget: budget,
                            receiverId: taskPosterId,
                            senderId: currentUser.uid,
                            taskId: widget.taskId,
                            offerId: offerRef.id,
                            offerAmount: offerAmount,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error sending offer: $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: allRequiredFieldsCompleted
                ? const Color(0xFF00C7BE)
                : Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Send Offer"),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required bool isCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isCompleted ? const Color(0xFF00C7BE) : Colors.grey[600],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isCompleted ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}