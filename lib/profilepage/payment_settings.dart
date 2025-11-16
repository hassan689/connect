import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkster/services/points_service.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PointsService _pointsService = PointsService();
  double _pointsBalance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPointsData();
  }

  Future<void> _loadPointsData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _pointsBalance = await _pointsService.getUserPoints(user.uid);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading points data: $e');
      setState(() => _isLoading = false);
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
          'Payment Settings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Points Balance Card
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
                              Icons.stars,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Points Balance',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_pointsBalance.toStringAsFixed(0)} Points',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showAddPointsDialog();
                                },
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: Text(
                                  'Earn Points',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showPointsInfoDialog();
                                },
                                icon: const Icon(Icons.info_outline, color: Colors.white),
                                label: Text(
                                  'How Points Work',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Points Information Section
                  _sectionTitle('Points System'),
                  _infoCard(
                    icon: Icons.info_outline,
                    title: 'How Points Work',
                    subtitle: 'Learn about earning and using points',
                    onTap: () => _showPointsInfoDialog(),
                  ),
                  _infoCard(
                    icon: Icons.star,
                    title: 'Earn Points',
                    subtitle: 'Complete tasks to earn points',
                    onTap: () => _showEarnPointsDialog(),
                  ),
                  const SizedBox(height: 24),

                  // Transaction History Section
                  _sectionTitle('Recent Transactions'),
                  _buildTransactionHistory(),
                  const SizedBox(height: 24),

                  // Security Section
                  _sectionTitle('Security'),
                  _settingCard(
                    icon: Icons.security,
                    title: 'Payment Security',
                    subtitle: 'Manage payment security settings',
                    onTap: () => _showSecuritySettings(),
                  ),
                  _settingCard(
                    icon: Icons.notifications,
                    title: 'Payment Notifications',
                    subtitle: 'Get notified about transactions',
                    onTap: () => _showNotificationSettings(),
                  ),
                ],
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

  Widget _settingCard({
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
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.grey[700]),
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

  Widget _buildTransactionHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _pointsService.getUserPointTransactions(user.uid, limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your point transaction history will appear here',
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
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final points = (data['points'] as num).toDouble();
            final type = data['type'] as String;
            final description = data['description'] as String? ?? '';
            final timestamp = (data['timestamp'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: type == 'credit' 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    type == 'credit' ? Icons.add : Icons.remove,
                    color: type == 'credit' ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  description,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${timestamp.day}/${timestamp.month}/${timestamp.year}',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                trailing: Text(
                  '${type == 'credit' ? '+' : '-'}${points.toStringAsFixed(0)} pts',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: type == 'credit' ? Colors.green : Colors.red,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _infoCard({
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

  void _showAddPointsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Earn Points', style: GoogleFonts.poppins()),
        content: Text(
          'Complete tasks as a service provider to earn points!\n\n'
          '• Complete a task: Earn 90% of task points\n'
          '• Platform commission: 10%\n\n'
          'Points can be used to post tasks and pay for services.',
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

  void _showPointsInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('How Points Work', style: GoogleFonts.poppins()),
        content: SingleChildScrollView(
          child: Text(
            'Points System Overview:\n\n'
            '✓ Points are used instead of money\n'
            '✓ Earn points by completing tasks\n'
            '✓ Use points to post and pay for tasks\n'
            '✓ Platform takes 10% commission\n'
            '✓ Service providers receive 90% of points\n\n'
            'This is a point-based economy system for the Connect platform.',
            style: GoogleFonts.poppins(),
          ),
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

  void _showEarnPointsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Earn Points', style: GoogleFonts.poppins()),
        content: Text(
          'Ways to earn points:\n\n'
          '1. Complete tasks as a service provider\n'
          '2. Receive points when tasks you posted are completed\n'
          '3. Participate in platform activities\n\n'
          'Start by browsing available tasks!',
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

  void _showSecuritySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Security Settings', style: GoogleFonts.poppins()),
        content: Text(
          'Payment security settings will be available soon!',
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

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notifications', style: GoogleFonts.poppins()),
        content: Text(
          'Payment notification settings will be available soon!',
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
} 