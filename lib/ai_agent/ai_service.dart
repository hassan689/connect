import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connect/config/app_config.dart';

class AIService {
  static String get _apiKey => AppConfig.openAiApiKey;
  static String get _baseUrl => AppConfig.openAiBaseUrl;

  // Context for Dino agent
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
        return data['choices'][0]['message']['content'];
      } else {
        // Fallback to simple responses if API fails
        return _getSimpleResponse(userMessage);
      }
    } catch (e) {
      // Fallback to simple responses
      return _getSimpleResponse(userMessage);
    }
  }

  static String _getSimpleResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return 'Hello! How can I help you today? 😊';
    } else if (lowerMessage.contains('post') || lowerMessage.contains('create') || lowerMessage.contains('task')) {
      return 'To post a task:\n\n1️⃣ Tap the "Post a Task" button on the main screen\n2️⃣ Fill in the task details (title, description, budget)\n3️⃣ Add location and images if needed\n4️⃣ Review and post!\n\nWould you like me to walk you through any specific step? 🚀';
    } else if (lowerMessage.contains('find') || lowerMessage.contains('search') || lowerMessage.contains('browse')) {
      return 'To find tasks:\n\n1️⃣ Go to the "Browse" tab\n2️⃣ Use filters to narrow down tasks\n3️⃣ Tap on a task to see details\n4️⃣ Make an offer if interested!\n\nYou can also use the map view to see tasks near you! 📍';
    } else if (lowerMessage.contains('payment') || lowerMessage.contains('pay') || lowerMessage.contains('money')) {
      return 'We use a point-based system for payments! ⭐\n\n• Earn points by completing tasks\n• Use points to post and pay for tasks\n• Platform takes 10% commission\n• Service providers receive 90% of points\n\nNeed help understanding the points system?';
    } else if (lowerMessage.contains('help') || lowerMessage.contains('support')) {
      return 'I\'m here to help! Here are some common topics:\n\n📝 How to post tasks\n🔍 How to find tasks\n💳 Payment setup\n📍 Location services\n📱 App features\n\nWhat would you like to know more about?';
    } else if (lowerMessage.contains('feature') || lowerMessage.contains('what can') || lowerMessage.contains('do')) {
      return 'Connect is a task marketplace where you can:\n\n✅ Post tasks and get them done\n✅ Find work and earn money\n✅ Connect with local taskers\n✅ Use secure payments\n✅ Track task progress\n✅ Get real-time notifications\n\nPretty cool, right? 😎';
    } else if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      return 'You\'re welcome! I\'m always here to help. Don\'t hesitate to ask if you need anything else! 🦕✨';
    } else if (lowerMessage.contains('earn') || lowerMessage.contains('money') || lowerMessage.contains('work')) {
      return 'Want to earn points? Here\'s how:\n\n⭐ Browse available tasks in your area\n💼 Make competitive offers\n✅ Complete tasks professionally\n💰 Earn points (90% of task value)\n⭐ Build your reputation\n\nStart by checking the Browse tab! 🚀';
    } else if (lowerMessage.contains('safety') || lowerMessage.contains('secure') || lowerMessage.contains('trust')) {
      return 'Your safety is our priority! 🔒\n\n• All users are verified\n• Secure payment system\n• Real-time tracking\n• User ratings and reviews\n• 24/7 support available\n\nFeel free to ask about any safety concerns!';
    } else {
      return 'That\'s interesting! 🤔 I\'m still learning, but I can help you with:\n\n• Posting tasks\n• Finding work\n• Payment setup\n• App navigation\n• General questions\n\nWhat would you like to know?';
    }
  }

  // Method to save conversation history to Firestore
  static Future<void> saveConversation(String userId, String userMessage, String aiResponse) async {
    // You can implement this to save conversations for analytics
    // This helps improve the AI responses over time
  }

  // Method to get conversation suggestions based on user behavior
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