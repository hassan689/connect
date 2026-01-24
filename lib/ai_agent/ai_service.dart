import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:connect/config/app_config.dart';
import 'package:connect/services/points_service.dart';

/// Service class for handling AI-powered chat interactions with Dino agent.
/// 
/// Provides integration with OpenAI's GPT-3.5-turbo model and fallback
/// responses for handling user queries about the Connect app features.
class AIService {
  /// OpenAI API key loaded from environment configuration.
  static String get _apiKey => AppConfig.openAiApiKey;
  
  /// OpenAI API base URL loaded from environment configuration.
  static String get _baseUrl => AppConfig.openAiBaseUrl;

  /// System prompt that defines Dino's personality and capabilities.
  static const String _systemPrompt = '''
You are Dino, a friendly and helpful AI assistant for the Connect app - a task marketplace where people can post tasks and find work. 

Your personality:
- Friendly and enthusiastic 🦕
- Use emojis occasionally to keep it fun
- Be helpful and patient
- Keep responses concise but informative
- Always encourage users to explore the app

You can help with:
- Explaining how to post tasks
- Guiding users through finding work
- Explaining points system
- App navigation and features
- General questions about the platform

Key app features:
- Post tasks with title, description, budget, location
- Browse and filter tasks
- Make offers on tasks
- Point-based payment system
- Real-time notifications
- Map view for nearby tasks
- User profiles and ratings

Always be encouraging and help users get the most out of Connect!
''';

  /// Gets an AI-generated response to the user's message.
  /// 
  /// Sends the user's message to OpenAI's GPT-3.5-turbo model with Dino's
  /// personality context. Falls back to simple pattern-based responses if
  /// the API call fails or the API key is not configured.
  /// 
  /// [userMessage] The message from the user to respond to
  /// 
  /// Returns a String containing Dino's response to the user
  /// 
  /// Throws [Exception] if the API key is not configured
  static Future<String> getAIResponse(String userMessage) async {
    if (_apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured. Please set OPENAI_API_KEY in .env file');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': _systemPrompt,
            },
            {
              'role': 'user',
              'content': userMessage,
            },
          ],
          'max_tokens': 300,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // We extract 'choices' safely
        final choices = data['choices'] as List?;
        
        // We check if the list exists and is not empty
        if (choices == null || choices.isEmpty) {
          return _getSimpleResponse(userMessage);
        }

        //  We extract the first option message
        final firstChoice = choices[0] as Map?;
        final message = firstChoice?['message'] as Map?;
        
        // We extract the final content
        final content = message?['content'] as String?;

