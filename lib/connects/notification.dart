import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:linkster/profilepage/payment_settings.dart';
import 'package:linkster/messaging/message_requests_screen.dart';
import 'package:linkster/messaging/chat_screen.dart';
import 'package:linkster/task_post/task_completion_screen.dart';
import 'package:linkster/task_post/task_completion_review_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isMarkingAllRead = false;

  Future<void> _markAllAsRead() async {
    setState(() => _isMarkingAllRead = true);
    try {
      final notifications = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Color(0xFF00C7BE),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking all as read: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingAllRead = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: _isMarkingAllRead
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C7BE)),
                      ),
                    )
                  : const Icon(Icons.mark_email_read_outlined),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C7BE)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Please try again later',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C7BE).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: Color(0xFF00C7BE),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your notifications will appear here',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp']?.toDate();
              final isRead = data['isRead'] ?? false;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_forever, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'Delete Notification',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      content: Text(
                        'Are you sure you want to delete this notification?',
                        style: GoogleFonts.inter(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(color: Colors.grey[600]),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            'Delete',
                            style: GoogleFonts.inter(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  doc.reference.delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification deleted'),
                      backgroundColor: Color(0xFF00C7BE),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (!isRead)
                        BoxShadow(
                          color: const Color(0xFF00C7BE).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                    border: !isRead
                        ? Border.all(
                            color: const Color(0xFF00C7BE).withOpacity(0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isRead
                                ? Colors.grey[200]
                                : const Color(0xFF00C7BE),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getNotificationIcon(data['type']),
                            color: isRead ? Colors.grey[600] : Colors.white,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          data['title'] ?? 'Notification',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              data['body'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (timestamp != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy - hh:mm a')
                                        .format(timestamp),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        trailing: !isRead
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00C7BE),
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        onTap: () {
                          if (!isRead) {
                            doc.reference.update({'isRead': true});
                          }

                          final type = data['type'];
                          
                          switch (type) {
                            case 'offer':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OfferDetailsScreen(
                                    taskId: data['taskId'],
                                    senderId: data['senderId'],
                                    notificationId: doc.id,
                                  ),
                                ),
                              );
                              break;
                            case 'offer_accepted':
                              // Navigate to task completion screen
                              final taskId = data['taskId'];
                              final taskTitle = data['taskTitle'] ?? 'Task';
                              final taskAmount = double.tryParse(data['taskAmount']?.toString() ?? '0') ?? 0.0;
                              
                              if (taskId != null) {
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
                              }
                              break;
                            case 'message_request':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MessageRequestsScreen(),
                                ),
                              );
                              break;
                            case 'message_request_accepted':
                              if (data['fromUserId'] != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      otherUserId: data['fromUserId'],
                                      otherUserName: data['senderName'] ?? 'Anonymous',
                                    ),
                                  ),
                                );
                              }
                              break;
                            case 'message':
                              if (data['chatId'] != null && data['fromUserId'] != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      otherUserId: data['fromUserId'],
                                      otherUserName: data['senderName'] ?? 'Anonymous',
                                    ),
                                  ),
                                );
                              }
                              break;
                            default:
                              // Handle other notification types
                              break;
                          }
                        },
                      ),
                      // Action button for offer_accepted notifications
                      if (data['type'] == 'offer_accepted')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (!isRead) {
                                  doc.reference.update({'isRead': true});
                                }
                                
                                final taskId = data['taskId'];
                                final taskTitle = data['taskTitle'] ?? 'Task';
                                final taskAmount = double.tryParse(data['taskAmount']?.toString() ?? '0') ?? 0.0;
                                
                                if (taskId != null) {
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
                                }
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Completion images preview for task_completed notifications
                      if (data['type'] == 'task_completed' && data['completionImages'] != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Completion Images:',
                                style: GoogleFonts.inter(
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
                                  itemCount: (data['completionImages'] as List).length,
                                  itemBuilder: (context, index) {
                                    final imageUrl = (data['completionImages'] as List)[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: () {
                                          // Navigate to review screen
                                          final taskId = data['taskId'];
                                          if (taskId != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => TaskCompletionReviewScreen(
                                                  taskId: taskId,
                                                  completionImages: List<String>.from(data['completionImages'] ?? []),
                                                  completionNotes: data['completionNotes'] ?? '',
                                                  providerId: data['providerId'],
                                                  providerName: data['providerName'] ?? 'Service provider',
                                                ),
                                              ),
                                            );
                                          }
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
                                    if (!isRead) {
                                      doc.reference.update({'isRead': true});
                                    }
                                    
                                    final taskId = data['taskId'];
                                    if (taskId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TaskCompletionReviewScreen(
                                            taskId: taskId,
                                            completionImages: List<String>.from(data['completionImages'] ?? []),
                                            completionNotes: data['completionNotes'] ?? '',
                                            providerId: data['providerId'],
                                            providerName: data['providerName'] ?? 'Service provider',
                                          ),
                                        ),
                                      );
                                    }
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
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
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
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'offer':
        return Icons.local_offer_rounded;
      case 'offer_accepted':
        return Icons.check_circle_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'task_completed':
        return Icons.task_alt_rounded;
      case 'message':
        return Icons.message_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
class OfferDetailsScreen extends StatefulWidget {
  final String taskId;
  final String senderId;
  final String notificationId;

  const OfferDetailsScreen({
    super.key,
    required this.taskId,
    required this.senderId,
    required this.notificationId,
  });

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  late Future<Map<String, dynamic>> _offerDetailsFuture;
  bool _isLoading = false;
  bool _showPaymentOptions = false;
  String? _selectedPaymentOption;

  @override
  void initState() {
    super.initState();
    _offerDetailsFuture = _loadOfferDetails();
  }

  Future<Map<String, dynamic>> _loadOfferDetails() async {
    try {
      // 1. Get task details
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .get();
      
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }

      // 2. Get sender details
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.senderId)
          .get();

      // 3. Get offer details - check multiple collections
      Map<String, dynamic>? offerData;
      
      // First, check service_provider_offers collection
      var offerQuery = await FirebaseFirestore.instance
          .collection('service_provider_offers')
          .where('taskId', isEqualTo: widget.taskId)
          .where('senderId', isEqualTo: widget.senderId)
          .limit(1)
          .get();
      
      if (offerQuery.docs.isNotEmpty) {
        offerData = offerQuery.docs.first.data();
        offerData['offerId'] = offerQuery.docs.first.id;
        offerData['collection'] = 'service_provider_offers';
      } else {
        // Check tasks/{taskId}/offers subcollection
        offerQuery = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskId)
            .collection('offers')
            .where('userId', isEqualTo: widget.senderId)
            .limit(1)
            .get();
        
        if (offerQuery.docs.isNotEmpty) {
          offerData = offerQuery.docs.first.data();
          offerData['offerId'] = offerQuery.docs.first.id;
          offerData['collection'] = 'tasks_offers';
          offerData['senderId'] = widget.senderId; // Add senderId for consistency
        } else {
          // Check offers collection (legacy)
          offerQuery = await FirebaseFirestore.instance
              .collection('offers')
              .where('taskId', isEqualTo: widget.taskId)
              .where('senderId', isEqualTo: widget.senderId)
              .limit(1)
              .get();
          
          if (offerQuery.docs.isNotEmpty) {
            offerData = offerQuery.docs.first.data();
            offerData['offerId'] = offerQuery.docs.first.id;
            offerData['collection'] = 'offers';
          }
        }
      }

      return {
        'task': taskDoc.data(),
        'sender': senderDoc.data(),
        'offer': offerData,
      };
    } catch (e) {
      throw Exception('Failed to load offer details: $e');
    }
  }

  Future<void> _sendNotificationToSender({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final taskData = (await _offerDetailsFuture)['task'];
      final taskTitle = taskData['title'] ?? 'Task';
      final taskAmount = taskData['budget'] ?? '0';
      
      // Send notification to sender's notifications collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.senderId)
          .collection('notifications')
          .add({
        'title': '🎉 Offer Accepted!',
        'body': 'Your offer for "$taskTitle" has been accepted! Complete the task and upload photos to receive payment.',
        'type': 'offer_accepted',
        'taskId': widget.taskId,
        'taskTitle': taskTitle,
        'taskAmount': taskAmount,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'actionRequired': true,
        'actionText': 'Complete Task',
        'priority': 'high',
      });
      
      debugPrint('✅ Notification sent to service provider: ${widget.senderId}');
    } catch (e) {
      debugPrint('❌ Error sending notification to sender: $e');
    }
  }

  Future<void> _acceptOffer() async {
    if (!_showPaymentOptions) {
      setState(() => _showPaymentOptions = true);
      return;
    }

    if (_selectedPaymentOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment option'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Get offer details from loaded data
      final offerData = (await _offerDetailsFuture)['offer'];
      final offerCollection = offerData?['collection'] as String?;
      final offerId = offerData?['offerId'] as String?;
      
      // 2. Update offer status based on which collection it's in
      if (offerCollection == 'service_provider_offers' && offerId != null) {
        await FirebaseFirestore.instance
            .collection('service_provider_offers')
            .doc(offerId)
            .update({
          'status': 'accepted',
          'paymentOption': _selectedPaymentOption,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      } else if (offerCollection == 'tasks_offers' && offerId != null) {
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskId)
            .collection('offers')
            .doc(offerId)
            .update({
          'status': 'accepted',
          'paymentOption': _selectedPaymentOption,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      } else if (offerCollection == 'offers' && offerId != null) {
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(offerId)
            .update({
          'status': 'accepted',
          'paymentOption': _selectedPaymentOption,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Fallback: Try to find offer in service_provider_offers
        final offerQuery = await FirebaseFirestore.instance
            .collection('service_provider_offers')
            .where('taskId', isEqualTo: widget.taskId)
            .where('senderId', isEqualTo: widget.senderId)
            .limit(1)
            .get();

        if (offerQuery.docs.isEmpty) {
          // Try tasks/{taskId}/offers subcollection
          final taskOfferQuery = await FirebaseFirestore.instance
              .collection('tasks')
              .doc(widget.taskId)
              .collection('offers')
              .where('userId', isEqualTo: widget.senderId)
              .limit(1)
              .get();
          
          if (taskOfferQuery.docs.isEmpty) {
            throw Exception('Offer not found in any collection');
          }
          
          await taskOfferQuery.docs.first.reference.update({
            'status': 'accepted',
            'paymentOption': _selectedPaymentOption,
            'acceptedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await offerQuery.docs.first.reference.update({
            'status': 'accepted',
            'paymentOption': _selectedPaymentOption,
            'acceptedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 3. Update task status
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .update({
        'status': 'assigned',
        'assignedTo': widget.senderId,
        'paymentOption': _selectedPaymentOption,
        'paymentStatus': 'pending',
        'assignedAt': FieldValue.serverTimestamp(),
      });

      // 4. Delete notification
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('notifications')
            .doc(widget.notificationId)
            .delete();
      }

      // 5. Send notification to sender
      final taskData = (await _offerDetailsFuture)['task'];
      await _sendNotificationToSender(
        title: 'Offer Accepted!',
        body: 'Your offer for "${taskData['title']}" has been accepted.',
        type: 'offer_accepted',
      );

      // 6. Reject all other offers for this task
      await _rejectOtherOffers();

      // 7. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer accepted successfully'),
            backgroundColor: Color(0xFF00C7BE),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // 8. Navigate back
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting offer: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectOtherOffers() async {
    try {
      // Reject offers from service_provider_offers collection
      final serviceProviderOffers = await FirebaseFirestore.instance
          .collection('service_provider_offers')
          .where('taskId', isEqualTo: widget.taskId)
          .where('senderId', isNotEqualTo: widget.senderId)
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in serviceProviderOffers.docs) {
        batch.update(doc.reference, {'status': 'rejected'});
      }

      // Reject offers from tasks/{taskId}/offers subcollection
      final taskOffers = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .collection('offers')
          .where('userId', isNotEqualTo: widget.senderId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in taskOffers.docs) {
        batch.update(doc.reference, {'status': 'rejected'});
      }

      // Reject offers from offers collection (legacy)
      final legacyOffers = await FirebaseFirestore.instance
          .collection('offers')
          .where('taskId', isEqualTo: widget.taskId)
          .where('senderId', isNotEqualTo: widget.senderId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in legacyOffers.docs) {
        batch.update(doc.reference, {'status': 'rejected'});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error rejecting other offers: $e');
    }
  }

  Future<void> _rejectOffer() async {
    final TextEditingController messageController = TextEditingController();
    final bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Reject Offer',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you like to send a message to the sender?',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Optional feedback message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00C7BE)),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Reject',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      // 1. Update offer status
      final offerQuery = await FirebaseFirestore.instance
          .collection('service_provider_offers')
          .where('taskId', isEqualTo: widget.taskId)
          .where('senderId', isEqualTo: widget.senderId)
          .limit(1)
          .get();

      if (offerQuery.docs.isEmpty) {
        throw Exception('Offer not found');
      }

      await offerQuery.docs.first.reference.update({
        'status': 'rejected',
        'rejectionMessage': messageController.text.isNotEmpty 
            ? messageController.text 
            : null,
      });

      // 2. Delete notification
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('notifications_requests')
            .doc(widget.notificationId)
            .delete();
      }

      // 3. Send notification to sender
      final taskData = (await _offerDetailsFuture)['task'];
      await _sendNotificationToSender(
        title: 'Offer Rejected',
        body: messageController.text.isNotEmpty
            ? 'Your offer for "${taskData['title']}" was rejected with the following feedback: ${messageController.text}'
            : 'Your offer for "${taskData['title']}" was rejected.',
        type: 'offer_rejected',
      );

      // 4. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer rejected'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // 5. Navigate back
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting offer: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Offer Details',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_isLoading)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C7BE)),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _offerDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C7BE)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading offer details',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Please try again later',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _offerDetailsFuture = _loadOfferDetails();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7BE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'No offer details available',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final task = data['task'] as Map<String, dynamic>? ?? {};
          final sender = data['sender'] as Map<String, dynamic>? ?? {};
          final offer = data['offer'] as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Details Section
                _buildSectionCard(
                  'Task Details',
                  Icons.work_rounded,
                  [
                    _buildDetailItem(
                      Icons.title_rounded,
                      'Title',
                      task['title'] ?? 'N/A',
                    ),
                    _buildDetailItem(
                      Icons.description_rounded,
                      'Description',
                      task['description'] ?? 'N/A',
                    ),
                    _buildDetailItem(
                      Icons.currency_rupee,
                      'Budget',
                      'Rs ${task['budget'] ?? 'N/A'}',
                    ),
                    _buildDetailItem(
                      Icons.category_rounded,
                      'Category',
                      task['category'] ?? 'Not specified',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sender Details Section
                _buildSectionCard(
                  'Sender Details',
                  Icons.person_rounded,
                  [
                    _buildDetailItem(
                      Icons.badge_rounded,
                      'Name',
                      sender['name'] ?? 'Unknown',
                    ),
                    _buildDetailItem(
                      Icons.email_rounded,
                      'Email',
                      sender['email'] ?? 'N/A',
                    ),
                    if (sender['phone'] != null)
                      _buildDetailItem(
                        Icons.phone_rounded,
                        'Phone',
                        sender['phone'],
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Offer Details Section
                _buildSectionCard(
                  'Offer Details',
                  Icons.local_offer_rounded,
                  [
                    _buildDetailItem(
                      Icons.info_rounded,
                      'Status',
                      (offer['status'] ?? 'submitted').toString().toUpperCase(),
                    ),
                    if (offer['timestamp'] != null)
                      _buildDetailItem(
                        Icons.access_time_rounded,
                        'Sent on',
                        DateFormat('MMM dd, yyyy - hh:mm a')
                            .format(offer['timestamp'].toDate()),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Payment Options Section
                _buildSectionCard(
                  'Payment Options',
                  Icons.payment_rounded,
                  [
                    RadioListTile<String>(
                      title: Text(
                        'Release Payment Now',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Funds will be released to the sender immediately',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                      ),
                      value: 'release_now',
                      groupValue: _selectedPaymentOption,
                      activeColor: const Color(0xFF00C7BE),
                      onChanged: (value) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PaymentSettingsScreen()),
                        );
                        setState(() => _selectedPaymentOption = value);
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(
                        'Hold Payment Until Completion',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Funds will be held until you confirm task completion',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                      ),
                      value: 'hold_until_completion',
                      groupValue: _selectedPaymentOption,
                      activeColor: const Color(0xFF00C7BE),
                      onChanged: (value) {
                        setState(() => _selectedPaymentOption = value);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons
                if (_showPaymentOptions)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7BE),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _acceptOffer,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Confirm Acceptance',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                if (!_showPaymentOptions) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7BE),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _acceptOffer,
                    child: Text(
                      'Accept Offer',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _rejectOffer,
                    child: Text(
                      'Reject Offer',
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C7BE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF00C7BE),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
