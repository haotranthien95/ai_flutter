# Tasks: Multi-Vendor E-Commerce Marketplace MVP

**Input**: Design documents from `/specs/001-ecommerce-marketplace/`  
**Prerequisites**: ✅ plan.md, ✅ spec.md, ✅ research.md, ✅ data-model.md, ✅ contracts/  
**Date**: 2025-12-03  
**Branch**: `001-ecommerce-marketplace`

**Scope**: This task list covers **P1 user stories only** (MVP Foundation):
- US-001: Guest Product Discovery
- US-002: Buyer Account & Authentication  
- US-003: Shopping Cart & Simple Checkout

**Tests**: TDD approach - tests written FIRST, must FAIL before implementation. Target >80% coverage.

**Organization**: Tasks grouped by user story for independent implementation and testing.

---

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story tag (US1, US2, US3)
- Paths use Flutter conventions: `lib/`, `test/`

---

## Phase 1: Setup & Project Initialization

**Purpose**: Initialize Flutter project with dependencies and basic structure

- [x] **T001** Create Flutter project structure per `plan.md` (lib/, test/, assets/ directories)
- [x] **T002** Configure `pubspec.yaml` with all dependencies from `research.md`:
  - State management: `flutter_riverpod: ^2.4.0`
  - HTTP: `dio: ^5.4.0`
  - Routing: `go_router: ^12.1.3`
  - Images: `cached_network_image: ^3.3.0`, `image_picker: ^1.0.5`
  - Storage: `shared_preferences: ^2.2.2`, `flutter_secure_storage: ^9.0.0`, `sqflite: ^2.3.0`
  - WebSocket: `web_socket_channel: ^2.4.0`
  - Push: `firebase_messaging: ^14.7.6`
  - Forms: `flutter_form_builder: ^9.1.1`
  - i18n: `intl: ^0.18.1`, `flutter_localizations` (SDK)
  - Testing: `mockito: ^5.4.4`, `build_runner: ^2.4.7`, `http_mock_adapter: ^0.6.0`
- [x] **T003** [P] Configure linting with `analysis_options.yaml` (strict lint rules per constitution)
- [x] **T004** [P] Setup Vietnamese localization files in `lib/l10n/app_vi.arb`
- [x] **T005** [P] Create `lib/app/config.dart` for environment configuration (API URLs, timeouts)
- [x] **T006** [P] Initialize Firebase project and add config files:
  - iOS: `ios/Runner/GoogleService-Info.plist`
  - Android: `android/app/google-services.json`
  - Note: Setup instructions documented in `FIREBASE_SETUP.md` (can be deferred for MVP)
- [x] **T007** Run `flutter pub get` and verify no dependency conflicts

**Checkpoint**: ✅ COMPLETE - Project structure initialized, dependencies installed, no errors on `flutter doctor`

---

## Phase 2: Foundational Infrastructure (CRITICAL - BLOCKS ALL USER STORIES)

**Purpose**: Core infrastructure required before ANY user story implementation

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Core API Client

- [x] **T008** Create Dio HTTP client in `lib/core/api/api_client.dart` with base configuration:
  - Base URL from `config.dart`
  - Connect/receive timeouts
  - JSON serialization
- [x] **T009** Implement auth interceptor in `lib/core/api/interceptors/auth_interceptor.dart`:
  - Inject JWT token from secure storage
  - Handle 401 responses (token refresh)
- [x] **T010** [P] Implement logging interceptor in `lib/core/api/interceptors/logging_interceptor.dart`:
  - Log requests, responses, errors (dev mode only)
- [x] **T011** [P] Implement error interceptor in `lib/core/api/interceptors/error_interceptor.dart`:
  - Map HTTP errors to `AppException` types
  - Centralized error handling
- [x] **T012** Create `lib/core/api/api_error.dart` with exception classes:
  - `NetworkException`, `ServerException`, `UnauthorizedException`, `ValidationException`

### Storage Infrastructure

- [x] **T013** [P] Create `lib/core/storage/local_storage.dart` wrapper for SharedPreferences:
  - Methods: `getString()`, `setString()`, `getBool()`, `setBool()`, `remove()`, `clear()`
- [x] **T014** [P] Create `lib/core/storage/secure_storage.dart` wrapper for FlutterSecureStorage:
  - Methods: `saveToken()`, `getToken()`, `deleteToken()`
  - Store JWT access/refresh tokens
- [x] **T015** [P] Create SQLite database helper in `lib/core/storage/database/database_helper.dart`:
  - Initialize database with version management
  - Tables: `cart_items`, `favorite_products`
- [x] **T016** Create cart local data source in `lib/core/storage/database/cart_local_data_source.dart`:
  - Methods: `insertCartItem()`, `getCartItems()`, `updateQuantity()`, `deleteCartItem()`, `clearCart()`

### Entity Models (Core)

- [x] **T017** [P] Create `lib/core/models/user.dart` with User entity:
  - Fields per `data-model.md`: id, phoneNumber, fullName, avatarUrl, role, etc.
  - `fromJson()`, `toJson()`, `copyWith()` methods
- [x] **T018** [P] Create `lib/core/models/address.dart` with Address entity
- [x] **T019** [P] Create `lib/core/models/product.dart` with Product entity
- [x] **T020** [P] Create `lib/core/models/product_variant.dart` with ProductVariant entity
- [x] **T021** [P] Create `lib/core/models/category.dart` with Category entity
- [x] **T022** [P] Create `lib/core/models/cart_item.dart` with CartItem entity
- [x] **T023** [P] Create `lib/core/models/order.dart` with Order entity
- [x] **T024** [P] Create `lib/core/models/order_item.dart` with OrderItem entity
- [x] **T025** [P] Create `lib/core/models/shop.dart` with Shop entity
- [x] **T026** [P] Create `lib/core/models/review.dart` with Review entity
- [x] **T027** [P] Create `lib/core/models/voucher.dart` with Voucher entity

### Shared Widgets

- [x] **T028** [P] Create `lib/core/widgets/loading_indicator.dart` (CircularProgressIndicator wrapper)
- [x] **T029** [P] Create `lib/core/widgets/error_view.dart` (error display with retry button)
- [x] **T030** [P] Create `lib/core/widgets/empty_state.dart` (empty list placeholder)
- [x] **T031** [P] Create `lib/core/widgets/custom_button.dart` (styled primary/secondary buttons)
- [x] **T032** [P] Create `lib/core/widgets/product_card.dart` (reusable product tile for lists)

### Utilities

- [x] **T033** [P] Create `lib/core/utils/formatters.dart`:
  - `formatVND()` - currency formatting (e.g., "299,000 ₫")
  - `formatDate()` - Vietnamese date format
