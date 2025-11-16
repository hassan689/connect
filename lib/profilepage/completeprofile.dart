import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CompleteInfoPage extends StatefulWidget {
  final String userId;

  const CompleteInfoPage({
    Key? key,
    required this.userId,
  }) : super(key: key);
 
  @override
  State<CompleteInfoPage> createState() => _CompleteInfoPageState();
}

class _CompleteInfoPageState extends State<CompleteInfoPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _workTransportController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  
  final String _selectedBadge = 'Silver';
  File? _profileImage;
  List<File> _portfolioImages = [];
  List<String> _languages = [];

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickPortfolioImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      imageQuality: 80,
    );
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _portfolioImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _addLanguage() {
    if (_languageController.text.trim().isNotEmpty) {
      setState(() {
        _languages.add(_languageController.text.trim());
        _languageController.clear();
      });
    }
  }

  void _removeLanguage(int index) {
    setState(() {
      _languages.removeAt(index);
    });
  }

  Future<List<String>> uploadPortfolioImages(List<File> images) async {
    List<String> urls = [];
    try {
      for (var image in images) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('portfolio_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        final uploadTask = storageRef.putFile(image);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        urls.add(downloadUrl);
      }
      return urls;
    } catch (e) {
      debugPrint('Error uploading portfolio images: $e');
      return [];
    }
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
 
  Future<bool> saveProfile({
  required String fullName,
  required String bio,
  required String email,
  required String location,
  required String badge,
  String? profileImageUrl,
  required String userId,
  String? birthday,
  List<String>? portfolioImages,
  String? education,
  List<String>? languages,
  String? workTransport,
}) async {
  try {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    await userDoc.set({
      'fullName': fullName,
      'bio': bio,
      'location': location,
      'badge': badge,
      'profileImageUrl': profileImageUrl ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
      'email': email,
      // New fields
      'birthday': birthday,
      'portfolioImages': portfolioImages ?? [],
      'education': education,
      'languages': languages ?? [],
      'workTransport': workTransport,
      'rating': 0.0,
      'communicationRating': 0.0,
      'punctualityRating': 0.0,
      'eyeForDetailRating': 0.0,
      'efficiencyRating': 0.0,
      'taskCount': 0,
      'taskCompletionRate': 0.0,
      'isIDVerified': false,
      'isPhoneVerified': false,
      'skills': [],
      'points': {
        'balance': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    return true;
  } catch (e) {
    debugPrint('Error saving profile: $e');
    return false;
  }
}

  @override
  Widget build(BuildContext context) {
    final Color tealColor = const Color(0xFF00C7BE);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Your Info',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: tealColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile picture
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage:
                                  _profileImage != null ? FileImage(_profileImage!) : null,
                              child: _profileImage == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey[500],
                                    )
                                  : null,
                            ),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: tealColor,
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Full name
                    _buildLabel('Full Name'),
                    TextField(
                      controller: _fullNameController,
                      decoration: _inputDecoration('Enter your full name'),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    _buildLabel('Email'),
                    TextField(
                      controller: _emailController,
                      decoration: _inputDecoration('example@gmail.com'),
                    ),
                    const SizedBox(height: 20),

                    // Bio
                    _buildLabel('Short Bio'),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: _inputDecoration('Tell us something about you'),
                    ),
                    const SizedBox(height: 20),

                    // Location
                    _buildLabel('Location'),
                    TextField(
                      controller: _locationController,
                      decoration: _inputDecoration('Where do you live?'),
                    ),
                    const SizedBox(height: 20),

                    // Birthday
                    _buildLabel('Birthday'),
                    TextField(
                      controller: _birthdayController,
                      decoration: _inputDecoration('Select your birthday'),
                      readOnly: true,
                      onTap: () => _selectBirthday(context),
                    ),
                    const SizedBox(height: 20),

                    // Education
                    _buildLabel('Education'),
                    TextField(
                      controller: _educationController,
                      decoration: _inputDecoration('Your education background'),
                    ),
                    const SizedBox(height: 20),

                    // Work Transport
                    _buildLabel('Work Transport'),
                    TextField(
                      controller: _workTransportController,
                      decoration: _inputDecoration('How do you commute to work?'),
                    ),
                    const SizedBox(height: 20),

                    // Languages
                    _buildLabel('Languages'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _languageController,
                            decoration: _inputDecoration('Add a language you speak'),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: tealColor),
                          onPressed: _addLanguage,
                        ),
                      ],
                    ),
                    if (_languages.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: List.generate(_languages.length, (index) {
                          return Chip(
                            label: Text(_languages[index]),
                            deleteIcon: Icon(Icons.close, size: 18),
                            onDeleted: () => _removeLanguage(index),
                          );
                        }),
                      ),
                    const SizedBox(height: 20),

                    // Portfolio Images
                    _buildLabel('Portfolio Images'),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _portfolioImages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _portfolioImages.length) {
                            return GestureDetector(
                              onTap: _pickPortfolioImages,
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.add, color: Colors.grey[500], size: 40),
                              ),
                            );
                          }
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_portfolioImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Badge selection
                    _buildLabel('Badge'),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Text(
                        _selectedBadge,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Save Info button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User not signed in')),
                            );
                            return;
                          }

                          setState(() {
                            _isLoading = true;
                          });

                          String? imageUrl;
                          if (_profileImage != null) {
                            imageUrl = await uploadProfileImage(_profileImage!);
                          }

                          List<String> portfolioUrls = [];
                          if (_portfolioImages.isNotEmpty) {
                            portfolioUrls = await uploadPortfolioImages(_portfolioImages);
                          }

                          final success = await saveProfile(
                            email: _emailController.text.trim(),
                            fullName: _fullNameController.text.trim(),
                            bio: _bioController.text.trim(),
                            location: _locationController.text.trim(),
                            badge: _selectedBadge,
                            profileImageUrl: imageUrl,
                            userId: user.uid,
                            birthday: _birthdayController.text.trim().isNotEmpty 
                                ? _birthdayController.text.trim() 
                                : null,
                            portfolioImages: portfolioUrls.isNotEmpty 
                                ? portfolioUrls 
                                : null,
                            education: _educationController.text.trim().isNotEmpty
                                ? _educationController.text.trim()
                                : null,
                            languages: _languages.isNotEmpty ? _languages : null,
                            workTransport: _workTransportController.text.trim().isNotEmpty
                                ? _workTransportController.text.trim()
                                : null,
                          );

                          setState(() {
                            _isLoading = false;
                          });

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile info saved')),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to save profile info')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tealColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Save Info',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00C7BE), width: 2),
      ),
    );
  }
}