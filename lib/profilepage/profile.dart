import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connect/core/theme/app_theme.dart';
import 'package:connect/loginpage/loginp.dart';
import 'package:connect/profilepage/account_info.dart';
import 'package:connect/widgets/shimmer_loading.dart';
import 'package:connect/profilepage/notification_settings.dart';
import 'package:connect/profilepage/payment_settings.dart';
import 'package:connect/profilepage/task_alerts.dart';
import 'package:connect/profilepage/tasker_dashboard.dart';
import 'package:connect/connects/notification.dart';
import 'package:connect/messaging/message_requests_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  String? _profileImageUrl;
  String _fullName = '';
  String _location = '';
  String _bio = '';
  String _userID = '';
  String _badge = 'silver'; // Default badge
  bool _loading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  // Calculate badge tier based on points and tasks
  String _calculateBadgeTier(double points, int tasks) {
    // Platinum: 1000+ points OR 50+ completed tasks
    if (points >= 1000 || tasks >= 50) {
      return 'platinum';
    }
    // Gold: 500+ points OR 25+ completed tasks
    if (points >= 500 || tasks >= 25) {
      return 'gold';
    }
    // Silver: default for all users
    return 'silver';
  }

  Future<void> _initializeUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _userID = user.uid);
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
  try {
    final doc = await _firestore.collection('users').doc(_userID).get();

    if (doc.exists) {
      final data = doc.data()!;
      
      // Get badge from user data or calculate based on points/tasks
      final badge = data['badge'] as String?;
      final pointsData = data['points'] as Map<String, dynamic>? ?? {};
      final pointsBalance = (pointsData['balance'] as num? ?? 0).toDouble();
      final taskCount = (data['taskCount'] as num? ?? 0).toInt();
      
      // Calculate badge tier if not set
      String calculatedBadge = badge ?? _calculateBadgeTier(pointsBalance, taskCount);
      
      setState(() {
        _fullName = data['fullName'] ?? '';
        _location = data['location'] ?? '';
        _profileImageUrl = data['profileImageUrl'];
        _bio = data['bio'] ?? '';
        _badge = calculatedBadge;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      print('User document does not exist'); // Debug print
    }
  } catch (e) {
    print('Error loading user data: $e');
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading profile: ${e.toString()}')),
    );
  }
}
  Future<void> _pickImage() async {
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to upload images')),
        );
        return;
      }

      // Debug: Print user authentication info
      print('User authenticated: ${user.uid}');
      print('User email: ${user.email}');
      print('User email verified: ${user.emailVerified}');

      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _image = File(pickedFile.path);
        _profileImageUrl = null;
        _loading = true;
      });

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(user.uid) // User-specific folder
          .child('profile_$timestamp.jpg'); // Unique filename

      // Upload with metadata
      final uploadTask = storageRef.putFile(
        _image!,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Wait for upload to complete
      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore with new image URL
      await _firestore.collection('users').doc(_userID).update({
        'profileImageUrl': downloadUrl,
        'profileImageUpdatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageUrl = downloadUrl;
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image updated successfully!'),
          backgroundColor: Color(0xFF00C7BE),
        ),
      );
    } catch (e) {
      print('Error uploading image: $e');
      setState(() => _loading = false);
      
      String errorMessage = 'Failed to update image';
      if (e.toString().contains('unauthorized')) {
        errorMessage = 'Permission denied. Please check your account status.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('storage')) {
        errorMessage = 'Storage error. Please try again later.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editProfileField(String fieldName, String currentValue) {
    // Prevent location editing for privacy and security
    if (fieldName == 'location') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location cannot be changed for privacy and security reasons'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Edit ${fieldName.toLowerCase()}"),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: "Enter new $fieldName"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newValue = controller.text.trim();
                  if (newValue.isEmpty) return;

                  try {
                    await _firestore.collection('users').doc(_userID).update({
                      fieldName: newValue,
                    });

                    setState(() {
                      if (fieldName == 'fullName') _fullName = newValue;
                      // Location editing is disabled for privacy/security
                      if (fieldName == 'bio') _bio = newValue;
                    });

                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Error updating $fieldName: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update $fieldName')),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ShimmerLoading.profilePage();
    }

    if (_userID.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Please sign in to view your profile"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text("Go to Login"),
              ),
            ],
          ),
        ),
      );
    }

  // Generate DiceBear avatar URL
  // Using Avataaars style - professional human-style avatars
  // Alternative styles: personas, lorelei, notionists
  String getAvatarUrl(String seed) {
    // Use DiceBear API with avataaars style (professional human-style)
    // Seed can be user ID, name, or email for consistent avatar generation
    final encodedSeed = Uri.encodeComponent(seed.isEmpty ? 'user' : seed);
    // Avataaars style with custom background color matching app theme
   // return 'https://api.dicebear.com/7.x/avataaars/png?seed=$encodedSeed&size=120&backgroundColor=b6e3f4';
    
    // Alternative: Personas (more realistic)
    // return 'https://api.dicebear.com/7.x/personas/png?seed=$encodedSeed&size=120&backgroundColor=b6e3f4';
    
    // Alternative: Lorelei (modern, diverse)
     return 'https://api.dicebear.com/7.x/lorelei/png?seed=$encodedSeed&size=120&backgroundColor=b6e3f4';
    
    // Alternative: Notionists (minimalist professional)
    // return 'https://api.dicebear.com/7.x/notionists/png?seed=$encodedSeed&size=120&backgroundColor=b6e3f4';
  }

  // Get badge color
  Color _getBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'platinum':
        return const Color(0xFFE5E4E2); // Platinum color
      case 'gold':
        return const Color(0xFFFFD700); // Gold color
      case 'silver':
      default:
        return const Color(0xFFC0C0C0); // Silver color
    }
  }

  // Get badge icon
  IconData _getBadgeIcon(String badge) {
    switch (badge.toLowerCase()) {
      case 'platinum':
        return Icons.diamond;
      case 'gold':
        return Icons.star;
      case 'silver':
      default:
        return Icons.workspace_premium;
    }
  }

    ImageProvider? imageProvider;
    if (_image != null) {
      imageProvider = FileImage(_image!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_profileImageUrl!);
    } else {
      // Use DiceBear API when no profile image is available
      // Use user ID or name as seed for consistent avatar generation
      final seed = _userID.isNotEmpty ? _userID : (_fullName.isNotEmpty ? _fullName : 'user');
      imageProvider = NetworkImage(getAvatarUrl(seed));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF00C7BE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C7BE),
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: imageProvider,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      // Fallback handling if avatar fails to load
                      onBackgroundImageError: (exception, stackTrace) {
                        debugPrint('Avatar image error: $exception');
                      },
                    ),
                    // Badge indicator
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getBadgeColor(_badge),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getBadgeIcon(_badge),
                          size: 20,
                          color: _badge.toLowerCase() == 'platinum' 
                              ? Colors.black87 
                              : Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _editProfileField('fullName', _fullName),
                        child: Text(
                          _fullName.isNotEmpty ? _fullName : 'Your Name',
                          style: AppTheme.heading3.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Location is read-only for privacy and security
                      Text(
                        _location.isNotEmpty
                            ? _location
                            : 'Location not set',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _editProfileField('bio', _bio),
                        child: Text(
                          _bio.isNotEmpty ? _bio : "Add your bio...",
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Action buttons
          // Center(
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       SizedBox(
          //         width: 130,
          //         height: 50,
          //         child: ElevatedButton(
          //           onPressed: () {
          //             Navigator.push(
          //               context,
          //               MaterialPageRoute(
          //                 builder:
          //                     (context) => CompleteInfoPage(userId: _userID),
          //               ),
          //             );
          //           },
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: const Color.fromARGB(255, 0, 199, 190),
          //             shape: const StadiumBorder(),
          //             padding: EdgeInsets.zero,
          //             side: const BorderSide(color: Colors.white, width: 2),
          //           ),
          //           child: Text(
          //             "Edit Profile",
          //             style: GoogleFonts.poppins(
          //               color: Colors.white,
          //               fontSize: 14,
          //               fontWeight: FontWeight.w600,
          //             ),
          //           ),
          //         ),
          //       ),
          //       const SizedBox(width: 8),
          //       SizedBox(
          //         width: 130,
          //         height: 50,
          //         child: ElevatedButton(
          //           onPressed: () {
          //             Navigator.push(
          //               context,
          //               MaterialPageRoute(
          //                 builder:
          //                     (context) => TaskerProfileTab(userId: _userID),
          //               ),
          //             );
          //           },
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: const Color.fromARGB(255, 1, 153, 146),
          //             shape: const StadiumBorder(),
          //             padding: EdgeInsets.zero,
          //           ),
          //           child: Text(
          //             "Public Profile",
          //             style: GoogleFonts.poppins(
          //               color: Colors.white,
          //               fontSize: 14,
          //               fontWeight: FontWeight.w600,
          //             ),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          const SizedBox(height: 20),
          // Main content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle("Account Settings"),
                  _settingItem(Icons.payment, "Payment options", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentSettingsScreen()))),
                  _settingItem(Icons.lock, "Account information", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountInfoScreen()))),
                  const SizedBox(height: 16),
                  _sectionTitle("Notification Settings"),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_userID)
                        .collection('notifications')
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      
                      return _settingItem(
                        Icons.notifications,
                        "Notifications",
                        subtitle: unreadCount > 0 ? "$unreadCount unread notifications" : "View all notifications",
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const NotificationsScreen())
                        ),
                        trailing: unreadCount > 0 ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ) : const Icon(Icons.chevron_right, color: Colors.grey),
                      );
                    },
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('message_requests')
                        .where('toUserId', isEqualTo: _userID)
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      
                      return _settingItem(
                        Icons.message,
                        "Message Requests",
                        subtitle: pendingCount > 0 ? "$pendingCount pending requests" : "View message requests",
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const MessageRequestsScreen())
                        ),
                        trailing: pendingCount > 0 ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C7BE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            pendingCount > 99 ? '99+' : pendingCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ) : const Icon(Icons.chevron_right, color: Colors.grey),
                      );
                    },
                  ),
                  _settingItem(Icons.notifications, "Notification preferences", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()))),
                  _settingItem(
                    Icons.task,
                    "Task alerts for Taskers",
                    subtitle: "Be the first to know relevant tasks",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskAlertsScreen())),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle("For Taskers"),
                  _settingItem(Icons.dashboard, "My dashboard", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskerDashboardScreen()))),
                  const SizedBox(height: 24),
                  _sectionTitle("More"),

                  _settingItem(
                    Icons.logout,
                    "Logout",
                    onTap: () async {
                      await _auth.signOut();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _settingItem(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
