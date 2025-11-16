# Contributing to Connect

First off, thank you for considering contributing to Connect! It's people like you that make Connect such a great tool.

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find out that you don't need to create one. When creating a bug report, include as many details as possible:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior**
- **Actual behavior**
- **Screenshots** (if applicable)
- **Environment details** (OS, Flutter version, device)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Use case** - why is this enhancement useful?
- **Proposed solution** (if you have one)
- **Alternatives considered**

### Pull Requests

1. **Fork the repository**
2. **Create your feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Run tests** (`flutter test`)
5. **Run linter** (`flutter analyze`)
6. **Commit your changes** (`git commit -m 'Add amazing feature'`)
   - Use clear, descriptive commit messages
   - Reference issues in commit messages when applicable
7. **Push to the branch** (`git push origin feature/amazing-feature`)
8. **Open a Pull Request**

## Development Setup

### Prerequisites

- Flutter SDK (3.16.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Git

### Setup Steps

1. **Clone your fork**
   ```bash
   git clone https://github.com/your-username/connect.git
   cd connect
   ```

2. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/original-owner/connect.git
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys (see README.md for details)
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Coding Standards

### Dart Style Guide

We follow the [Effective Dart Style Guide](https://dart.dev/guides/language/effective-dart/style). Key points:

- Use `lowerCamelCase` for variables, parameters, and named parameters
- Use `UpperCamelCase` for types and classes
- Use `lowercase_with_underscores` for library names
- Prefer `final` over `var` when possible
- Use `const` constructors when possible

### Code Formatting

Run the formatter before committing:
```bash
flutter format .
```

### Linting

We use `flutter_lints` for code analysis. Run:
```bash
flutter analyze
```

Fix all warnings and errors before submitting a PR.

### Documentation

- **Public APIs**: Add dartdoc comments to all public classes, methods, and properties
- **Complex logic**: Add inline comments explaining why, not what
- **Examples**: Include code examples in documentation when helpful

Example:
```dart
/// Calculates the commission for a given amount.
/// 
/// The commission is calculated as a percentage of the total amount.
/// 
/// Example:
/// ```dart
/// final commission = calculateCommission(100.0, 0.10); // Returns 10.0
/// ```
double calculateCommission(double amount, double rate) {
  return amount * rate;
}
```

### Testing

- Write tests for new features
- Maintain or improve test coverage
- Run tests before submitting PR: `flutter test`

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Maintenance tasks

Examples:
```
feat: Add dark mode support
fix: Resolve login authentication issue
docs: Update README with setup instructions
```

## Project Structure

```
lib/
├── core/              # Core functionality
├── features/          # Feature modules
├── shared/            # Shared code
└── main.dart          # Entry point
```

When adding new features:
- Place feature code in `lib/features/[feature_name]/`
- Create reusable widgets in `lib/core/widgets/`
- Add shared utilities to `lib/core/utils/`

## Pull Request Process

1. **Update documentation** if needed
2. **Add tests** for new features
3. **Ensure all tests pass**
4. **Run linter** and fix issues
5. **Update CHANGELOG.md** (if applicable)
6. **Request review** from maintainers

### PR Checklist

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] All tests pass
- [ ] No new warnings
- [ ] CHANGELOG updated (if applicable)

## Questions?

- Open an issue for bug reports or feature requests
- Check existing issues and discussions
- Contact maintainers via GitHub

Thank you for contributing! 🎉



