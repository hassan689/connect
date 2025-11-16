import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linkster/messaging/chat_screen.dart';
import 'package:lottie/lottie.dart';

class MessageRequestsScreen extends StatefulWidget {
  const MessageRequestsScreen({super.key});

  @override
  State<MessageRequestsScreen> createState() => _MessageRequestsScreenState();
}

class _MessageRequestsScreenState extends State<MessageRequestsScreen> {
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
          'Message Requests',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('message_requests')
            .where('toUserId', isEqualTo: _auth.currentUser?.uid)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading message requests',
                style: GoogleFonts.roboto(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00C7BE),
              ),
            );
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dino Animation
                  Container(
                    height: 120,
                    width: 120,
                    child: Lottie.asset(
                      'assets/images/animations/dinodance.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No message requests yet! 🦖',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00C7BE),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see message requests here when someone wants to chat with you',
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
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index].data() as Map<String, dynamic>;
              return _buildRequestTile(request, requests[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestTile(Map<String, dynamic> request, String requestId) {
    final fromUserId = request['fromUserId'];
    final message = request['message'] ?? 'No message';
    final createdAt = (request['createdAt'] as Timestamp?)?.toDate();

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(fromUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'User';
        final userImage = userData?['profileImage'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: userImage != null ? CachedNetworkImageProvider(userImage) : null,
                      child: userImage == null
                          ? Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              DateFormat('MMM d, yyyy - hh:mm a').format(createdAt),
                              style: GoogleFonts.roboto(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectRequest(requestId),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                                                 child: Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             SizedBox(
                               width: 16,
                               height: 16,
                               child: Lottie.asset(
                                 'assets/images/animations/dinodance.json',
                                 fit: BoxFit.contain,
                                 repeat: true,
                               ),
                             ),
                             const SizedBox(width: 4),
                             Text(
                               'Decline',
                               style: GoogleFonts.roboto(
                                 color: Colors.red,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                           ],
                         ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptRequest(requestId, fromUserId, userName, userImage),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C7BE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                                                 child: Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             SizedBox(
                               width: 16,
                               height: 16,
                               child: Lottie.asset(
                                 'assets/images/animations/dinodance.json',
                                 fit: BoxFit.contain,
                                 repeat: true,
                               ),
                             ),
                             const SizedBox(width: 4),
                             Text(
                               'Accept',
                               style: GoogleFonts.roboto(
                                 color: Colors.white,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                           ],
                         ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _acceptRequest(String requestId, String fromUserId, String userName, String userImage) async {
    try {
      // Update request status
      await _firestore
          .collection('message_requests')
          .doc(requestId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to requester
      await _firestore
          .collection('users')
          .doc(fromUserId)
          .collection('notifications')
          .add({
        'title': 'Message Request Accepted',
        'body': '${_auth.currentUser?.displayName ?? 'Someone'} accepted your message request',
        'type': 'message_request_accepted',
        'fromUserId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'priority': 'normal',
      });

      // Navigate to chat
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: fromUserId,
              otherUserName: userName,
            ),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message request accepted'),
          backgroundColor: Color(0xFF00C7BE),
        ),
      );
    } catch (e) {
      print('Error accepting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await _firestore
          .collection('message_requests')
          .doc(requestId)
          .update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message request declined'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Error declining request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to decline request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 