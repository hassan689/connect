import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connect/messaging/chat_screen.dart';
import 'package:connect/widgets/shimmer_loading.dart';
import 'package:lottie/lottie.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  
  int _messageRequestCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessageRequestCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMessageRequestCount() async {
    try {
      final requestsQuery = await _firestore
          .collection('message_requests')
          .where('toUserId', isEqualTo: _auth.currentUser?.uid)
          .where('status', isEqualTo: 'pending')
          .get();
      
      setState(() {
        _messageRequestCount = requestsQuery.docs.length;
      });
    } catch (e) {
      print('Error loading message request count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Messages',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00C7BE),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF00C7BE),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline),
                  const SizedBox(width: 8),
                  const Text('Chats'),
                  if (_messageRequestCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _messageRequestCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_outlined),
                  SizedBox(width: 8),
                  Text('Requests'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsTab(),
          _buildRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildChatsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .where('participants', arrayContains: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading messages',
              style: GoogleFonts.roboto(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => ShimmerLoading.messageItem(),
          );
        }

        final chats = snapshot.data!.docs;
        
        // Sort chats by lastMessageTime (most recent first)
        final sortedChats = List<QueryDocumentSnapshot>.from(chats);
        sortedChats.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['lastMessageTime'] as Timestamp?;
          final bTime = bData['lastMessageTime'] as Timestamp?;
          
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          
          return bTime.compareTo(aTime);
        });

        if (sortedChats.isEmpty) {
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
                  'No messages yet! 🦖',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00C7BE),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation by accepting a message request',
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
          itemCount: sortedChats.length,
          itemBuilder: (context, index) {
            final chat = sortedChats[index].data() as Map<String, dynamic>;
            return _buildChatTile(chat, sortedChats[index].id);
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => ShimmerLoading.messageItem(),
          );
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No message requests',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
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
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat, String chatId) {
    final participants = List<String>.from(chat['participants'] ?? []);
    final otherUserId = participants.firstWhere(
      (id) => id != _auth.currentUser?.uid,
      orElse: () => '',
    );

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'Unknown User';
        final userImage = userData?['profileImage'];
        final lastMessage = chat['lastMessage'] ?? 'No messages yet';
        final lastMessageTime = (chat['lastMessageTime'] as Timestamp?)?.toDate();
        final unreadCount = chat['unreadCount']?[_auth.currentUser?.uid] ?? 0;

        return ListTile(
          leading: CircleAvatar(
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
          title: Text(
            userName,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  lastMessage,
                  style: GoogleFonts.roboto(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Add dino animation for fun
              SizedBox(
                width: 20,
                height: 20,
                child: Lottie.asset(
                  'assets/images/animations/dinodance.json',
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastMessageTime != null)
                Text(
                  DateFormat('MMM d').format(lastMessageTime),
                  style: GoogleFonts.roboto(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              if (unreadCount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C7BE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
                         Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => ChatScreen(
                   otherUserId: otherUserId,
                   otherUserName: userName,
                   otherUserImageUrl: userImage,
                 ),
               ),
             );
          },
        );
      },
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
        final userName = userData?['name'] ?? 'Unknown User';
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
                        child: Text(
                          'Decline',
                          style: GoogleFonts.roboto(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
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
                        child: Text(
                          'Accept',
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
            ),
          ),
        );
      },
    );
  }

  Future<void> _acceptRequest(String requestId, String fromUserId, String userName, String? userImage) async {
    try {
      // Update request status
      await _firestore.collection('message_requests').doc(requestId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Create or update chat document in chats collection
      // Check if chat already exists
      final existingChatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: _auth.currentUser!.uid)
          .get();
      
      String? chatId;
      for (var doc in existingChatQuery.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(fromUserId) && participants.contains(_auth.currentUser!.uid)) {
          chatId = doc.id;
          break;
        }
      }
      
      // Get user names for participantNames
      final currentUserDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      final fromUserDoc = await _firestore.collection('users').doc(fromUserId).get();
      final currentUserName = currentUserDoc.data()?['name'] ?? currentUserDoc.data()?['fullName'] ?? 'User';
      final fromUserName = fromUserDoc.data()?['name'] ?? fromUserDoc.data()?['fullName'] ?? 'User';
      
      if (chatId == null) {
        // Create new chat
        final newChatDoc = await _firestore.collection('chats').add({
          'participants': [_auth.currentUser!.uid, fromUserId],
          'participantNames': [currentUserName, fromUserName],
          'lastMessage': 'Message request accepted',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        chatId = newChatDoc.id;
      } else {
        // Update existing chat
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': 'Message request accepted',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      }

             // Navigate to chat
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (context) => ChatScreen(
             otherUserId: fromUserId,
             otherUserName: userName,
             otherUserImageUrl: userImage,
           ),
         ),
       );

      // Update message request count
      _loadMessageRequestCount();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Started chatting with $userName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await _firestore.collection('message_requests').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Update message request count
      _loadMessageRequestCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message request declined'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error declining request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

} 