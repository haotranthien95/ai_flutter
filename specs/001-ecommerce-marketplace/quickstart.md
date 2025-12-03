# Development Quickstart Guide

**Feature**: Multi-Vendor E-Commerce Marketplace  
**Branch**: `001-ecommerce-marketplace`  
**Date**: 2025-12-03  
**Purpose**: Step-by-step guide to set up development environment and start building.

---

## Prerequisites

### Required Software

| Software | Minimum Version | Installation |
|----------|----------------|--------------|
| **Flutter SDK** | 3.5.4 | [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) |
| **Dart SDK** | 3.5.0 | Included with Flutter |
| **Xcode** (macOS) | 15.0 | Mac App Store (for iOS development) |
| **Android Studio** | 2023.1 | [developer.android.com/studio](https://developer.android.com/studio) |
| **Git** | 2.30+ | [git-scm.com](https://git-scm.com/) |
| **VS Code** (recommended) | 1.85+ | [code.visualstudio.com](https://code.visualstudio.com/) |

### VS Code Extensions (Recommended)

- **Flutter** (Dart-Code.flutter)
- **Dart** (Dart-Code.dart-code)
- **Error Lens** (usernamehw.errorlens)
- **GitLens** (eamodio.gitlens)
- **Prettier** (esbenp.prettier-vscode)

---

## Initial Setup

### 1. Clone Repository

```bash
# Clone the repository
git clone https://github.com/your-org/ai_flutter.git
cd ai_flutter

# Checkout feature branch
git checkout 001-ecommerce-marketplace
```

### 2. Verify Flutter Installation

```bash
# Check Flutter installation
flutter doctor -v

# Expected output:
# [✓] Flutter (Channel stable, 3.5.4, on macOS ...)
# [✓] Android toolchain - develop for Android devices
# [✓] Xcode - develop for iOS and macOS
# [✓] Chrome - develop for the web
# [✓] Android Studio
# [✓] VS Code
# [✓] Connected device
```

**Troubleshooting**:
- If Android toolchain issues: Run `flutter doctor --android-licenses`
- If Xcode issues: Run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
- If CocoaPods issues (iOS): `sudo gem install cocoapods`

### 3. Install Dependencies

```bash
# Install Flutter packages
flutter pub get

# Verify no issues
flutter pub outdated
```

**Expected packages** (see `pubspec.yaml`):
- `flutter_riverpod: ^2.4.0`
- `dio: ^5.4.0`
- `go_router: ^12.1.3`
- `cached_network_image: ^3.3.0`
- `sqflite: ^2.3.0`
- `firebase_messaging: ^14.7.6`
- And more (see `specs/001-ecommerce-marketplace/research.md`)

### 4. Configure Backend API

Create environment configuration file:

```bash
# Create config file
touch lib/app/config.dart
```

Add backend URL configuration:

```dart
// lib/app/config.dart
class AppConfig {
  static const String apiBaseUrl = _getApiBaseUrl();
  
  static String _getApiBaseUrl() {
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    switch (environment) {
      case 'production':
        return 'https://api.marketplace.example.com/api/v1';
      case 'staging':
        return 'https://api-staging.marketplace.example.com/api/v1';
      case 'development':
      default:
        return 'http://localhost:3000/api/v1';
    }
  }
  
  static const int apiTimeout = 30; // seconds
  static const bool enableLogging = true;
}
```

**Backend Setup** (separate repository):
```bash
# Assuming backend repo exists
cd ../marketplace-backend
npm install
npm run dev  # Starts backend on http://localhost:3000
```

---

## Running the App

### Run on iOS Simulator

```bash
# List available iOS simulators
flutter devices

# Open iOS simulator
open -a Simulator

# Run app
flutter run -d "iPhone 15 Pro"

# Or with hot reload
flutter run --hot
```

### Run on Android Emulator

```bash
# List available Android emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator_id>

# Run app
flutter run -d emulator-5554
```

### Run on Physical Device

**iOS**:
1. Connect iPhone via USB
2. Open Xcode → Settings → Accounts → Add Apple ID
3. Select `ios/Runner.xcworkspace` → Signing & Capabilities → Select Team
4. Run: `flutter run -d <device-name>`

**Android**:
1. Enable Developer Options on device (tap Build Number 7 times)
2. Enable USB Debugging
3. Connect device via USB
4. Run: `flutter run -d <device-name>`

---

## Project Structure Overview

```
lib/
├── main.dart                    # App entry point
├── app/
│   ├── routes.dart              # GoRouter configuration
│   ├── theme.dart               # Material Design 3 theme
│   └── config.dart              # Environment config
├── core/
│   ├── api/                     # Dio HTTP client
│   ├── storage/                 # SharedPreferences, SecureStorage, SQLite
│   ├── websocket/               # WebSocket client for chat
│   ├── models/                  # Entity models (User, Product, Order, etc.)
│   └── widgets/                 # Shared UI components
└── features/
    ├── home/                    # US-001: Guest Product Discovery
    ├── auth/                    # US-002: Authentication
    ├── cart/                    # US-003: Shopping Cart & Checkout
    ├── orders/                  # US-004: Order Management
    ├── reviews/                 # US-005: Reviews & Ratings
    ├── seller/                  # US-006 to US-010: Seller features
    ├── chat/                    # US-011: Messaging
    ├── admin/                   # US-014, US-015: Admin
    └── ...                      # Other features

test/
├── widget/                      # Widget tests
├── integration/                 # Integration tests
└── unit/                        # Unit tests
```

---

## Development Workflow

### 1. Feature Development (TDD Approach)

**Red-Green-Refactor Cycle**:

```bash
# Step 1: Write failing test
# Create test file: test/unit/features/cart/domain/use_cases/add_to_cart_test.dart

flutter test test/unit/features/cart/domain/use_cases/add_to_cart_test.dart
# ❌ Test fails (expected)

# Step 2: Implement minimal code
# Create: lib/features/cart/domain/use_cases/add_to_cart.dart

flutter test test/unit/features/cart/domain/use_cases/add_to_cart_test.dart
# ✅ Test passes

# Step 3: Refactor
# Clean up code while keeping tests green
```

### 2. Running Tests

**Unit Tests**:
```bash
# Run all unit tests
flutter test test/unit

# Run specific test file
flutter test test/unit/features/cart/domain/use_cases/add_to_cart_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Widget Tests**:
```bash
# Run all widget tests
flutter test test/widget

# Run specific widget test
flutter test test/widget/features/home/home_screen_test.dart
```

**Integration Tests**:
```bash
# Start app in integration test mode
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/guest_shopping_flow_test.dart
```

### 3. Code Generation (Mocks, Models)

```bash
# Generate mock classes for testing
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on changes)
flutter pub run build_runner watch
```

### 4. Linting & Formatting

```bash
# Run linter
flutter analyze

# Format code
dart format lib/ test/

# Fix auto-fixable issues
dart fix --apply
```

---

## Firebase Configuration (Push Notifications)

### iOS Setup

1. **Create Firebase Project**: [console.firebase.google.com](https://console.firebase.google.com)
2. **Add iOS App**:
   - Bundle ID: `com.example.marketplace` (match `ios/Runner/Info.plist`)
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/`
3. **APNs Certificate**:
   - Xcode → Signing & Capabilities → Add `Push Notifications` capability
   - Generate APNs key in Apple Developer Console
   - Upload to Firebase Console → Project Settings → Cloud Messaging

### Android Setup

1. **Add Android App** in Firebase Console:
   - Package name: `com.example.marketplace` (match `android/app/build.gradle`)
   - Download `google-services.json`
   - Place in `android/app/`
2. **No additional setup required** (FCM works automatically on Android)

### Initialize Firebase in App

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase automatically
flutterfire configure
```

---

## Common Tasks

### Add New Package

```bash
# Add package to pubspec.yaml
flutter pub add package_name

# For dev dependencies
flutter pub add --dev package_name

# Example: Add image compression
flutter pub add flutter_image_compress
```

### Create New Feature Module

```bash
# Example: Create notifications feature
mkdir -p lib/features/notifications/{presentation,domain,data}
mkdir -p lib/features/notifications/presentation/widgets
mkdir -p lib/features/notifications/domain/{repositories,use_cases}
mkdir -p lib/features/notifications/data/{data_sources,repositories}

# Create corresponding test structure
mkdir -p test/unit/features/notifications
mkdir -p test/widget/features/notifications
```

### Debug API Calls

Enable Dio logging in development:

```dart
// lib/core/api/api_client.dart
if (AppConfig.enableLogging) {
  dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    error: true,
  ));
}
```

---

## Platform-Specific Configuration

### iOS Permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Upload product photos and reviews</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Select photos for products and reviews</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Show nearby shops and estimate shipping</string>
```

### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### iOS Minimum Version

Ensure `ios/Podfile` has:

```ruby
platform :ios, '13.0'
```

### Android Minimum SDK

Ensure `android/app/build.gradle` has:

```gradle
minSdkVersion 24
targetSdkVersion 34
```

---

## Troubleshooting

### Issue: "CocoaPods not installed"

```bash
sudo gem install cocoapods
cd ios && pod install
```

### Issue: "Android license not accepted"

```bash
flutter doctor --android-licenses
# Accept all licenses
```

### Issue: "Dio timeout error"

- Check backend is running: `curl http://localhost:3000/api/v1/health`
- Increase timeout in `lib/app/config.dart`
- Check iOS Simulator network: Settings → WiFi → Ensure connected

### Issue: "SQLite database locked"

```bash
# Clear app data
flutter clean
flutter pub get

# iOS: Reset simulator
# Android: Uninstall app from emulator
```

### Issue: "Hot reload not working"

```bash
# Full restart
flutter run --hot

# If still broken, restart IDE and simulator
```

---

## Performance Profiling

### Measure Frame Rendering

```bash
# Run in profile mode (not debug)
flutter run --profile

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Performance tab → Record → Analyze frame times
```

### Check App Size

```bash
# Analyze bundle size
flutter build apk --analyze-size
flutter build ios --analyze-size
```

