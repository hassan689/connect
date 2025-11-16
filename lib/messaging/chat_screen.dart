import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImageUrl;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _chatId;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get current user's name from Firestore
      String currentUserName = 'User';
      try {
        final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (currentUserDoc.exists) {
          currentUserName = currentUserDoc.data()?['name'] ?? 'User';
        }
      } catch (e) {
        print('Error fetching current user name: $e');
      }

      // Find existing chat or create new one
      final chatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      for (final doc in chatQuery.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(widget.otherUserId)) {
          _chatId = doc.id;
          break;
        }
      }

      // If no existing chat, create one
      if (_chatId == null) {
        final chatDoc = await _firestore.collection('chats').add({
          'participants': [currentUser.uid, widget.otherUserId],
          'participantNames': [currentUserName, widget.otherUserName],
          'lastMessage': null,
          'lastMessageTime': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _chatId = chatDoc.id;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      final message = _messageController.text.trim();
      _messageController.clear();

      // Get current user's name from Firestore
      String currentUserName = 'User';
      try {
        final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (currentUserDoc.exists) {
          currentUserName = currentUserDoc.data()?['name'] ?? 'User';
        }
      } catch (e) {
        print('Error fetching current user name: $e');
      }

      // Add message to chat
      await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderName': currentUserName,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update chat with last message
      await _firestore.collection('chats').doc(_chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Send notification to other user
      await _firestore
          .collection('users')
          .doc(widget.otherUserId)
          .collection('notifications')
          .add({
        'title': 'New Message',
        'body': '$currentUserName sent you a message',
        'type': 'message',
        'fromUserId': currentUser.uid,
        'chatId': _chatId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'priority': 'normal',
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error sending message: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C7BE),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.otherUserImageUrl != null
                  ? CachedNetworkImageProvider(widget.otherUserImageUrl!)
                  : null,
              child: widget.otherUserImageUrl == null
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Online',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show chat options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _chatId == null
                ? const Center(child: Text('Chat not available'))
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('chats')
                        .doc(_chatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: false)
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
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final messages = snapshot.data!.docs;

                                             if (messages.isEmpty) {
                         return Center(
                           child: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                                                               // Profile Box with Dino Animation
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.all(20),
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00C7BE), Color(0xFF00A8A0)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00C7BE).withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Dino Animation - Made smaller and positioned better
                                      Container(
                                        height: 80,
                                        width: 80,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: Lottie.asset(
                                          'assets/images/animations/dinodance.json',
                                          fit: BoxFit.contain,
                                          repeat: true,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // User Info - Made smaller
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundImage: widget.otherUserImageUrl != null
                                            ? CachedNetworkImageProvider(widget.otherUserImageUrl!)
                                            : null,
                                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                                        child: widget.otherUserImageUrl == null
                                            ? Icon(
                                                Icons.person,
                                                size: 30,
                                                color: Colors.white.withValues(alpha: 0.8),
                                              )
                                            : null,
                                      ),
                                     const SizedBox(height: 12),
                                     Text(
                                       widget.otherUserName,
                                       style: GoogleFonts.roboto(
                                         fontSize: 24,
                                         fontWeight: FontWeight.bold,
                                         color: Colors.white,
                                       ),
                                     ),
                                     const SizedBox(height: 8),
                                     Text(
                                       'Ready to chat! 🦖',
                                       style: GoogleFonts.roboto(
                                         fontSize: 16,
                                         color: Colors.white.withValues(alpha: 0.9),
                                       ),
                                     ),
                                     const SizedBox(height: 16),
                                     Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                       decoration: BoxDecoration(
                                         color: Colors.white.withValues(alpha: 0.2),
                                         borderRadius: BorderRadius.circular(20),
                                       ),
                                       child: Text(
                                         'Send a message to begin chatting with dino friends!',
                                         style: GoogleFonts.roboto(
                                           fontSize: 14,
                                           color: Colors.white,
                                         ),
                                         textAlign: TextAlign.center,
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ],
                           ),
                         );
                       }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index].data() as Map<String, dynamic>;
                          final isMe = message['senderId'] == _auth.currentUser?.uid;
                          final timestamp = message['timestamp'] as Timestamp?;
                          final time = timestamp != null
                              ? DateFormat('HH:mm').format(timestamp.toDate())
                              : '';

                          return _buildMessageBubble(
                            message['text'] ?? '',
                            isMe,
                            time,
                            message['senderName'] ?? 'Anonymous',
                          );
                        },
                      );
                    },
                  ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C7BE),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: Lottie.asset(
                            'assets/images/animations/dinodance.json',
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isMe, String time, String senderName) {
    // Generate a random dino reaction based on message content
    final dinoReaction = _getDinoReaction(message);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                senderName,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF00C7BE) : Colors.white,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      message,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (dinoReaction != null) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Lottie.asset(
                        dinoReaction,
                        fit: BoxFit.contain,
                        repeat: false,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getDinoReaction(String message) {
    final random = Random();
    final lowerMessage = message.toLowerCase();
    
    // Happy reactions
    if (lowerMessage.contains('happy') || lowerMessage.contains('great') || 
        lowerMessage.contains('awesome') || lowerMessage.contains('amazing') ||
        lowerMessage.contains('😊') || lowerMessage.contains('😄') || lowerMessage.contains('🎉')) {
      return 'assets/images/animations/dinodance.json';
    }
    
    // Laugh reactions
    if (lowerMessage.contains('lol') || lowerMessage.contains('haha') || 
        lowerMessage.contains('funny') || lowerMessage.contains('😂') || 
        lowerMessage.contains('🤣')) {
      return 'assets/images/animations/dinodance.json';
    }
    
    // Love reactions
    if (lowerMessage.contains('love') || lowerMessage.contains('❤️') || 
        lowerMessage.contains('heart') || lowerMessage.contains('💕')) {
      return 'assets/images/animations/dinodance.json';
    }
    
    // Sad reactions
    if (lowerMessage.contains('sad') || lowerMessage.contains('sorry') || 
        lowerMessage.contains('😢') || lowerMessage.contains('😭')) {
      return 'assets/images/animations/dinodance.json';
    }
    
    // Random dino reaction (20% chance)
    if (random.nextInt(5) == 0) {
      return 'assets/images/animations/dinodance.json';
    }
    
    return null;
  }
} 