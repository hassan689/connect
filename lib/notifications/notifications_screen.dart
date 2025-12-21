import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:connect/search_tasks/taskdetails.dart';
import 'package:connect/widgets/shimmer_loading.dart';
import 'package:connect/task_post/task_completion_screen.dart';
import 'package:connect/task_post/task_completion_review_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading notifications',
                style: GoogleFonts.roboto(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => ShimmerLoading.notificationItem(),
            );
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when you receive offers or updates',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final isRead = notification['isRead'] ?? false;
              final type = notification['type'] ?? 'general';
              final priority = notification['priority'] ?? 'normal';

              return _buildNotificationCard(
                notification,
                notifications[index].id,
                isRead,
                type,
                priority,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    String notificationId,
    bool isRead,
    String type,
    String priority,
  ) {
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? '';
    final timestamp = notification['timestamp'] as Timestamp?;
    final taskId = notification['taskId'];
    final offerAmount = notification['offerAmount'];

    return GestureDetector(
      onTap: () => _handleNotificationTap(notification, notificationId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0FDFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey[200]! : const Color(0xFF00C7BE).withValues(alpha: 0.3),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildNotificationIcon(type, priority),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                            color: isRead ? Colors.black87 : Colors.black,
                          ),
                        ),
                        if (timestamp != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(timestamp),
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C7BE),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              if (type == 'offer' && offerAmount != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C7BE).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00C7BE).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Offer: Rs $offerAmount',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00C7BE),
                    ),
                  ),
                ),
              ],
              // Action button for offer_accepted notifications
              if (type == 'offer_accepted' && taskId != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final taskTitle = notification['taskTitle'] ?? 'Task';
                      final taskAmount = double.tryParse(notification['taskAmount']?.toString() ?? '0') ?? 0.0;
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskCompletionScreen(
                            taskId: taskId,
                            taskTitle: taskTitle,
                            taskAmount: taskAmount,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload_file, color: Colors.white),
                    label: const Text(
                      'Upload Completion Images',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7BE),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _viewTask(taskId),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00C7BE)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'View Task Details',
                      style: GoogleFonts.roboto(
                        color: const Color(0xFF00C7BE),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else if (type == 'task_completed' && taskId != null && notification['completionImages'] != null) ...[
                // Completion images preview
                const SizedBox(height: 16),
                Text(
                  'Completion Images:',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (notification['completionImages'] as List).length,
                    itemBuilder: (context, index) {
                      final imageUrl = (notification['completionImages'] as List)[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskCompletionReviewScreen(
                                  taskId: taskId,
                                  completionImages: List<String>.from(notification['completionImages'] ?? []),
                                  completionNotes: notification['completionNotes'] ?? '',
                                  providerId: notification['providerId'] ?? '',
                                  providerName: notification['providerName'] ?? 'Service provider',
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Builder(
                              builder: (context) {
                                // Decode Base64 image
                                try {
                                  String base64Data = imageUrl.toString();
                                  if (base64Data.contains(',')) {
                                    base64Data = base64Data.split(',')[1];
                                  }
                                  final imageBytes = base64Decode(base64Data);
                                  return Image.memory(
                                    imageBytes,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  );
                                } catch (e) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskCompletionReviewScreen(
                            taskId: taskId,
                            completionImages: List<String>.from(notification['completionImages'] ?? []),
                            completionNotes: notification['completionNotes'] ?? '',
                            providerId: notification['providerId'] ?? '',
                            providerName: notification['providerName'] ?? 'Service provider',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, color: Colors.white),
                    label: const Text(
                      'Review & Approve',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7BE),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else if (taskId != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _viewTask(taskId),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00C7BE)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'View Task',
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF00C7BE),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _viewOffers(taskId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C7BE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'View Offers',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type, String priority) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'offer':
        iconData = Icons.local_offer;
        iconColor = const Color(0xFF00C7BE);
        break;
      case 'offer_accepted':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'message':
        iconData = Icons.message;
        iconColor = Colors.blue;
        break;
      case 'payment':
        iconData = Icons.payment;
        iconColor = Colors.green;
        break;
      case 'task':
        iconData = Icons.task;
        iconColor = Colors.orange;
        break;
      case 'task_completed':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final notificationTime = timestamp.toDate();
    final difference = now.difference(notificationTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, yyyy').format(notificationTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _handleNotificationTap(
    Map<String, dynamic> notification,
    String notificationId,
  ) async {
    // Mark as read
    if (!(notification['isRead'] ?? false)) {
      await _markAsRead(notificationId);
    }

    // Navigate based on notification type
    final type = notification['type'];
    final taskId = notification['taskId'];

    if (type == 'offer' && taskId != null) {
      _viewTask(taskId);
    } else if (type == 'offer_accepted' && taskId != null) {
      // Navigate to task completion screen
      final taskTitle = notification['taskTitle'] ?? 'Task';
      final taskAmount = double.tryParse(notification['taskAmount']?.toString() ?? '0') ?? 0.0;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskCompletionScreen(
            taskId: taskId,
            taskTitle: taskTitle,
            taskAmount: taskAmount,
          ),
        ),
      );
    } else if ((type == 'task_completed' || type == 'proof_uploaded') && taskId != null && notification['completionImages'] != null) {
      // Navigate to review screen for proof images
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskCompletionReviewScreen(
            taskId: taskId,
            completionImages: List<String>.from(notification['completionImages'] ?? []),
            completionNotes: notification['completionNotes'] ?? '',
            providerId: notification['providerId'] ?? '',
            providerName: notification['providerName'] ?? 'Service provider',
          ),
        ),
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Color(0xFF00C7BE),
          ),
        );
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark notifications as read'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewTask(String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(taskId: taskId),
      ),
    );
  }

  void _viewOffers(String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(taskId: taskId),
      ),
    );
  }
} 