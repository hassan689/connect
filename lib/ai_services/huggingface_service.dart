import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connect/config/app_config.dart';

/// Service for integrating with Hugging Face's machine learning models.
/// 
/// Provides access to various AI capabilities including:
/// - Sentiment analysis of text
/// - Automatic task categorization
/// - Question answering
/// - Text summarization
/// - Language detection
/// 
/// All methods require a valid Hugging Face API token configured in the
/// environment. Falls back gracefully with exceptions if token is missing.
class HuggingFaceService {
  /// Hugging Face API token loaded from environment configuration.
  static String get _apiToken => AppConfig.huggingFaceApiToken;
  
  /// Hugging Face API base URL loaded from environment configuration.
  static String get _baseUrl => AppConfig.huggingFaceBaseUrl;

  /// Analyzes the sentiment of the given text.
  /// 
  /// Uses the twitter-roberta-base-sentiment-latest model to determine
  /// if the text expresses positive, negative, or neutral sentiment.
  /// Useful for analyzing user feedback, reviews, or task descriptions.
  /// 
  /// [text] The text to analyze for sentiment
  /// 
  /// Returns a Map containing:
  /// - `label`: Raw sentiment label from the model
  /// - `score`: Confidence score (0.0 to 1.0)
  /// - `sentiment`: User-friendly sentiment label (Positive/Negative/Neutral)
  /// 
  /// Throws [Exception] if API token is not configured or API call fails
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

  /// Automatically classifies a task into predefined categories.
  /// 
  /// Uses the BART-large-MNLI zero-shot classification model to categorize
  /// task descriptions into categories like Cleaning, Gardening, Moving,
  /// Pet Care, etc. This helps organize tasks and improve searchability.
  /// 
  /// [taskDescription] The task description text to classify
  /// 
  /// Returns the most likely category label (e.g., 'Cleaning', 'Delivery')
  /// 
  /// Throws [Exception] if API token is not configured or API call fails
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

  /// Answers a question based on the provided context.
  /// 
  /// Uses the RoBERTa-base-squad2 question answering model to extract
  /// answers from context text. Useful for building FAQ systems or
  /// helping users find information in task descriptions.
  /// 
  /// [question] The question to answer
  /// [context] The context text containing the answer
  /// 
  /// Returns the extracted answer string, or 'No answer found' if no
  /// answer can be extracted from the context
  /// 
  /// Throws [Exception] if API token is not configured or API call fails
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

  /// Generates a concise summary of long text.
  /// 
  /// Uses the BART-large-CNN summarization model to create shorter
  /// versions of long text while preserving key information. Useful
  /// for creating task previews or condensing user feedback.
  /// 
  /// [text] The text to summarize
  /// 
  /// Returns a summarized version of the text, or the original text
  /// if summarization fails
  /// 
  /// Throws [Exception] if API token is not configured or API call fails
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

  /// Detects the language of the given text.
  /// 
  /// Uses the xlm-roberta-base-language-detection model to identify
  /// what language the text is written in. Useful for multilingual
  /// support and routing content to appropriate translators.
  /// 
  /// [text] The text whose language to detect
  /// 
  /// Returns the detected language code (e.g., 'en', 'ur', 'es'),
  /// or 'unknown' if detection fails
  /// 
  /// Throws [Exception] if API token is not configured or API call fails
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

  /// Processes raw sentiment analysis results into a structured format.
  /// 
  /// Extracts and formats the sentiment label and confidence score from
  /// the Hugging Face API response into a standardized Map structure.
  /// 
  /// [data] Raw response data from the sentiment analysis API
  /// 
  /// Returns a Map with standardized sentiment information
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

  /// Converts model sentiment labels to user-friendly text.
  /// 
  /// Maps technical labels from the sentiment analysis model to
  /// human-readable labels suitable for display in the UI.
  /// 
  /// [label] The raw sentiment label from the model
  /// 
  /// Returns 'Positive', 'Negative', or 'Neutral'
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

  /// Enhances a task description by adding AI-generated metadata.
  /// 
  /// Automatically classifies the task and prepends category information
  /// to the description, making it easier for users to find relevant tasks.
  /// Falls back to the original description if AI classification fails.
  /// 
  /// [description] The original task description
  /// 
  /// Returns an enhanced description with category metadata, or the
  /// original description if enhancement fails
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

  /// Analyzes user feedback using multiple AI models.
  /// 
  /// Combines sentiment analysis and language detection to provide
  /// comprehensive insights about user feedback. Useful for understanding
  /// user satisfaction and routing feedback to appropriate handlers.
  /// 
  /// [feedback] The user feedback text to analyze
  /// 
  /// Returns a Map containing:
  /// - `sentiment`: Sentiment analysis results
  /// - `language`: Detected language code
  /// - `feedback`: Original feedback text
  /// - `timestamp`: ISO 8601 formatted timestamp
  /// - `error`: Error message if analysis fails (optional)
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