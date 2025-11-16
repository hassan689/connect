# Firebase Web Configuration Guide

## Current Issues

Your app is showing these errors:
1. **Firebase API Key Error**: `api-key-not-valid.-please-pass-a-valid-api-key`
2. **Google Sign-In Client ID Error**: `ClientID not set`

## How to Fix

### 1. Get Firebase Web Configuration

The Firebase web app needs its own configuration separate from Android:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **linkster-ad331**
3. Click the gear icon ⚙️ → **Project settings**
4. Scroll down to **Your apps** section
5. If you don't have a **Web app**, click **Add app** → Select the web icon `</>`
6. Register your app with a nickname (e.g., "Linkster Web")
7. Copy the configuration values

### 2. Update `lib/firebase_options.dart`

Replace the web configuration with your actual values:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',  // Copy from Firebase Console
  appId: 'YOUR_WEB_APP_ID',    // Format: 1:718569523487:web:xxxxx
  messagingSenderId: '718569523487',
  projectId: 'linkster-ad331',
  authDomain: 'linkster-ad331.firebaseapp.com',
  storageBucket: 'linkster-ad331.firebasestorage.app',
  measurementId: 'G-XXXXXXXXXX',  // Optional: For Analytics
);
```

**Important**: The Web API Key might be different from the Android API Key!

### 3. Configure Google Sign-In for Web

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **linkster-ad331**
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**
5. Select **Web application**
6. Add authorized JavaScript origins:
   - `http://localhost` (for development)
   - `http://localhost:xxxxx` (your dev server port)
   - Your production domain (if deployed)
7. Copy the **Client ID** (format: `xxxxx.apps.googleusercontent.com`)

### 4. Update `web/index.html`

Replace the placeholder in `web/index.html`:

```html
<meta name="google-signin-client_id" content="YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com">
```

### 5. Verify API Key Restrictions

If you still get API key errors:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. **APIs & Services** → **Credentials**
3. Find your Web API Key
4. Click to edit
5. Under **API restrictions**, make sure:
   - **Firebase Authentication API** is enabled
   - **Firebase Installations API** is enabled
   - Or set to **Don't restrict key** (for testing)

### 6. Restart Your App

After making changes:
1. Stop the Flutter web server
2. Run `flutter clean` (optional but recommended)
3. Run `flutter run -d chrome` again

## Quick Checklist

- [ ] Created Web app in Firebase Console
- [ ] Updated `lib/firebase_options.dart` with Web API Key and App ID
- [ ] Created OAuth 2.0 Client ID for Web in Google Cloud Console
- [ ] Updated `web/index.html` with Google Sign-In Client ID
- [ ] Verified API key restrictions allow Firebase APIs
- [ ] Restarted the app

## Alternative: Use FlutterFire CLI

The easiest way is to use FlutterFire CLI:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for all platforms
flutterfire configure

# Select your Firebase project
# Select platforms: web, android, ios, etc.
# This will automatically update firebase_options.dart
```

This will generate the correct configuration for all platforms automatically!


