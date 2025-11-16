import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen for service providers to upload task completion images and request payment
class TaskCompletionScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final double taskAmount;

  const TaskCompletionScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.taskAmount,
  });

  @override
  State<TaskCompletionScreen> createState() => _TaskCompletionScreenState();
}

class _TaskCompletionScreenState extends State<TaskCompletionScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _completionNotesController = TextEditingController();
  List<File> _selectedImages = [];
  bool _isSubmitting = false;
  bool _showRules = false;

  @override
  void dispose() {
    _completionNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((xFile) => File(xFile.path)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Send proof images via WhatsApp
  Future<void> _sendProofOnWhatsApp() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image to share'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get task data to get client's phone number
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();
      final taskData = taskDoc.data();
      final taskPosterId = taskData?['userId'];

      if (taskPosterId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task poster information not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get client's phone number
      final clientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(taskPosterId)
          .get();
      final clientData = clientDoc.data();
      final clientPhone = clientData?['phoneNumber'] ?? '';

      // Prepare message
      final message = 'Task Completion Proof for: ${widget.taskTitle}\n\n'
          'Please review the images and reply "Approved" if satisfied.';

      // Share images via WhatsApp
      if (clientPhone.isNotEmpty) {
        // Format phone number for WhatsApp (remove + and spaces)
        String formattedPhone = clientPhone.replaceAll(RegExp(r'[+\s]'), '');
        
        // Try to open WhatsApp with phone number
        final whatsappUrl = 'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}';
        final uri = Uri.parse(whatsappUrl);
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          
          // Share images using share_plus (will show share sheet, user can select WhatsApp)
          await Share.shareXFiles(
            _selectedImages.map((file) => XFile(file.path)).toList(),
            text: message,
            subject: 'Task Completion Proof: ${widget.taskTitle}',
          );
        } else {
          // If WhatsApp URL doesn't work, just use share_plus
          await Share.shareXFiles(
            _selectedImages.map((file) => XFile(file.path)).toList(),
            text: message,
            subject: 'Task Completion Proof: ${widget.taskTitle}',
          );
        }
      } else {
        // No phone number, just share images
        await Share.shareXFiles(
          _selectedImages.map((file) => XFile(file.path)).toList(),
          text: message,
          subject: 'Task Completion Proof: ${widget.taskTitle}',
        );
      }

      // Update Firestore - mark as pending WhatsApp approval
      await _markAsWhatsAppPending();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proof images shared! Please wait for client approval.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing on WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mark task as pending WhatsApp approval in Firestore
  Future<void> _markAsWhatsAppPending() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Update task document - status = "pending_whatsapp_approval"
      await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
        'status': 'pending_whatsapp_approval',
        'completedAt': FieldValue.serverTimestamp(),
        'completedBy': user.uid,
        'completionNotes': _completionNotesController.text.trim(),
        'completionStatus': 'pending_whatsapp_approval',
        'paymentRequested': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'proofSharedViaWhatsApp': true,
        'proofSharedAt': FieldValue.serverTimestamp(),
      });

      // Create completion document
      await FirebaseFirestore.instance
          .collection('task_completions')
          .doc(widget.taskId)
          .set({
        'taskId': widget.taskId,
        'providerId': user.uid,
        'notes': _completionNotesController.text.trim(),
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending_whatsapp_approval',
        'proofSharedViaWhatsApp': true,
      }, SetOptions(merge: true));

      // Get task poster ID for notification
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();
      final taskData = taskDoc.data();
      final taskPosterId = taskData?['userId'];

      if (taskPosterId != null) {
        // Get provider name
        final providerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final providerName = providerDoc.data()?['fullName'] ?? 
                            providerDoc.data()?['name'] ?? 
                            user.displayName ?? 
                            'Service provider';

        // Send notification to task poster
        await FirebaseFirestore.instance
            .collection('users')
            .doc(taskPosterId)
            .collection('notifications')
            .add({
          'type': 'whatsapp_proof_shared',
          'title': '📱 Proof Shared on WhatsApp',
          'body': '$providerName has shared proof images for task "${widget.taskTitle}" via WhatsApp. Please review and approve.',
          'taskId': widget.taskId,
          'taskTitle': widget.taskTitle,
          'completionNotes': _completionNotesController.text.trim(),
          'providerId': user.uid,
          'providerName': providerName,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'isRead': false,
          'actionRequired': true,
          'priority': 'high',
        });
      }
    } catch (e) {
      debugPrint('Error marking as WhatsApp pending: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }


  Future<void> _requestPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if task is completed
    final taskDoc = await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .get();
    
    if (!taskDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task not found')),
      );
      return;
    }

    final taskData = taskDoc.data()!;
    final status = taskData['status'] ?? 'open';
    final completionStatus = taskData['completionStatus'];

    // Task must be approved (status can be 'approved' or 'completed' with 'approved' completionStatus)
    if (status != 'approved' && (status != 'completed' || completionStatus != 'approved')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task must be approved before requesting payment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Update task to request payment
    await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
      'paymentRequested': true,
      'paymentRequestedAt': FieldValue.serverTimestamp(),
      'paymentStatus': 'pending',
    });

    // Send notification to task poster
    final taskPosterId = taskData['userId'];
    if (taskPosterId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(taskPosterId)
          .collection('notifications')
          .add({
        'type': 'payment_request',
        'title': 'Payment Request',
        'body': 'Service provider has requested payment for completed task "${widget.taskTitle}"',
        'taskId': widget.taskId,
        'amount': widget.taskAmount,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment request sent to task poster'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Task'),
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
              color: const Color(0xFF00C7BE).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.taskTitle,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount: ${widget.taskAmount.toStringAsFixed(0)} Points',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        color: const Color(0xFF00C7BE),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rules & Guidelines Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.orange[200]!, width: 1),
              ),
              child: ExpansionTile(
                leading: Icon(Icons.rule, color: Colors.orange[700]),
                title: Text(
                  'Proof Submission Rules & Guidelines',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                subtitle: Text(
                  'Tap to view detailed instructions',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                initiallyExpanded: _showRules,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _showRules = expanded;
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem(
                          Icons.check_circle,
                          'Image Requirements',
                          '• At least one clear image showing the completed task\n'
                          '• Images should be well-lit and in focus\n'
                          '• Show the full scope of work completed\n'
                          '• Include multiple angles if applicable',
                        ),
                        const SizedBox(height: 16),
                        _buildRuleItem(
                          Icons.camera_alt,
                          'What to Include in Photos',
                          '• Clear view of the completed work\n'
                          '• Before/after comparison (if applicable)\n'
                          '• Any relevant details or close-ups\n'
                          '• Your work should be clearly visible\n'
                          '• Avoid blurry or dark images',
                        ),
                        const SizedBox(height: 16),
                        _buildRuleItem(
                          Icons.share,
                          'How to Submit Proof',
                          '• Select or take photos using the buttons below\n'
                          '• Add completion notes (optional but recommended)\n'
                          '• Click "Send Proof on WhatsApp" button\n'
                          '• Share images with the task poster via WhatsApp\n'
                          '• Wait for approval notification in the app',
                        ),
                        const SizedBox(height: 16),
                        _buildRuleItem(
                          Icons.how_to_reg,
                          'After Submission',
                          '• Task status will change to "Pending Approval"\n'
                          '• Task poster will review your proof images\n'
                          '• You will receive a notification when approved/rejected\n'
                          '• If approved, you can request payment\n'
                          '• If rejected, you may need to resubmit proof',
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_rounded, 
                                color: Colors.red[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Important: Only submit proof after completing the task. False or misleading proof may result in task rejection and account penalties.',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.red[900],
                                    fontWeight: FontWeight.w500,
                                  ),
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
            const SizedBox(height: 24),

            // Instructions
            Text(
              'Upload completion images',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take photos or upload images showing the completed task. At least one image is required.',
              style: GoogleFonts.roboto(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Image Picker Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick Images'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected Images Grid
            if (_selectedImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, size: 16, color: Colors.white),
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 24),

            // Completion Notes
            Text(
              'Completion Notes (Optional)',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _completionNotesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add any notes about the completion...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // WhatsApp Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isSubmitting || _selectedImages.isEmpty) ? null : _sendProofOnWhatsApp,
                icon: const Icon(Icons.share, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Processing...' : 'Send Proof on WhatsApp',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp green
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Share images via WhatsApp. Client will approve/reject in the app.',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF00C7BE), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

