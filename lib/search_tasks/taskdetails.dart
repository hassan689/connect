import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:linkster/core/theme/app_theme.dart';
import 'package:linkster/profilepage/publicprofile.dart';
import 'package:linkster/search_tasks/mappoints/points.dart';
import 'package:linkster/search_tasks/offer_verification/offer_verification_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final _offerController = TextEditingController();
  final _questionController = TextEditingController();
  final _replyController = TextEditingController();
  int _selectedTab = 0; // 0 for offers, 1 for questions
  bool _hasViewed = false;

  @override
  void initState() {
    super.initState();
    _trackTaskView();
  }

  @override
  void dispose() {
    _offerController.dispose();
    _questionController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _trackTaskView() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if user has already viewed this task
      final viewDoc = await FirebaseFirestore.instance
          .collection('task_views')
          .doc('${widget.taskId}_${user.uid}')
          .get();

      if (!viewDoc.exists) {
        // Record the view
        await FirebaseFirestore.instance
            .collection('task_views')
            .doc('${widget.taskId}_${user.uid}')
            .set({
          'taskId': widget.taskId,
          'userId': user.uid,
          'viewedAt': FieldValue.serverTimestamp(),
        });

        // Increment task view count
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskId)
            .update({
          'views': FieldValue.increment(1),
        });

        setState(() {
          _hasViewed = true;
        });
      }
    } catch (e) {
      print('Error tracking task view: $e');
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
          'Task Details',
          style: AppTheme.appBarTitle,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00C7BE),
              ),
            );
          }

          final taskData = snapshot.data!.data() as Map<String, dynamic>;
          final taskViews = taskData['views'] ?? 0;
          final dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();
          final formattedDate = dueDate != null
              ? DateFormat('EEE, d MMM').format(dueDate)
              : 'No deadline';
          final imageUrls = List<String>.from(taskData['imageUrls'] ?? []);
          final userId = taskData['userId'];

          // Update view count if this is a new view
          if (_hasViewed && taskViews > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _hasViewed = false; // Reset to prevent multiple updates
              });
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Poster Info
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return SizedBox();
                    }
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    final userName = userData?['fullName'] ?? 'Anonymous';
                    final profileImageUrl = userData?['profileImageUrl'];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskerProfileTab(
                              userId: userId,
                              isFromTaskDetails: true,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundImage: profileImageUrl != null
                                  ? CachedNetworkImageProvider(profileImageUrl)
                                  : null,
                              child: profileImageUrl == null
                                  ? Icon(Icons.person, size: 24)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: AppTheme.cardTitle,
                                ),
                                Text(
                                  'Posted on ${DateFormat('MMM d, yyyy').format(snapshot.data!['createdAt'].toDate())}',
                                  style: AppTheme.bodyMedium.copyWith(color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Task Images
                if (imageUrls.isNotEmpty) ...[
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: imageUrls[index],
                              width: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Task Title
                Text(
                  taskData['title'] ?? 'No title',
                  style: AppTheme.heading2,
                ),
                const SizedBox(height: 8),

                // Task Status Badge
                _buildStatusBadge(taskData),
                const SizedBox(height: 16),

                // Task Details Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailItem(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        value: taskData['location'] ?? 'No location',
                        actionText: 'View on map',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.calendar_today_outlined,
                        title: 'Due date',
                        value: 'Before $formattedDate',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.currency_rupee,
                        title: 'Budget',
                        value: 'Rs ${taskData['budget'] ?? '0'}',
                        isHighlighted: true,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.visibility_outlined,
                        title: 'Views',
                        value: '$taskViews Taskers have viewed this task',
                        isViews: true,
                      ),
                      if (taskViews > 5) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Popular task',
                                style: AppTheme.statusText.copyWith(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Task Description
                Text(
                  'Description',
                  style: AppTheme.heading4,
                ),
                const SizedBox(height: 8),
                Text(
                  taskData['description'] ?? 'No description provided',
                  style: AppTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // Requirements
                if (taskData['requirements'] != null &&
                    (taskData['requirements'] as List).isNotEmpty) ...[
                  Text(
                    'Requirements',
                    style: AppTheme.heading4,
                  ),
                  const SizedBox(height: 8),
                  ...List<Widget>.from(
                    (taskData['requirements'] as List).map(
                      (req) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: Color(0xFF00C7BE),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                req,
                                style: AppTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton('Offers', 0),
                      _buildTabButton('Questions', 1),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Content
                if (_selectedTab == 0) _buildOffersTab(taskData),
                if (_selectedTab == 1) _buildQuestionsTab(taskData),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> taskData) {
    final status = taskData['status'] ?? 'open';
    final paymentStatus = taskData['paymentStatus'] ?? 'pending';
    final assignedTo = taskData['assignedTo'];
    
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status) {
      case 'open':
        badgeColor = Colors.blue;
        badgeText = 'Open for Offers';
        badgeIcon = Icons.schedule;
        break;
      case 'assigned':
        if (paymentStatus == 'pending') {
          badgeColor = Colors.orange;
          badgeText = 'Payment Pending';
          badgeIcon = Icons.payment;
        } else if (paymentStatus == 'paid') {
          badgeColor = Colors.green;
          badgeText = 'In Progress';
          badgeIcon = Icons.work;
        } else {
          badgeColor = Colors.purple;
          badgeText = 'Assigned';
          badgeIcon = Icons.person_add;
        }
        break;
      case 'in_progress':
        badgeColor = Colors.green;
        badgeText = 'In Progress';
        badgeIcon = Icons.work;
        break;
      case 'completed':
        badgeColor = Colors.green;
        badgeText = 'Completed';
        badgeIcon = Icons.check_circle;
        break;
      case 'cancelled':
        badgeColor = Colors.red;
        badgeText = 'Cancelled';
        badgeIcon = Icons.cancel;
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = 'Unknown';
        badgeIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    String? actionText,
    bool isHighlighted = false,
    bool isViews = false,
  }) {
    return Row(
      children: [
        Icon(
          icon, 
          size: 24, 
          color: isViews 
              ? Colors.blue 
              : const Color(0xFF00C7BE)
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isViews 
                      ? Colors.blue 
                      : (isHighlighted ? const Color(0xFF00C7BE) : Colors.black),
                ),
              ),
            ],
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskMapScreen(taskId: widget.taskId),
                ),
              );
            },
            child: Text(
              actionText,
              style: AppTheme.bodyLarge.copyWith(
                color: const Color(0xFF00C7BE),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabButton(String text, int index) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _selectedTab == index
                ? const Color(0xFF00C7BE)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: _selectedTab == index ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOffersTab(Map<String, dynamic> taskData) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .collection('offers')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00C7BE),
            ),
          );
        }

        final offers = snapshot.data!.docs;

        if (offers.isEmpty) {
          return Column(
            children: [
              const SizedBox(height: 24),
              const SizedBox(height: 16),
              Text(
                'No offers yet',
                style: AppTheme.heading4,
              ),
              const SizedBox(height: 8),
              Text(
                'Make the first offer and get ahead of the competition!',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(color: Colors.black54),
              ),
            ],
          );
        }

        return Column(
          children: offers.map((doc) {
            final offer = doc.data() as Map<String, dynamic>;
            return _buildOfferCard(offer);
          }).toList(),
        );
      },
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    return GestureDetector(
      onTap: () {
        if (offer['userId'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskerProfileTab(userId: offer['userId']),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: offer['profileImageUrl'] != null
                        ? CachedNetworkImageProvider(offer['profileImageUrl'])
                        : null,
                    child: offer['profileImageUrl'] == null
                        ? const Icon(Icons.person, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer['userName'] ?? 'Anonymous',
                          style: AppTheme.cardTitle,
                        ),
                        Text(
                          DateFormat('MMM d, yyyy').format(
                            (offer['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                          ),
                          style: AppTheme.bodyMedium.copyWith(color: Colors.black54),
                        ),
                        if (offer['isPhoneVerified'] == true) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Phone Verified',
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    'Rs ${offer['amount']}',
                    style: AppTheme.priceText,
                  ),
                ],
              ),
              if (offer['message'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  offer['message']!,
                  style: AppTheme.bodyLarge,
                ),
              ],
              if (offer['location'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        offer['location']!,
                        style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
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

  Widget _buildQuestionsTab(Map<String, dynamic> taskData) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .collection('questions')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00C7BE),
            ),
          );
        }

        final questions = snapshot.data!.docs;

        return Column(
          children: [
            ...questions.map((doc) {
              final question = doc.data() as Map<String, dynamic>;
              return _buildQuestionCard(doc.id, question, taskData);
            }).toList(),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask a question about this task...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00C7BE)),
                  onPressed: _submitQuestion,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionCard(String questionId, Map<String, dynamic> question, Map<String, dynamic> taskData) {
    return GestureDetector(
      onTap: () {
        if (question['userId'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskerProfileTab(userId: question['userId']),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: question['profileImageUrl'] != null
                        ? CachedNetworkImageProvider(question['profileImageUrl'])
                        : null,
                    child: question['profileImageUrl'] == null
                        ? Icon(Icons.person, size: 20)
                        : null,
                  ),
                  SizedBox(width: 12),
                  Text(
                    question['fullName'] ?? 'Anonymous',
                    style: AppTheme.cardTitle,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(question['text'], style: AppTheme.bodyLarge),
              if (question['answer'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Response:',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00C7BE),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(question['answer']!, style: AppTheme.bodyLarge),
                    ],
                  ),
                ),
              ] else if (FirebaseAuth.instance.currentUser?.uid == taskData['userId']) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: 'Write a reply...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF00C7BE)),
                      onPressed: () => _submitReply(questionId),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _offerController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter your offer amount in Rs...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.currency_rupee,
                  color: Color(0xFF00C7BE),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _submitOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C7BE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
            child: Text(
              'Offer',
              style: AppTheme.button,
            ),
          ),
        ],
      ),
    );
  }

  void _submitOffer() async {
    if (_offerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an offer amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to make an offer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to verification screen instead of direct submission
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferVerificationScreen(
          taskId: widget.taskId,
          offerAmount: _offerController.text,
        ),
      ),
    );
    
    // Clear the input field
    _offerController.clear();
    FocusScope.of(context).unfocus();
  }

  void _submitQuestion() async {
    if (_questionController.text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .collection('questions')
        .add({
      'text': _questionController.text,
      'userId': user.uid,
      'userName': userDoc.data()?['name'] ?? 'Anonymous',
      'profileImageUrl': userDoc.data()?['photoUrl'],
      'createdAt': FieldValue.serverTimestamp(),
      'answered': false,
    });

    _questionController.clear();
    FocusScope.of(context).unfocus();
  }

  void _submitReply(String questionId) async {
    if (_replyController.text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .collection('questions')
        .doc(questionId)
        .update({
      'answer': _replyController.text,
      'answered': true,
      'answeredAt': FieldValue.serverTimestamp(),
    });

    _replyController.clear();
    FocusScope.of(context).unfocus();
  }
}