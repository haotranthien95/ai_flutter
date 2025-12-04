# Phase 0: Technology Research & Decisions

**Feature**: Multi-Vendor E-Commerce Marketplace  
**Branch**: `001-ecommerce-marketplace`  
**Date**: 2025-12-03  
**Purpose**: Evaluate and document technology choices, architecture patterns, and package selections for the MVP implementation.

---

## 1. State Management Decision

**Requirement**: Manage shared state (cart, authentication, product catalog) across 50-70 screens with clean, testable code. Local UI state (form fields, animations) should remain simple.

### Options Evaluated

#### Option A: Provider (`provider` ^6.1.1)
**Pros**:
- Official Flutter recommendation, minimal boilerplate
- Excellent documentation and community support
- ChangeNotifier pattern is simple to understand and implement
- Built-in dependency injection via Provider tree
- Low learning curve for team members
- Sufficient for MVP complexity (cart, auth, product state)

**Cons**:
- Manual state mutation (requires notifyListeners() calls)
- Less structured for complex async operations
- No built-in immutability enforcement
- Potential for rebuild optimization issues at scale

**Example Use Case**:
```dart
class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  
  void addItem(Product product, int quantity) {
    // Mutation logic
    _items.add(CartItem(product: product, quantity: quantity));
    notifyListeners(); // Manual trigger
  }
}
```

#### Option B: Riverpod (`riverpod` ^2.4.0 or `flutter_riverpod` ^2.4.0)
**Pros**:
- Compile-time safety with no BuildContext dependency
- Built-in async state handling with AsyncValue
- Immutable state by default (encourages best practices)
- Better testing: providers can be overridden easily in tests
- More scalable for complex state interactions
- Automatic dependency tracking and disposal

**Cons**:
- Steeper learning curve (concepts: Provider vs StateProvider vs FutureProvider)
- More verbose setup for simple cases
- Smaller community compared to Provider (though growing fast)
- Team may need ramp-up time

**Example Use Case**:
```dart
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState(items: []));
  
  void addItem(Product product, int quantity) {
    state = state.copyWith(
      items: [...state.items, CartItem(product: product, quantity: quantity)]
    );
  }
}
```

### Decision: **Riverpod** ✅

**Rationale**:
- **Constitution Compliance**: Constitution Principle #2 (State Management Clarity) emphasizes clear separation and testability. Riverpod's compile-time safety and immutability align better with long-term maintainability.
- **Async Operations**: E-commerce involves heavy async work (API calls, cart sync, real-time chat). Riverpod's `AsyncValue` and `FutureProvider` simplify error handling and loading states.
- **Testing**: MVP requires >80% test coverage. Riverpod's provider overrides make mocking dependencies trivial.
- **Scalability**: With 15 user stories (50-70 screens), Riverpod's structured approach prevents technical debt as features grow.
- **Team Investment**: Learning curve is justified for a multi-phase project (P1-P5 stories). Riverpod patterns will scale better than Provider refactoring.

**Package Choice**: `flutter_riverpod` ^2.4.0 (for ConsumerWidget and ConsumerStatefulWidget)

---

## 2. HTTP Client Selection

**Requirement**: REST API communication with interceptors for authentication, error handling, retry logic, and request/response logging.

### Options Evaluated

#### Option A: `http` package (official)
**Pros**: Lightweight, official Dart package, simple API
**Cons**: Minimal features (no interceptors, manual retry logic, basic error handling)

#### Option B: `dio` ^5.4.0
**Pros**:
- Interceptor support for token injection, logging, error handling
- Built-in retry logic with `dio_retry_interceptor`
- FormData support for multipart/form-data (image uploads)
- Request cancellation (useful for search autocomplete)
- Better error responses with status codes and messages

**Cons**: Slightly heavier than `http`, but negligible for this use case

### Decision: **dio** ✅

**Rationale**: Interceptors are essential for JWT token refresh, centralized error handling, and logging. Image upload (seller product images) requires FormData. Request cancellation improves UX for real-time search.

**Implementation Plan**:
```dart
// lib/core/api/api_client.dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 3),
  ));
  
  dio.interceptors.addAll([
    AuthInterceptor(ref), // Inject tokens
    LoggingInterceptor(), // Log requests/responses
    ErrorInterceptor(),   // Centralized error handling
  ]);
  
  return dio;
});
```

---

## 3. Image Handling Strategy

**Requirement**: Display product images with caching, support user uploads (product photos, review images), and optimize for 4G networks.

### Options Evaluated

#### Option A: `cached_network_image` ^3.3.0
**Pros**:
- Automatic caching with LRU policy
- Placeholder and error widgets
- Fade-in animations
- Widely used, battle-tested

**Cons**: Limited control over cache expiry (needs manual cache manager)

#### Option B: `flutter_cache_manager` + `image` package
**Pros**: More granular control over caching
**Cons**: More boilerplate, less integrated UI experience

### Decision: **cached_network_image** ^3.3.0 ✅

**Rationale**: 
- Simplicity for MVP (<2s image load requirement)
- Built-in placeholders improve perceived performance
- LRU cache is sufficient for marketplace browsing patterns
- Can extend with `flutter_cache_manager` in later phases if needed

**Image Upload**: Use `image_picker` ^1.0.5 for camera/gallery access + `image` package for compression before upload (reduce bandwidth on 4G).

**Implementation Plan**:
```dart
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => Shimmer.fromColors(...),
  errorWidget: (context, url, error) => Icon(Icons.error),
  cacheManager: CacheManager(Config(
    'product_images',
    stalePeriod: Duration(days: 7),
    maxNrOfCacheObjects: 200,
  )),
)
```

---

## 4. Local Storage & Offline Support

**Requirement**: Persist cart items, user preferences, and cached data for offline browsing.

### Options Evaluated

| Package | Use Case | Pros | Cons |
|---------|----------|------|------|
| `shared_preferences` ^2.2.2 | Key-value storage (settings, tokens) | Simple API, fast | No encryption, small data only |
| `flutter_secure_storage` ^9.0.0 | Secure storage (JWT tokens) | Encrypted, platform-native keychains | Slower than SharedPreferences |
| `sqflite` ^2.3.0 | Cart persistence, offline product cache | SQL queries, relational data | More setup, overkill for simple data |

### Decision: **Hybrid Approach** ✅

- **shared_preferences**: User settings (language, theme), non-sensitive flags
- **flutter_secure_storage**: JWT access/refresh tokens (required for security)
- **sqflite**: Cart items (support offline cart editing), favorite products

**Rationale**: 
- Cart must persist across app restarts (users expect cart continuity)
- Tokens must be encrypted (security requirement)
- Simple settings don't need database overhead

---

## 5. Navigation & Routing

**Requirement**: Deep linking support (product URLs, order tracking links), clean route management for 50-70 screens.

### Options Evaluated

#### Option A: `Navigator 2.0` (built-in)
**Pros**: Official API, no dependencies
**Cons**: Verbose, steep learning curve, manual route management

#### Option B: `go_router` ^12.1.3
**Pros**:
- Declarative routing with type-safe routes
- Built-in deep linking support
- Automatic browser URL sync (for web phase)
- Route guards for authentication (redirect to login if not authenticated)
- Simple nested navigation (tabs, drawers)

**Cons**: External dependency

### Decision: **go_router** ✅

**Rationale**: 
- Deep linking is required for marketing campaigns (share product links)
- Type-safe routes reduce runtime errors
- Authentication guards prevent manual checks in every screen
- Web-ready for future phase

**Implementation Plan**:
```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.location.startsWith('/auth');
      
      if (!isLoggedIn && !isAuthRoute && state.location != '/') {
        return '/auth/login';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => HomeScreen()),
      GoRoute(path: '/product/:id', builder: (context, state) {
        final productId = state.params['id']!;
        return ProductDetailScreen(productId: productId);
      }),
      // ... more routes
    ],
  );
});
```

---

## 6. WebSocket Client for Chat

**Requirement**: Real-time buyer-seller messaging with connection resilience (reconnect on network drop).

### Options Evaluated

#### Option A: `web_socket_channel` ^2.4.0
**Pros**: Official Dart package, simple API
**Cons**: Manual reconnection logic, no message queue for offline messages

#### Option B: `socket_io_client` ^2.0.3
**Pros**: Auto-reconnect, room support, fallback to polling
**Cons**: Requires Socket.IO server (backend dependency), heavier library

### Decision: **web_socket_channel** ^2.4.0 ✅

**Rationale**: 
- Spec clarification confirmed WebSocket backend (not Socket.IO)
- Lighter weight for MVP
- Manual reconnection logic is acceptable for P3 feature (chat is not P1)
- Can wrap with custom reconnection logic:

```dart
class ResilientWebSocket {
  IOWebSocketChannel? _channel;
  Timer? _reconnectTimer;
  
  void connect(String url) {
    _channel = IOWebSocketChannel.connect(url);
    _channel!.stream.listen(
      (message) => _handleMessage(message),
      onError: (error) => _reconnect(url),
      onDone: () => _reconnect(url),
    );
  }
  
  void _reconnect(String url) {
    _reconnectTimer = Timer(Duration(seconds: 5), () => connect(url));
  }
}
```

---

## 7. Push Notifications

**Requirement**: Notify users about order status, messages, promotions (Firebase Cloud Messaging for iOS/Android).

### Decision: **firebase_messaging** ^14.7.6 ✅

**Rationale**: 
- Industry standard for Flutter push notifications
- Cross-platform (iOS, Android, Web)
- Background/foreground message handling
- Integration with Firebase Console for targeted campaigns

**Setup Requirements**:
- Firebase project configuration (google-services.json, GoogleService-Info.plist)
- APNs certificate for iOS
- Handle notification permissions (iOS requires user prompt)

---

## 8. Form Handling & Validation

**Requirement**: Multi-step forms (registration, checkout, product creation) with validation, error messages, and complex fields (address, phone).

### Options Evaluated

#### Option A: Manual `Form` + `TextFormField` widgets
**Pros**: Built-in, no dependencies
**Cons**: Repetitive validation logic, manual controller management

#### Option B: `flutter_form_builder` ^9.1.1
**Pros**: 
- Pre-built field types (dropdown, date picker, checkbox)
- Centralized validation (e.g., email, phone number)
- Dynamic form generation
- Conditional field visibility

**Cons**: Learning curve for custom field types

### Decision: **flutter_form_builder** ✅

**Rationale**: 
- Complex forms: Seller product creation (variants, images, pricing), checkout (address, voucher selection)
- Reduces boilerplate and ensures consistent UX
- Built-in validators (required, email, phone, min/max length)

---

## 9. Architecture Pattern

**Requirement**: Clear separation of concerns for business logic, data sources, and UI. Support >80% test coverage.

### Decision: **Clean Architecture with Feature-Based Modules** ✅

**Layers**:
1. **Presentation Layer** (`presentation/`):
   - Screens (StatelessWidget/ConsumerWidget)
   - Widgets (UI components)
   - State management (Riverpod providers/notifiers)

2. **Domain Layer** (`domain/`):
   - Use Cases (business logic, e.g., `PlaceOrderUseCase`)
   - Repository Interfaces (contracts, e.g., `ProductRepository`)
   - Entities (pure Dart models with business rules)

3. **Data Layer** (`data/`):
   - Repository Implementations (e.g., `ProductRepositoryImpl`)
   - Data Sources (e.g., `ProductRemoteDataSource` for API, `CartLocalDataSource` for SQLite)
   - DTOs (Data Transfer Objects for JSON serialization)