### Memory Profiling

```bash
# Run with memory profiler
flutter run --profile
# DevTools → Memory tab → Monitor allocations
```

---

## Next Steps

1. ✅ **Setup Complete**: Environment configured
2. **Read Specs**: Review `specs/001-ecommerce-marketplace/spec.md` for user stories
3. **Architecture**: Study `specs/001-ecommerce-marketplace/research.md` for technology decisions
4. **Data Models**: Review `specs/001-ecommerce-marketplace/data-model.md` for entities
5. **API Contracts**: Check `specs/001-ecommerce-marketplace/contracts/` for REST endpoints
6. **Start Development**: Begin with P1 user stories (Guest Discovery, Auth, Cart/Checkout)

### Recommended First Tasks

1. **Setup Core Infrastructure**:
   - Create Dio API client (`lib/core/api/api_client.dart`)
   - Setup Riverpod providers (`lib/app/providers.dart`)
   - Configure GoRouter (`lib/app/routes.dart`)
   - Create base models (`lib/core/models/`)

2. **Implement US-001 (Guest Product Discovery)**:
   - TDD: Write product repository tests
   - Implement product list screen
   - Add category filtering
   - Product detail view

3. **Implement US-002 (Authentication)**:
   - TDD: Write auth repository tests
   - Login/Register screens
   - OTP verification flow
   - Secure token storage

---

## Resources

- **Flutter Docs**: [flutter.dev/docs](https://flutter.dev/docs)
- **Riverpod Guide**: [riverpod.dev](https://riverpod.dev)
- **Dio Documentation**: [pub.dev/packages/dio](https://pub.dev/packages/dio)
- **Material Design 3**: [m3.material.io](https://m3.material.io/)
- **Project Spec**: `specs/001-ecommerce-marketplace/spec.md`
- **API Contracts**: `specs/001-ecommerce-marketplace/contracts/`

---

## Getting Help

- **Team Chat**: [Link to Slack/Discord channel]
- **Backend Docs**: [Link to backend API documentation]
- **Design Mockups**: [Link to Figma files]
- **Issue Tracker**: [Link to GitHub Issues]

---

**Happy Coding! 🚀**
