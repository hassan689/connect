import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:linkster/messages/taskdone.dart';
import 'package:uuid/uuid.dart';
import 'title.dart';

// Custom app bar

class FinalSummaryScreen extends StatelessWidget {
  final String taskTitle;
  final DateTime? selectedDate;
  final String location;
  final String description;
  final List<File>? imageFiles;
  final String budget;
  final double longitude;
  final double latitude;
  final String dateOption;
  final String taskType;
  final String? suggestedCategory;

  const FinalSummaryScreen({
    super.key,
    required this.taskType,
    required this.dateOption,
    required this.longitude,
    required this.latitude,
    required this.taskTitle,
    required this.selectedDate,
    required this.location,
    required this.description,
    required this.imageFiles,
    required this.budget,
    this.suggestedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(step: 7),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Alright, ready to get offers?",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Post the task when you’re ready",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            _buildDetailRow(Icons.title, taskTitle),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.calendar_today,
              selectedDate != null
                  ? "On ${selectedDate!.day} ${_monthName(selectedDate!.month)} ${selectedDate!.year}"
                  : "No date selected",
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.location_on, location),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.description, description),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.stars, "$budget Points"),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.date_range, "$dateOption"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await uploadTaskData(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7BE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Post the task",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ],
    );
  }

  String _monthName(int monthNumber) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[monthNumber];
  }
Future<void> uploadTaskData(BuildContext context) async {
  final taskId = const Uuid().v4();
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Authentication required')),
    );
    return;
  }

  try {
    List<String> imageUrls = [];
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C7BE)),
              ),
              SizedBox(height: 16),
              Text('Uploading images and posting task...'),
            ],
          ),
        );
      },
    );
    
    if (imageFiles != null && imageFiles!.isNotEmpty) {
      for (int i = 0; i < imageFiles!.length; i++) {
        final file = imageFiles![i];
        try {
          debugPrint('📤 Uploading image ${i + 1}/${imageFiles!.length}: ${file.path}');
          
          // Create a unique filename for each image
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${i}_${file.path.split('/').last}';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('task_images')
              .child(userId)
              .child(taskId)
              .child(fileName);

          // Upload the file with metadata
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': userId,
              'taskId': taskId,
              'uploadTime': DateTime.now().toIso8601String(),
            },
          );

          // Upload with progress tracking
          final uploadTask = storageRef.putFile(file, metadata);
          
          // Wait for upload to complete
          final taskSnapshot = await uploadTask;
          
          if (taskSnapshot.state == TaskState.success) {
            // Get download URL
            final downloadUrl = await storageRef.getDownloadURL();
            imageUrls.add(downloadUrl);
            debugPrint('✅ Successfully uploaded image ${i + 1}: $downloadUrl');
          } else {
            debugPrint('❌ Upload failed for image ${i + 1}');
          }
          
        } catch (e) {
          debugPrint('🔥 Error uploading image ${i + 1}: ${e.toString()}');
          // Continue with other images even if one fails
          continue;
        }
      }
    }

    // Close loading dialog
    Navigator.of(context).pop();

    // Validate that we have at least some data
    if (taskTitle.trim().isEmpty) {
      throw Exception('Task title is required');
    }

    if (location.trim().isEmpty) {
      throw Exception('Location is required');
    }

    if (description.trim().isEmpty) {
      throw Exception('Task description is required');
    }

    if (budget.trim().isEmpty) {
      throw Exception('Budget is required');
    }

    // Upload task data to Firestore
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).set({
      'taskId': taskId,
      'title': taskTitle,
      'taskType': taskType,
      'date': selectedDate?.toIso8601String(),
      'location': location,
      'description': description,
      'budget': budget,
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'longitude': longitude,
      'latitude': latitude,
      'userId': userId,
      'status': 'active',
      'imageCount': imageUrls.length,
      'hasImages': imageUrls.isNotEmpty,
      'aiCategory': suggestedCategory?.isNotEmpty == true ? suggestedCategory : null, // Save AI category
    });

    debugPrint('✅ Task posted successfully with budget: $budget');
    debugPrint('✅ Task data saved: {taskId: $taskId, title: $taskTitle, budget: $budget, location: $location}');

    // Navigate to success screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TaskPostedAnimationScreen()),
    );

  } catch (e) {
    // Close loading dialog if it's still open
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    
    debugPrint('💥 Critical error: ${e.toString()}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to post task: ${e.toString()}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => uploadTaskData(context),
        ),
      ),
    );
  }
}
  // Future<void> uploadTaskData(BuildContext context) async {
  //   final taskId = const Uuid().v4();
  //   final userId = FirebaseAuth.instance.currentUser?.uid;

  //   if (userId == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('You must be logged in to post a task')),
  //     );
  //     return;
  //   }

  //   try {
  //     // 1. Upload images to Firebase Storage
  //     List<String> imageUrls = [];
  //     if (imageFiles != null && imageFiles!.isNotEmpty) {
  //       for (var file in imageFiles!) {
  //         try {
  //           // Create a unique filename for each image
  //           final fileName =
  //               '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
  //           final ref = FirebaseStorage.instance
  //               .ref()
  //               .child('task_images')
  //               .child(userId)
  //               .child(taskId)
  //               .child(fileName);

  //           // Add metadata to the upload
  //           final metadata = SettableMetadata(
  //             contentType: 'image/jpeg',
  //             customMetadata: {'uploadedBy': userId, 'taskId': taskId},
  //           );

  //           // Upload the file
  //           await ref.putFile(file, metadata);
  //           final downloadUrl = await ref.getDownloadURL();
  //           imageUrls.add(downloadUrl);
  //         } catch (e) {
  //           print('Error uploading image: $e');
  //           // Continue with other images even if one fails
  //           continue;
  //         }
  //       }

  //       if (imageUrls.isEmpty && imageFiles!.isNotEmpty) {
  //         throw Exception('Failed to upload all images');
  //       }
  //     }

  //     // 2. Upload task data to Firestore
  //     await FirebaseFirestore.instance.collection('tasks').doc(taskId).set({
  //       'taskId': taskId,
  //       'title': taskTitle,
  //       'date': selectedDate?.toIso8601String(),
  //       'location': location,
  //       'description': description,
  //       'budget': budget,
  //       'imageUrls': imageUrls,
  //       'createdAt': FieldValue.serverTimestamp(),
  //       'longitude': longitude,
  //       'latitude': latitude,
  //       'userId': userId,
  //       'status': 'active', // Add task status
  //     });

  //     // 3. Navigate to success screen
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => const TaskPostedAnimationScreen(),
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to post task: ${e.toString()}')),
  //     );
  //     print('Task posting error: $e');
  //   }
  // }
}