- [x] **T034** [P] Create `lib/core/utils/validators.dart`:
  - `isValidVietnamesePhone()`, `isValidEmail()`, `isValidPrice()`, `isValidProductTitle()`
- [x] **T035** [P] Create `lib/core/utils/image_helper.dart`:
  - `compressImage()` - reduce image size before upload
  - `pickImageFromGallery()`, `pickImageFromCamera()`

### App Configuration

- [x] **T036** Create Material Design 3 theme in `lib/app/theme.dart`:
  - Color scheme, typography, component themes
  - Light theme (dark theme optional for MVP)
- [x] **T037** Create GoRouter configuration in `lib/app/routes.dart`:
  - Named routes for all screens
  - Deep linking support
  - Auth guard (redirect to login if not authenticated)
- [x] **T038** Create Riverpod providers container in `lib/app/providers.dart`:
  - `dioProvider`, `apiClientProvider`, `localStorageProvider`, `secureStorageProvider`
- [x] **T039** Update `lib/main.dart` with ProviderScope, MaterialApp.router, theme

**Checkpoint**: ✅ COMPLETE - Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Guest Product Discovery (Priority: P1) 🎯 MVP

**Goal**: Guest users can browse products, search, filter, and view product details without authentication

**Independent Test**: Open app as guest → browse categories → search products → view product detail with images/reviews → see seller info

### Tests for US-001 (Write FIRST, must FAIL before implementation)

#### Unit Tests

- [x] **T040** [P] [US1] Unit test for `GetProductsUseCase` in `test/unit/features/home/domain/use_cases/get_products_test.dart`:
  - Test successful product fetch
  - Test error handling (network, server errors)
  - Mock `ProductRepository`
- [x] **T041** [P] [US1] Unit test for `SearchProductsUseCase` in `test/unit/features/home/domain/use_cases/search_products_test.dart`:
  - Test search with keywords
  - Test empty results
  - Test pagination
- [x] **T042** [P] [US1] Unit test for `GetProductDetailUseCase` in `test/unit/features/product_detail/domain/use_cases/get_product_detail_test.dart`:
  - Test successful fetch with variants
  - Test 404 handling
- [x] **T043** [P] [US1] Unit test for `GetCategoriesUseCase` in `test/unit/features/home/domain/use_cases/get_categories_test.dart`
- [x] **T044** [P] [US1] Unit test for `ProductRepositoryImpl` in `test/unit/features/home/data/repositories/product_repository_impl_test.dart`:
  - Mock remote data source
  - Test data transformation

#### Widget Tests

- [ ] **T045** [P] [US1] Widget test for `HomeScreen` in `test/widget/features/home/home_screen_test.dart`:
  - Test loading state renders spinner
  - Test product grid renders cards
  - Test category chips render
  - Test search bar present
- [ ] **T046** [P] [US1] Widget test for `ProductCard` in `test/widget/core/widgets/product_card_test.dart`:
  - Test displays product title, price, image, rating
  - Test tap navigates to product detail
- [ ] **T047** [P] [US1] Widget test for `ProductDetailScreen` in `test/widget/features/product_detail/product_detail_screen_test.dart`:
  - Test image carousel renders
  - Test variant selector appears if variants exist
  - Test reviews section renders
  - Test "Add to Cart" button shows login prompt for guests
- [ ] **T048** [P] [US1] Widget test for `SearchScreen` in `test/widget/features/search/search_screen_test.dart`:
  - Test autocomplete suggestions appear on typing
  - Test filter dialog opens
  - Test sort options work

#### Integration Tests

- [ ] **T049** [US1] Integration test for guest shopping flow in `integration_test/guest_shopping_flow_test.dart`:
  - Launch app → see home screen
  - Tap category → see filtered products
  - Tap product → see detail page
  - Scroll to reviews → see review tiles
  - Tap "Add to Cart" → see login prompt

### Implementation for US-001

#### Data Layer

- [x] **T050** [P] [US1] Create remote data source in `lib/features/home/data/data_sources/product_remote_data_source.dart`:
  - `fetchProducts(limit, cursor, categoryId, search, filters)` → calls GET `/products` API
  - `fetchProductDetail(productId)` → calls GET `/products/{id}` API
  - `fetchCategories()` → calls GET `/categories` API
  - `searchAutocomplete(query)` → calls GET `/products/search/autocomplete` API
  - Handle Dio exceptions
- [x] **T051** [US1] Create product repository implementation in `lib/features/home/data/repositories/product_repository_impl.dart`:
  - Implements `ProductRepository` interface
  - Delegates to `ProductRemoteDataSource`
  - Maps DTOs to domain entities
  - Returns `Either<Failure, List<Product>>`

#### Domain Layer

- [x] **T052** [P] [US1] Create product repository interface in `lib/features/home/domain/repositories/product_repository.dart`:
  - Abstract methods: `getProducts()`, `searchProducts()`, `getCategories()`
- [ ] **T053** [P] [US1] Create `GetProductsUseCase` in `lib/features/home/domain/use_cases/get_products.dart`:
  - Constructor injection of `ProductRepository`
  - `execute(limit, cursor, categoryId, filters, sortBy)` method
  - Business logic: validation, default values
- [ ] **T054** [P] [US1] Create `SearchProductsUseCase` in `lib/features/home/domain/use_cases/search_products.dart`
- [ ] **T055** [P] [US1] Create `GetCategoriesUseCase` in `lib/features/home/domain/use_cases/get_categories.dart`
- [ ] **T056** [P] [US1] Create `GetProductDetailUseCase` in `lib/features/product_detail/domain/use_cases/get_product_detail.dart`
- [ ] **T057** [P] [US1] Create `GetProductReviewsUseCase` in `lib/features/product_detail/domain/use_cases/get_product_reviews.dart`

#### Presentation Layer - Home Feature

- [ ] **T058** [US1] Create `HomeProvider` (Riverpod StateNotifier) in `lib/features/home/presentation/home_provider.dart`:
  - State: `AsyncValue<List<Product>>` (loading, data, error)
  - Methods: `loadProducts()`, `loadMoreProducts()` (pagination), `filterByCategory(categoryId)`, `sortProducts(sortBy)`
  - Depends on `GetProductsUseCase`, `GetCategoriesUseCase`
- [ ] **T059** [US1] Create `HomeScreen` in `lib/features/home/presentation/home_screen.dart`:
  - ConsumerWidget consuming `HomeProvider`
  - AppBar with search icon
  - Horizontal category chip list (scrollable)
  - Product grid (GridView.builder with const ProductCard widgets)
  - Pull-to-refresh
  - Loading indicator on initial load
  - Error view with retry on failure
  - Empty state if no products
