import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connect/services/points_service.dart';

/// Payment Confirmation Screen - Shows payment details before processing
class PaymentConfirmationScreen extends StatefulWidget {
  final String taskId;
  final String providerId;
  final String taskTitle;
  final double taskAmount;
  final String? providerName;

  const PaymentConfirmationScreen({
    super.key,
    required this.taskId,
    required this.providerId,
    required this.taskTitle,
    required this.taskAmount,
    this.providerName,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  bool _isProcessing = false;
  final PointsService _pointsService = PointsService();

  @override
  Widget build(BuildContext context) {
    // Use configured commission rates from PointsService
    final commissionCalculation = PointsService.calculateCommission(widget.taskAmount);
    final platformCommission = commissionCalculation['platformCommission']!;
    final providerPayout = commissionCalculation['providerPayout']!;
    
    // Get percentage rates for display
    final platformCommissionRate = PointsService.platformCommissionRate;
    final providerPayoutRate = PointsService.providerPayoutRate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
        backgroundColor: const Color(0xFF00C7BE),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.task, color: Color(0xFF00C7BE)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Task Details',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.taskTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Service Provider: ${widget.providerName ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Breakdown Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, color: Color(0xFF00C7BE)),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Breakdown',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentRow(
                      'Task Points',
                      '${widget.taskAmount.toStringAsFixed(0)} Points',
                      isTotal: false,
                    ),
                    const Divider(),
                    _buildPaymentRow(
                      'Platform Commission (${(platformCommissionRate * 100).toStringAsFixed(0)}%)',
                      '-${platformCommission.toStringAsFixed(0)} Points',
                      isTotal: false,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentRow(
                      'Provider Payout (${(providerPayoutRate * 100).toStringAsFixed(0)}%)',
                      '${providerPayout.toStringAsFixed(0)} Points',
                      isTotal: false,
                      color: Colors.green,
                    ),
                    const Divider(height: 24),
                    _buildPaymentRow(
                      'Total Deduction',
                      '${widget.taskAmount.toStringAsFixed(0)} Points',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payment, color: Color(0xFF00C7BE)),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Method',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Points Payment',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Points will be deducted from your account',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Warning Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Ensure you have sufficient points in your account\n'
                          '• Points will be deducted immediately\n'
                          '• Provider will receive ${(providerPayoutRate * 100).toStringAsFixed(0)}% of the points\n'
                          '• Platform commission is ${(platformCommissionRate * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7BE),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Confirm Payment',
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
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String amount, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: color ?? const Color(0xFF00C7BE),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    // Check wallet balance first
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('User not authenticated');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Check wallet balance
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Check points balance
      final currentPoints = await _pointsService.getUserPoints(user.uid);

      if (currentPoints < widget.taskAmount) {
        setState(() => _isProcessing = false);
        _showInsufficientPointsDialog(currentPoints);
        return;
      }

      // Process payment with commission
      final result = await _pointsService.processTaskPayment(
        taskId: widget.taskId,
        providerId: widget.providerId,
        taskPoints: widget.taskAmount,
      );

      setState(() => _isProcessing = false);

      if (result['success'] == true) {
        // Update payment status
        await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
          'paymentStatus': 'paid',
          'paymentReleasedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ Payment Processed Successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Platform Commission: ${result['platformCommission'].toStringAsFixed(0)} Points\n'
                    'Provider Payout: ${result['providerPayout'].toStringAsFixed(0)} Points',
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.pop(context, true); // Return success
        }
      } else {
        _showError(result['error'] ?? 'Payment failed');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error processing payment: $e');
    }
  }

  void _showInsufficientPointsDialog(double currentPoints) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your current points balance is insufficient.'),
            const SizedBox(height: 8),
            Text('Current Points: ${currentPoints.toStringAsFixed(0)}'),
            Text('Required Points: ${widget.taskAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            const Text('Please earn more points before proceeding.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

