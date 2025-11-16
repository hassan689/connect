// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:intl/intl.dart';

// class ReceiverMessageScreen extends StatefulWidget {
//   final String recipientId;
  
//   const ReceiverMessageScreen({
//     super.key,
//     required this.recipientId,
//   });

//   @override
//   State<ReceiverMessageScreen> createState() => _ReceiverMessageScreenState();
// }

// class _ReceiverMessageScreenState extends State<ReceiverMessageScreen> {
//   final _messageController = TextEditingController();
//   final _auth = FirebaseAuth.instance;
//   final _firestore = FirebaseFirestore.instance;
//   String? _senderName;
//   String? _senderImageUrl;
//   String? _recipientName;
//   String? _recipientImageUrl;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//     _markMessagesAsRead();
//   }

//   Future<void> _loadUserData() async {
//     // Load sender data (current user)
//     final senderDoc = await _firestore
//         .collection('users')
//         .doc(_auth.currentUser?.uid)
//         .get();
    
//     if (senderDoc.exists) {
//       setState(() {
//         _senderName = senderDoc.data()?['fullName'];
//         _senderImageUrl = senderDoc.data()?['profileImageUrl'];
//       });
//     }

//     // Load recipient data
//     final recipientDoc = await _firestore
//         .collection('users')
//         .doc(widget.recipientId)
//         .get();
    
//     if (recipientDoc.exists) {
//       setState(() {
//         _recipientName = recipientDoc.data()?['fullName'];
//         _recipientImageUrl = recipientDoc.data()?['profileImageUrl'];
//       });
//     }
//   }

//   Future<void> _markMessagesAsRead() async {
//     final currentUserId = _auth.currentUser?.uid;
//     if (currentUserId == null) return;

//     final unreadMessages = await _firestore
//         .collection('messages')
//         .where('recipientId', isEqualTo: currentUserId)
//         .where('senderId', isEqualTo: widget.recipientId)
//         .where('read', isEqualTo: false)
//         .get();

//     for (var doc in unreadMessages.docs) {
//       await doc.reference.update({'read': true});
//     }
//   }

//   Future<void> _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;

//     final currentUser = _auth.currentUser;
//     if (currentUser == null) return;

//     await _firestore.collection('messages').add({
//       'content': _messageController.text.trim(), // Changed from 'text' to 'content'
//       'senderId': currentUser.uid,
//       'recipientId': widget.recipientId,
//       'timestamp': FieldValue.serverTimestamp(),
//       'read': false,
//     });

//     _messageController.clear();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             CircleAvatar(
//               radius: 16,
//               backgroundImage: _recipientImageUrl != null
//                   ? CachedNetworkImageProvider(_recipientImageUrl!)
//                   : null,
//               child: _recipientImageUrl == null
//                   ? const Icon(Icons.person, size: 16)
//                   : null,
//             ),
//             const SizedBox(width: 8),
//             Text(_recipientName ?? 'Loading...'),
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('messages')
//                   .where('senderId', isEqualTo: _auth.currentUser?.uid)
//                   .where('recipientId', isEqualTo: widget.recipientId)
//                   .orderBy('timestamp', descending: false)
//                   .snapshots(),
//               builder: (context, senderSnapshot) {
//                 return StreamBuilder<QuerySnapshot>(
//                   stream: _firestore
//                       .collection('messages')
//                       .where('senderId', isEqualTo: widget.recipientId)
//                       .where('recipientId', isEqualTo: _auth.currentUser?.uid)
//                       .orderBy('timestamp', descending: false)
//                       .snapshots(),
//                   builder: (context, recipientSnapshot) {
//                     if (senderSnapshot.connectionState == ConnectionState.waiting ||
//                         recipientSnapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }

//                     // Combine both streams
//                     final messages = [
//                       ...?senderSnapshot.data?.docs,
//                       ...?recipientSnapshot.data?.docs,
//                     ];

//                     // Sort by timestamp
//                     messages.sort((a, b) {
//                       final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
//                       final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
//                       return (aTime?.millisecondsSinceEpoch ?? 0)
//                           .compareTo(bTime?.millisecondsSinceEpoch ?? 0);
//                     });

//                     return ListView.builder(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: messages.length,
//                       itemBuilder: (context, index) {
//                         final message = messages[index];
//                         final data = message.data() as Map<String, dynamic>;
//                         final isMe = data['senderId'] == _auth.currentUser?.uid;
//                         final timestamp = data['timestamp'] as Timestamp?;

//                         if (timestamp == null) return const SizedBox();

//                         return Align(
//                           alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                           child: Container(
//                             margin: const EdgeInsets.symmetric(vertical: 4),
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 12,
//                             ),
//                             decoration: BoxDecoration(
//                               color: isMe
//                                   ? const Color(0xFF00C7BE)
//                                   : Colors.grey[200],
//                               borderRadius: BorderRadius.only(
//                                 topLeft: const Radius.circular(16),
//                                 topRight: const Radius.circular(16),
//                                 bottomLeft: isMe
//                                     ? const Radius.circular(16)
//                                     : const Radius.circular(4),
//                                 bottomRight: isMe
//                                     ? const Radius.circular(4)
//                                     : const Radius.circular(16),
//                               ),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   data['content'] ?? '', // Changed from 'text' to 'content'
//                                   style: TextStyle(
//                                     color: isMe ? Colors.white : Colors.black87,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   DateFormat('hh:mm a').format(timestamp.toDate()),
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     color: isMe
//                                         ? Colors.white.withOpacity(0.8)
//                                         : Colors.black54,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: 'Type your message...',
//                       filled: true,
//                       fillColor: Colors.grey[100],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(25),
//                         borderSide: BorderSide.none,
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 16,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF00C7BE),
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.send, color: Colors.white),
//                     onPressed: _sendMessage,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }