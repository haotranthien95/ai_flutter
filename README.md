# AI Flutter E-Commerce Marketplace 🛍️

A multi-vendor e-commerce marketplace mobile application built with Flutter, featuring guest browsing, buyer authentication, and shopping cart functionality.

## 📱 Features

### Phase 1-2: Foundation ✅
- Clean Architecture with Riverpod state management
- Dio HTTP client with interceptors (auth, logging, error handling)
- Local storage (SQLite, SharedPreferences, Secure Storage)
- Vietnamese localization
- Comprehensive error handling

### Phase 3: Guest Product Discovery ✅ (US-001)
- **Browse Products**: Grid view with infinite scroll, Vietnamese currency formatting
- **Search & Filter**: Text search with category, price range, and rating filters
- **Product Detail**: Image carousel, variant selection, reviews display
- **Responsive UI**: Optimized for various screen sizes

### Phase 4: Buyer Account & Authentication ✅ (US-002)
- **Registration**: Phone number + OTP verification flow
- **Login/Logout**: JWT token-based authentication with secure storage
- **Password Management**: Forgot password with OTP reset
- **Profile Management**: Update name, email, avatar
- **Address Book**: Add, edit, delete, set default shipping addresses

### Phase 5: Shopping Cart & Checkout ✅ (US-003)
- **Cart Management**: Add/update/remove items, grouped by shop
- **Offline-First**: Local SQLite caching for cart persistence
- **Checkout Flow**: Address selection, order summary, VND pricing
- **Order Confirmation**: Order ID display with navigation options
- **Voucher Support**: Platform and shop-level discount codes

### Phase 6: Polish & Testing 🚧 (In Progress)
- 159 passing unit tests (>80% coverage on business logic)
- Code formatting and linting (zero errors/warnings)
- Integration tests for auth and shopping flows

## 🏗️ Architecture

```
lib/
├── app/                    # App-level configuration
│   ├── config.dart        # Environment config (API URLs, timeouts)
│   ├── providers.dart     # Dependency injection
│   ├── routes.dart        # GoRouter navigation
│   └── theme.dart         # Material theme
├── core/                   # Shared infrastructure
│   ├── api/               # Dio client, interceptors
│   ├── models/            # Entity models (User, Product, Order)
│   ├── storage/           # Local/secure storage wrappers
│   ├── utils/             # Formatters, validators
│   └── widgets/           # Reusable UI components
└── features/              # Feature modules (Clean Architecture)
    ├── home/              # Product browsing
    ├── search/            # Search & filters
    ├── product_detail/    # Product details
    ├── auth/              # Authentication
    ├── profile/           # User profile
    └── cart/              # Shopping cart & checkout
        ├── data/          # Repositories, data sources
        ├── domain/        # Use cases, entities
        └── presentation/  # Providers, screens, widgets
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.5.4+
- Dart 3.5.4+
- iOS: Xcode 15+ (for iOS development)
- Android: Android Studio with SDK 24+ (Android 7.0+)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ai_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment** (Optional)
   - Edit `lib/app/config.dart` to set API URLs
   - Default: Mock API endpoints

4. **Run the app**
   ```bash
   # iOS simulator
   flutter run -d "iPhone 15 Pro"
   
   # Android emulator
   flutter run -d emulator-5554
   ```

### Firebase Setup (Optional)
For push notifications, follow instructions in [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

## 🧪 Testing

```bash
# Run all unit tests
flutter test test/unit/

# Run integration tests
flutter test test/integration_test/

# Generate coverage report
flutter test --coverage
```

**Current Coverage**: 159 passing tests across auth, profile, cart, and product features.

## 📦 Dependencies

Key packages:
- **State Management**: `flutter_riverpod: ^2.6.1`
- **HTTP Client**: `dio: ^5.4.0`
- **Navigation**: `go_router: ^12.1.3`
- **Images**: `cached_network_image: ^3.3.0`
- **Storage**: `sqflite: ^2.3.0`, `flutter_secure_storage: ^9.0.0`
- **Testing**: `mockito: ^5.4.4`, `build_runner: ^2.4.7`

See [pubspec.yaml](pubspec.yaml) for complete list.

## 📚 Documentation

- **Specification**: [specs/001-ecommerce-marketplace/spec.md](specs/001-ecommerce-marketplace/spec.md)
- **Data Model**: [specs/001-ecommerce-marketplace/data-model.md](specs/001-ecommerce-marketplace/data-model.md)
- **API Contracts**: [specs/001-ecommerce-marketplace/contracts/](specs/001-ecommerce-marketplace/contracts/)
- **Task List**: [specs/001-ecommerce-marketplace/tasks.md](specs/001-ecommerce-marketplace/tasks.md)

## 🎯 MVP Scope

This MVP focuses on **buyer experience** (guest browsing + authenticated checkout):

**✅ Implemented (P1)**:
- US-001: Guest Product Discovery
- US-002: Buyer Account & Authentication
- US-003: Shopping Cart & Simple Checkout

**🔮 Future Phases (P2-P4)**:
- Seller dashboard & product management
- Real-time chat & notifications
- Reviews & ratings management
- Order tracking & logistics
- Admin panel

## 🛠️ Development

### Code Quality
```bash
# Run linter
flutter analyze

# Format code
dart format lib/ test/

# Fix common issues
dart fix --apply
```

### Branch Strategy
- `main`: Production-ready code
- `001-ecommerce-marketplace`: MVP development branch (current)

## 📱 Screenshots

*Coming soon: Home, Product Detail, Cart, Checkout screens*

## 🤝 Contributing

This is a demonstration project. For production use, ensure:
1. Backend API implementation (currently mock endpoints)
2. Firebase configuration for push notifications
3. Payment gateway integration
4. Security audit (JWT token handling, API security)

## 📄 License

[Add your license here]

## 👥 Team

Built with ❤️ using Flutter and Clean Architecture principles.

---

**Status**: MVP Phase 6 (Polish) in progress | **Branch**: `001-ecommerce-marketplace` | **Tests**: 159 passing