- [ ] **T060** [P] [US1] Create category chip widget in `lib/features/home/presentation/widgets/category_chip.dart`:
  - Selected state styling
  - Tap callback
- [ ] **T061** [P] [US1] Create filter bottom sheet in `lib/features/home/presentation/widgets/filter_bottom_sheet.dart`:
  - Price range slider
  - Rating filter (1-5 stars)
  - Condition filter (new/used/refurbished)
  - Apply/Clear buttons

#### Presentation Layer - Search Feature

- [ ] **T062** [US1] Create `SearchProvider` in `lib/features/search/presentation/search_provider.dart`:
  - State: search query, autocomplete suggestions, search results
  - Debounced autocomplete (300ms delay)
  - Methods: `updateQuery()`, `search()`, `applyFilters()`, `applySorting()`
- [ ] **T063** [US1] Create `SearchScreen` in `lib/features/search/presentation/search_screen.dart`:
  - Search bar with autocomplete dropdown
  - Filter/Sort action buttons
  - Product grid with search results
  - Handle empty results with helpful message
- [ ] **T064** [P] [US1] Create sort options dialog in `lib/features/search/presentation/widgets/sort_options_dialog.dart`:
  - Radio buttons: Relevance, Newest, Best-selling, Price (low-high), Price (high-low), Top Rated

#### Presentation Layer - Product Detail Feature

- [ ] **T065** [US1] Create `ProductDetailProvider` in `lib/features/product_detail/presentation/product_detail_provider.dart`:
  - State: `AsyncValue<Product>`, selected variant, reviews
  - Methods: `loadProductDetail(productId)`, `selectVariant(variantId)`, `loadReviews()`
- [ ] **T066** [US1] Create `ProductDetailScreen` in `lib/features/product_detail/presentation/product_detail_screen.dart`:
  - Image carousel (PageView with cached images)
  - Product title, price (variant price if selected)
  - Stock status indicator
  - Variant selector (if product has variants)
  - Description section (expandable)
  - Shop info card (name, rating, follower count) - tap navigates to shop page (placeholder for MVP)
  - Reviews summary (average rating, total count, rating distribution)
  - Review list (first 5 reviews, "See All" button)
  - Floating "Add to Cart" button → shows login dialog if guest
- [ ] **T067** [P] [US1] Create image carousel widget in `lib/features/product_detail/presentation/widgets/image_carousel.dart`:
  - PageView with CachedNetworkImage
  - Dot indicators
  - Zoom on tap (Hero animation)
- [ ] **T068** [P] [US1] Create variant selector widget in `lib/features/product_detail/presentation/widgets/variant_selector.dart`:
  - Dropdown or chip list for each attribute (color, size)
  - Update price and stock on selection
- [ ] **T069** [P] [US1] Create review summary widget in `lib/features/product_detail/presentation/widgets/review_summary.dart`:
  - Average rating (large number + stars)
  - Rating distribution bar chart (5→1 stars with percentage bars)
- [ ] **T070** [P] [US1] Create review tile widget in `lib/features/product_detail/presentation/widgets/review_tile.dart`:
  - Reviewer name, avatar (placeholder if null)
  - Star rating
  - Review text
  - Review images (horizontal scrollable)
  - "Verified Purchase" badge
  - Date

#### Routing Integration

- [ ] **T071** [US1] Add routes to `lib/app/routes.dart`:
  - `/` → HomeScreen
  - `/search` → SearchScreen
  - `/product/:id` → ProductDetailScreen
  - `/category/:id` → CategoryProductsScreen (optional, can reuse HomeScreen with filter)

**Checkpoint**: US-001 complete - Guest can browse, search, view products. Test independently before proceeding.

---

## Phase 4: User Story 2 - Buyer Account & Authentication (Priority: P1) 🎯 MVP

**Goal**: Users can register, verify phone with OTP, login, manage profile and addresses

**Independent Test**: Register new account → verify OTP → login → edit profile → add shipping address → logout → login again

### Tests for US-002 (Write FIRST, must FAIL before implementation)

#### Unit Tests

- [ ] **T072** [P] [US2] Unit test for `RegisterUseCase` in `test/unit/features/auth/domain/use_cases/register_test.dart`:
  - Test successful registration
  - Test validation errors (invalid phone, weak password)
  - Test 409 conflict (phone already exists)
- [ ] **T073** [P] [US2] Unit test for `VerifyOTPUseCase` in `test/unit/features/auth/domain/use_cases/verify_otp_test.dart`:
  - Test successful verification
  - Test invalid/expired OTP
- [ ] **T074** [P] [US2] Unit test for `LoginUseCase` in `test/unit/features/auth/domain/use_cases/login_test.dart`:
  - Test successful login with valid credentials
  - Test 401 unauthorized (wrong password)
- [ ] **T075** [P] [US2] Unit test for `LogoutUseCase` in `test/unit/features/auth/domain/use_cases/logout_test.dart`
- [ ] **T076** [P] [US2] Unit test for `GetUserProfileUseCase` in `test/unit/features/profile/domain/use_cases/get_user_profile_test.dart`
- [ ] **T077** [P] [US2] Unit test for `UpdateProfileUseCase` in `test/unit/features/profile/domain/use_cases/update_profile_test.dart`
- [ ] **T078** [P] [US2] Unit test for `AddAddressUseCase` in `test/unit/features/profile/domain/use_cases/add_address_test.dart`:
  - Test address validation
  - Test setting first address as default
- [ ] **T079** [P] [US2] Unit test for `AuthRepositoryImpl` in `test/unit/features/auth/data/repositories/auth_repository_impl_test.dart`

#### Widget Tests

- [ ] **T080** [P] [US2] Widget test for `LoginScreen` in `test/widget/features/auth/login_screen_test.dart`:
  - Test phone/password fields present
  - Test validation errors display
  - Test "Sign Up" link navigates to register
  - Test "Forgot Password" link
- [ ] **T081** [P] [US2] Widget test for `RegisterScreen` in `test/widget/features/auth/register_screen_test.dart`:
  - Test all form fields render
  - Test password strength indicator
  - Test validation on submit
- [ ] **T082** [P] [US2] Widget test for `OTPVerificationScreen` in `test/widget/features/auth/otp_verification_screen_test.dart`:
  - Test 6-digit input fields
  - Test countdown timer
  - Test resend OTP button
- [ ] **T083** [P] [US2] Widget test for `ProfileScreen` in `test/widget/features/profile/profile_screen_test.dart`:
  - Test user info displays
  - Test "Edit Profile" navigates
  - Test "Manage Addresses" navigates
  - Test "Logout" button
- [ ] **T084** [P] [US2] Widget test for `AddressFormScreen` in `test/widget/features/profile/address_form_screen_test.dart`:
  - Test all address fields render
  - Test validation (required fields)
  - Test default address checkbox

