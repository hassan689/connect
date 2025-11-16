import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkster/examples/chart_navigation.dart';
import 'package:linkster/ai_services/ai_demo_screen.dart';

class TaskerDashboardScreen extends StatefulWidget {
  const TaskerDashboardScreen({super.key});

  @override
  State<TaskerDashboardScreen> createState() => _TaskerDashboardScreenState();
}

class _TaskerDashboardScreenState extends State<TaskerDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  double _parseBudget(dynamic budget) {
    if (budget == null) return 0.0;
    if (budget is num) return budget.toDouble();
    if (budget is String) {
      // Remove any currency symbols and whitespace
      final cleanBudget = budget.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanBudget) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);
      
      final user = _auth.currentUser;
      if (user != null) {
        // Load user's tasks
        final tasksSnapshot = await _firestore
            .collection('tasks')
            .where('userId', isEqualTo: user.uid)
            .get();

        final tasks = tasksSnapshot.docs.map((doc) => doc.data()).toList();
        
        // Calculate statistics with error handling
        final completedTasks = tasks.where((task) => task['status'] == 'completed').length;
        final pendingTasks = tasks.where((task) => task['status'] == 'pending').length;
        final totalEarnings = tasks
            .where((task) => task['status'] == 'completed')
            .fold(0.0, (sum, task) => sum + _parseBudget(task['budget']));
        
        // Calculate average rating with error handling
        final completedTasksWithRating = tasks.where((task) => 
            task['status'] == 'completed' && task['rating'] != null).toList();
        final averageRating = completedTasksWithRating.isEmpty 
            ? 0.0 
            : completedTasksWithRating.fold(0.0, (sum, task) {
                try {
                  return sum + (task['rating'] as num? ?? 0);
                } catch (e) {
                  print('Error parsing rating: $e');
                  return sum;
                }
              }) / completedTasksWithRating.length;

        setState(() {
          _dashboardData = {
            'totalTasks': tasks.length,
            'completedTasks': completedTasks,
            'pendingTasks': pendingTasks,
            'totalEarnings': totalEarnings,
            'averageRating': averageRating,
            'recentTasks': tasks.take(5).toList(),
            'monthlyEarnings': _calculateMonthlyEarnings(tasks),
            'weeklyEarnings': _calculateWeeklyEarnings(tasks),
          };
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
        _dashboardData = {
          'totalTasks': 0,
          'completedTasks': 0,
          'pendingTasks': 0,
          'totalEarnings': 0.0,
          'averageRating': 0.0,
          'recentTasks': [],
          'monthlyEarnings': 0.0,
          'weeklyEarnings': 0.0,
        };
      });
    }
  }

  double _calculateMonthlyEarnings(List<Map<String, dynamic>> tasks) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    return tasks
        .where((task) {
          final taskDate = (task['createdAt'] as Timestamp?)?.toDate();
          return task['status'] == 'completed' && 
                 taskDate != null && 
                 taskDate.isAfter(monthStart);
        })
        .fold(0.0, (sum, task) => sum + _parseBudget(task['budget']));
  }

  double _calculateWeeklyEarnings(List<Map<String, dynamic>> tasks) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return tasks
        .where((task) {
          final taskDate = (task['createdAt'] as Timestamp?)?.toDate();
          return task['status'] == 'completed' && 
                 taskDate != null && 
                 taskDate.isAfter(weekStart);
        })
        .fold(0.0, (sum, task) => sum + _parseBudget(task['budget']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C7BE),
        elevation: 0,
        title: Text(
          'My Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _loadDashboardData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00C7BE),
              ),
            )
          : _dashboardData['totalTasks'] == 0
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C7BE), Color(0xFF00A8A0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C7BE).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.dashboard,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Welcome Back!',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Here\'s your task performance overview',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Statistics Cards
                        _sectionTitle('Statistics'),
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                icon: Icons.task,
                                title: 'Total Tasks',
                                value: _dashboardData['totalTasks']?.toString() ?? '0',
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                icon: Icons.check_circle,
                                title: 'Completed',
                                value: _dashboardData['completedTasks']?.toString() ?? '0',
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                icon: Icons.pending,
                                title: 'Pending',
                                value: _dashboardData['pendingTasks']?.toString() ?? '0',
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                icon: Icons.star,
                                title: 'Rating',
                                value: _dashboardData['averageRating']?.toStringAsFixed(1) ?? '0.0',
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Earnings Section
                        _sectionTitle('Earnings'),
                        _earningsCard(),
                        const SizedBox(height: 24),

                        // Recent Tasks Section
                        _sectionTitle('Recent Tasks'),
                        _buildRecentTasks(),
                        const SizedBox(height: 24),

                        // Performance Metrics
                        _sectionTitle('Performance'),
                        _performanceCard(),
                        const SizedBox(height: 24),

                        // Quick Actions
                        _sectionTitle('Quick Actions'),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _earningsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: const Color(0xFF00C7BE).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.currency_rupee,
                    color: Color(0xFF00C7BE),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Total Earnings',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
                              'Rs ${_dashboardData['totalEarnings']?.toStringAsFixed(2) ?? '0.00'}',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00C7BE),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Week',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Rs ${_dashboardData['weeklyEarnings']?.toStringAsFixed(2) ?? '0.00'}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Month',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Rs ${_dashboardData['monthlyEarnings']?.toStringAsFixed(2) ?? '0.00'}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTasks() {
    final recentTasks = _dashboardData['recentTasks'] as List<dynamic>? ?? [];
    
    if (recentTasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.task_alt,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'No tasks yet',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start posting tasks to see them here',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: recentTasks.map((task) {
        final taskData = task as Map<String, dynamic>;
        final status = taskData['status'] as String? ?? 'pending';
        final title = taskData['title'] as String? ?? 'Untitled Task';
        final budget = _parseBudget(taskData['budget']);
        final createdAt = taskData['createdAt'] as Timestamp?;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
              ),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              createdAt != null 
                  ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
                  : 'No date',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs ${budget.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00C7BE),
                  ),
                ),
                Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _performanceCard() {
    final completedTasks = _dashboardData['completedTasks'] ?? 0;
    final totalTasks = _dashboardData['totalTasks'] ?? 0;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;
    final averageRating = _dashboardData['averageRating'] ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        value: completionRate / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C7BE)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${completionRate.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Completion Rate',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < averageRating.floor() 
                                ? Icons.star 
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Average Rating',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _actionCard(
          icon: Icons.add_task,
          title: 'Post New Task',
          subtitle: 'Create a new task',
          onTap: () => _postNewTask(),
        ),
        _actionCard(
          icon: Icons.history,
          title: 'Task History',
          subtitle: 'View all your tasks',
          onTap: () => _viewTaskHistory(),
        ),
        _actionCard(
          icon: Icons.analytics,
          title: 'Analytics & Charts',
          subtitle: 'View charts and insights',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChartNavigationScreen()),
          ),
        ),
        _actionCard(
          icon: Icons.psychology,
          title: 'AI Features',
          subtitle: 'Try AI-powered enhancements',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIDemoScreen()),
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00C7BE).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF00C7BE)),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'in_progress':
        return Icons.play_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.task;
    }
  }

  void _postNewTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Post New Task', style: GoogleFonts.poppins()),
        content: Text(
          'Navigate to the task posting section to create a new task.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _viewTaskHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Task History', style: GoogleFonts.poppins()),
        content: Text(
          'Task history view will be available soon!',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _viewAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analytics', style: GoogleFonts.poppins()),
        content: Text(
          'Detailed analytics will be available soon!',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found for your account.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start posting tasks to see them here.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 