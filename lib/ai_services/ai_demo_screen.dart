import 'package:flutter/material.dart';
import 'huggingface_service.dart';

class AIDemoScreen extends StatefulWidget {
  const AIDemoScreen({super.key});

  @override
  State<AIDemoScreen> createState() => _AIDemoScreenState();
}

class _AIDemoScreenState extends State<AIDemoScreen> {
  String _result = 'Click any button to test the AI services!';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Services Demo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Results:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Processing...'),
                      ],
                    )
                  else
                    Text(
                      _result,
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Test Buttons
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTestButton(
                      'Test Sentiment Analysis',
                      'I love this amazing app!',
                      () => _testSentimentAnalysis(),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildTestButton(
                      'Test Task Classification',
                      'Need help cleaning my house and doing laundry',
                      () => _testTaskClassification(),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildTestButton(
                      'Test Text Summarization',
                      'I need someone to help me move furniture from my old apartment to my new house. The move is scheduled for next Saturday and I have a lot of heavy items including a sofa, dining table, and several boxes of books. I would appreciate help with loading and unloading everything.',
                      () => _testTextSummarization(),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildTestButton(
                      'Test Language Detection',
                      'Bonjour, comment allez-vous?',
                      () => _testLanguageDetection(),
                    ),
                    const SizedBox(height: 12),
                    
                                         _buildTestButton(
                       'Test Question Answering',
                       'What is the capital of France?',
                       () => _testQuestionAnswering(),
                       'France is a country in Europe. Paris is the capital city of France.',
                     ),
                    const SizedBox(height: 12),
                    
                    _buildTestButton(
                      'Test Task Enhancement',
                      'Need someone to walk my dog twice a day',
                      () => _testTaskEnhancement(),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildTestButton(
                      'Test User Feedback Analysis',
                      'This app is fantastic! The service was excellent and the person who helped me was very professional.',
                      () => _testUserFeedbackAnalysis(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String title, String sampleText, VoidCallback onPressed, [String? context]) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sample: "$sampleText"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            if (context != null) ...[
              const SizedBox(height: 4),
              Text(
                'Context: "$context"',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testSentimentAnalysis() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing sentiment analysis...';
    });

    try {
      final result = await HuggingFaceService.analyzeSentiment('I love this amazing app!');
      setState(() {
        _result = 'Sentiment Analysis Result:\n\n'
            'Label: ${result['label']}\n'
            'Score: ${(result['score'] * 100).toStringAsFixed(1)}%\n'
            'Sentiment: ${result['sentiment']}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testTaskClassification() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing task classification...';
    });

    try {
      final result = await HuggingFaceService.classifyTask('Need help cleaning my house and doing laundry');
      setState(() {
        _result = 'Task Classification Result:\n\n'
            'Category: $result';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testTextSummarization() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing text summarization...';
    });

    try {
      final result = await HuggingFaceService.summarizeText(
        'I need someone to help me move furniture from my old apartment to my new house. The move is scheduled for next Saturday and I have a lot of heavy items including a sofa, dining table, and several boxes of books. I would appreciate help with loading and unloading everything.'
      );
      setState(() {
        _result = 'Text Summarization Result:\n\n'
            'Summary: $result';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLanguageDetection() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing language detection...';
    });

    try {
      final result = await HuggingFaceService.detectLanguage('Bonjour, comment allez-vous?');
      setState(() {
        _result = 'Language Detection Result:\n\n'
            'Detected Language: $result';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testQuestionAnswering() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing question answering...';
    });

    try {
      final result = await HuggingFaceService.answerQuestion(
        'What is the capital of France?',
        'France is a country in Europe. Paris is the capital city of France.'
      );
      setState(() {
        _result = 'Question Answering Result:\n\n'
            'Question: What is the capital of France?\n'
            'Answer: $result';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testTaskEnhancement() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing task enhancement...';
    });

    try {
      final result = await HuggingFaceService.enhanceTaskDescription('Need someone to walk my dog twice a day');
      setState(() {
        _result = 'Task Enhancement Result:\n\n$result';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testUserFeedbackAnalysis() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing user feedback analysis...';
    });

    try {
      final result = await HuggingFaceService.analyzeUserFeedback(
        'This app is fantastic! The service was excellent and the person who helped me was very professional.'
      );
      setState(() {
        _result = 'User Feedback Analysis Result:\n\n'
            'Sentiment: ${result['sentiment']['sentiment']}\n'
            'Confidence: ${(result['sentiment']['score'] * 100).toStringAsFixed(1)}%\n'
            'Language: ${result['language']}\n'
            'Timestamp: ${result['timestamp']}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 