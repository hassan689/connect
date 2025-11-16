import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:linkster/connects/notification.dart';
import 'package:linkster/profilepage/profile.dart';
import 'package:linkster/search_tasks/taskdetails.dart';
import 'package:linkster/search_tasks/tasks.dart';
import 'package:linkster/task_post/mytasks.dart';
import 'package:linkster/task_post/title.dart';
import 'package:linkster/core/utils/responsive.dart';

import 'package:linkster/ai_agent/dino_agent.dart';
import 'package:linkster/messaging/messages_screen.dart';
import 'package:linkster/ai_services/ai_demo_screen.dart';
import 'package:lottie/lottie.dart';

// Guide Step class for dino tutorial
class GuideStep {
  final String title;
  final String description;
  final GuideTarget target;
  final String animation;
  final String actionText;

  GuideStep({
    required this.title,
    required this.description,
    required this.target,
    required this.animation,
    required this.actionText,
  });
}

// Guide Target enum for different UI elements
enum GuideTarget {
  top,
  tasks,
  filters,
  postButton,
  messages,
  profile,
  none,
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key, this.showDinoGuide = false});

  final bool showDinoGuide;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  String userName = '';
  String greeting = '';
  String selectedCategory = 'All';
  
  // Cache variables
  String? _cachedUserName;
  String? _cachedGreeting;
  
  // Location and task variables
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  List<QueryDocumentSnapshot> _allTasks = []; // Store all tasks
  List<QueryDocumentSnapshot> _filteredTasks = [];
  bool _isLoadingTasks = false;
  
  // Dino Guide variables
  bool _showDinoGuide = false;
  int _currentGuideStep = 0;
  bool _showGuideHighlight = false;
  final List<GuideStep> _guideSteps = [
    GuideStep(
      title: 'Welcome to Connect! 🦖',
      description: 'I\'m your dino guide! Let me show you around the app.',
      target: GuideTarget.top,
      animation: 'assets/images/animations/dinodance.json',
      actionText: 'Start',
    ),
    GuideStep(
      title: 'Browse Tasks 📋',
      description: 'See all available tasks posted by others.',
      target: GuideTarget.tasks,
      animation: 'assets/images/animations/dinodance.json',
      actionText: 'View Tasks',
    ),
    GuideStep(
      title: 'Filter & Search 🔍',
      description: 'Use filters to find exactly what you need.',
      target: GuideTarget.filters,
      animation: 'assets/images/animations/dinodance.json',
      actionText: 'Explore',
    ),
    GuideStep(
      title: 'Post Your Task ✨',
      description: 'Create your own task to get help from others.',
      target: GuideTarget.postButton,
      animation: 'assets/images/animations/dinodance.json',
      actionText: 'Create',
    ),
    GuideStep(
      title: 'Messages 💬',
      description: 'Chat with task posters and helpers.',
      target: GuideTarget.messages,
      animation: 'assets/images/animations/dinodance.json',
      actionText: 'Messages',
    ),
    GuideStep(
      title: 'Profile 👤',
      description: 'Manage your profile and account settings.',
      target: GuideTarget.profile,
      animation: 'assets/images/animations/dinodance.json',
      actionText: 'Profile',
    ),
    GuideStep(
      title: 'You\'re All Set! 🎉',
      description: 'You now know how to use Connect!',
      target: GuideTarget.none,
      animation: 'assets/images/animations/done.json',
      actionText: 'Finish',
    ),
  ];
  
  final List<IconData> testicons = [
    Icons.all_inbox, // All
    Icons.location_on, // Nearby
    Icons.star, // Popular
  ];
  
  final List<String> test = ['All', 'Nearby', 'Popular'];
  
  final List<String> cardNames = [
    'Gardening',
    'Painting',
    'Cleaning',
    'Repair & Install',
    'Copy Writing',
    'Data Entry',
    'Furniture Assembly',
  ];
  
  final List<IconData> cardIcons = [
    Icons.local_florist, // Gardening
    Icons.format_paint, // Painting
    Icons.cleaning_services, // Cleaning
    Icons.build, // Repair & Install
    Icons.edit, // Copy Writing
    Icons.keyboard, // Data Entry
    Icons.chair_alt, // Furniture Assembly
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _fetchUserData();
    _getCurrentLocation();
    _loadTasks();
    requestPermission();
    initFCM();
    
    // Check if this is the user's first time and show welcome dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeAndShowWelcome();
      
      // Check if dino guide should be shown (for testing)
      if (widget.showDinoGuide) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            startDinoGuide();
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cachedUserName == null || _cachedGreeting == null) {
      _fetchUserData();
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _cachedGreeting = 'Good morning';
    } else if (hour < 17) {
      _cachedGreeting = 'Good afternoon';
    } else {
      _cachedGreeting = 'Good evening';
    }
    setState(() {
      greeting = _cachedGreeting!;
    });
  }

  Future<void> _fetchUserData() async {
    // Return cached data if available
    if (_cachedUserName != null) {
      setState(() {
        userName = _cachedUserName!;
      });
      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
            
        if (doc.exists) {
          _cachedUserName = doc.get('fullName') ?? 'User';
          setState(() {
            userName = _cachedUserName!;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        userName = 'User';
      });
    }
  }

  void initFCM() {
    // Get device token
    FirebaseMessaging.instance.getToken().then((token) {
      print('FCM Token: $token');
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
    });

    // App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened via notification');
    });
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoadingTasks = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _allTasks = snapshot.docs;
        _filteredTasks = _filterTasksByCategory(_allTasks, selectedCategory);
        _isLoadingTasks = false;
      });
    } catch (e) {
      print('Error loading tasks: $e');
      
      // If it's an index error, show a helpful message
      if (e.toString().contains('FAILED_PRECONDITION') && e.toString().contains('index')) {
        print('⚠️ Firestore index missing. Please create the required index.');
        print('🔗 Index creation link: https://console.firebase.google.com/v1/r/project/linkster-ad331/firestore/indexes?create_composite=Ckxwcm9qZWN0cy9saW5rc3Rlci1hZDMzMS9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvdGFza3MvaW5kZXhlcy9fEAEaCgoGc3RhdHVzEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg');
      }
      
      setState(() {
        _isLoadingTasks = false;
      });
    }
  }

  List<QueryDocumentSnapshot> _filterTasksByCategory(List<QueryDocumentSnapshot> tasks, String category) {
    switch (category) {
      case 'All':
        return tasks;
      
      case 'Nearby':
        if (_currentPosition == null) return [];
        return tasks.where((doc) {
          final taskData = doc.data() as Map<String, dynamic>;
          if (taskData['latitude'] == null || taskData['longitude'] == null) return false;
          
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            taskData['latitude'],
            taskData['longitude'],
          );
          return distance <= 10000; // 10km
        }).toList();
      
      case 'Popular':
        // Sort by views or get top 10
        final sortedTasks = List<QueryDocumentSnapshot>.from(tasks);
        sortedTasks.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aViews = aData['views'] ?? 0;
          final bViews = bData['views'] ?? 0;
          return bViews.compareTo(aViews);
        });
        return sortedTasks.take(10).toList();
      
      default:
        return tasks;
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      selectedCategory = category;
      _filteredTasks = _filterTasksByCategory(_allTasks, category);
    });
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyTasksScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MessagesScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BrowseTasksScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildTaskCard(QueryDocumentSnapshot taskDoc) {
    final taskData = taskDoc.data() as Map<String, dynamic>;
    final taskId = taskDoc.id;
    final createdAt = (taskData['createdAt'] as Timestamp?)?.toDate();
    final formattedDate = createdAt != null 
        ? DateFormat('MMM d').format(createdAt) 
        : 'No date';

    // Calculate distance if location is available
    String distanceText = '';
    if (_currentPosition != null && taskData['latitude'] != null && taskData['longitude'] != null) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        taskData['latitude'],
        taskData['longitude'],
      );
      distanceText = '${(distance / 1000).toStringAsFixed(1)}km away';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(taskId: taskId),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.width > 600 ? 16 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Budget
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      taskData['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C7BE).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Rs ${taskData['budget'] ?? '0'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00C7BE),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Location and Date
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      taskData['location'] ?? 'No location',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (distanceText.isNotEmpty) ...[
                    Text(
                      ' • $distanceText',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkFirstTimeAndShowWelcome() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final hasSeenWelcome = userData['hasSeenWelcome'] ?? false;
          final hasSeenDinoGuide = userData['hasSeenDinoGuide'] ?? false;
          
          if (!hasSeenWelcome) {
            // Show welcome dialog for first-time users
            _showDinoWelcomeDialog(userData['name'] ?? 'User');
            
            // Mark that user has seen the welcome dialog
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'hasSeenWelcome': true,
              'welcomeShownAt': FieldValue.serverTimestamp(),
            });
          }
          
          // Check if user needs dino guide
          if (!hasSeenDinoGuide) {
            // Start dino guide after a short delay
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _showDinoGuide = true;
                  _currentGuideStep = 0;
                });
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error checking first time welcome: $e');
    }
  }

  void _showDinoWelcomeDialog(String userName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dino Animation
                Container(
                  height: 120,
                  width: 120,
                  child: Lottie.asset(
                    'assets/images/animations/dinodance.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Welcome Text
                Text(
                  'Welcome to Connect! 🎉',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00C7BE),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                Text(
                  'Hi $userName! Welcome to your new adventure.\nStart exploring and connecting with amazing people!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C7BE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Let\'s Explore! 🚀',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _nextGuideStep() {
    if (_currentGuideStep < _guideSteps.length - 1) {
      setState(() {
        _currentGuideStep++;
      });
    } else {
      _finishDinoGuide();
    }
  }

  void _previousGuideStep() {
    if (_currentGuideStep > 0) {
      setState(() {
        _currentGuideStep--;
      });
    }
  }

  void _finishDinoGuide() async {
    setState(() {
      _showDinoGuide = false;
      _showGuideHighlight = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'hasSeenDinoGuide': true,
          'dinoGuideCompletedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error marking dino guide as completed: $e');
    }
  }

  void _skipDinoGuide() {
    _finishDinoGuide();
  }

  // Public method to start the dino guide (for testing purposes)
  void startDinoGuide() {
    setState(() {
      _showDinoGuide = true;
      _currentGuideStep = 0;
    });
  }

  void _handleGuideAction(GuideStep step) {
    switch (step.target) {
      case GuideTarget.top:
        // Just move to next step
        _nextGuideStep();
        break;
      case GuideTarget.tasks:
        // Navigate to tasks section (index 0)
        setState(() {
          _selectedIndex = 0;
          _showGuideHighlight = true;
        });
        // Hide highlight after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showGuideHighlight = false;
            });
          }
        });
        _nextGuideStep();
        break;
      case GuideTarget.filters:
        // Navigate to browse section (index 1) where filters are
        setState(() {
          _selectedIndex = 1;
          _showGuideHighlight = true;
        });
        // Hide highlight after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showGuideHighlight = false;
            });
          }
        });
        _nextGuideStep();
        break;
      case GuideTarget.postButton:
        // Navigate to browse section and show post button
        setState(() {
          _selectedIndex = 1;
          _showGuideHighlight = true;
        });
        // Hide highlight after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showGuideHighlight = false;
            });
          }
        });
        _nextGuideStep();
        break;
      case GuideTarget.messages:
        // Navigate to messages section (index 3)
        setState(() {
          _selectedIndex = 3;
          _showGuideHighlight = true;
        });
        // Hide highlight after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showGuideHighlight = false;
            });
          }
        });
        _nextGuideStep();
        break;
      case GuideTarget.profile:
        // Navigate to profile section (index 4)
        setState(() {
          _selectedIndex = 4;
          _showGuideHighlight = true;
        });
        // Hide highlight after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showGuideHighlight = false;
            });
          }
        });
        _nextGuideStep();
        break;
      case GuideTarget.none:
        // Finish the guide
        _finishDinoGuide();
        break;
    }
  }

  Widget _buildDinoGuideOverlay() {
    if (!_showDinoGuide) return const SizedBox.shrink();

    final currentStep = _guideSteps[_currentGuideStep];

    return Stack(
      children: [
        // Semi-transparent background
        Positioned.fill(
          child: Container(
                            color: Colors.black.withValues(alpha: 0.7),
          ),
        ),
        
        // Guide content
        Positioned(
          top: 80,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dino Animation
                Container(
                  height: 120,
                  width: 120,
                  child: Lottie.asset(
                    currentStep.animation,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  currentStep.title,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00C7BE),
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  currentStep.description,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                
                // Progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _guideSteps.length,
                    (index) => Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentGuideStep
                            ? const Color(0xFF00C7BE)
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                
                // Action buttons
                Column(
                  children: [
                    // Skip button (top row)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _skipDinoGuide,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            'Skip Tutorial',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Navigation buttons (bottom row)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Previous button
                        if (_currentGuideStep > 0)
                          Expanded(
                            child: TextButton(
                              onPressed: _previousGuideStep,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              child: Text(
                                'Previous',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF00C7BE),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        
                        // Action/Next button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => _handleGuideAction(currentStep),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C7BE),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            child: Text(
                              currentStep.actionText,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final responsive = context.responsive;
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
                child: Column(
                  children: [
                    // AppBar
                    Padding(
                      padding: responsive.padding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Paw icon before Connect
                      const Icon(
                        Icons.pets,
                        color: Color(0xFF00C7BE),
                        size: 42,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Connect',
                        style: GoogleFonts.inter(
                          fontSize: responsive.value(mobile: 24.0, tablet: 28.0, desktop: 32.0),
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Dino AI Agent Button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DinoAgentScreen(),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Lottie.asset(
                            'assets/images/animations/dinodance.json',
                            fit: BoxFit.contain,
                            repeat: true,
                          ),
                        ),
                      ),

                      // Notifications Button
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('notifications')
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          
                          return Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_none, size: 28),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

                    // Green Header Container
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C7BE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: responsive.padding,
                      margin: EdgeInsets.symmetric(horizontal: responsive.value(mobile: 16.0, tablet: 24.0, desktop: 0.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting${userName.isNotEmpty ? ', $userName' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                      Text(
                        'Post a task. Get it done',
                        style: GoogleFonts.inter(
                          fontSize: responsive.value(mobile: 18.0, tablet: 22.0, desktop: 24.0),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskTitleScreen(),
                        ),
                      );
                    },
                    child: TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'What do you need done?',
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

                    SizedBox(height: responsive.value(mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                    
                    // Category Filter
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: responsive.value(mobile: 16.0, tablet: 24.0, desktop: 32.0)),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          selectedCategory == 'All' ? 'Need something done?' : '$selectedCategory Tasks',
                          style: GoogleFonts.inter(
                            fontSize: responsive.value(mobile: 14.0, tablet: 16.0, desktop: 18.0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: responsive.value(mobile: 8.0, tablet: 10.0, desktop: 12.0)),
                    SizedBox(
                      height: responsive.value(mobile: 70.0, tablet: 80.0, desktop: 90.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: responsive.value(mobile: 16.0, tablet: 24.0, desktop: 32.0)),
                        itemCount: test.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _onCategoryChanged(test[index]);
                            },
                            child: Container(
                              width: responsive.value(mobile: 70.0, tablet: 80.0, desktop: 90.0),
                              margin: EdgeInsets.symmetric(horizontal: responsive.value(mobile: 6.0, tablet: 8.0, desktop: 10.0)),
                      decoration: BoxDecoration(
                        color: selectedCategory == test[index]
                            ? const Color(0xFF00C7BE)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            testicons[index],
                            color: selectedCategory == test[index]
                                ? Colors.white
                                : Colors.black54,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            test[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: selectedCategory == test[index]
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
                    SizedBox(height: responsive.value(mobile: 12.0, tablet: 18.0, desktop: 24.0)),
                    Expanded(
                      child: _isLoadingTasks
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00C7BE),
                              ),
                            )
                          : selectedCategory == 'All'
                              ? Padding(
                                  padding: EdgeInsets.symmetric(horizontal: responsive.value(mobile: 16.0, tablet: 24.0, desktop: 32.0)),
                                  child: GridView.builder(
                                    itemCount: cardNames.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: responsive.gridColumns,
                                      crossAxisSpacing: responsive.value(mobile: 10.0, tablet: 13.0, desktop: 16.0),
                                      mainAxisSpacing: responsive.value(mobile: 10.0, tablet: 13.0, desktop: 16.0),
                                      childAspectRatio: responsive.value(mobile: 1.6, tablet: 1.75, desktop: 1.8),
                                    ),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaskTitleScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 212, 212, 212), // soft light grey
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        cardIcons[index],
                                        size: 30,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        cardNames[index],
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : _filteredTasks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.task_alt,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tasks found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    selectedCategory == 'Nearby' && _currentPosition == null
                                        ? 'Enable location to see nearby tasks'
                                        : 'Try a different category or check back later',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                              : Padding(
                                  padding: EdgeInsets.symmetric(horizontal: responsive.value(mobile: 16.0, tablet: 24.0, desktop: 32.0)),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Use grid for larger screens, list for mobile
                                      if (constraints.maxWidth > 600) {
                                        return GridView.builder(
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: responsive.value(mobile: 1, tablet: 2, desktop: 3),
                                            crossAxisSpacing: responsive.value(mobile: 10.0, tablet: 16.0, desktop: 20.0),
                                            mainAxisSpacing: responsive.value(mobile: 12.0, tablet: 16.0, desktop: 20.0),
                                            childAspectRatio: 1.2,
                                          ),
                                          itemCount: _filteredTasks.length,
                                          itemBuilder: (context, index) {
                                            return _buildTaskCard(_filteredTasks[index]);
                                          },
                                        );
                                      } else {
                                        return ListView.builder(
                                          itemCount: _filteredTasks.length,
                                          itemBuilder: (context, index) {
                                            return _buildTaskCard(_filteredTasks[index]);
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Get it done'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'My tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
        ),
        // Dino Guide Overlay
        _buildDinoGuideOverlay(),
      ],
    );
  }
}