#### Integration Tests

- [ ] **T085** [US2] Integration test for registration flow in `integration_test/registration_flow_test.dart`:
  - Tap "Sign Up" → fill form → submit
  - Enter OTP → verify
  - Complete profile setup
  - See home screen
- [ ] **T086** [US2] Integration test for login/logout flow in `integration_test/login_logout_flow_test.dart`:
  - Enter credentials → login
  - Navigate to profile
  - Tap logout → return to home

### Implementation for US-002

#### Data Layer

- [ ] **T087** [P] [US2] Create auth remote data source in `lib/features/auth/data/data_sources/auth_remote_data_source.dart`:
  - `register(phoneNumber, password, fullName)` → POST `/auth/register`
  - `verifyOTP(phoneNumber, otpCode)` → POST `/auth/verify-otp` → returns tokens
  - `login(phoneNumber, password)` → POST `/auth/login` → returns tokens + user
  - `logout()` → POST `/auth/logout`
  - `refreshToken(refreshToken)` → POST `/auth/refresh`
  - `forgotPassword(phoneNumber)` → POST `/auth/forgot-password`
  - `resetPassword(phoneNumber, otpCode, newPassword)` → POST `/auth/reset-password`
- [ ] **T088** [US2] Create auth repository implementation in `lib/features/auth/data/repositories/auth_repository_impl.dart`:
  - Save tokens to secure storage on login/register
  - Clear tokens on logout
  - Handle token refresh on 401
- [ ] **T089** [P] [US2] Create profile remote data source in `lib/features/profile/data/data_sources/profile_remote_data_source.dart`:
  - `getUserProfile()` → GET `/users/me`
  - `updateProfile(fullName, email, avatarUrl)` → PATCH `/users/me`
  - `getAddresses()` → GET `/users/me/addresses`
  - `addAddress(address)` → POST `/users/me/addresses`
  - `updateAddress(addressId, address)` → PATCH `/users/me/addresses/{id}`
  - `deleteAddress(addressId)` → DELETE `/users/me/addresses/{id}`
  - `setDefaultAddress(addressId)` → PATCH `/users/me/addresses/{id}/default`
- [ ] **T090** [US2] Create profile repository implementation in `lib/features/profile/data/repositories/profile_repository_impl.dart`

#### Domain Layer

- [ ] **T091** [P] [US2] Create auth repository interface in `lib/features/auth/domain/repositories/auth_repository.dart`
- [ ] **T092** [P] [US2] Create `RegisterUseCase` in `lib/features/auth/domain/use_cases/register.dart`:
  - Validate phone format (Vietnamese)
  - Validate password strength (min 8 chars)
  - Call repository
- [ ] **T093** [P] [US2] Create `VerifyOTPUseCase` in `lib/features/auth/domain/use_cases/verify_otp.dart`
- [ ] **T094** [P] [US2] Create `LoginUseCase` in `lib/features/auth/domain/use_cases/login.dart`
- [ ] **T095** [P] [US2] Create `LogoutUseCase` in `lib/features/auth/domain/use_cases/logout.dart`
- [ ] **T096** [P] [US2] Create `ForgotPasswordUseCase` in `lib/features/auth/domain/use_cases/forgot_password.dart`
- [ ] **T097** [P] [US2] Create `ResetPasswordUseCase` in `lib/features/auth/domain/use_cases/reset_password.dart`
- [ ] **T098** [P] [US2] Create profile repository interface in `lib/features/profile/domain/repositories/profile_repository.dart`
- [ ] **T099** [P] [US2] Create `GetUserProfileUseCase` in `lib/features/profile/domain/use_cases/get_user_profile.dart`
- [ ] **T100** [P] [US2] Create `UpdateProfileUseCase` in `lib/features/profile/domain/use_cases/update_profile.dart`
- [ ] **T101** [P] [US2] Create `AddAddressUseCase` in `lib/features/profile/domain/use_cases/add_address.dart`:
  - Validate address fields (required: recipientName, phoneNumber, streetAddress, ward, district, city)
  - If first address, set as default
- [ ] **T102** [P] [US2] Create `UpdateAddressUseCase` in `lib/features/profile/domain/use_cases/update_address.dart`
- [ ] **T103** [P] [US2] Create `DeleteAddressUseCase` in `lib/features/profile/domain/use_cases/delete_address.dart`
- [ ] **T104** [P] [US2] Create `SetDefaultAddressUseCase` in `lib/features/profile/domain/use_cases/set_default_address.dart`

#### Presentation Layer - Auth Feature

- [ ] **T105** [US2] Create `AuthProvider` (Riverpod StateNotifier) in `lib/features/auth/presentation/auth_provider.dart`:
  - State: `AuthState` (unauthenticated, authenticated(user), loading, error)
  - Methods: `register()`, `verifyOTP()`, `login()`, `logout()`, `checkAuthStatus()`
  - Listen to secure storage for token changes
- [ ] **T106** [US2] Create `LoginScreen` in `lib/features/auth/presentation/login_screen.dart`:
  - Phone number input (Vietnamese format)
  - Password input (obscured)
  - "Forgot Password" link
  - "Sign Up" link
  - Login button (calls `AuthProvider.login()`)
  - Loading indicator during login
  - Error snackbar on failure
- [ ] **T107** [US2] Create `RegisterScreen` in `lib/features/auth/presentation/register_screen.dart`:
  - Phone number input with validator
  - Password input with strength indicator
  - Confirm password input
  - Full name input
  - Email input (optional)
  - "Already have account? Login" link
  - Register button → navigates to OTP screen
- [ ] **T108** [US2] Create `OTPVerificationScreen` in `lib/features/auth/presentation/otp_verification_screen.dart`:
  - 6-digit OTP input (auto-focus next field)
  - Countdown timer (e.g., "Resend code in 0:45")
  - Resend OTP button (enabled after countdown)
  - Verify button → calls `AuthProvider.verifyOTP()`
  - On success → navigate to home (authenticated state)
- [ ] **T109** [P] [US2] Create password strength indicator widget in `lib/features/auth/presentation/widgets/password_strength_indicator.dart`:
  - Color-coded bar (red/yellow/green)
  - Text: Weak/Medium/Strong
- [ ] **T110** [P] [US2] Create `ForgotPasswordScreen` in `lib/features/auth/presentation/forgot_password_screen.dart`:
  - Phone input → send OTP
  - OTP verification
  - New password input → reset
- [ ] **T111** [P] [US2] Create `ResetPasswordScreen` in `lib/features/auth/presentation/reset_password_screen.dart`

#### Presentation Layer - Profile Feature

