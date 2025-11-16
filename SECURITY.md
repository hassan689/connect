# Security Guidelines

## 🔒 API Keys and Sensitive Information

This project follows strict security practices to ensure no sensitive information is exposed in the open-source repository.

### ✅ What's Safe to Commit

- Template files (`.env.example`, `firebase_options.example.dart`)
- Placeholder values (`YOUR_API_KEY_HERE`)
- Configuration structure (without actual keys)

### ❌ What's NEVER Committed

- `.env` file (contains actual API keys)
- `lib/firebase_options.dart` (contains Firebase API keys)
- `google-services.json` (Android Firebase config)
- `GoogleService-Info.plist` (iOS Firebase config)
- Any file with actual API keys, tokens, or secrets

### 🔐 Protected Files

These files are in `.gitignore` and will NOT be committed:

```
.env
.env.local
.env.*
lib/firebase_options.dart
google-services.json
GoogleService-Info.plist
*.key
*.p12
```

### 📝 Setting Up API Keys

1. **Copy template files:**
   ```bash
   cp .env.example .env
   cp lib/firebase_options.example.dart lib/firebase_options.dart
   ```

2. **Add your actual keys to `.env`:**
   ```bash
   OPENAI_API_KEY=sk-your-actual-key
   GOOGLE_MAPS_API_KEY=your-actual-key
   HUGGINGFACE_API_TOKEN=hf_your-actual-token
   ```

3. **Generate Firebase config:**
   ```bash
   flutterfire configure
   ```
   This creates `lib/firebase_options.dart` with your Firebase keys.

### 🚨 If You Accidentally Commit Keys

1. **Immediately revoke the exposed keys:**
   - OpenAI: https://platform.openai.com/api-keys
   - Google Maps: https://console.cloud.google.com/google/maps-apis/credentials
   - Hugging Face: https://huggingface.co/settings/tokens
   - Firebase: https://console.firebase.google.com/

2. **Remove from git history:**
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch lib/firebase_options.dart" \
     --prune-empty --tag-name-filter cat -- --all
   ```

3. **Generate new keys** and update your `.env` file

### ✅ Security Checklist

Before committing code, ensure:

- [ ] No hardcoded API keys in source files
- [ ] `.env` file is in `.gitignore`
- [ ] `firebase_options.dart` is in `.gitignore`
- [ ] All sensitive values use environment variables
- [ ] Template files use placeholder values
- [ ] No credentials in comments or documentation

### 📚 Additional Resources

- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)



