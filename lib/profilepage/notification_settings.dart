import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connect/screens/engagement_notification_settings.dart';
import 'package:connect/screens/language_selection_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, bool> _notificationSettings = {};

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          final notificationData = data['notificationSettings'] as Map<String, dynamic>? ?? {};
          
          setState(() {
            _notificationSettings = {
              'pushNotifications': notificationData['pushNotifications'] ?? true,
              'emailNotifications': notificationData['emailNotifications'] ?? true,
              'taskAlerts': notificationData['taskAlerts'] ?? true,
              'messageNotifications': notificationData['messageNotifications'] ?? true,
              'paymentNotifications': notificationData['paymentNotifications'] ?? true,
              'reviewNotifications': notificationData['reviewNotifications'] ?? true,
              'promotionalNotifications': notificationData['promotionalNotifications'] ?? false,
              'soundEnabled': notificationData['soundEnabled'] ?? true,
              'vibrationEnabled': notificationData['vibrationEnabled'] ?? true,
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'notificationSettings.$key': value,
        });
        
        setState(() {
          _notificationSettings[key] = value;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getSettingName(key)} ${value ? 'enabled' : 'disabled'}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating notification setting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update setting')),
        );
      }
    }
  }

  String _getSettingName(String key) {
    switch (key) {
      case 'pushNotifications':
        return 'Push notifications';
      case 'emailNotifications':
        return 'Email notifications';
      case 'taskAlerts':
        return 'Task alerts';
      case 'messageNotifications':
        return 'Message notifications';
      case 'paymentNotifications':
        return 'Payment notifications';
      case 'reviewNotifications':
        return 'Review notifications';
      case 'promotionalNotifications':
        return 'Promotional notifications';
      case 'soundEnabled':
        return 'Sound';
      case 'vibrationEnabled':
        return 'Vibration';
      default:
        return 'Notification';
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
          'Notification Settings',
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
                  // Notification Status Card
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
                              Icons.notifications_active,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Notification Status',
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
                          _notificationSettings['pushNotifications'] == true ? 'Enabled' : 'Disabled',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage how you receive notifications',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // General Notifications Section
                  _sectionTitle('General Notifications'),
                  _notificationCard(
                    icon: Icons.notifications,
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications on your device',
                    value: _notificationSettings['pushNotifications'] ?? true,
                    onChanged: (value) => _updateNotificationSetting('pushNotifications', value),
                  ),
                  _notificationCard(
                    icon: Icons.email,
                    title: 'Email Notifications',
                    subtitle: 'Receive notifications via email',
                    value: _notificationSettings['emailNotifications'] ?? true,
                    onChanged: (value) => _updateNotificationSetting('emailNotifications', value),
                  ),
                  const SizedBox(height: 24),

                  // Task Notifications Section
                  _sectionTitle('Task Notifications'),
                  _notificationCard(
                    icon: Icons.task,
                    title: 'Task Alerts',
                    subtitle: 'Get notified about new relevant tasks',
                    value: _notificationSettings['taskAlerts'] ?? true,
                    onChanged: (value) => _updateNotificationSetting('taskAlerts', value),
                  ),
                  _notificationCard(
                    icon: Icons.message,
                    title: 'Message Notifications',
                    subtitle: 'Get notified about new messages',
                    value: _notificationSettings['messageNotifications'] ?? true,
                    onChanged: (value) => _updateNotificationSetting('messageNotifications', value),
                  ),
                  const SizedBox(height: 24),

                  // Payment Notifications Section
                  _sectionTitle('Payment Notifications'),
                  _notificationCard(
                    icon: Icons.payment,
                    title: 'Payment Notifications',
                    subtitle: 'Get notified about payment activities',
                    value: _notificationSettings['paymentNotifications'] ?? true,
                    onChanged: (value) => _updateNotificationSetting('paymentNotifications', value),
                  ),
                  _notificationCard(
                    icon: Icons.star,
                    title: 'Review Notifications',
                    subtitle: 'Get notified about new reviews',
                    value: _notificationSettings['reviewNotifications'] ?? true,
                    onChanged: (value) => _updateNotificationSetting('reviewNotifications', value),
                  ),
                  const SizedBox(height: 24),

                  // Promotional Notifications Section
                  _sectionTitle('Promotional Notifications'),
                  _notificationCard(
                    icon: Icons.local_offer,
                    title: 'Promotional Notifications',
                    subtitle: 'Receive offers and promotional content',
                    value: _notificationSettings['promotionalNotifications'] ?? false,
                    onChanged: (value) => _updateNotificationSetting('promotionalNotifications', value),
                  ),
                  const SizedBox(height: 24),

                  // Engagement Notifications Section
                  _sectionTitle('Engagement Notifications'),
                  _actionCard(
                    icon: Icons.sentiment_satisfied_alt,
                    title: 'Fun & Motivational Notifications',
                    subtitle: 'Get jokes, tips, and motivational messages',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EngagementNotificationSettings(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notification Behavior Section
                  _sectionTitle('Notification Behavior'),
                  _notificationCard(
                    icon: Icons.volume_up,
                    title: 'Sound',
                    subtitle: 'Play sound for notifications',
                    value: _notificationSettings['soundEnabled'] ?? true,
                    onChanged: (value) => _updateNotificationSetting('soundEnabled', value),
                  ),
                  _notificationCard(
                    icon: Icons.vibration,
                    title: 'Vibration',
                    subtitle: 'Vibrate for notifications',
                    value: _notificationSettings['vibrationEnabled'] ?? true,
                    onChanged: (value) => _updateNotificationSetting('vibrationEnabled', value),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions Section
                  _sectionTitle('Quick Actions'),
                  _actionCard(
                    icon: Icons.settings,
                    title: 'Test Notifications',
                    subtitle: 'Send a test notification',
                    onTap: () => _testNotification(),
                  ),
                                          _actionCard(
                          icon: Icons.language,
                          title: 'Language',
                          subtitle: 'Change app language',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LanguageSelectionScreen(),
                            ),
                          ),
                        ),
                  _actionCard(
                    icon: Icons.schedule,
                    title: 'Quiet Hours',
                    subtitle: 'Set quiet hours for notifications',
                    onTap: () => _showQuietHoursDialog(),
                  ),
                  _actionCard(
                    icon: Icons.clear_all,
                    title: 'Clear All Settings',
                    subtitle: 'Reset to default settings',
                    onTap: () => _resetToDefaults(),
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

  Widget _notificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
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
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF00C7BE),
        ),
      ),
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
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue),
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

  void _testNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test Notification', style: GoogleFonts.poppins()),
        content: Text(
          'A test notification will be sent to your device.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test notification sent!'),
                  backgroundColor: Color(0xFF00C7BE),
                ),
              );
            },
            child: Text('Send Test', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showQuietHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quiet Hours', style: GoogleFonts.poppins()),
        content: Text(
          'Quiet hours functionality will be available soon!',
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

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Settings', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to reset all notification settings to default?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetNotificationSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetNotificationSettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final defaultSettings = {
          'pushNotifications': true,
          'emailNotifications': true,
          'taskAlerts': true,
          'messageNotifications': true,
          'paymentNotifications': true,
          'reviewNotifications': true,
          'promotionalNotifications': false,
          'soundEnabled': true,
          'vibrationEnabled': true,
        };

        await _firestore.collection('users').doc(user.uid).update({
          'notificationSettings': defaultSettings,
        });

        setState(() {
          _notificationSettings = defaultSettings;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification settings reset to default'),
              backgroundColor: Color(0xFF00C7BE),
            ),
          );
        }
      }
    } catch (e) {
      print('Error resetting notification settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reset settings')),
        );
      }
    }
  }
} 