- [ ] **T112** [US2] Create `ProfileProvider` in `lib/features/profile/presentation/profile_provider.dart`:
  - State: `AsyncValue<User>`, addresses list
  - Methods: `loadProfile()`, `updateProfile()`, `loadAddresses()`, `addAddress()`, `updateAddress()`, `deleteAddress()`, `setDefaultAddress()`
- [ ] **T113** [US2] Create `ProfileScreen` in `lib/features/profile/presentation/profile_screen.dart`:
  - Avatar (circular, placeholder if null)
  - User name, phone, email
  - "Edit Profile" button → navigates to edit screen
  - "Manage Addresses" button → navigates to addresses screen
  - "My Orders" button (placeholder, links to US-004)
  - "Logout" button → shows confirmation dialog → calls `AuthProvider.logout()`
- [ ] **T114** [US2] Create `EditProfileScreen` in `lib/features/profile/presentation/edit_profile_screen.dart`:
  - Full name input
  - Email input (optional)
  - Avatar picker (camera/gallery)
  - Save button → calls `ProfileProvider.updateProfile()`
- [ ] **T115** [US2] Create `AddressListScreen` in `lib/features/profile/presentation/address_list_screen.dart`:
  - List of saved addresses
  - Each address shows: recipient name, phone, full address
  - Default address badge
  - Edit/Delete actions (swipe or menu)
  - "Add New Address" FAB → navigates to address form
- [ ] **T116** [US2] Create `AddressFormScreen` in `lib/features/profile/presentation/address_form_screen.dart`:
  - Recipient name input
  - Phone number input (with validator)
  - Street address input
  - Ward dropdown/input
  - District dropdown/input
  - City/Province dropdown/input
  - "Set as default address" checkbox
  - Save button → calls `ProfileProvider.addAddress()` or `updateAddress()`
- [ ] **T117** [P] [US2] Create address tile widget in `lib/features/profile/presentation/widgets/address_tile.dart`:
  - Display formatted address
  - "Default" badge if default
  - Edit/Delete icons

#### Routing & Auth Guard

- [ ] **T118** [US2] Add auth routes to `lib/app/routes.dart`:
  - `/auth/login` → LoginScreen
  - `/auth/register` → RegisterScreen
  - `/auth/verify-otp` → OTPVerificationScreen
  - `/auth/forgot-password` → ForgotPasswordScreen
  - `/profile` → ProfileScreen (requires auth)
  - `/profile/edit` → EditProfileScreen (requires auth)
  - `/profile/addresses` → AddressListScreen (requires auth)
  - `/profile/addresses/add` → AddressFormScreen (requires auth)
- [ ] **T119** [US2] Implement auth guard in `lib/app/routes.dart`:
  - `redirect` callback checks `AuthProvider` state
  - If unauthenticated and accessing protected route → redirect to `/auth/login`
  - If authenticated and accessing auth routes → redirect to home

#### Integration with US-001

- [ ] **T120** [US2] Update `ProductDetailScreen` "Add to Cart" button logic:
  - If `AuthProvider` state is unauthenticated → show login dialog with "Login" / "Sign Up" buttons
  - If authenticated → proceed to add to cart (US-003 functionality)

**Checkpoint**: US-002 complete - Users can register, login, manage profile/addresses. Test independently.

---

## Phase 5: User Story 3 - Shopping Cart & Simple Checkout (Priority: P1) 🎯 MVP

**Goal**: Logged-in users can add products to cart, review selections, apply vouchers, and checkout with COD

**Independent Test**: Login → add multiple products to cart → see items grouped by shop → apply voucher → proceed to checkout → confirm address → place order with COD → see order confirmation

### Tests for US-003 (Write FIRST, must FAIL before implementation)

#### Unit Tests

- [ ] **T121** [P] [US3] Unit test for `AddToCartUseCase` in `test/unit/features/cart/domain/use_cases/add_to_cart_test.dart`:
  - Test adding product to empty cart
  - Test adding product with variant
  - Test quantity validation (> 0, <= stock)
  - Test duplicate item handling (update quantity)
- [ ] **T122** [P] [US3] Unit test for `UpdateCartItemQuantityUseCase` in `test/unit/features/cart/domain/use_cases/update_quantity_test.dart`:
  - Test quantity update
  - Test stock limit enforcement
- [ ] **T123** [P] [US3] Unit test for `RemoveCartItemUseCase` in `test/unit/features/cart/domain/use_cases/remove_cart_item_test.dart`
- [ ] **T124** [P] [US3] Unit test for `GetCartUseCase` in `test/unit/features/cart/domain/use_cases/get_cart_test.dart`:
  - Test cart grouping by shop
  - Test subtotal calculations
- [ ] **T125** [P] [US3] Unit test for `CheckoutUseCase` in `test/unit/features/cart/domain/use_cases/checkout_test.dart`:
  - Test order creation from cart
  - Test voucher application
  - Test cart clearing after successful checkout
  - Test insufficient stock handling
- [ ] **T126** [P] [US3] Unit test for `ApplyVoucherUseCase` in `test/unit/features/cart/domain/use_cases/apply_voucher_test.dart`:
  - Test valid voucher application
  - Test expired voucher rejection
  - Test usage limit enforcement
  - Test minimum order value validation
- [ ] **T127** [P] [US3] Unit test for `CartRepositoryImpl` in `test/unit/features/cart/data/repositories/cart_repository_impl_test.dart`:
  - Mock local and remote data sources
  - Test sync logic

#### Widget Tests

- [ ] **T128** [P] [US3] Widget test for `CartScreen` in `test/widget/features/cart/cart_screen_test.dart`:
  - Test empty cart shows empty state
  - Test cart items grouped by shop
  - Test quantity increment/decrement buttons
  - Test remove item button
  - Test subtotal displays correctly
  - Test "Proceed to Checkout" button
- [ ] **T129** [P] [US3] Widget test for `CartItemTile` in `test/widget/features/cart/widgets/cart_item_tile_test.dart`:
  - Test displays product info (image, title, variant, price)
  - Test quantity controls
  - Test remove button
- [ ] **T130** [P] [US3] Widget test for `CheckoutScreen` in `test/widget/features/cart/checkout_screen_test.dart`:
  - Test address selection
  - Test order summary displays
  - Test voucher input field
  - Test COD payment method selected by default
  - Test "Place Order" button
- [ ] **T131** [P] [US3] Widget test for `OrderConfirmationScreen` in `test/widget/features/cart/order_confirmation_screen_test.dart`:
  - Test displays order number
  - Test shows order items
  - Test "View Order" button

#### Integration Tests

