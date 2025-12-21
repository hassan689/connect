import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:connect/core/theme/app_theme.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  
  // Chart data
  List<TaskData> _taskCompletionData = [];
  List<RevenueData> _revenueData = [];
  List<CategoryData> _categoryData = [];
  List<MonthlyData> _monthlyData = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Load task completion data (last 7 days)
      await _loadTaskCompletionData(user.uid);
      
      // Load revenue data (last 6 months)
      await _loadRevenueData(user.uid);
      
      // Load category distribution
      await _loadCategoryData(user.uid);
      
      // Load monthly trends
      await _loadMonthlyData(user.uid);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _parseBudget(dynamic budget) {
    if (budget == null) return 0.0;
    if (budget is num) return budget.toDouble();
    if (budget is String) {
      final cleanBudget = budget.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanBudget) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _loadTaskCompletionData(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .get();

      final Map<String, int> dayCounts = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };

      for (var doc in tasksSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final date = createdAt.toDate();
          final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
          dayCounts[dayName] = (dayCounts[dayName] ?? 0) + 1;
        }
      }

      _taskCompletionData = dayCounts.entries
          .map((e) => TaskData(e.key, e.value))
          .toList();
    } catch (e) {
      print('Error loading task completion data: $e');
      _taskCompletionData = [];
    }
  }

  Future<void> _loadRevenueData(String userId) async {
    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
          .get();

      final Map<String, double> monthRevenue = {};
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      for (var doc in tasksSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final date = createdAt.toDate();
          final monthName = monthNames[date.month - 1];
          final budget = _parseBudget(data['budget']);
          monthRevenue[monthName] = (monthRevenue[monthName] ?? 0.0) + budget;
        }
      }

      // Get last 6 months
      final last6Months = <String>[];
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        last6Months.add(monthNames[month.month - 1]);
      }

      _revenueData = last6Months
          .map((month) => RevenueData(month, monthRevenue[month] ?? 0.0))
          .toList();
    } catch (e) {
      print('Error loading revenue data: $e');
      _revenueData = [];
    }
  }

  Future<void> _loadCategoryData(String userId) async {
    try {
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      final Map<String, int> categoryCounts = {};
      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.red,
        Colors.purple,
        Colors.teal,
        Colors.pink,
        Colors.amber,
      ];

      for (var doc in tasksSnapshot.docs) {
        final data = doc.data();
        final category = data['aiCategory'] as String? ?? 
                        data['taskType'] as String? ?? 
                        'Other';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      final total = categoryCounts.values.fold(0, (sum, count) => sum + count);
      if (total == 0) {
        _categoryData = [];
        return;
      }

      final sortedCategories = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      _categoryData = sortedCategories.take(8).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final categoryEntry = entry.value;
        return CategoryData(
          categoryEntry.key,
          (categoryEntry.value / total * 100),
          colors[index % colors.length],
        );
      }).toList();
    } catch (e) {
      print('Error loading category data: $e');
      _categoryData = [];
    }
  }

  Future<void> _loadMonthlyData(String userId) async {
    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
          .get();

      final Map<String, int> monthTaskCounts = {};
      final Map<String, double> monthRevenue = {};
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      for (var doc in tasksSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final date = createdAt.toDate();
          final monthName = monthNames[date.month - 1];
          monthTaskCounts[monthName] = (monthTaskCounts[monthName] ?? 0) + 1;
          
          if (data['status'] == 'completed') {
            final budget = _parseBudget(data['budget']);
            monthRevenue[monthName] = (monthRevenue[monthName] ?? 0.0) + budget;
          }
        }
      }

      // Get last 6 months
      final last6Months = <String>[];
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        last6Months.add(monthNames[month.month - 1]);
      }

      _monthlyData = last6Months
          .map((month) => MonthlyData(
                month,
                monthTaskCounts[month] ?? 0,
                monthRevenue[month] ?? 0.0,
              ))
          .toList();
    } catch (e) {
      print('Error loading monthly data: $e');
      _monthlyData = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C7BE),
        elevation: 0,
        title: Text(
          'Analytics Dashboard',
          style: AppTheme.appBarTitle.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  
                  // Task Completion Chart
                  _buildTaskCompletionChart(),
                  const SizedBox(height: 24),
                  
                  // Revenue Chart
                  _buildRevenueChart(),
                  const SizedBox(height: 24),
                  
                  // Category Distribution
                  _buildCategoryChart(),
                  const SizedBox(height: 24),
                  
                  // Monthly Trends
                  _buildMonthlyTrendsChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Tasks',
            '156',
            Icons.task_alt,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Completed',
            '142',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Revenue',
            'Rs 24.5K',
            Icons.currency_rupee,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Icon(Icons.trending_up, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.heading3.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCompletionChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Completion (Last 7 Days)',
            style: AppTheme.heading4,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(),
              series: <CartesianSeries>[
                ColumnSeries<TaskData, String>(
                  dataSource: _taskCompletionData,
                  xValueMapper: (TaskData data, _) => data.day,
                  yValueMapper: (TaskData data, _) => data.tasks,
                  name: 'Tasks Completed',
                  color: const Color(0xFF00C7BE),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Revenue',
            style: AppTheme.heading4,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(),
              series: <CartesianSeries>[
                LineSeries<RevenueData, String>(
                  dataSource: _revenueData,
                  xValueMapper: (RevenueData data, _) => data.month,
                  yValueMapper: (RevenueData data, _) => data.revenue,
                  name: 'Revenue',
                  color: const Color(0xFF00C7BE),
                  width: 3,
                  markerSettings: const MarkerSettings(isVisible: true),
                ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Categories',
            style: AppTheme.heading4,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCircularChart(
              series: <CircularSeries>[
                PieSeries<CategoryData, String>(
                  dataSource: _categoryData,
                  xValueMapper: (CategoryData data, _) => data.category,
                  yValueMapper: (CategoryData data, _) => data.percentage,
                  pointColorMapper: (CategoryData data, _) => data.color,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                  ),
                ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendsChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Trends',
            style: AppTheme.heading4,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(),
              series: <CartesianSeries>[
                ColumnSeries<MonthlyData, String>(
                  dataSource: _monthlyData,
                  xValueMapper: (MonthlyData data, _) => data.month,
                  yValueMapper: (MonthlyData data, _) => data.tasks,
                  name: 'Tasks',
                  color: Colors.blue.withValues(alpha: 0.7),
                ),
                LineSeries<MonthlyData, String>(
                  dataSource: _monthlyData,
                  xValueMapper: (MonthlyData data, _) => data.month,
                  yValueMapper: (MonthlyData data, _) => data.revenue / 100,
                  name: 'Revenue (K)',
                  color: const Color(0xFF00C7BE),
                  width: 3,
                  markerSettings: const MarkerSettings(isVisible: true),
                ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ),
        ],
      ),
    );
  }
}

// Data classes for charts
class TaskData {
  final String day;
  final int tasks;

  TaskData(this.day, this.tasks);
}

class RevenueData {
  final String month;
  final double revenue;

  RevenueData(this.month, this.revenue);
}

class CategoryData {
  final String category;
  final double percentage;
  final Color color;

  CategoryData(this.category, this.percentage, this.color);
}

class MonthlyData {
  final String month;
  final int tasks;
  final double revenue;

  MonthlyData(this.month, this.tasks, this.revenue);
} 