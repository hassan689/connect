# Quick Start: Making Connect Open Source Ready

This is a condensed guide to get you started quickly. For detailed information, see [OPEN_SOURCE_IMPROVEMENT_PLAN.md](OPEN_SOURCE_IMPROVEMENT_PLAN.md).

## 🚨 Critical Actions (Do First!)

### 1. Remove Hardcoded API Keys (URGENT)

**Files to fix immediately:**

1. **`lib/ai_agent/ai_service.dart`**
   ```dart
   // ❌ REMOVE THIS LINE:
   static const String _apiKey = 'sk-proj-...';
   
   // ✅ REPLACE WITH:
   static String get _apiKey => AppConfig.openAiApiKey;
   ```

2. **`lib/search_tasks/mappoints/points.dart`**
   ```dart
   // ❌ REMOVE:
   '&key=AIzaSyD5pNweBdXlfqpujqzIZjBApmxnI5BpCmo'
   
   // ✅ REPLACE WITH:
   '&key=${AppConfig.googleMapsApiKey}'
   ```

3. **Update `lib/config/app_config.dart`**
   ```dart
   // Add these getters:
   static String get openAiApiKey => 
       _getEnv('OPENAI_API_KEY', '');
   ```

4. **Create `.env` file** (copy from `.env.example`)
   ```bash
   cp .env.example .env
   # Edit .env and add your actual API keys
   ```

5. **Revoke exposed keys** and generate new ones:
   - OpenAI: https://platform.openai.com/api-keys
   - Google Maps: https://console.cloud.google.com/google/maps-apis/credentials

### 2. Verify .gitignore

Ensure these are in `.gitignore`:
```
.env
.env.local
*.key
google-services.json
GoogleService-Info.plist
```

## 📋 Checklist

### Phase 1: Security (Week 1)
- [ ] Remove all hardcoded API keys
- [ ] Create `.env.example` file
- [ ] Update `app_config.dart` with new keys
- [ ] Revoke and regenerate exposed keys
- [ ] Verify `.gitignore` is correct
- [ ] Test app with environment variables

### Phase 2: Documentation (Week 2)
- [ ] Update README.md with screenshots
- [ ] Create CONTRIBUTING.md ✅ (Done)
- [ ] Create CODE_OF_CONDUCT.md ✅ (Done)
- [ ] Create LICENSE ✅ (Done)
- [ ] Add doc comments to public APIs
- [ ] Create architecture diagram

### Phase 3: Code Quality (Week 3)
- [ ] Run `flutter analyze` and fix issues
- [ ] Run `flutter format .` to format code
- [ ] Rename unclear files (`loginp.dart` → `login_page.dart`)
- [ ] Update package name in `pubspec.yaml`
- [ ] Organize code into feature-based structure

### Phase 4: Testing (Week 4)
- [ ] Add test dependencies
- [ ] Write unit tests for services
- [ ] Write widget tests for reusable components
- [ ] Set up CI/CD pipeline
- [ ] Aim for 70%+ test coverage

## 🛠️ Quick Commands

```bash
# Format code
flutter format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Check test coverage
flutter test --coverage

# Generate API docs
dart doc lib/
```

## 📚 Key Files Created

1. **OPEN_SOURCE_IMPROVEMENT_PLAN.md** - Comprehensive improvement plan
2. **CONTRIBUTING.md** - Contributor guidelines ✅
3. **CODE_OF_CONDUCT.md** - Code of conduct ✅
4. **LICENSE** - MIT License ✅
5. **.env.example** - Environment variables template ✅
6. **docs/REFACTORING_EXAMPLES.md** - Code examples

## 🎯 Priority Order

1. **Security** (Remove API keys) - CRITICAL
2. **Documentation** (README, CONTRIBUTING) - HIGH
3. **Code Organization** - MEDIUM
4. **Testing** - MEDIUM
5. **CI/CD** - LOW (but important)

## 📖 Next Steps

1. Read [OPEN_SOURCE_IMPROVEMENT_PLAN.md](OPEN_SOURCE_IMPROVEMENT_PLAN.md) for details
2. Review [docs/REFACTORING_EXAMPLES.md](docs/REFACTORING_EXAMPLES.md) for code examples
3. Start with Phase 1 (Security)
4. Work through phases sequentially

## ❓ Questions?

- Check the detailed plan: `OPEN_SOURCE_IMPROVEMENT_PLAN.md`
- Review examples: `docs/REFACTORING_EXAMPLES.md`
- Open an issue for help

---

**Remember:** Security first! Remove those API keys before making the repo public. 🔒