**Rationale**:
- **Testability**: Each layer can be tested independently (unit tests for use cases, widget tests for UI, integration tests for flows)
- **Constitution Compliance**: Supports TDD (Principle #3) and State Management Clarity (Principle #2)
- **Scalability**: 15 user stories map cleanly to feature modules (e.g., `features/cart/`, `features/auth/`)

**Example Structure**:
```
lib/features/cart/
├── presentation/
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── widgets/
│   │   └── cart_item_tile.dart
│   └── cart_provider.dart (Riverpod StateNotifier)
├── domain/
│   ├── repositories/
│   │   └── cart_repository.dart (abstract interface)
│   └── use_cases/
│       ├── add_to_cart.dart
│       ├── update_quantity.dart
│       └── checkout.dart
└── data/
    ├── data_sources/
    │   ├── cart_local_data_source.dart (SQLite)
    │   └── cart_remote_data_source.dart (Dio API calls)
    ├── repositories/
    │   └── cart_repository_impl.dart (implements domain interface)
    └── models/
        └── cart_dto.dart (JSON serialization)
```

---

## 10. Testing Strategy

**Requirement**: >80% coverage on business logic, TDD workflow (Red-Green-Refactor), widget/integration/unit tests.

### Tools & Packages

| Test Type | Package | Purpose | Example |
|-----------|---------|---------|---------|
| **Widget Tests** | `flutter_test` (SDK) | Test UI components in isolation | `testWidgets('CartItemTile displays product name', ...)` |
| **Integration Tests** | `integration_test` | End-to-end user journeys | `testWidgets('Complete checkout flow', ...)` |
| **Unit Tests** | `mockito` ^5.4.4 | Test business logic (use cases, repositories) | `test('AddToCartUseCase adds item to cart', ...)` |
| **Mocking** | `mockito` + build_runner | Generate mock classes for repositories, API clients | `@GenerateMocks([ProductRepository])` |
| **HTTP Mocking** | `http_mock_adapter` | Mock Dio responses in tests | `dioAdapter.onGet('/products').reply(200, mockData)` |

### Coverage Setup

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.7
  http_mock_adapter: ^0.6.0
```

```bash
# Generate mocks
flutter pub run build_runner build

# Run tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### TDD Workflow Example (Cart Feature)

1. **Red**: Write failing test
```dart
test('addItem adds product to cart', () {
  final repository = MockCartRepository();
  final useCase = AddToCartUseCase(repository);
  
  when(repository.addItem(any)).thenAnswer((_) async => Right(null));
  
  final result = await useCase.execute(mockProduct, quantity: 2);
  
  expect(result.isRight(), true);
  verify(repository.addItem(any)).called(1);
});
```

2. **Green**: Implement minimal code to pass
```dart
class AddToCartUseCase {
  final CartRepository repository;
  AddToCartUseCase(this.repository);
  
  Future<Either<Failure, void>> execute(Product product, {required int quantity}) {
    return repository.addItem(CartItem(product: product, quantity: quantity));
  }
}
```

3. **Refactor**: Clean up code while keeping tests green

---

## 11. Performance Optimization Patterns

**Requirement**: 60fps scrolling, <3s app launch, <2s image loads.

### Techniques

#### 1. Lazy Loading & Pagination
```dart
ListView.builder(
  itemCount: products.length + 1, // +1 for loading indicator
  itemBuilder: (context, index) {
    if (index == products.length) {
      _loadMoreProducts(); // Fetch next page
      return CircularProgressIndicator();
    }
    return ProductCard(product: products[index]);
  },
)
```

#### 2. Const Constructors (reduce rebuilds)
```dart
const ProductCard({Key? key, required this.product}) : super(key: key);
```

#### 3. RepaintBoundary (isolate expensive widgets)
```dart
RepaintBoundary(
  child: ComplexChart(data: chartData),
)
```

#### 4. Image Compression Before Upload
```dart
final compressedImage = await FlutterImageCompress.compressWithFile(
  imageFile.absolute.path,
  quality: 85,
  minWidth: 1024,
  minHeight: 1024,
);
```

#### 5. Debouncing for Search Autocomplete
```dart
Timer? _debounce;

void onSearchChanged(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(Duration(milliseconds: 300), () {
    _searchProducts(query);
  });
}
```

---

## 12. Localization (Vietnamese)

**Requirement**: All text in Vietnamese, currency format (VND), date/time formats.

### Approach

#### Option A: Manual String Constants
**Pros**: Simple for single language
**Cons**: Hard to extend to multiple languages later

#### Option B: `flutter_localizations` + `intl` package
**Pros**: Industry standard, supports pluralization, date/time formatting, currency
**Cons**: Initial setup overhead

### Decision: **intl + flutter_localizations** ✅

**Rationale**: Even for Vietnamese-only MVP, `intl` provides currency formatting (VND) and date formatting. Future-proofs for English localization.

**Setup**:
```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.1

flutter:
  generate: true
```

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_vi.arb
output-localization-file: app_localizations.dart
```

```json
// lib/l10n/app_vi.arb
{
  "@@locale": "vi",
  "homeTitle": "Trang chủ",
  "addToCart": "Thêm vào giỏ",
  "priceFormat": "{price} ₫",
  "@priceFormat": {
    "placeholders": {
      "price": {
        "type": "String"
      }
    }
  }
}
```

**Usage**:
```dart
Text(AppLocalizations.of(context)!.addToCart)
Text(AppLocalizations.of(context)!.priceFormat(NumberFormat('#,###').format(product.price)))
```

---

## 13. Error Handling & Logging

**Requirement**: Centralized error handling for API errors, graceful degradation for network failures.

### Strategy

#### 1. Custom Exception Classes
```dart
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  AppException(this.message, {this.statusCode});
}