- [ ] **T132** [US3] Integration test for shopping flow in `integration_test/shopping_flow_test.dart`:
  - Login
  - Browse products → tap product
  - Select variant → add to cart
  - Navigate to cart → see item
  - Add another product from different shop
  - See items grouped by shop
  - Update quantity
  - Apply voucher
  - Proceed to checkout
  - Select address
  - Place order with COD
  - See order confirmation

### Implementation for US-003

#### Data Layer

- [ ] **T133** [P] [US3] Create cart remote data source in `lib/features/cart/data/data_sources/cart_remote_data_source.dart`:
  - `getCart()` → GET `/cart`
  - `addItem(productId, variantId, quantity)` → POST `/cart`
  - `updateItemQuantity(itemId, quantity)` → PATCH `/cart/items/{id}`
  - `removeItem(itemId)` → DELETE `/cart/items/{id}`
  - `syncCart(items)` → POST `/cart/sync`
- [ ] **T134** [US3] Create cart repository implementation in `lib/features/cart/data/repositories/cart_repository_impl.dart`:
  - Sync between local SQLite and remote server
  - Offline-first approach: writes to local DB immediately, syncs to server in background
  - Merge conflicts: server cart wins
- [ ] **T135** [P] [US3] Create order remote data source in `lib/features/cart/data/data_sources/order_remote_data_source.dart`:
  - `createOrder(items, addressId, paymentMethod, voucherCode, notes)` → POST `/orders`
  - `getOrders(status, limit, cursor)` → GET `/orders`
  - `getOrderDetail(orderId)` → GET `/orders/{id}`
  - `cancelOrder(orderId, reason, notes)` → POST `/orders/{id}/cancel`
- [ ] **T136** [US3] Create order repository implementation in `lib/features/cart/data/repositories/order_repository_impl.dart`
- [ ] **T137** [P] [US3] Create voucher remote data source in `lib/features/cart/data/data_sources/voucher_remote_data_source.dart`:
  - `getAvailableVouchers(shopId, orderSubtotal)` → GET `/shops/{id}/vouchers`
  - `validateVoucher(voucherCode, shopId, orderSubtotal)` → POST `/vouchers/validate`

#### Domain Layer

- [ ] **T138** [P] [US3] Create cart repository interface in `lib/features/cart/domain/repositories/cart_repository.dart`
- [ ] **T139** [P] [US3] Create `AddToCartUseCase` in `lib/features/cart/domain/use_cases/add_to_cart.dart`:
  - Validate quantity > 0
  - Check stock availability
  - If item already in cart with same variant → update quantity
  - Otherwise add new cart item
- [ ] **T140** [P] [US3] Create `UpdateCartItemQuantityUseCase` in `lib/features/cart/domain/use_cases/update_quantity.dart`:
  - Validate quantity > 0 and <= stock
- [ ] **T141** [P] [US3] Create `RemoveCartItemUseCase` in `lib/features/cart/domain/use_cases/remove_cart_item.dart`
- [ ] **T142** [P] [US3] Create `GetCartUseCase` in `lib/features/cart/domain/use_cases/get_cart.dart`:
  - Fetch cart from repository
  - Group items by shop
  - Calculate subtotals per shop
  - Calculate grand total
- [ ] **T143** [P] [US3] Create `ClearCartUseCase` in `lib/features/cart/domain/use_cases/clear_cart.dart`
- [ ] **T144** [P] [US3] Create order repository interface in `lib/features/cart/domain/repositories/order_repository.dart`
- [ ] **T145** [P] [US3] Create `CheckoutUseCase` in `lib/features/cart/domain/use_cases/checkout.dart`:
  - Validate cart not empty
  - Validate address selected
  - Create orders (one per shop in cart)
  - Apply voucher if provided
  - Clear cart on success
  - Return list of created orders
- [ ] **T146** [P] [US3] Create `ApplyVoucherUseCase` in `lib/features/cart/domain/use_cases/apply_voucher.dart`:
  - Validate voucher code format
  - Check voucher validity (active, not expired, usage limit)
  - Check minimum order value
  - Calculate discount (percentage or fixed amount)
  - Return discounted total
- [ ] **T147** [P] [US3] Create `GetAvailableVouchersUseCase` in `lib/features/cart/domain/use_cases/get_available_vouchers.dart`

#### Presentation Layer - Cart Feature

- [ ] **T148** [US3] Create `CartProvider` (Riverpod StateNotifier) in `lib/features/cart/presentation/cart_provider.dart`:
  - State: `AsyncValue<Cart>` (loading, data, error)
  - Cart model includes: items grouped by shop, subtotals, grand total
  - Methods: `loadCart()`, `addToCart(productId, variantId, quantity)`, `updateQuantity(itemId, quantity)`, `removeItem(itemId)`, `applyVoucher(shopId, voucherCode)`, `removeVoucher(shopId)`
  - Listen to cart changes (optimistic updates)
- [ ] **T149** [US3] Create `CartScreen` in `lib/features/cart/presentation/cart_screen.dart`:
  - AppBar with "Cart" title and item count
  - If cart empty → show empty state with "Start Shopping" button
  - List of shop groups (each shop as section)
  - Each shop section:
    - Shop header (name, voucher button)
    - List of cart items for that shop
    - Shop subtotal, shipping fee
  - Grand total section at bottom (sticky)
  - "Proceed to Checkout" button (disabled if cart empty)
- [ ] **T150** [P] [US3] Create cart item tile widget in `lib/features/cart/presentation/widgets/cart_item_tile.dart`:
  - Product image (CachedNetworkImage)
  - Product title, variant name (if applicable)
  - Price (unit price × quantity)
  - Quantity controls (-, quantity, +)
  - Stock warning if quantity > available stock
  - Remove button (trash icon)
  - Inactive product warning (if product no longer active)
- [ ] **T151** [P] [US3] Create shop cart section widget in `lib/features/cart/presentation/widgets/shop_cart_section.dart`:
  - Shop header (name, "Apply Voucher" button)
  - List of CartItemTiles for shop
  - Subtotal and shipping fee rows
  - Applied voucher badge (removable)
- [ ] **T152** [P] [US3] Create voucher selector bottom sheet in `lib/features/cart/presentation/widgets/voucher_selector_bottom_sheet.dart`:
  - Manual code input field with "Apply" button
  - List of available shop vouchers (if any)
  - Each voucher shows: title, discount, minimum spend, expiry
  - Tap voucher to apply
  - "No vouchers available" message if empty

#### Presentation Layer - Checkout Feature

- [ ] **T153** [US3] Create `CheckoutProvider` in `lib/features/cart/presentation/checkout_provider.dart`:
  - State: selected address, applied vouchers (per shop), payment method, order processing status
  - Methods: `selectAddress(addressId)`, `placeOrder()`, `setNotes(notes)`
