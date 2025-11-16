import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Screen for task poster to review completion images and approve/reject
class TaskCompletionReviewScreen extends StatefulWidget {
  final String taskId;
  final List<String> completionImages;
  final String completionNotes;
  final String providerId;
  final String providerName;

  const TaskCompletionReviewScreen({
    super.key,
    required this.taskId,
    required this.completionImages,
    required this.completionNotes,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<TaskCompletionReviewScreen> createState() => _TaskCompletionReviewScreenState();
}

class _TaskCompletionReviewScreenState extends State<TaskCompletionReviewScreen> {
  bool _isLoading = false;
  int _selectedImageIndex = 0;

  /// Decode Base64 string to Uint8List for image display
  Uint8List? _decodeBase64Image(String base64String) {
    try {
      // Handle data URI format: "data:image/jpeg;base64,..."
      String base64Data = base64String;
      if (base64String.contains(',')) {
        base64Data = base64String.split(',')[1];
      }
      return base64Decode(base64Data);
    } catch (e) {
      debugPrint('Error decoding Base64 image: $e');
      return null;
    }
  }

  Future<void> _approveCompletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Completion'),
        content: const Text('Are you satisfied with the task completion? This will allow the service provider to request payment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Get task data for task title
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();
      final taskData = taskDoc.data();
      final taskTitle = taskData?['title'] ?? 'Task';

      // Update task status to "approved"
      await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
        'status': 'approved',
        'completionStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update task_completions document
      await FirebaseFirestore.instance
          .collection('task_completions')
          .doc(widget.taskId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Get provider's FCM token
      final providerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.providerId)
          .get();
      final providerData = providerDoc.data();
      final fcmToken = providerData?['fcmToken'];

      // Send Firestore notification (in-app)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.providerId)
          .collection('notifications')
          .add({
        'type': 'completion_approved',
        'title': '✅ Proof Approved!',
        'body': 'Your proof images for "$taskTitle" have been approved. You can now request payment.',
        'taskId': widget.taskId,
        'taskTitle': taskTitle,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'isRead': false,
        'priority': 'high',
      });

      // Send FCM push notification to worker
      if (fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('notification_requests')
            .add({
          'receiverToken': fcmToken,
          'title': '✅ Proof Approved!',
          'body': 'Your proof images for "$taskTitle" have been approved. You can now request payment.',
          'data': {
            'type': 'completion_approved',
            'taskId': widget.taskId,
            'route': '/task/$widget.taskId',
          },
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task completion approved! Service provider can now request payment.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving completion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectCompletion() async {
    final TextEditingController reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Completion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Get task data for task title
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();
      final taskData = taskDoc.data();
      final taskTitle = taskData?['title'] ?? 'Task';
      final rejectionReason = reasonController.text.trim();

      // Update task status to "rejected" and reset to "assigned" so worker can resubmit
      await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
        'status': 'assigned', // Reset to assigned so worker can resubmit
        'completionStatus': 'rejected',
        'rejectionReason': rejectionReason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Clear completion images so worker can upload new ones
        'completionImages': FieldValue.delete(),
        'completionNotes': FieldValue.delete(),
      });

      // Update task_completions document
      await FirebaseFirestore.instance
          .collection('task_completions')
          .doc(widget.taskId)
          .update({
        'status': 'rejected',
        'rejectionReason': rejectionReason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Get provider's FCM token
      final providerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.providerId)
          .get();
      final providerData = providerDoc.data();
      final fcmToken = providerData?['fcmToken'];

      // Send Firestore notification (in-app)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.providerId)
          .collection('notifications')
          .add({
        'type': 'completion_rejected',
        'title': '❌ Proof Rejected',
        'body': 'Your proof images for "$taskTitle" were rejected. Reason: $rejectionReason',
        'taskId': widget.taskId,
        'taskTitle': taskTitle,
        'rejectionReason': rejectionReason,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'isRead': false,
        'priority': 'high',
      });

      // Send FCM push notification to worker
      if (fcmToken != null) {
        await FirebaseFirestore.instance
            .collection('notification_requests')
            .add({
          'receiverToken': fcmToken,
          'title': '❌ Proof Rejected',
          'body': 'Your proof images for "$taskTitle" were rejected. Please upload new proof images.',
          'data': {
            'type': 'completion_rejected',
            'taskId': widget.taskId,
            'route': '/task/$widget.taskId',
          },
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task completion rejected. Service provider has been notified.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting completion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Completion'),
        backgroundColor: const Color(0xFF00C7BE),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider Info
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Completed by:',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  widget.providerName,
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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

                  // Completion Images
                  Text(
                    'Completion Images (${widget.completionImages.length})',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Main Image Viewer
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PageView.builder(
                        itemCount: widget.completionImages.length,
                        onPageChanged: (index) {
                          setState(() {
                            _selectedImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          // Decode Base64 image
                          final imageBytes = _decodeBase64Image(widget.completionImages[index]);
                          if (imageBytes == null) {
                            return const Center(
                              child: Icon(Icons.broken_image, size: 50),
                            );
                          }
                          return Image.memory(
                            imageBytes,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Image Indicators
                  if (widget.completionImages.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.completionImages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedImageIndex == index
                                ? const Color(0xFF00C7BE)
                                : Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Thumbnail Grid
                  if (widget.completionImages.length > 1)
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.completionImages.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImageIndex = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedImageIndex == index
                                      ? const Color(0xFF00C7BE)
                                      : Colors.grey[300]!,
                                  width: _selectedImageIndex == index ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Builder(
                                  builder: (context) {
                                    // Decode Base64 image for thumbnail
                                    final imageBytes = _decodeBase64Image(widget.completionImages[index]);
                                    if (imageBytes == null) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image),
                                      );
                                    }
                                    return Image.memory(
                                      imageBytes,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Completion Notes
                  if (widget.completionNotes.isNotEmpty) ...[
                    Text(
                      'Completion Notes',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        widget.completionNotes,
                        style: GoogleFonts.roboto(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _rejectCompletion,
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text(
                            'Reject',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _approveCompletion,
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            'Approve',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
}

