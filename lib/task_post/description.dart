import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkster/task_post/photo.dart';
import 'package:linkster/ai_services/huggingface_service.dart';
import 'title.dart';

class TaskDescriptionScreen extends StatefulWidget {
  final String taskTitle;
  final DateTime? selectedDate;
  final String location;
  final String? selectedTimeSlot;
  final double longitude;
  final double latitude;
  final String dateOption;
  final String tasktype;
  
  const TaskDescriptionScreen({
    super.key,
    required this.tasktype,
    required this.taskTitle,
    required this.selectedDate,
    required this.location,
    this.selectedTimeSlot,
    required this.longitude,
    required this.latitude,
    required this.dateOption
  });

  @override
  State<TaskDescriptionScreen> createState() => _TaskDescriptionScreenState();
}

class _TaskDescriptionScreenState extends State<TaskDescriptionScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String _suggestedCategory = '';
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _analyzeTask() async {
    if (_descriptionController.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Analyze the task description to get category
      final category = await HuggingFaceService.classifyTask(_descriptionController.text);
      
      setState(() {
        _suggestedCategory = category;
      });
    } catch (e) {
      // Silently fail - AI is optional
      print('AI categorization failed: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(step: 4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Describe the task",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Description Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 6,
                  minLines: 4,
                  onChanged: (value) {
                    // Auto-analyze when user types
                    if (value.trim().isNotEmpty && !_isAnalyzing) {
                      _analyzeTask();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Describe what you need help with...",
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                    suffixIcon: _isAnalyzing
                        ? Container(
                            margin: const EdgeInsets.all(16),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(0xFF00C7BE),
                            ),
                          )
                        : _suggestedCategory.isNotEmpty
                            ? Container(
                                margin: const EdgeInsets.all(16),
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: const Color(0xFF00C7BE),
                                  size: 24,
                                ),
                              )
                            : null,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Character count and tips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_descriptionController.text.length} characters',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (_descriptionController.text.length < 50)
                    Text(
                      'Add more details for better matches',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                      ),
                    ),
                ],
              ),

              // Show suggested category if available
              if (_suggestedCategory.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C7BE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00C7BE).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.category, color: const Color(0xFF00C7BE), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Suggested Category: ',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C7BE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _suggestedCategory,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),
              
              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_descriptionController.text.trim().isNotEmpty) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UploadPhotoScreen(
                            taskType: widget.tasktype,
                            taskTitle: widget.taskTitle,
                            selectedDate: widget.selectedDate,
                            location: widget.location,
                            description: _descriptionController.text.trim(),
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                            dateOption: widget.dateOption,
                            suggestedCategory: _suggestedCategory.isNotEmpty ? _suggestedCategory : null, // Pass the AI category
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a description")),
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
                    "Next",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
