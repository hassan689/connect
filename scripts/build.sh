#!/bin/bash

# Connect App Build Script
# This script automates the build process for different platforms

set -e

echo "🚀 Starting Connect App Build Process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Get Flutter version
print_status "Flutter version: $(flutter --version | head -n 1)"

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Run tests
print_status "Running tests..."
flutter test

# Build for Android
print_status "Building for Android..."
flutter build apk --release

# Build for iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building for iOS..."
    flutter build ios --release
else
    print_warning "Skipping iOS build (not on macOS)"
fi

# Build for Web
print_status "Building for Web..."
flutter build web --release

print_status "✅ Build process completed successfully!"
print_status "📱 Android APK: build/app/outputs/flutter-apk/app-release.apk"
print_status "🌐 Web build: build/web/"
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "📱 iOS build: build/ios/archive/Runner.xcarchive"
fi 