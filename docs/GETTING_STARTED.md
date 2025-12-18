# Getting Started

This guide helps you quickly run the Connect app locally for development.

## Prerequisites

- Flutter 3.16.0+ and Dart 3.0+
- Android Studio or Xcode (for native builds)
- Firebase CLI (optional but recommended)
- Git

## Clone

```bash
git clone https://github.com/hassan689/connect.git
cd connect
```

## Install dependencies

```bash
flutter pub get
```

## Firebase setup

1. Create a Firebase project and enable Auth, Firestore, Storage, and Cloud Messaging.
2. Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

3. Configure Firebase for the project:

```bash
flutterfire configure
```

4. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in the respective platform folders.

## Environment variables

Copy the example env file (if present) and add required keys:

```bash
cp .env.example .env
# edit .env with your keys
```

Required keys (examples):

- `OPENAI_API_KEY`
- `GOOGLE_MAPS_API_KEY`
- `HUGGINGFACE_API_TOKEN`

## Run the app

```bash
flutter run
```

## Useful commands

- Run tests: `flutter test`
- Run analyzer: `flutter analyze`
- Format code: `flutter format .`

If you run into issues, check the full `README.md` and open an issue with reproduction steps.
