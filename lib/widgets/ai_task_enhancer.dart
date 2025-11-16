import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkster/ai_services/huggingface_service.dart';

class AITaskEnhancer extends StatefulWidget {
  final String initialDescription;
  final Function(String) onDescriptionChanged;
  final Function(String) onCategoryChanged;

  const AITaskEnhancer({
    Key? key,
    required this.initialDescription,
    required this.onDescriptionChanged,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  State<AITaskEnhancer> createState() => _AITaskEnhancerState();
}

class _AITaskEnhancerState extends State<AITaskEnhancer> {
  bool _isAnalyzing = false;
  String _enhancedDescription = '';
  String _suggestedCategory = '';
  String _currentDescription = '';

  @override
  void initState() {
    super.initState();
    _currentDescription = widget.initialDescription;
    _enhancedDescription = widget.initialDescription;
  }

  Future<void> _enhanceDescription() async {
    if (_currentDescription.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task description first')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Get AI-enhanced description
      final enhanced = await HuggingFaceService.enhanceTaskDescription(_currentDescription);
      
      // Get suggested category
      final category = await HuggingFaceService.classifyTask(_currentDescription);

      setState(() {
        _enhancedDescription = enhanced;
        _suggestedCategory = category;
        _isAnalyzing = false;
      });

      // Update parent widgets
      widget.onDescriptionChanged(enhanced);
      widget.onCategoryChanged(category);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI enhanced your task description!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI enhancement failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Enhancement Button
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _enhanceDescription,
            icon: _isAnalyzing 
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(
              _isAnalyzing ? 'AI is analyzing...' : 'Enhance with AI',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C7BE),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Enhanced Description Display
        if (_enhancedDescription.isNotEmpty && _enhancedDescription != widget.initialDescription)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AI Enhanced Description',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _enhancedDescription,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

        // Suggested Category Display
        if (_suggestedCategory.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Suggested Category',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _suggestedCategory,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Description Input Field
        TextFormField(
          initialValue: _currentDescription,
          onChanged: (value) {
            _currentDescription = value;
          },
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Task Description',
            hintText: 'Describe your task in detail...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: const Color(0xFF00C7BE)),
            ),
          ),
        ),
      ],
    );
  }
} 