class NetworkException extends AppException {
  NetworkException() : super('No internet connection');
}

class ServerException extends AppException {
  ServerException(String message, {int? statusCode}) 
      : super(message, statusCode: statusCode);
}
```

#### 2. Either Monad for Error Handling (functional approach)
```dart
// Using dartz package for Either<Failure, Success>
abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure(String message) : super(message);
}

// Use case returns Either
Future<Either<Failure, List<Product>>> getProducts() async {
  try {
    final products = await remoteDataSource.fetchProducts();
    return Right(products);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException {
    return Left(NetworkFailure());
  }
}
```

#### 3. Logging with `logger` package
```dart
final logger = Logger(
  printer: PrettyPrinter(),
);

logger.d('Debug message');
logger.e('Error occurred', error, stackTrace);
```

---

## Summary of Technology Choices

| Category | Package/Technology | Version | Rationale |
|----------|-------------------|---------|-----------|
| **State Management** | `flutter_riverpod` | ^2.4.0 | Compile-time safety, async handling, testability |
| **HTTP Client** | `dio` | ^5.4.0 | Interceptors, retry logic, FormData support |
| **Image Caching** | `cached_network_image` | ^3.3.0 | Automatic caching, placeholders, simple API |
| **Image Upload** | `image_picker` | ^1.0.5 | Camera/gallery access |
| **Image Compression** | `flutter_image_compress` | ^2.1.0 | Reduce bandwidth on 4G |
| **Local Storage (KV)** | `shared_preferences` | ^2.2.2 | User settings, non-sensitive data |
| **Secure Storage** | `flutter_secure_storage` | ^9.0.0 | JWT tokens (encrypted) |
| **Local Database** | `sqflite` | ^2.3.0 | Cart persistence, offline data |
| **Routing** | `go_router` | ^12.1.3 | Deep linking, type-safe routes, auth guards |
| **WebSocket** | `web_socket_channel` | ^2.4.0 | Real-time chat (official package) |
| **Push Notifications** | `firebase_messaging` | ^14.7.6 | FCM for iOS/Android |
| **Forms** | `flutter_form_builder` | ^9.1.1 | Complex forms, validation |
| **Localization** | `intl` + `flutter_localizations` | ^0.18.1 | Vietnamese text, VND formatting |
| **Testing (Mocking)** | `mockito` | ^5.4.4 | Generate mocks for repositories |
| **Testing (HTTP Mocking)** | `http_mock_adapter` | ^0.6.0 | Mock Dio responses |
| **Logging** | `logger` | ^2.0.2 | Structured logging |
| **Error Handling** | `dartz` | ^0.10.1 | Either monad for functional error handling |

**Architecture**: Clean Architecture with feature-based modules (presentation/domain/data layers)  
**Testing Strategy**: TDD with >80% coverage (widget/integration/unit tests, mockito for mocking)  
**Performance Patterns**: ListView.builder, const constructors, RepaintBoundary, image compression, debouncing

---

## Next Steps

1. ✅ **Phase 0 Complete**: Technology research and decisions documented
2. **Phase 1a**: Define data models (14 entities) in `data-model.md`
3. **Phase 1b**: Create REST API contracts (OpenAPI specs) in `contracts/` directory
4. **Phase 1c**: Write development quickstart guide in `quickstart.md`
5. **Phase 2**: Break down P1 user stories into tasks in `tasks.md` (/speckit.tasks command)
