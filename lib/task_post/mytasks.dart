import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connect/task_post/title.dart';
import 'package:connect/services/points_service.dart';
import 'package:connect/search_tasks/taskdetails.dart';
import 'package:connect/widgets/shimmer_loading.dart';
import 'package:connect/task_post/task_completion_screen.dart';
import 'package:connect/task_post/payment_confirmation_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view your tasks")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Tasks", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00C7BE),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF00C7BE),
          tabs: const [
            Tab(text: 'Posted Tasks'),
            Tab(text: 'Assigned Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostedTasks(user.uid),
          _buildAssignedTasks(user.uid),
        ],
      ),
    );
  }

  Widget _buildPostedTasks(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 5,
              itemBuilder: (context, index) => ShimmerLoading.taskCard(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _NoTasksWidget();
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index].data() as Map<String, dynamic>;
              final taskId = tasks[index].id;
              final status = task['status'] ?? 'open';
              final assignedTo = task['assignedTo'];
              final paymentStatus = task['paymentStatus'] ?? 'pending';
              
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task['title'] ?? 'No title',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status Badge
                      _buildStatusBadge(status, paymentStatus),

                      // Action Buttons
                      const SizedBox(height: 12),
                      _buildActionButtons(context, taskId, status, paymentStatus, assignedTo),
                    ],
                  ),
                ),
              );
            },
          );
        },
    );
  }

  Widget _buildAssignedTasks(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .orderBy('assignedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: 5,
            itemBuilder: (context, index) => ShimmerLoading.taskCard(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No assigned tasks yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When your offers are accepted, tasks will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final tasks = snapshot.data!.docs;

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index].data() as Map<String, dynamic>;
            final taskId = tasks[index].id;
            final status = task['status'] ?? 'assigned';
            final paymentStatus = task['paymentStatus'] ?? 'pending';
            final taskTitle = task['title'] ?? 'No title';
            final taskAmount = double.tryParse(task['budget']?.toString() ?? '0') ?? 0.0;
            
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      taskTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Status Badge
                    _buildStatusBadge(status, paymentStatus),

                    // Action Buttons for Service Provider
                    const SizedBox(height: 12),
                    _buildAssignedTaskActions(context, taskId, status, paymentStatus, taskTitle, taskAmount),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAssignedTaskActions(
    BuildContext context,
    String taskId,
    String status,
    String paymentStatus,
    String taskTitle,
    double taskAmount,
  ) {
    List<Widget> buttons = [];

    if (status == 'assigned' || status == 'in_progress') {
      buttons.add(
        _buildActionButton(
          context,
          'Complete Task',
          Icons.check_circle,
          const Color(0xFF00C7BE),
          () => _completeTask(context, taskId, taskTitle, taskAmount),
        ),
      );
      buttons.add(
        _buildActionButton(
          context,
          'View Details',
          Icons.info,
          Colors.blue,
          () => _viewTaskDetails(context, taskId),
        ),
      );
    } else if (status == 'completed') {
      if (paymentStatus == 'pending') {
        buttons.add(
          _buildActionButton(
            context,
            'Request Payment',
            Icons.payment,
            Colors.orange,
            () => _requestPayment(context, taskId),
          ),
        );
      }
      buttons.add(
        _buildActionButton(
          context,
          'View Details',
          Icons.info,
          Colors.blue,
          () => _viewTaskDetails(context, taskId),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  void _completeTask(BuildContext context, String taskId, String taskTitle, double taskAmount) {
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

  Future<void> _requestPayment(BuildContext context, String taskId) async {
    try {
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();
      
      if (!taskDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task not found')),
        );
        return;
      }

      final taskData = taskDoc.data()!;
      final completionStatus = taskData['completionStatus'];

      if (completionStatus != 'approved') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task completion must be approved before requesting payment'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'paymentRequested': true,
        'paymentRequestedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment request sent to task poster'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusBadge(String status, String paymentStatus) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status) {
      case 'open':
        badgeColor = Colors.blue;
        badgeText = 'Open';
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
        if (paymentStatus == 'pending') {
          badgeColor = Colors.orange;
          badgeText = 'Awaiting Payment';
          badgeIcon = Icons.payment;
        } else if (paymentStatus == 'paid') {
          badgeColor = Colors.green;
          badgeText = 'Completed & Paid';
          badgeIcon = Icons.check_circle;
        } else {
          badgeColor = Colors.green;
          badgeText = 'Completed';
          badgeIcon = Icons.check_circle;
        }
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String taskId, String status, String paymentStatus, String? assignedTo) {
    List<Widget> buttons = [];

    switch (status) {
      case 'open':
        buttons.addAll([
          _buildActionButton(
            context,
            'View Offers',
            Icons.list_alt,
            Colors.blue,
            () => _viewOffers(context, taskId),
          ),
          _buildActionButton(
            context,
            'Edit Task',
            Icons.edit,
            Colors.orange,
            () => _editTask(context, taskId),
          ),
          _buildActionButton(
            context,
            'Cancel Task',
            Icons.cancel,
            Colors.red,
            () => _cancelTask(context, taskId),
          ),
        ]);
        break;
      
      case 'assigned':
        if (paymentStatus == 'pending') {
          buttons.addAll([
            _buildActionButton(
              context,
              'Release Payment',
              Icons.payment,
              Colors.green,
              () => _releasePayment(context, taskId),
            ),
            _buildActionButton(
              context,
              'View Details',
              Icons.info,
              Colors.blue,
              () => _viewTaskDetails(context, taskId),
            ),
          ]);
        } else if (paymentStatus == 'paid') {
          buttons.addAll([
            _buildActionButton(
              context,
              'Mark Complete',
              Icons.check_circle,
              Colors.green,
              () => _markComplete(context, taskId),
            ),
            _buildActionButton(
              context,
              'View Progress',
              Icons.timeline,
              Colors.blue,
              () => _viewProgress(context, taskId),
            ),
          ]);
        }
        break;
      
      case 'in_progress':
        buttons.addAll([
          _buildActionButton(
            context,
            'Mark Complete',
            Icons.check_circle,
            Colors.green,
            () => _markComplete(context, taskId),
          ),
          _buildActionButton(
            context,
            'View Progress',
            Icons.timeline,
            Colors.blue,
            () => _viewProgress(context, taskId),
          ),
        ]);
        break;
      
      case 'pending_whatsapp_approval':
        buttons.addAll([
          _buildActionButton(
            context,
            'Approve',
            Icons.check_circle,
            Colors.green,
            () => _approveWhatsAppProof(context, taskId),
          ),
          _buildActionButton(
            context,
            'Reject',
            Icons.cancel,
            Colors.red,
            () => _rejectWhatsAppProof(context, taskId),
          ),
          _buildActionButton(
            context,
            'View Details',
            Icons.info,
            Colors.blue,
            () => _viewTaskDetails(context, taskId),
          ),
        ]);
        break;
      
      case 'completed':
        buttons.addAll([
          _buildActionButton(
            context,
            'Rate Service',
            Icons.star,
            Colors.orange,
            () => _rateService(context, taskId),
          ),
          _buildActionButton(
            context,
            'View Details',
            Icons.info,
            Colors.blue,
            () => _viewTaskDetails(context, taskId),
          ),
        ]);
        break;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Action Methods
  void _viewOffers(BuildContext context, String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(taskId: taskId),
      ),
    );
  }

  void _editTask(BuildContext context, String taskId) {
    // Navigate to edit task
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editing task: $taskId')),
    );
  }

  void _cancelTask(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Task'),
        content: const Text('Are you sure you want to cancel this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateTaskStatus(taskId, 'cancelled');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _releasePayment(BuildContext context, String taskId) async {
    try {
      // Get task details first
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();
      
      if (!taskDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task not found')),
        );
        return;
      }

      final taskData = taskDoc.data()!;
      final taskAmount = (taskData['budget'] as num? ?? 0).toDouble();
      final assignedTo = taskData['assignedTo'] as String?;
      final taskTitle = taskData['title'] ?? 'Task';
      final status = taskData['status'] ?? 'open';
      final completionStatus = taskData['completionStatus'];
      final paymentRequested = taskData['paymentRequested'] ?? false;
      
      if (assignedTo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No provider assigned to this task')),
        );
        return;
      }

      // Check if task is completed and payment is requested
      if (status != 'completed' || completionStatus != 'approved') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Task Not Completed'),
            content: Text(
              status == 'completed' && completionStatus == 'pending_review'
                  ? 'Task completion is pending review. Please wait for approval before releasing payment.'
                  : 'Task must be completed and approved before releasing payment. The service provider needs to upload completion images first.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      if (!paymentRequested) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Not Requested'),
            content: const Text(
              'The service provider has not requested payment yet. Please wait for them to request payment after completing the task.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Get provider name
      final providerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(assignedTo)
          .get();
      final providerName = providerDoc.data()?['fullName'] ?? 
                          providerDoc.data()?['name'] ?? 
                          'Service Provider';

      // Navigate to payment confirmation screen
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentConfirmationScreen(
            taskId: taskId,
            providerId: assignedTo,
            taskTitle: taskTitle,
            taskAmount: taskAmount,
            providerName: providerName,
          ),
        ),
      );

      // If payment was successful, refresh the screen
      if (result == true && mounted) {
        setState(() {}); // Refresh the state
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processPaymentRelease(
    BuildContext context,
    String taskId,
    String providerId,
    double taskAmount,
  ) async {
    try {
      // Check if task is completed first
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();
      
      if (!taskDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task not found')),
        );
        return;
      }

      final taskData = taskDoc.data()!;
      final status = taskData['status'] ?? 'open';
      final completionStatus = taskData['completionStatus'];
      final paymentRequested = taskData['paymentRequested'] ?? false;

      // Check if task is completed and payment is requested
      if (status != 'completed' || completionStatus != 'approved') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Task Not Completed'),
            content: Text(
              status == 'completed' && completionStatus == 'pending_review'
                  ? 'Task completion is pending review. Please wait for approval before releasing payment.'
                  : 'Task must be completed and approved before releasing payment. The service provider needs to upload completion images first.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      if (!paymentRequested) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Not Requested'),
            content: const Text(
              'The service provider has not requested payment yet. Please wait for them to request payment after completing the task.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Import points service
      final pointsService = PointsService();
      
      // Process payment with commission
      final result = await pointsService.processTaskPayment(
        taskId: taskId,
        providerId: providerId,
        taskPoints: taskAmount,
      );

      // Close loading
      if (context.mounted) Navigator.pop(context);

      if (result['success']) {
        // Update payment status
        await _updatePaymentStatus(taskId, 'paid');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment released successfully!\n'
                  'Platform Commission: ${result['platformCommission'].toStringAsFixed(0)} Points\n'
                  'Provider Payout: ${result['providerPayout'].toStringAsFixed(0)} Points'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _markComplete(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Complete'),
        content: const Text('Are you sure you want to mark this task as complete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateTaskStatus(taskId, 'completed');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );
  }

  void _viewTaskDetails(BuildContext context, String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(taskId: taskId),
      ),
    );
  }

  void _viewProgress(BuildContext context, String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(taskId: taskId),
      ),
    );
  }

  void _rateService(BuildContext context, String taskId) {
    // Navigate to rating screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rating service for task: $taskId')),
    );
  }

  Future<void> _approveWhatsAppProof(BuildContext context, String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Task Completion'),
        content: const Text(
          'Are you satisfied with the task completion? This will allow the service provider to request payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get task data
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();
      final taskData = taskDoc.data();
      if (taskData == null) return;

      final providerId = taskData['completedBy'];
      final taskTitle = taskData['title'] ?? 'Task';

      // Update task status to "approved"
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'status': 'approved',
        'completionStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update task_completions document
      await FirebaseFirestore.instance
          .collection('task_completions')
          .doc(taskId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to provider
      if (providerId != null) {
        final user = FirebaseAuth.instance.currentUser;
        final clientName = user?.displayName ?? 'Client';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .collection('notifications')
            .add({
          'type': 'task_approved',
          'title': '✅ Task Approved!',
          'body': 'Your completion proof for "$taskTitle" has been approved. You can now request payment.',
          'taskId': taskId,
          'taskTitle': taskTitle,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'isRead': false,
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectWhatsAppProof(BuildContext context, String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Task Completion'),
        content: const Text(
          'Are you sure you want to reject this completion? The service provider will need to resubmit proof.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get task data
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();
      final taskData = taskDoc.data();
      if (taskData == null) return;

      final providerId = taskData['completedBy'];
      final taskTitle = taskData['title'] ?? 'Task';

      // Update task status back to "in_progress" or "assigned"
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'status': 'in_progress',
        'completionStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update task_completions document
      await FirebaseFirestore.instance
          .collection('task_completions')
          .doc(taskId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to provider
      if (providerId != null) {
        final user = FirebaseAuth.instance.currentUser;
        final clientName = user?.displayName ?? 'Client';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .collection('notifications')
            .add({
          'type': 'task_rejected',
          'title': '❌ Task Rejected',
          'body': 'Your completion proof for "$taskTitle" has been rejected. Please resubmit proof images.',
          'taskId': taskId,
          'taskTitle': taskTitle,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'isRead': false,
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task rejected. Service provider will be notified.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateTaskStatus(String taskId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating task status: $e');
    }
  }

  Future<void> _updatePaymentStatus(String taskId, String paymentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({
        'paymentStatus': paymentStatus,
        'paymentReleasedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating payment status: $e');
    }
  }
}

// 👇 Widget shown when user has no tasks
class _NoTasksWidget extends StatelessWidget {
  const _NoTasksWidget();

    
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/images/animations/dinodance.json',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'No tasks found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You haven\'t posted any tasks yet. Tap the button below to post your first task!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TaskTitleScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C7BE),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Post a Task',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
