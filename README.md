# Linkster - Task Management App

[![CI/CD Pipeline](https://github.com/your-username/linkster/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/linkster/actions/workflows/ci.yml)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.16.0-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A modern task management application built with Flutter that connects service providers with clients. Linkster makes it easy to find help for tasks or offer your services to others.

## 🚀 Features

### For Task Seekers
- **Browse Tasks**: Find available tasks in your area
- **Map View**: Interactive map showing task locations
- **Search & Filter**: Find specific types of tasks
- **Real-time Messaging**: Communicate with task posters
- **Secure Payments**: Safe and protected transactions

### For Task Posters
- **Post Tasks**: Create and publish new tasks
- **Manage Tasks**: Edit, cancel, or mark tasks complete
- **Track Progress**: Monitor task status and completion
- **Rate Providers**: Leave feedback after completion

### Core Features
- **Location-based Discovery**: Find tasks near you
- **User Verification**: Secure and verified user accounts
- **Real-time Updates**: Live task and message updates
- **Push Notifications**: Stay informed about new activities
- **Multi-platform**: Works on Android, iOS, and Web

## 📱 Screenshots

[Add screenshots here]

## 🛠️ Technology Stack

- **Frontend**: Flutter 3.16.0
- **Backend**: Firebase
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Maps**: Google Maps Flutter
- **Payments**: JazzCash
- **Notifications**: Firebase Cloud Messaging

## 📋 Prerequisites

Before running this project, make sure you have the following installed:

- [Flutter](https://flutter.dev/docs/get-started/install) (3.16.0 or higher)
- [Dart](https://dart.dev/get-dart) (3.0.0 or higher)
- [Android Studio](https://developer.android.com/studio) (for Android development)
- [Xcode](https://developer.apple.com/xcode/) (for iOS development, macOS only)
- [Firebase CLI](https://firebase.google.com/docs/cli) (for Firebase setup)

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/linkster.git
cd linkster
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

**⚠️ Important:** The `firebase_options.dart` file contains your Firebase API keys and should NOT be committed to version control. It's already in `.gitignore`.

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

3. **⚠️ Never commit the `.env` file** - it's already in `.gitignore`

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

## 📁 Project Structure

```
lib/
├── core/                    # Core functionality
│   ├── constants/          # App constants
│   ├── utils/              # Utility functions
│   ├── services/           # Core services
│   └── widgets/            # Reusable components
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── tasks/             # Task management
│   ├── messaging/         # Messaging system
│   ├── payments/          # Payment processing
│   └── notifications/     # Push notifications
├── shared/                # Shared components
│   ├── widgets/           # Shared UI widgets
│   ├── models/            # Data models
│   └── services/          # Shared services
└── main.dart              # App entry point
```

## 🧪 Testing

Run the test suite:

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/auth_test.dart
```

## 🏗️ Building

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

## 📚 Documentation

- [Architecture Guide](docs/architecture/README.md)
- [User Guide](docs/user-guide/README.md)
- [API Documentation](docs/api/README.md)
- [Deployment Guide](docs/deployment/README.md)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

We follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) and use [flutter_lints](https://pub.dev/packages/flutter_lints) for code analysis.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you need help or have questions:

- **Documentation**: Check our [docs](docs/) folder
- **Issues**: Create an issue on [GitHub](https://github.com/your-username/linkster/issues)
- **Email**: support@linkster.com
- **Community**: Join our [Discord](https://discord.gg/linkster) server

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev/) for the amazing framework
- [Firebase](https://firebase.google.com/) for backend services
- [Google Maps](https://developers.google.com/maps) for mapping services
- [JazzCash](https://www.jazzcash.com.pk/) for payment processing
- All our contributors and users

## 📊 Project Status

- ✅ Core functionality implemented
- ✅ Authentication system
- ✅ Task management
- ✅ Messaging system
- ✅ Payment integration
- ✅ Map integration
- 🔄 Push notifications (in progress)
- 🔄 Offline support (planned)
- 🔄 Multi-language support (planned)

---

**Made with ❤️ by the Linkster Team**

[Website](https://linkster.com) | [Twitter](https://twitter.com/linkster) | [LinkedIn](https://linkedin.com/company/linkster)
