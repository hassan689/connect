import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TaskerProfileTab extends StatefulWidget {
  final String userId;
  final bool isFromTaskDetails;

  const TaskerProfileTab({
    super.key,
    required this.userId,
    this.isFromTaskDetails = false,
  });

  @override
  State<TaskerProfileTab> createState() => _TaskerProfileTabState();
}

class _TaskerProfileTabState extends State<TaskerProfileTab> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _postedTasks = [];
  List<Map<String, dynamic>> _completedTasks = [];
  Map<String, dynamic> _stats = {
    'totalPosted': 0,
    'activePosted': 0,
    'completedPosted': 0,
    'totalCompleted': 0,
    'totalEarnings': 0.0,
    'averageRating': 0.0,
    'totalRatings': 0,
    'responseRate': 0.0,
  };
  bool _isRequestingMessage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      // Load user profile data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        _userData = userDoc.data()!;
      }

      // Load posted tasks (as poster)
      final postedTasksQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      _postedTasks = postedTasksQuery.docs.map((doc) {
        final data = doc.data();
        data['taskId'] = doc.id;
        return data;
      }).toList();

      // Load completed tasks (as tasker)
      final completedTasksQuery = await FirebaseFirestore.instance
          .collection('completed_tasks')
          .where('taskerId', isEqualTo: widget.userId)
          .orderBy('completedAt', descending: true)
          .limit(10)
          .get();

      _completedTasks = completedTasksQuery.docs.map((doc) {
        final data = doc.data();
        data['taskId'] = doc.id;
        return data;
      }).toList();

      // Calculate statistics
      await _calculateStats();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateStats() async {
    try {
      // Posted tasks stats
      final postedTasksQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: widget.userId)
          .get();

      final totalPosted = postedTasksQuery.docs.length;
      final activePosted = postedTasksQuery.docs
          .where((doc) => doc.data()['status'] == 'active')
          .length;
      final completedPosted = postedTasksQuery.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      // Completed tasks as tasker stats
      final completedTasksQuery = await FirebaseFirestore.instance
          .collection('completed_tasks')
          .where('taskerId', isEqualTo: widget.userId)
          .get();

      final totalCompleted = completedTasksQuery.docs.length;
      double totalEarnings = 0;
      double averageRating = 0;
      int totalRatings = 0;

      for (final doc in completedTasksQuery.docs) {
        final data = doc.data();
        totalEarnings += (data['amount'] ?? 0).toDouble();
        if (data['rating'] != null) {
          averageRating += data['rating'].toDouble();
          totalRatings++;
        }
      }

      if (totalRatings > 0) {
        averageRating = averageRating / totalRatings;
      }

      // Response rate calculation
      final offersQuery = await FirebaseFirestore.instance
          .collection('offers')
          .where('userId', isEqualTo: widget.userId)
          .get();

      final totalOffers = offersQuery.docs.length;
      final acceptedOffers = offersQuery.docs
          .where((doc) => doc.data()['status'] == 'accepted')
          .length;

      final responseRate = totalOffers > 0 ? (acceptedOffers / totalOffers) * 100 : 0;

      setState(() {
        _stats = {
          'totalPosted': totalPosted,
          'activePosted': activePosted,
          'completedPosted': completedPosted,
          'totalCompleted': totalCompleted,
          'totalEarnings': totalEarnings,
          'averageRating': averageRating,
          'totalRatings': totalRatings,
          'responseRate': responseRate,
        };
      });
    } catch (e) {
      print('Error calculating stats: $e');
      // Set default values if calculation fails
      setState(() {
        _stats = {
          'totalPosted': 0,
          'activePosted': 0,
          'completedPosted': 0,
          'totalCompleted': 0,
          'totalEarnings': 0.0,
          'averageRating': 0.0,
          'totalRatings': 0,
          'responseRate': 0.0,
        };
      });
    }
  }

  Future<void> _requestMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to send message requests')),
      );
      return;
    }

    if (currentUser.uid == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself')),
      );
      return;
    }

    setState(() {
      _isRequestingMessage = true;
    });

    try {
      // Check if message request already exists
      final existingRequest = await FirebaseFirestore.instance
          .collection('message_requests')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('toUserId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message request already sent')),
        );
        return;
      }

      // Create message request
      await FirebaseFirestore.instance
          .collection('message_requests')
          .add({
        'fromUserId': currentUser.uid,
        'toUserId': widget.userId,
        'fromUserName': _userData?['fullName'] ?? 'Anonymous',
        'toUserName': _userData?['fullName'] ?? 'Anonymous',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send notification to profile owner
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('notifications')
          .add({
        'title': 'New Message Request',
        'body': '${_userData?['fullName'] ?? 'Someone'} wants to message you about a task',
        'type': 'message_request',
        'fromUserId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'priority': 'normal',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message request sent successfully!'),
          backgroundColor: Color(0xFF00C7BE),
        ),
      );
    } catch (e) {
      print('Error sending message request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRequestingMessage = false;
      });
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio Section
          if (_userData!['bio'] != null && _userData!['bio'].isNotEmpty) ...[
            _buildSectionTitle('About'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Text(
                _userData!['bio'],
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Performance Stats
          _buildSectionTitle('Performance'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildPerformanceRow('Total Earnings', 'Rs ${(_stats['totalEarnings'] ?? 0.0).toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.green),
                const SizedBox(height: 16),
                _buildPerformanceRow('Average Rating', '${(_stats['averageRating'] ?? 0.0).toStringAsFixed(1)}/5', Icons.star, Colors.amber),
                const SizedBox(height: 16),
                _buildPerformanceRow('Tasks Completed', (_stats['totalCompleted'] ?? 0).toString(), Icons.check_circle, Colors.blue),
                const SizedBox(height: 16),
                _buildPerformanceRow('Response Rate', '${(_stats['responseRate'] ?? 0.0).toStringAsFixed(0)}%', Icons.reply, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostedTasksTab() {
    return _postedTasks.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No posted tasks yet',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _postedTasks.length,
            itemBuilder: (context, index) {
              final task = _postedTasks[index];
              return _buildTaskCard(task, true);
            },
          );
  }

  Widget _buildCompletedTasksTab() {
    return _completedTasks.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No completed tasks yet',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _completedTasks.length,
            itemBuilder: (context, index) {
              final task = _completedTasks[index];
              return _buildTaskCard(task, false);
            },
          );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPerformanceRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, bool isPosted) {
    final status = task['status'] ?? 'unknown';
    final amount = task['amount'] ?? task['budget'] ?? 0;
    final createdAt = task['createdAt'] ?? task['completedAt'];
    final date = createdAt != null ? DateFormat('MMM d, yyyy').format(createdAt.toDate()) : 'No date';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task['title'] ?? 'No Title',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(status).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C7BE).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.currency_rupee,
                  size: 16,
                  color: Color(0xFF00C7BE),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rs $amount',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00C7BE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTab(String text, IconData icon) {
    return Tab(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00C7BE),
          ),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (widget.isFromTaskDetails)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: _isRequestingMessage ? null : _requestMessage,
                icon: _isRequestingMessage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.message, size: 18),
                label: Text(
                  _isRequestingMessage ? 'Sending...' : 'Message',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7BE),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF00C7BE).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00C7BE).withValues(alpha: 0.1),
                  const Color(0xFF00C7BE).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Profile Image and Basic Info
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundImage: _userData!['profileImageUrl'] != null
                            ? CachedNetworkImageProvider(_userData!['profileImageUrl'])
                            : null,
                        child: _userData!['profileImageUrl'] == null
                            ? const Icon(Icons.person, size: 45, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData!['fullName'] ?? 'Anonymous',
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _userData!['location'] ?? 'Location not set',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          if (_stats['totalRatings'] != null && _stats['totalRatings'] > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  final avgRating = _stats['averageRating'] ?? 0.0;
                                  return Icon(
                                    index < avgRating.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 18,
                                    color: Colors.amber,
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  '${(_stats['averageRating'] ?? 0.0).toStringAsFixed(1)} (${_stats['totalRatings'] ?? 0})',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Posted Tasks',
                        (_stats['totalPosted'] ?? 0).toString(),
                        Icons.task,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Completed',
                        (_stats['totalCompleted'] ?? 0).toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Response Rate',
                        '${(_stats['responseRate'] ?? 0.0).toStringAsFixed(0)}%',
                        Icons.reply,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF00C7BE),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C7BE).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                _buildTab('Overview', Icons.dashboard_outlined),
                _buildTab('Posted Tasks', Icons.task_alt_outlined),
                _buildTab('Completed', Icons.check_circle_outlined),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPostedTasksTab(),
                _buildCompletedTasksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