        // 5. If content is null, we use fallback
        return content ?? _getSimpleResponse(userMessage);
      } else {
        // Fallback to simple responses if API fails
        return _getSimpleResponse(userMessage);
      }
    } catch (e) {
      // Fallback to simple responses
      return _getSimpleResponse(userMessage);
    }
  }

  /// Provides simple pattern-based responses when AI service is unavailable.
  /// 
  /// Uses keyword matching to detect user intent and provides helpful
  /// responses about common tasks like posting tasks, finding work, and
  /// understanding the points system.
  /// 
  /// [message] The user's message to analyze and respond to
  /// 
  /// Returns a helpful response based on detected keywords in the message
  static String _getSimpleResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return 'Hello! How can I help you today? 😊';
    } else if (lowerMessage.contains('post') || lowerMessage.contains('create') || lowerMessage.contains('task')) {
      return 'To post a task:\n\n1️⃣ Tap the "Post a Task" button on the main screen\n2️⃣ Fill in the task details (title, description, budget)\n3️⃣ Add location and images if needed\n4️⃣ Review and post!\n\nWould you like me to walk you through any specific step? 🚀';
    } else if (lowerMessage.contains('find') || lowerMessage.contains('search') || lowerMessage.contains('browse')) {
      return 'To find tasks:\n\n1️⃣ Go to the "Browse" tab\n2️⃣ Use filters to narrow down tasks\n3️⃣ Tap on a task to see details\n4️⃣ Make an offer if interested!\n\nYou can also use the map view to see tasks near you! 📍';
    } else if (lowerMessage.contains('payment') || lowerMessage.contains('pay') || lowerMessage.contains('money')) {
      final platformCommissionRate = PointsService.platformCommissionRate;
      final providerPayoutRate = PointsService.providerPayoutRate;
      return 'We use a point-based system for payments! ⭐\n\n• Earn points by completing tasks\n• Use points to post and pay for tasks\n• Platform takes ${(platformCommissionRate * 100).toStringAsFixed(0)}% commission\n• Service providers receive ${(providerPayoutRate * 100).toStringAsFixed(0)}% of points\n\nNeed help understanding the points system?';
    } else if (lowerMessage.contains('help') || lowerMessage.contains('support')) {
      return 'I\'m here to help! Here are some common topics:\n\n📝 How to post tasks\n🔍 How to find tasks\n💳 Payment setup\n📍 Location services\n📱 App features\n\nWhat would you like to know more about?';
    } else if (lowerMessage.contains('feature') || lowerMessage.contains('what can') || lowerMessage.contains('do')) {
      return 'Connect is a task marketplace where you can:\n\n✅ Post tasks and get them done\n✅ Find work and earn money\n✅ Connect with local taskers\n✅ Use secure payments\n✅ Track task progress\n✅ Get real-time notifications\n\nPretty cool, right? 😎';
    } else if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      return 'You\'re welcome! I\'m always here to help. Don\'t hesitate to ask if you need anything else! 🦕✨';
    } else if (lowerMessage.contains('earn') || lowerMessage.contains('money') || lowerMessage.contains('work')) {
      final providerPayoutRate = PointsService.providerPayoutRate;
      return 'Want to earn points? Here\'s how:\n\n⭐ Browse available tasks in your area\n💼 Make competitive offers\n✅ Complete tasks professionally\n💰 Earn points (${(providerPayoutRate * 100).toStringAsFixed(0)}% of task value)\n⭐ Build your reputation\n\nStart by checking the Browse tab! 🚀';
    } else if (lowerMessage.contains('safety') || lowerMessage.contains('secure') || lowerMessage.contains('trust')) {
      return 'Your safety is our priority! 🔒\n\n• All users are verified\n• Secure payment system\n• Real-time tracking\n• User ratings and reviews\n• 24/7 support available\n\nFeel free to ask about any safety concerns!';
    } else {
      return 'That\'s interesting! 🤔 I\'m still learning, but I can help you with:\n\n• Posting tasks\n• Finding work\n• Payment setup\n• App navigation\n• General questions\n\nWhat would you like to know?';
    }
  }

  /// Saves conversation history to Firestore for analytics and improvement.
  /// 
  /// Stores user interactions with Dino to the 'ai_conversations' collection,
  /// which helps analyze user needs and improve AI responses over time.
  /// 
  /// [userId] The ID of the user having the conversation
  /// [userMessage] The message sent by the user
  /// [aiResponse] The response generated by the AI
  /// 
  /// Saves to the 'ai_conversations' collection in Firestore with timestamp.
  static Future<void> saveConversation(String userId, String userMessage, String aiResponse) async {
    try {
      await FirebaseFirestore.instance
          .collection('ai_conversations')
          .add({
            'userId': userId,
            'userMessage': userMessage,
            'aiResponse': aiResponse,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error saving conversation: $e');
    }
  }

  /// Gets a list of suggested questions users can ask Dino.
  /// 
  /// Provides quick-start prompts to help users discover what Dino can
  /// assist with, covering common topics like task posting, finding work,
  /// and understanding app features.
  /// 
  /// Returns a List of suggested question strings
  static List<String> getSuggestions() {
    return [
      'How do I post a task?',
      'How do I find tasks?',
      'How do payments work?',
      'What features does the app have?',
      'How do I earn money?',
      'Is the app safe to use?',
    ];
  }
} 