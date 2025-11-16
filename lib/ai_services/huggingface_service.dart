import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:linkster/config/app_config.dart';

class HuggingFaceService {
  static String get _apiToken => AppConfig.huggingFaceApiToken;
  static String get _baseUrl => AppConfig.huggingFaceBaseUrl;

  static Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    if (_apiToken.isEmpty) {
      throw Exception('Hugging Face API token not configured. Please set HUGGINGFACE_API_TOKEN in .env file');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/cardiffnlp/twitter-roberta-base-sentiment-latest'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _processSentimentResult(data);
      } else {
        throw Exception('Failed to analyze sentiment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error analyzing sentiment: $e');
    }
  }

  static Future<String> classifyTask(String taskDescription) async {
    if (_apiToken.isEmpty) {
      throw Exception('Hugging Face API token not configured. Please set HUGGINGFACE_API_TOKEN in .env file');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/facebook/bart-large-mnli'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': taskDescription,
          'parameters': {
            'candidate_labels': [
              'Cleaning',
              'Gardening',
              'Moving',
              'Pet Care',
              'Tutoring',
              'Handyman',
              'Delivery',
              'Photography',
              'Cooking',
              'Other'
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['labels'][0]; // Return the most likely category
      } else {
        throw Exception('Failed to classify task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error classifying task: $e');
    }
  }

  static Future<String> answerQuestion(String question, String context) async {
    if (_apiToken.isEmpty) {
      throw Exception('Hugging Face API token not configured. Please set HUGGINGFACE_API_TOKEN in .env file');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/deepset/roberta-base-squad2'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': {
            'question': question,
            'context': context,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'No answer found';
      } else {
        throw Exception('Failed to answer question: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error answering question: $e');
    }
  }

  static Future<String> summarizeText(String text) async {
    if (_apiToken.isEmpty) {
      throw Exception('Hugging Face API token not configured. Please set HUGGINGFACE_API_TOKEN in .env file');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/facebook/bart-large-cnn'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data[0]['summary_text'] ?? text;
      } else {
        throw Exception('Failed to summarize text: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error summarizing text: $e');
    }
  }

  static Future<String> detectLanguage(String text) async {
    if (_apiToken.isEmpty) {
      throw Exception('Hugging Face API token not configured. Please set HUGGINGFACE_API_TOKEN in .env file');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/papluca/xlm-roberta-base-language-detection'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data[0]['label'] ?? 'unknown';
      } else {
        throw Exception('Failed to detect language: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error detecting language: $e');
    }
  }

  // Process sentiment analysis results
  static Map<String, dynamic> _processSentimentResult(dynamic data) {
    if (data is List && data.isNotEmpty) {
      final result = data[0];
      return {
        'label': result['label'] ?? 'neutral',
        'score': result['score'] ?? 0.0,
        'sentiment': _getSentimentLabel(result['label']),
      };
    }
    return {'label': 'neutral', 'score': 0.0, 'sentiment': 'neutral'};
  }

  // Convert sentiment labels to user-friendly text
  static String _getSentimentLabel(String? label) {
    switch (label?.toLowerCase()) {
      case 'positive':
        return 'Positive';
      case 'negative':
        return 'Negative';
      case 'neutral':
      default:
        return 'Neutral';
    }
  }

  // Smart task description enhancement
  static Future<String> enhanceTaskDescription(String description) async {
    try {
      // First, classify the task
      final category = await classifyTask(description);
      
      // Then, create an enhanced description
      final enhancedDescription = '''
Task Category: $category

$description

This task has been automatically categorized as "$category" to help you find the right person for the job.
''';
      
      return enhancedDescription;
    } catch (e) {
      // If AI fails, return original description
      return description;
    }
  }

  // Analyze user feedback and provide insights
  static Future<Map<String, dynamic>> analyzeUserFeedback(String feedback) async {
    try {
      final sentiment = await analyzeSentiment(feedback);
      final language = await detectLanguage(feedback);
      
      return {
        'sentiment': sentiment,
        'language': language,
        'feedback': feedback,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'sentiment': {'label': 'neutral', 'score': 0.0, 'sentiment': 'neutral'},
        'language': 'unknown',
        'feedback': feedback,
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
} 