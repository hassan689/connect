# Connect
[![CI/CD Pipeline](https://github.com/hassan689/connect-open-source/actions/workflows/ci.yml/badge.svg)](https://github.com/hassan689/connect/actions/workflows/ci.yml)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.16.0-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A modern task management application built with Flutter that connects service providers with clients. Connect makes it easy to find help for tasks or offer your services to others.
<img width="1920" height="864" alt="Screenshot (134)" src="https://github.com/user-attachments/assets/1a437441-fd42-41a9-8d2c-9d94ed3c384e" />
**Demo:** https://connect-app-landing.netlify.app/

**Note:** You can download the APK from the landing page. 
## Features

### For Task Seekers
- **Browse Tasks**: Find available tasks in your area
- **Map View**: Interactive map showing task locations with distance and pricing
- **Search & Filter**: Find specific types of tasks
- **Real-time Messaging**: Communicate with task posters
- **Secure Payments**: Safe and protected transactions
- **AI Assistant**: Get help from Dino, your AI guide

### For Task Posters
- **Post Tasks**: Create and publish new tasks with detailed requirements
- **Manage Tasks**: Edit, cancel, or mark tasks complete
- **Track Progress**: Monitor task status and completion
- **Rate Providers**: Leave feedback after completion
- **Schedule Tasks**: Set specific dates and times for task completion

### Core Features
- **Location-based Discovery**: Find tasks near you with interactive maps
- **User Verification**: Secure and verified user accounts
- **Real-time Updates**: Live task and message updates
- **Push Notifications**: Stay informed about new activities
- **Multi-platform**: Works on Android, iOS, and Web
- **AI-Powered Assistance**: Get help navigating the app with Dino

## Screenshots

<div style="display: flex; flex-wrap: wrap; gap: 10px;">

  <img src="https://github.com/user-attachments/assets/3db1f61f-f73b-4129-9b8e-bd832caaa1a6" width="150" height="1800"/>
  <img src="https://github.com/user-attachments/assets/86fef8da-f41c-4e9a-b122-ddf55ab7c010" width="150"/>
  <img src="https://github.com/user-attachments/assets/e62a061a-2324-4cc9-99a3-629c9cd491a5" width="150"/>

  <img src="https://github.com/user-attachments/assets/f72d799f-402a-4e03-9e63-e1f4fdb5a628" width="150"/>
  <img src="https://github.com/user-attachments/assets/4ee012cb-e850-4a02-ad25-5f746a749545" width="150"/>
  <img src="https://github.com/user-attachments/assets/6c1601f3-a5b1-441e-8520-ec7ec5802e7e" width="150"/>

  <img src="https://github.com/user-attachments/assets/7e1de8f6-7e97-49d0-add5-eef69c74f601" width="150"/>

</div>


## Technology Stack

- **Frontend**: Flutter 3.16.0
- **Backend**: Firebase
- **Authentication**: Firebase Auth (Email, Google, Apple Sign-In)
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Maps**: Google Maps Flutter
- **Payments**: Stripe Integration
- **Notifications**: Firebase Cloud Messaging
- **AI Integration**: OpenAI & Hugging Face

## Prerequisites

Before running this project, make sure you have the following installed:

- [Flutter](https://flutter.dev/docs/get-started/install) (3.16.0 or higher)
- [Dart](https://dart.dev/get-dart) (3.0.0 or higher)
- [Android Studio](https://developer.android.com/studio) (for Android development)
- [Xcode](https://developer.apple.com/xcode/) (for iOS development, macOS only)
- [Firebase CLI](https://firebase.google.com/docs/cli) (for Firebase setup)

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/hassan689/connect.git
cd connect
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication, Firestore, Storage, and Cloud Messaging
3. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
4. Configure Firebase for your project:
   ```bash
   flutterfire configure
   ```
   This will generate `lib/firebase_options.dart` with your Firebase configuration.
5. Download the configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
6. Place the files in the appropriate directories:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

### 4. Environment Variables Setup

1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your API keys:
   ```bash
   # OpenAI (for AI features)
   OPENAI_API_KEY=your_openai_api_key_here
   
   # Google Maps
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
   
   # Hugging Face (for AI features)
   HUGGINGFACE_API_TOKEN=your_huggingface_token_here
   ```

### 5. Google Maps Setup

1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Maps SDK for Android and iOS
3. Add the API key to your `.env` file (see step 4)
4. **For Android:** Replace `YOUR_GOOGLE_MAPS_API_KEY` in `android/app/src/main/AndroidManifest.xml` with your actual key
5. **For iOS:** Add the key to `ios/Runner/AppDelegate.swift` (see Firebase setup)

**Note:** The API key in AndroidManifest.xml needs to be set manually as Android doesn't support environment variables directly.

### 6. Run the App

```bash
# For Android
flutter run

# For iOS (macOS only)
flutter run -d ios

# For Web
flutter run -d chrome
```

## Project Structure

```
lib/
├── core/                    # Core functionality
│   ├── constants/          # App constants
│   ├── utils/              # Utility functions
│   ├── services/           # Core services
│   └── theme/              # App theme
├── ai_agent/               # AI assistant (Dino)
├── ai_services/            # AI service integrations
├── auth/                   # Authentication screens
├── connects/               # User connection features
├── dashboard/              # Analytics dashboard
├── messaging/              # Messaging system
├── profilepage/             # User profile management
├── search_tasks/            # Task browsing and search
├── task_post/               # Task creation flow
├── widgets/                 # Reusable components
└── main.dart                # App entry point
```

## Testing

Run the test suite:

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

## Building

### Android

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# App bundle for Play Store
flutter build appbundle --release
```

### iOS

```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release
```

### Web

```bash
# Debug build
flutter build web --debug

# Release build
flutter build web --release
```

## Documentation

- [Getting Started](docs/GETTING_STARTED.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

We follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) and use [flutter_lints](https://pub.dev/packages/flutter_lints) for code analysis.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you need help or have questions:

- **Documentation**: Check our [docs](docs/) folder
- **Issues**: Create an issue on [GitHub](https://github.com/hassan689/connect/issues)
- **Security**: Report security issues via [SECURITY.md](SECURITY.md)

## Acknowledgments

- [Flutter Team](https://flutter.dev/) for the amazing framework
- [Firebase](https://firebase.google.com/) for backend services
- [Google Maps](https://developers.google.com/maps) for mapping services
- [OpenAI](https://openai.com/) for AI capabilities
- [Hugging Face](https://huggingface.co/) for AI models
- All our contributors and users

## Project Status

- ✅ Core functionality implemented
- ✅ Authentication system (Email, Google, Apple)
- ✅ Task management
- ✅ Messaging system
- ✅ Payment integration
- ✅ Map integration
- ✅ AI Assistant (Dino)
- ✅ Push notifications
- ✅ Multi-language support (English, Urdu)
- 🔄 Offline support (planned)
- 🔄 Advanced analytics (planned)

---
## 🤝 Community, Discord & Contributions

We believe in building Connect together.  
Join our Discord server to:
- Ask questions
- Discuss features
- Find contribution opportunities
- Collaborate with other developers

👉 [Join our Discord](https://discord.gg/Vc9P84fp)
**Developed by the Connect Team**

[GitHub Repository](https://github.com/hassan689/connect) | [Report Issue](https://github.com/hassan689/connect-open-source/issues)
