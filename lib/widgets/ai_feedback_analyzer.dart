import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkster/ai_services/huggingface_service.dart';

class AIFeedbackAnalyzer extends StatefulWidget {
  final String feedback;
  final Function(Map<String, dynamic>) onAnalysisComplete;

  const AIFeedbackAnalyzer({
    Key? key,
    required this.feedback,
    required this.onAnalysisComplete,
  }) : super(key: key);

  @override
  State<AIFeedbackAnalyzer> createState() => _AIFeedbackAnalyzerState();
}

class _AIFeedbackAnalyzerState extends State<AIFeedbackAnalyzer> {
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  @override
  void initState() {
    super.initState();
    if (widget.feedback.isNotEmpty) {
      _analyzeFeedback();
    }
  }

  Future<void> _analyzeFeedback() async {
    if (widget.feedback.trim().isEmpty) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await HuggingFaceService.analyzeUserFeedback(widget.feedback);
      
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      widget.onAnalysisComplete(result);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      case 'neutral':
      default:
        return Colors.orange;
    }
  }

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Icons.sentiment_satisfied;
      case 'negative':
        return Icons.sentiment_dissatisfied;
      case 'neutral':
      default:
        return Icons.sentiment_neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Analysis Button
        if (_analysisResult == null)
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeFeedback,
              icon: _isAnalyzing 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.psychology, color: Colors.white),
              label: Text(
                _isAnalyzing ? 'Analyzing...' : 'Analyze Feedback with AI',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF019992),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Analysis Results
        if (_analysisResult != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AI Analysis Results',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sentiment Analysis
                Row(
                  children: [
                    Icon(
                      _getSentimentIcon(_analysisResult!['sentiment']['sentiment']),
                      color: _getSentimentColor(_analysisResult!['sentiment']['sentiment']),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sentiment: ${_analysisResult!['sentiment']['sentiment']}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: _getSentimentColor(_analysisResult!['sentiment']['sentiment']),
                            ),
                          ),
                          Text(
                            'Confidence: ${(_analysisResult!['sentiment']['score'] * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Language Detection
                Row(
                  children: [
                    Icon(Icons.language, color: Colors.purple.shade600, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Language: ${_analysisResult!['language']}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Confidence Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence Level',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _analysisResult!['sentiment']['score'],
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getSentimentColor(_analysisResult!['sentiment']['sentiment']),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Re-analyze Button
        if (_analysisResult != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeFeedback,
              icon: _isAnalyzing 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh, color: const Color(0xFF019992)),
              label: Text(
                _isAnalyzing ? 'Re-analyzing...' : 'Re-analyze',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF019992),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFF019992)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 