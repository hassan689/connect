# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the Connect project's CI/CD pipeline.

## 📋 Available Workflows

### `ci.yml` - Flutter CI/CD Pipeline

**Purpose:** Automated testing, code analysis, and builds for the Connect Flutter application.

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests targeting `main` branch
- Manual trigger via workflow dispatch

**Jobs:**

#### 1. `analyze-and-test`
Runs code quality checks and tests on Ubuntu runner.

**Steps:**
- Checkout code
- Setup Flutter (v3.16.0 stable)
- Install dependencies (`flutter pub get`)
- Check code formatting (`flutter format`)
- Run static analysis (`flutter analyze`)
- Execute tests (`flutter test`)

#### 2. `build-android`
Builds Android APK after successful analysis.

**Steps:**
- Checkout code
- Setup Flutter
- Install dependencies
- Build debug APK (`flutter build apk --debug`)

#### 3. `build-ios`
Builds iOS app on macOS runner after successful analysis.

**Steps:**
- Checkout code
- Setup Flutter
- Install dependencies
- Build iOS without code signing (`flutter build ios --no-codesign --debug`)

## 🔧 Workflow Configuration

### Flutter Version
Current workflows use Flutter **3.16.0** on the **stable** channel. Update the `flutter-version` parameter in workflow files if the project upgrades Flutter.

### Caching
Workflows use Flutter action caching (`cache: true`) to speed up builds by caching:
- Flutter SDK
- Pub dependencies
- Gradle dependencies (Android)

### Error Handling
Most build steps use `continue-on-error: true` to allow the workflow to complete even if individual steps fail. This helps identify multiple issues in a single run.

## 🚀 Running Workflows

### Automatic Triggers
Workflows run automatically on:
```bash
# Push to main or develop
git push origin main
git push origin develop

# Pull requests to main
git push origin feature-branch
# Then create PR targeting main
```

### Manual Trigger
1. Go to repository **Actions** tab
2. Select **Flutter CI** workflow
3. Click **Run workflow**
4. Choose branch and click **Run workflow** button

## 📊 Monitoring Workflow Runs

### View Status
- **Repository main page:** Check status badge at top of README
- **Actions tab:** See all workflow runs with detailed logs
- **Pull requests:** View checks status at bottom of PR

### Understanding Results
- ✅ **Success:** All jobs passed
- ❌ **Failure:** One or more jobs failed
- 🟡 **In Progress:** Workflow is currently running
- ⚫ **Cancelled:** Workflow was manually cancelled

### Debugging Failures
1. Click on failed workflow run
2. Select failed job
3. Expand failed step to view logs
4. Check error messages and stack traces
5. Common issues:
   - **Format errors:** Run `flutter format .` locally
   - **Analysis warnings:** Fix issues shown by `flutter analyze`
   - **Test failures:** Run `flutter test` locally
   - **Build errors:** Ensure dependencies are up to date

## 🛠️ Modifying Workflows

### Best Practices
1. **Test locally first:** Run commands locally before adding to workflow
2. **Use caching:** Enable caching for faster builds
3. **Fail fast:** Set `fail-fast: true` if dependent jobs shouldn't run
4. **Descriptive names:** Use clear job and step names
5. **Comments:** Add comments for complex logic

### Adding New Workflow
1. Create new `.yml` file in `.github/workflows/`
2. Define workflow name and triggers
3. Add jobs with descriptive names
4. Test with workflow dispatch first
5. Document in this README

### Common Changes

#### Update Flutter Version
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.19.0'  # Update version here
    channel: 'stable'
```

#### Add New Build Target
```yaml
build-web:
  name: Build Web
  runs-on: ubuntu-latest
  needs: analyze-and-test
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter build web
```

#### Run on Different Branches
```yaml
on:
  push:
    branches: [ main, develop, staging ]  # Add branches here
```

## 📚 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter GitHub Action](https://github.com/marketplace/actions/flutter-action)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [YAML Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

## 🤝 Contributing

When adding or modifying workflows:
1. Test changes in a feature branch first
2. Ensure workflows pass on your branch
3. Document changes in this README
4. Request review from maintainers
5. Monitor first run after merge

## 📞 Support

If workflows are failing or you need help:
1. Check [troubleshooting section](#debugging-failures) above
2. Review workflow logs in Actions tab
3. Search [GitHub Actions community](https://github.community/c/actions)
4. Open an issue with workflow logs and description

---

**Last Updated:** 2025-12-21
**Maintained by:** Connect Development Team
