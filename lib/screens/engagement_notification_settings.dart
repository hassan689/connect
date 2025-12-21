import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connect/services/engagement_notifications.dart';

class EngagementNotificationSettings extends StatefulWidget {
  const EngagementNotificationSettings({super.key});

  @override
  State<EngagementNotificationSettings> createState() => _EngagementNotificationSettingsState();
}

class _EngagementNotificationSettingsState extends State<EngagementNotificationSettings> {
  final EngagementNotificationService _notificationService = EngagementNotificationService();
  
  bool _jokesEnabled = true;
  bool _tipsEnabled = true;
  bool _motivationalEnabled = true;
  bool _dailyEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await _notificationService.getUserEngagementStats();
      // You can load saved preferences here when implemented
    } catch (e) {
      print('Error loading preferences: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);
    
    try {
      await _notificationService.updateNotificationPreferences(
        jokes: _jokesEnabled,
        tips: _tipsEnabled,
        motivational: _motivationalEnabled,
        daily: _dailyEnabled,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Notification preferences saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.sendImmediateEngagementNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📱 Test notification sent!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error sending test notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Engagement Notifications',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF00C7BE)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFF00C7BE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: Color(0xFF00C7BE),
                          size: 32,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stay Engaged! 🎉',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00C7BE),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Get fun notifications to keep you motivated and engaged with Connect!',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Notification Types
                  Text(
                    'Notification Types',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Jokes
                  _buildNotificationOption(
                    icon: Icons.sentiment_satisfied_alt,
                    title: '😄 Dino Jokes',
                    subtitle: 'Fun jokes to brighten your day',
                    enabled: _jokesEnabled,
                    onChanged: (value) => setState(() => _jokesEnabled = value),
                  ),
                  
                  // Tips
                  _buildNotificationOption(
                    icon: Icons.lightbulb,
                    title: '💡 Pro Tips',
                    subtitle: 'Helpful tips to improve your experience',
                    enabled: _tipsEnabled,
                    onChanged: (value) => setState(() => _tipsEnabled = value),
                  ),
                  
                  // Motivational
                  _buildNotificationOption(
                    icon: Icons.psychology,
                    title: '🌟 Motivation',
                    subtitle: 'Inspiring messages to keep you going',
                    enabled: _motivationalEnabled,
                    onChanged: (value) => setState(() => _motivationalEnabled = value),
                  ),
                  
                  // Daily
                  _buildNotificationOption(
                    icon: Icons.schedule,
                    title: '📅 Daily Notifications',
                    subtitle: 'Receive notifications once per day',
                    enabled: _dailyEnabled,
                    onChanged: (value) => setState(() => _dailyEnabled = value),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Test Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testNotification,
                      icon: Icon(Icons.send, color: Colors.white),
                      label: Text(
                        'Send Test Notification',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Save Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePreferences,
                      child: Text(
                        'Save Preferences',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00C7BE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Info Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                            SizedBox(width: 8),
                            Text(
                              'How it works',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '• You\'ll receive one notification per day\n'
                          '• Notifications are sent at random times\n'
                          '• Content rotates between jokes, tips, and motivation\n'
                          '• You can disable any type you don\'t want',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        value: enabled,
        onChanged: onChanged,
        title: Row(
          children: [
            Icon(icon, color: Color(0xFF00C7BE), size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(left: 36),
          child: Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        activeColor: Color(0xFF00C7BE),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
} 