- [ ] **T154** [US3] Create `CheckoutScreen` in `lib/features/cart/presentation/checkout_screen.dart`:
  - Address section:
    - Shows selected address (recipient, phone, full address)
    - "Change Address" button → navigates to address selection
  - Order items section (grouped by shop, read-only view):
    - Shop name
    - List of items (image, title, variant, quantity, price)
    - Shop subtotal, shipping fee, discount (if voucher applied)
  - Payment method section:
    - COD selected by default (only option for MVP)
  - Notes input (optional, for seller)
  - Order summary (sticky bottom):
    - Total items count
    - Subtotal
    - Total shipping
    - Total discount
    - Grand total (large, bold)
  - "Place Order" button → calls `CheckoutProvider.placeOrder()`
  - Loading overlay during order creation
- [ ] **T155** [P] [US3] Create address selector screen in `lib/features/cart/presentation/address_selector_screen.dart`:
  - List of saved addresses (radio buttons)
  - Selected address highlighted
  - "Add New Address" button → navigates to address form
  - "Confirm" button → returns selected address
- [ ] **T156** [US3] Create `OrderConfirmationScreen` in `lib/features/cart/presentation/order_confirmation_screen.dart`:
  - Success checkmark animation
  - "Order Placed Successfully!" message
  - Order number(s) (if multiple orders from different shops)
  - Estimated delivery time
  - Order details summary (items, total)
  - "View Order" button → navigates to order detail (US-004 feature, placeholder for MVP)
  - "Continue Shopping" button → navigates to home

#### Routing Integration

- [ ] **T157** [US3] Add cart/checkout routes to `lib/app/routes.dart`:
  - `/cart` → CartScreen (requires auth)
  - `/checkout` → CheckoutScreen (requires auth + non-empty cart)
  - `/checkout/address-selector` → AddressSelectorScreen (requires auth)
  - `/order-confirmation` → OrderConfirmationScreen (requires auth)

#### Integration with US-001

- [ ] **T158** [US3] Update `ProductDetailScreen` "Add to Cart" button:
  - If authenticated → call `CartProvider.addToCart()` with selected variant and quantity
  - Show success snackbar with "View Cart" action
  - Update cart icon badge count

#### Integration with US-002

- [ ] **T159** [US3] Ensure checkout requires address:
  - If user has no saved addresses → show dialog prompting to add address → navigate to address form
  - If user has addresses → proceed to checkout

#### Cart Persistence & Sync

- [ ] **T160** [US3] Implement cart sync on app launch:
  - On app start (if authenticated) → sync local cart with server cart
  - Merge logic: server cart wins for conflicts, preserve local-only items
- [ ] **T161** [US3] Implement cart sync on login:
  - After successful login → sync guest cart (if any) with user's server cart

**Checkpoint**: US-003 complete - Users can add to cart, checkout, place orders. Test complete buyer journey: browse → login → add to cart → checkout → order confirmation.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final touches, documentation, performance optimization

- [ ] **T162** [P] Add loading skeletons (shimmer effect) for:
  - Product list loading state
  - Product detail loading state
  - Cart loading state
- [ ] **T163** [P] Add animations:
  - Page transitions (Hero animations for product images)
  - Cart badge count animation on add to cart
  - Success checkmark animation on order confirmation
- [ ] **T164** [P] Performance optimization:
  - Verify const constructors used throughout
  - Add RepaintBoundary to expensive widgets (product cards, image carousel)
  - Test 60fps scrolling on product lists
  - Verify image caching working (check network tab in DevTools)
- [ ] **T165** [P] Error handling improvements:
  - Network offline detection → show offline banner
  - Retry buttons on all error states
  - Graceful degradation (e.g., show cached products if API fails)
- [ ] **T166** [P] Accessibility:
  - Add semantic labels to all interactive elements
  - Test with screen reader (TalkBack on Android, VoiceOver on iOS)
  - Ensure touch targets are >= 48x48 dp
- [ ] **T167** [P] Vietnamese localization verification:
  - Review all UI text in Vietnamese
  - Ensure VND currency formatting correct (e.g., "299.000 ₫")
  - Verify date formats
- [ ] **T168** Run all tests and fix any failures:
  - `flutter test` (unit + widget tests)
  - `flutter drive` (integration tests)
  - Achieve >80% coverage on business logic
- [ ] **T169** Code cleanup:
  - Run `flutter analyze` → fix all issues
  - Run `dart format lib/ test/` → ensure consistent formatting
  - Remove unused imports, dead code
  - Add missing documentation comments
- [ ] **T170** Update `README.md`:
  - Add project description
  - Link to `quickstart.md`
  - Add screenshots (home, product detail, cart, checkout)
- [ ] **T171** Validate `quickstart.md`:
  - Fresh clone → follow setup steps → verify app runs
  - Test on iOS and Android
- [ ] **T172** Create demo data:
  - Seed backend with sample products, categories, shops
  - Create test accounts (buyer, seller)

**Checkpoint**: MVP complete - All P1 user stories functional, tested, polished. Ready for demo/deployment.

---

## Dependencies & Execution Order

### Phase Dependencies

1. **Setup (Phase 1)**: No dependencies - START HERE
2. **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories - CRITICAL PATH
3. **User Story 1 (Phase 3)**: Depends on Foundational - Can start after Phase 2
4. **User Story 2 (Phase 4)**: Depends on Foundational - Can start after Phase 2 (parallel with US-001)
5. **User Story 3 (Phase 5)**: Depends on Foundational, US-001 (product browsing), US-002 (authentication)
6. **Polish (Phase 6)**: Depends on all user stories complete

### User Story Dependencies

- **US-001 (Guest Discovery)**: Independent after Foundational ✅
- **US-002 (Authentication)**: Independent after Foundational ✅ (can parallel with US-001)
- **US-003 (Cart/Checkout)**: Depends on US-001 (product detail screen) + US-002 (auth, addresses)

### Within Each User Story

**Test-Driven Development Flow**:
1. Write tests FIRST (unit, widget, integration) - ALL MUST FAIL
2. Run tests → confirm failures
3. Implement code to pass tests
4. Run tests → confirm passes
5. Refactor if needed
6. Repeat

**Implementation Order per User Story**:
1. Tests (unit → widget → integration)
2. Data layer (remote data sources, repositories)
3. Domain layer (use cases, repository interfaces)
4. Presentation layer (providers → screens → widgets)
5. Routing integration
6. Integration with other user stories

### Parallel Opportunities

**Phase 1 (Setup)**: All tasks can run in parallel (T003-T007)

**Phase 2 (Foundational)**: Many tasks can parallel:
- API client + interceptors (T008-T012) can parallel
- Storage wrappers (T013-T016) can parallel
- All entity models (T017-T027) can parallel
- All shared widgets (T028-T032) can parallel
- All utilities (T033-T035) can parallel
- Theme, routes, providers (T036-T039) can parallel after dependencies

