import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskAlertsScreen extends StatefulWidget {
  const TaskAlertsScreen({super.key});

  @override
  State<TaskAlertsScreen> createState() => _TaskAlertsScreenState();
}

class _TaskAlertsScreenState extends State<TaskAlertsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic> _alertSettings = {};

  final List<String> _taskCategories = [
    'Cleaning',
    'Gardening',
    'Repair',
    'Painting',
    'Furniture',
    'Data Entry',
    'Copy Writing',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadAlertSettings();
  }

  Future<void> _loadAlertSettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          final alertData = data['taskAlertSettings'] as Map<String, dynamic>? ?? {};
          
          setState(() {
            _alertSettings = {
              'enabled': alertData['enabled'] ?? true,
              'maxDistance': alertData['maxDistance'] ?? 10.0,
              'minBudget': alertData['minBudget'] ?? 0.0,
              'maxBudget': alertData['maxBudget'] ?? 1000.0,
              'categories': List<String>.from(alertData['categories'] ?? _taskCategories),
              'urgentTasks': alertData['urgentTasks'] ?? true,
              'newTasks': alertData['newTasks'] ?? true,
              'priceDrops': alertData['priceDrops'] ?? false,
              'quietHours': alertData['quietHours'] ?? false,
              'quietStart': alertData['quietStart'] ?? '22:00',
              'quietEnd': alertData['quietEnd'] ?? '08:00',
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading alert settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAlertSetting(String key, dynamic value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'taskAlertSettings.$key': value,
        });
        
        setState(() {
          _alertSettings[key] = value;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getSettingName(key)} updated'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating alert setting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update setting')),
        );
      }
    }
  }

  String _getSettingName(String key) {
    switch (key) {
      case 'enabled':
        return 'Task alerts';
      case 'maxDistance':
        return 'Maximum distance';
      case 'minBudget':
        return 'Minimum budget';
      case 'maxBudget':
        return 'Maximum budget';
      case 'urgentTasks':
        return 'Urgent tasks';
      case 'newTasks':
        return 'New tasks';
      case 'priceDrops':
        return 'Price drops';
      case 'quietHours':
        return 'Quiet hours';
      default:
        return 'Setting';
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
          'Task Alerts',
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
                  // Alert Status Card
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
                              'Task Alert Status',
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
                          _alertSettings['enabled'] == true ? 'Active' : 'Inactive',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Get notified about relevant tasks in your area',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Toggle
                  _sectionTitle('Task Alerts'),
                  _toggleCard(
                    icon: Icons.notifications,
                    title: 'Enable Task Alerts',
                    subtitle: 'Receive notifications for new tasks',
                    value: _alertSettings['enabled'] ?? true,
                    onChanged: (value) => _updateAlertSetting('enabled', value),
                  ),
                  const SizedBox(height: 24),

                  // Distance Settings
                  _sectionTitle('Distance Settings'),
                  _sliderCard(
                    icon: Icons.location_on,
                    title: 'Maximum Distance',
                    subtitle: '${_alertSettings['maxDistance'].toStringAsFixed(1)} km',
                    value: _alertSettings['maxDistance'] ?? 10.0,
                    min: 1.0,
                    max: 50.0,
                    divisions: 49,
                    onChanged: (value) => _updateAlertSetting('maxDistance', value),
                  ),
                  const SizedBox(height: 24),

                  // Budget Settings
                  _sectionTitle('Budget Settings'),
                  _rangeSliderCard(
                    icon: Icons.currency_rupee,
                    title: 'Budget Range',
                    subtitle: 'Rs ${_alertSettings['minBudget'].toStringAsFixed(0)} - Rs ${_alertSettings['maxBudget'].toStringAsFixed(0)}',
                    minValue: _alertSettings['minBudget'] ?? 0.0,
                    maxValue: _alertSettings['maxBudget'] ?? 1000.0,
                    min: 0.0,
                    max: 2000.0,
                    onChanged: (min, max) {
                      _updateAlertSetting('minBudget', min);
                      _updateAlertSetting('maxBudget', max);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Task Types
                  _sectionTitle('Task Categories'),
                  _buildCategoryGrid(),
                  const SizedBox(height: 24),

                  // Alert Types
                  _sectionTitle('Alert Types'),
                  _toggleCard(
                    icon: Icons.priority_high,
                    title: 'Urgent Tasks',
                    subtitle: 'Get notified about urgent tasks',
                    value: _alertSettings['urgentTasks'] ?? true,
                    onChanged: (value) => _updateAlertSetting('urgentTasks', value),
                  ),
                  _toggleCard(
                    icon: Icons.new_releases,
                    title: 'New Tasks',
                    subtitle: 'Get notified about new tasks',
                    value: _alertSettings['newTasks'] ?? true,
                    onChanged: (value) => _updateAlertSetting('newTasks', value),
                  ),
                  _toggleCard(
                    icon: Icons.trending_down,
                    title: 'Price Drops',
                    subtitle: 'Get notified when task prices drop',
                    value: _alertSettings['priceDrops'] ?? false,
                    onChanged: (value) => _updateAlertSetting('priceDrops', value),
                  ),
                  const SizedBox(height: 24),

                  // Quiet Hours
                  _sectionTitle('Quiet Hours'),
                  _toggleCard(
                    icon: Icons.bedtime,
                    title: 'Enable Quiet Hours',
                    subtitle: 'Pause notifications during quiet hours',
                    value: _alertSettings['quietHours'] ?? false,
                    onChanged: (value) => _updateAlertSetting('quietHours', value),
                  ),
                  if (_alertSettings['quietHours'] == true) ...[
                    const SizedBox(height: 12),
                    _timeRangeCard(),
                  ],
                  const SizedBox(height: 24),

                  // Quick Actions
                  _sectionTitle('Quick Actions'),
                  _actionCard(
                    icon: Icons.science,
                    title: 'Test Alert',
                    subtitle: 'Send a test task alert',
                    onTap: () => _testAlert(),
                  ),
                  _actionCard(
                    icon: Icons.restore,
                    title: 'Reset to Defaults',
                    subtitle: 'Reset all alert settings',
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

  Widget _toggleCard({
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

  Widget _sliderCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  child: Icon(icon, color: const Color(0xFF00C7BE)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              activeColor: const Color(0xFF00C7BE),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${min.toStringAsFixed(0)} km', style: GoogleFonts.poppins(color: Colors.grey[600])),
                Text('${max.toStringAsFixed(0)} km', style: GoogleFonts.poppins(color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeSliderCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double minValue,
    required double maxValue,
    required double min,
    required double max,
    required Function(double, double) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  child: Icon(icon, color: const Color(0xFF00C7BE)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RangeSlider(
              values: RangeValues(minValue, maxValue),
              min: min,
              max: max,
              onChanged: (values) => onChanged(values.start, values.end),
              activeColor: const Color(0xFF00C7BE),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                                    Text('Rs ${min.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.grey[600])),
                    Text('Rs ${max.toStringAsFixed(0)}', style: GoogleFonts.poppins(color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final selectedCategories = List<String>.from(_alertSettings['categories'] ?? _taskCategories);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select categories you\'re interested in:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _taskCategories.map((category) {
                final isSelected = selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedCategories.add(category);
                      } else {
                        selectedCategories.remove(category);
                      }
                    });
                    _updateAlertSetting('categories', selectedCategories);
                  },
                  selectedColor: const Color(0xFF00C7BE).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF00C7BE),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeRangeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiet Hours: ${_alertSettings['quietStart']} - ${_alertSettings['quietEnd']}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectTime('quietStart'),
                    child: Text('Start: ${_alertSettings['quietStart']}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectTime('quietEnd'),
                    child: Text('End: ${_alertSettings['quietEnd']}'),
                  ),
                ),
              ],
            ),
          ],
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

  void _selectTime(String timeKey) async {
    final currentTime = _alertSettings[timeKey] ?? '08:00';
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      _updateAlertSetting(timeKey, timeString);
    }
  }

  void _testAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test Alert', style: GoogleFonts.poppins()),
        content: Text(
          'A test task alert will be sent to your device.',
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
                  content: Text('Test task alert sent!'),
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

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Settings', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to reset all task alert settings to default?',
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
              await _resetAlertSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAlertSettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final defaultSettings = {
          'enabled': true,
          'maxDistance': 10.0,
          'minBudget': 0.0,
          'maxBudget': 1000.0,
          'categories': _taskCategories,
          'urgentTasks': true,
          'newTasks': true,
          'priceDrops': false,
          'quietHours': false,
          'quietStart': '22:00',
          'quietEnd': '08:00',
        };

        await _firestore.collection('users').doc(user.uid).update({
          'taskAlertSettings': defaultSettings,
        });

        setState(() {
          _alertSettings = defaultSettings;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task alert settings reset to default'),
              backgroundColor: Color(0xFF00C7BE),
            ),
          );
        }
      }
    } catch (e) {
      print('Error resetting alert settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reset settings')),
        );
      }
    }
  }
} 