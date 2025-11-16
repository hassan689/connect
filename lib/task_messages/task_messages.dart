// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// class Tasktitlewithmessage extends StatefulWidget {
//   final String recipientId;
//   final String recipientName;
  
//   const Tasktitlewithmessage({
//     super.key,
//     required this.recipientId,
//     this.recipientName = '',
//   });

//   @override
//   State<Tasktitlewithmessage> createState() => _TasktitlewithmessageState();
// }

// class _TasktitlewithmessageState extends State<Tasktitlewithmessage> {
//   final TextEditingController _messageController = TextEditingController();
//   bool _isSending = false;
//   final int _maxHistoryCount = 10;
//   List<Map<String, dynamic>> _messageHistory = [];
//   late SharedPreferences _prefs;

//   @override
//   void initState() {
//     super.initState();
//     _initPreferences();
//   }

//   Future<void> _initPreferences() async {
//     _prefs = await SharedPreferences.getInstance();
//     _loadMessageHistory();
//   }

//   Future<void> _loadMessageHistory() async {
//     final historyString = _prefs.getString('messageHistory');
//     if (historyString != null) {
//       setState(() {
//         _messageHistory = List<Map<String, dynamic>>.from(
//           json.decode(historyString).map((x) => Map<String, dynamic>.from(x))
//         );
//       });
//     }
//   }

//   Future<void> _saveMessageHistory() async {
//     await _prefs.setString(
//       'messageHistory', 
//       json.encode(_messageHistory)
//     );
//   }

//   Future<void> _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;
    
//     setState(() => _isSending = true);
    
//     try {
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) return;
      
//       final messageContent = _messageController.text.trim();
//       final timestamp = DateTime.now();
      
//       // Add to local history
//       _addToMessageHistory(
//         content: messageContent,
//         timestamp: timestamp,
//         recipientId: widget.recipientId,
//         recipientName: widget.recipientName,
//       );
      
//       // Save to Firestore
//       final messagesRef = FirebaseFirestore.instance.collection('messages');
//       final newMessage = {
//         'senderId': currentUser.uid,
//         'recipientId': widget.recipientId,
//         'content': messageContent,
//         'timestamp': timestamp,
//         'read': false,
//       };
      
//       await messagesRef.add(newMessage);
      
//       // Send push notification
//       await _sendPushNotification(
//         recipientId: widget.recipientId,
//         message: messageContent,
//         senderId: currentUser.uid,
//       );
      
//       _messageController.clear();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Message sent successfully!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send message: $e')),
//       );
//     } finally {
//       setState(() => _isSending = false);
//     }
//   }

//   void _addToMessageHistory({
//     required String content,
//     required DateTime timestamp,
//     required String recipientId,
//     required String recipientName,
//   }) {
//     setState(() {
//       _messageHistory.insert(0, {
//         'content': content,
//         'timestamp': timestamp,
//         'recipientId': recipientId,
//         'recipientName': recipientName,
//       });
      
//       if (_messageHistory.length > _maxHistoryCount) {
//         _messageHistory.removeLast();
//       }
//       _saveMessageHistory();
//     });
//   }

//   Future<void> _sendPushNotification({
//     required String recipientId,
//     required String message,
//     required String senderId,
//   }) async {
//     try {
//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(recipientId)
//           .get();
      
//       final fcmToken = userDoc.data()?['fcmToken'];
//       if (fcmToken == null) return;
      
//       await FirebaseMessaging.instance.sendMessage(
//         to: fcmToken,
//         data: {
//           'type': 'message',
//           'senderId': senderId,
//           'click_action': 'FLUTTER_NOTIFICATION_CLICK',
//           'title': widget.recipientName.isNotEmpty 
//               ? 'New message from ${widget.recipientName}' 
//               : 'New message',
//           'body': message.length > 30 
//               ? '${message.substring(0, 30)}...' 
//               : message,
//         },
//       );
//     } catch (e) {
//       debugPrint('Error sending notification: $e');
//     }
//   }

//   void _showMessageHistory() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Last 10 Sent Messages'),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: _messageHistory.length,
//             itemBuilder: (context, index) {
//               final message = _messageHistory[index];
//               return ListTile(
//                 title: Text(message['content']),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('To: ${message['recipientName'] ?? message['recipientId']}'),
//                     Text(DateFormat('MMM dd, yyyy - hh:mm a').format(message['timestamp'])),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text(
//           widget.recipientName.isNotEmpty 
//               ? 'Message ${widget.recipientName}'
//               : 'New Message',
//         ),
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.history),
//             onPressed: _showMessageHistory,
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView(
//                 children: const [], // Your existing messages list
//               ),
//             ),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: "Type your message...",
//                       hintStyle: GoogleFonts.poppins(
//                         fontSize: 14,
//                         color: Colors.grey.shade500,
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(25),
//                         borderSide: BorderSide.none,
//                       ),
//                       filled: true,
//                       fillColor: Colors.grey.shade100,
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 16,
//                       ),
//                     ),
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       color: Colors.black87,
//                     ),
//                     maxLines: null,
//                     keyboardType: TextInputType.multiline,
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF00C7BE),
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   child: IconButton(
//                     icon: _isSending
//                         ? const CircularProgressIndicator(
//                             valueColor: AlwaysStoppedAnimation(Colors.white),
//                           )
//                         : const Icon(Icons.send, color: Colors.white),
//                     onPressed: _isSending ? null : _sendMessage,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }