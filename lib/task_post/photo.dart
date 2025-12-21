import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connect/task_post/budget.dart';
import 'title.dart'; // Your custom app bar

class UploadPhotoScreen extends StatefulWidget {
  final String taskTitle;
  final DateTime? selectedDate;
  final String location;
  final String description;
  final double longitude ;
  final double latitude ;
  final String dateOption;
  final String taskType ;
  final String? suggestedCategory;

  const UploadPhotoScreen({
    super.key,
    required this.taskType,
    required this.longitude ,
    required this.latitude,
    required this.taskTitle,
    required this.selectedDate,
    required this.location,
    required this.description,
    required this.dateOption,
    this.suggestedCategory,
  });

  @override
  State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  List<File> _imageFiles = <File>[];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    if (!mounted) return;
    
    try {
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          _imageFiles = pickedFiles.map((pickedFile) => File(pickedFile.path)).where((file) => file != null).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    if (!mounted) return;
    
    if (index >= 0 && index < _imageFiles.length) {
      setState(() {
        _imageFiles.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white ,
      appBar: const CustomAppBar(step: 5),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Snap a photo",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              "Help Taskers understand what needs doing. Add up to 10 photos.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
                        Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (_imageFiles.isNotEmpty)
                  ..._imageFiles.asMap().entries.where((entry) => entry.value != null).map((entry) {
                    final index = entry.key;
                    final file = entry.value!;
                    return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          file,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (_imageFiles.length < 10)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 24, color: Colors.grey[600]),
                          const SizedBox(height: 4),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!mounted) return;
                    
                    try {
                      final validImageFiles = _imageFiles.isNotEmpty 
                          ? _imageFiles.where((file) => file != null).toList() 
                          : null;
                      
                      print('Debug: Navigating to budget screen with ${validImageFiles?.length ?? 0} images');
                      print('Debug: taskType: ${widget.taskType}');
                      print('Debug: taskTitle: ${widget.taskTitle}');
                      print('Debug: location: ${widget.location}');
                      print('Debug: description: ${widget.description}');
                      print('Debug: dateOption: ${widget.dateOption}');
                      print('Debug: suggestedCategory: ${widget.suggestedCategory}');
                      
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DecideBudgetScreen(
                            taskType: widget.taskType,
                            taskTitle: widget.taskTitle,
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                            selectedDate: widget.selectedDate,
                            location: widget.location,
                            description: widget.description,
                            imageFiles: validImageFiles,
                            dateOption: widget.dateOption,
                            suggestedCategory: widget.suggestedCategory,
                          ),
                        ),
                      );
                    } catch (e) {
                      print('Debug: Error navigating to budget screen: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Navigation error: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C7BE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(
                    _imageFiles.isEmpty ? "Skip Photos" : "Continue with ${_imageFiles.length} Photo${_imageFiles.length == 1 ? '' : 's'}",
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