**Phase 3 (US-001)**: Parallel batches:
- All unit tests (T040-T044) → parallel
- All widget tests (T045-T048) → parallel
- Data sources (T050) + Use cases (T053-T057) → parallel after interfaces
- Widgets (T060, T061, T064, T067-T070) → parallel

**Phase 4 (US-002)**: Parallel batches:
- All unit tests (T072-T079) → parallel
- All widget tests (T080-T084) → parallel
- Data sources (T087, T089) + Use cases (T092-T104) → parallel after interfaces
- Auth screens (T106-T111) → parallel after providers
- Profile screens (T113-T117) → parallel after providers

**Phase 5 (US-003)**: Parallel batches:
- All unit tests (T121-T127) → parallel
- All widget tests (T128-T131) → parallel
- Data sources (T133, T135, T137) → parallel
- Use cases (T139-T147) → parallel after interfaces
- Widgets (T150-T152, T155) → parallel

**Phase 6 (Polish)**: Most tasks can parallel (T162-T167, T170-T172)

### Multi-Developer Strategy

**With 3 developers**:
1. **Together**: Complete Setup + Foundational (critical path)
2. **After Foundational**:
   - Dev A: US-001 (Guest Discovery)
   - Dev B: US-002 (Authentication)
   - Dev C: Prepare tests for US-003
3. **After US-001 + US-002**:
   - Dev A + Dev B: US-003 (Cart/Checkout) together (larger feature)
   - Dev C: Polish tasks
4. **Final**: All devs on Polish + Testing

---

## MVP Delivery Milestones

### Milestone 1: Foundation Ready (Foundational Phase Complete)
- [ ] All core infrastructure in place
- [ ] Can make authenticated API calls
- [ ] Can persist data locally
- [ ] Can navigate between screens
- **Deliverable**: Empty app shell with working authentication

### Milestone 2: Guest Browsing (US-001 Complete)
- [ ] Guests can browse products
- [ ] Search works with filters
- [ ] Product detail shows variants, reviews
- **Deliverable**: Demo browsing experience (no login required)

### Milestone 3: User Accounts (US-002 Complete)
- [ ] Registration with OTP verification
- [ ] Login/logout working
- [ ] Profile management
- [ ] Address management
- **Deliverable**: Full user lifecycle demo

### Milestone 4: MVP Complete (US-003 Complete)
- [ ] Add to cart functionality
- [ ] Checkout with address selection
- [ ] Order placement with COD
- [ ] Order confirmation
- **Deliverable**: Complete buyer journey: browse → login → purchase

### Milestone 5: Production Ready (Polish Complete)
- [ ] All tests passing (>80% coverage)
- [ ] Performance optimized (60fps, <3s launch)
- [ ] Error handling robust
- [ ] Documentation complete
- **Deliverable**: Production-ready MVP

---

## Estimation (Story Points)

**Legend**: 1 SP = 1 day of focused work

| Phase | Story Points | Duration (1 dev) | Duration (3 devs) |
|-------|-------------|------------------|-------------------|
| Setup (Phase 1) | 2 SP | 2 days | 1 day |
| Foundational (Phase 2) | 8 SP | 8 days | 3 days |
| US-001 (Phase 3) | 10 SP | 10 days | 10 days |
| US-002 (Phase 4) | 8 SP | 8 days | 8 days (parallel) |
| US-003 (Phase 5) | 12 SP | 12 days | 6 days |
| Polish (Phase 6) | 3 SP | 3 days | 1 day |
| **TOTAL** | **43 SP** | **43 days** | **15 days** |

**Notes**:
- Assumes experienced Flutter developer
- Includes testing time (TDD)
- Backend API assumed ready (or mocked)
- Does not include code review, QA, deployment
- US-001 and US-002 can parallel (saves ~8 days with 2 devs)

---

## Success Criteria

**MVP is considered complete when**:

✅ **Functional Requirements** (P1 user stories):
- [ ] Guest can browse products, search, view details, see reviews (US-001)
- [ ] User can register with OTP, login, manage profile, add addresses (US-002)
- [ ] User can add to cart, checkout, apply vouchers, place COD orders (US-003)

✅ **Technical Requirements**:
- [ ] All unit tests passing (>80% coverage on business logic)
- [ ] All widget tests passing
- [ ] All integration tests passing (3 flows: guest browsing, registration, shopping)
- [ ] No critical errors on `flutter analyze`
- [ ] App runs on iOS 13+ and Android 7.0+ without crashes

✅ **Performance Requirements**:
- [ ] 60fps scrolling on product lists (verified in DevTools)
- [ ] App launch <3s on 4G (cold start)
- [ ] Product images load <2s (cached)
- [ ] Search autocomplete responds <300ms

✅ **User Experience**:
- [ ] All text in Vietnamese with proper formatting
- [ ] VND currency displayed correctly (e.g., "299.000 ₫")
- [ ] Error messages helpful and actionable
- [ ] Loading states with indicators
- [ ] Empty states with clear messaging

✅ **Documentation**:
- [ ] `quickstart.md` validated (fresh setup works)
- [ ] `README.md` updated with screenshots
- [ ] All code has documentation comments

✅ **Constitution Compliance**:
- [ ] Widget Composition: Max 3-4 nesting levels, reusable widgets ✅
- [ ] State Management: Riverpod used correctly, state clear ✅
- [ ] TDD: Tests written first, >80% coverage ✅
- [ ] Performance: ListView.builder, const widgets, 60fps ✅
- [ ] Platform-Aware: Material Design 3, iOS/Android tested ✅

---

## Notes

- **[P] tasks**: Different files, no dependencies, can run in parallel
- **[Story] tags**: US1, US2, US3 map to user stories in spec.md
- **TDD mandatory**: Tests MUST fail before implementation
- **Commit frequently**: After each task or logical group
- **Checkpoint validation**: Test user stories independently before proceeding
- **Backend API**: Assumed available or mocked for development
- **Constitution**: All tasks designed to comply with 6 principles from constitution.md

---

## Ready to Start? 🚀

**Next Steps**:
1. Review this task list with team
2. Setup development environment per `quickstart.md`
3. Start with Phase 1: Setup (T001-T007)
4. Proceed to Phase 2: Foundational (CRITICAL PATH)
5. Implement P1 user stories in order (or parallel if team capacity allows)

**Questions?**
- Refer to `plan.md` for architecture decisions
- Check `research.md` for technology choices
- See `data-model.md` for entity details
- Review `contracts/` for API endpoints
- Follow `quickstart.md` for development workflow

Good luck building the MVP! 🎉
