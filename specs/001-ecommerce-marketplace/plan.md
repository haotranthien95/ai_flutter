# Implementation Plan: Multi-Vendor E-Commerce Marketplace

**Branch**: `001-ecommerce-marketplace` | **Date**: 2025-12-03 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-ecommerce-marketplace/spec.md`

## Summary

This plan outlines the implementation of a multi-vendor e-commerce marketplace inspired by Shopee, targeting the Vietnamese market with mobile-first approach (iOS/Android). The platform enables guest browsing, buyer purchasing, seller management, and platform administration across 15 prioritized user stories (P1-P5). The MVP (P1 stories) focuses on guest product discovery, buyer authentication, and shopping cart/checkout with COD payment, forming a complete transaction flow.

**Technical Approach:**
- **Frontend**: Flutter 3.5.4+ (iOS, Android, responsive web)
- **Backend**: REST API with separate backend service
- **Database**: PostgreSQL for transactional data integrity
- **Real-Time**: WebSocket for buyer-seller chat messaging
- **Storage**: Hybrid cloud (AWS S3/GCS) + local temporary for image processing
- **State Management**: Provider/Riverpod for shared state, setState for local UI state
- **Testing**: TDD with widget, integration, and unit tests before implementation

## Technical Context

**Language/Version**: Dart 3.5+ with Flutter SDK 3.5.4+ (stable channel)  
**Primary Dependencies**:
- **State Management**: `provider` ^6.1.1 or `riverpod` ^2.4.0 (to be chosen during Phase 0 research)
- **HTTP Client**: `dio` ^5.4.0 for REST API communication
- **WebSocket**: `web_socket_channel` ^2.4.0 for real-time chat
- **Image Handling**: `cached_network_image` ^3.3.0, `image_picker` ^1.0.5
- **Local Storage**: `shared_preferences` ^2.2.2, `sqflite` ^2.3.0 (cart persistence, offline data)
- **Authentication**: `flutter_secure_storage` ^9.0.0 for token storage
- **Push Notifications**: `firebase_messaging` ^14.7.6 (FCM for Android/iOS)
- **UI Components**: Material Design 3, `flutter_svg` ^2.0.9
- **Forms & Validation**: `flutter_form_builder` ^9.1.1
- **Routing**: `go_router` ^12.1.3 for declarative navigation

**Storage**: 
- **Backend Database**: PostgreSQL 15+ with ACID transactions
- **Local Mobile Storage**: SQLite via sqflite for offline cart and favorites
- **Image Storage**: Cloud storage (AWS S3, Google Cloud Storage, or Cloudinary) with CDN
- **Cache**: Shared preferences for user settings, tokens

**Testing**:
- **Widget Tests**: `flutter_test` (SDK included) for all custom widgets
- **Integration Tests**: `integration_test` package for end-to-end user journeys
- **Unit Tests**: `mockito` ^5.4.4 for mocking services and repositories
- **Test Coverage**: Target >80% coverage on business logic

**Target Platform**: 
- iOS 13+ (iPhone and iPad)
- Android 7.0+ (API level 24+)
- Responsive Web (future phase, architecture-ready)

**Project Type**: Mobile application with feature-based architecture

**Performance Goals**: 
- 60fps scrolling on product lists and category pages
- <3 seconds app launch to home screen on 4G
- <2 seconds product image load time (cached)
- <300ms search autocomplete response
- <500ms cart update operations
- <3 seconds real-time message delivery when both users online

**Constraints**: 
- Single currency (VND) in initial version
- Vietnamese localization mandatory
- COD payment only (online payments deferred)
- Manual shipping status workflow (carrier API integrations deferred)
- Mobile-first design (web responsive as secondary)
- Must work on typical Vietnamese 4G networks

**Scale/Scope**: 
- MVP target: 1,000+ concurrent users
- ~50-70 screens across buyer, seller, admin flows
- 15 user stories (5 priority levels: P1-P5)
- 78 functional requirements
- 14 key entities with complex relationships
- Expected: 1000s of products, 100s of sellers, 10,000s of users at launch



## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Assessment Date**: 2025-12-03  
**Constitution Version**: v1.0.0  
**Evaluator**: Development Team

| Principle | Status | Justification |
|-----------|--------|---------------|
| **1. Widget Composition** | ✅ PASS | Specification mandates decomposing complex UIs into reusable widgets (e.g., `ProductCard`, `ShopHeader`, `ReviewTile`). Design requires max 3-4 nesting levels in product list, cart, and checkout screens. Feature-based architecture enforces widget reusability across buyer/seller flows. |
| **2. State Management Clarity** | ✅ PASS | Technical Context specifies Provider/Riverpod for shared state (cart, auth, product catalog) and setState for local UI state (form fields, animations). Phase 0 research.md will evaluate and select between Provider vs Riverpod with explicit justification. Clear separation defined: global state via chosen provider, ephemeral state via StatefulWidget. |
| **3. TDD (Test-Driven Development)** | ✅ PASS | Plan mandates >80% test coverage with Red-Green-Refactor cycle. Testing strategy includes widget tests (flutter_test) for all custom components, integration tests (integration_test) for 15 user stories, unit tests (mockito) for business logic. Each functional requirement (FR-001 to FR-078) requires corresponding test before implementation. |
| **4. Performance-First Architecture** | ✅ PASS | Performance goals explicitly defined: 60fps scrolling (ListView.builder with const widgets), <3s launch (lazy loading modules), <2s image loads (cached_network_image with CDN). Specification requires const constructors, pagination for product lists (20 items/page), optimistic UI updates for cart operations, and background sync for offline mode. |
| **5. AI Integration (ChatGPT)** | ⚠️ NOT APPLICABLE | Feature specification does not include AI-powered features. Chatbot, personalized recommendations, and image search are deferred to future phases. MVP focuses on core e-commerce transactions without AI assistance. This principle will be revisited when AI features are prioritized. |
| **6. Platform-Aware Design** | ✅ PASS | Material Design 3 mandatory for cross-platform consistency. Specification requires adaptive layouts for iOS/Android with platform-specific testing on both operating systems. UI components must follow Flutter best practices (Scaffold, AppBar, BottomNavigationBar). Phase 1 design must include responsive breakpoints for tablet and web views. |

**Overall Assessment**: ✅ **APPROVED** to proceed to Phase 0 research  
**Conditions**: 
- State management decision (Provider vs Riverpod) must be documented in research.md with tradeoff analysis
- All P1 user stories (Guest Discovery, Auth, Checkout) require TDD with >80% coverage before merge
- Performance budgets (60fps, <3s launch) must be validated in integration tests

**Non-Compliance**: None. AI Integration principle deferred as not applicable to MVP scope.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

**Selected Structure**: Flutter Mobile Application with Feature-Based Architecture

```text
lib/
├── main.dart                    # App entry point, runApp, MaterialApp setup
├── app/
│   ├── routes.dart              # GoRouter configuration for navigation
│   ├── theme.dart               # Material Design 3 theme (colors, typography)
│   └── constants.dart           # App-wide constants (API base URL, timeouts)
├── core/
│   ├── api/
│   │   ├── api_client.dart      # Dio HTTP client with interceptors
│   │   ├── api_error.dart       # Error handling and exceptions
│   │   └── endpoints.dart       # REST endpoint constants
│   ├── storage/
│   │   ├── local_storage.dart   # SharedPreferences wrapper
│   │   ├── secure_storage.dart  # FlutterSecureStorage for tokens
│   │   └── database/            # SQLite schemas for offline cart/favorites
│   ├── websocket/
│   │   └── ws_client.dart       # WebSocket client for real-time chat
│   ├── models/
│   │   ├── user.dart            # User entity with fromJson/toJson
│   │   ├── product.dart         # Product, ProductVariant models
│   │   ├── shop.dart            # Shop entity
│   │   ├── order.dart           # Order, OrderItem models
│   │   ├── cart.dart            # Cart, CartItem models
│   │   ├── review.dart          # Review model
│   │   ├── message.dart         # Message model for chat
│   │   └── ...                  # Other entities (Voucher, Notification, etc.)
│   ├── widgets/
│   │   ├── loading_indicator.dart
│   │   ├── error_view.dart
│   │   ├── empty_state.dart
│   │   └── custom_button.dart
│   └── utils/
│       ├── formatters.dart      # Currency (VND), date formatters
│       ├── validators.dart      # Form validation helpers
│       └── image_helper.dart    # Image compression, caching
├── features/
│   ├── home/                    # US-001: Guest Product Discovery
│   │   ├── presentation/
│   │   │   ├── home_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── product_card.dart
│   │   │   │   ├── category_chip.dart
│   │   │   │   └── search_bar.dart
│   │   │   └── home_provider.dart (or home_controller.dart if Riverpod)
│   │   ├── domain/
│   │   │   ├── repositories/
│   │   │   │   └── product_repository.dart
│   │   │   └── use_cases/
│   │   │       ├── get_products.dart
│   │   │       └── search_products.dart
│   │   └── data/
│   │       ├── data_sources/
│   │       │   └── product_remote_data_source.dart
│   │       └── repositories/
│   │           └── product_repository_impl.dart
│   ├── auth/                    # US-002: Buyer Authentication
│   │   ├── presentation/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── otp_verification_screen.dart
│   │   │   └── auth_provider.dart
│   │   ├── domain/
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── use_cases/
│   │   │       ├── login.dart
│   │   │       ├── register.dart
│   │   │       └── verify_otp.dart
│   │   └── data/
│   │       └── repositories/
│   │           └── auth_repository_impl.dart
│   ├── cart/                    # US-003: Shopping Cart & Checkout
│   │   ├── presentation/
│   │   │   ├── cart_screen.dart
│   │   │   ├── checkout_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── cart_item_tile.dart
│   │   │   │   ├── voucher_selector.dart
│   │   │   │   └── shipping_address_form.dart
│   │   │   └── cart_provider.dart
│   │   ├── domain/
│   │   │   ├── repositories/
│   │   │   │   └── cart_repository.dart
│   │   │   └── use_cases/
│   │   │       ├── add_to_cart.dart
│   │   │       ├── update_quantity.dart
│   │   │       └── checkout.dart
│   │   └── data/
│   │       ├── data_sources/
│   │       │   ├── cart_local_data_source.dart  # SQLite persistence
│   │       │   └── cart_remote_data_source.dart
│   │       └── repositories/
│   │           └── cart_repository_impl.dart
│   ├── orders/                  # US-004: Order Management
│   │   ├── presentation/
│   │   │   ├── order_list_screen.dart
│   │   │   ├── order_detail_screen.dart
│   │   │   └── widgets/
│   │   │       └── order_status_timeline.dart
│   │   └── ...                  # domain, data layers
│   ├── product_detail/          # US-001 extended: Product detail view
│   │   ├── presentation/
│   │   │   ├── product_detail_screen.dart
│   │   │   └── widgets/
│   │   │       ├── image_carousel.dart
│   │   │       ├── variant_selector.dart
│   │   │       └── review_summary.dart
│   │   └── ...
│   ├── reviews/                 # US-005: Reviews & Ratings
│   │   ├── presentation/
│   │   │   ├── review_list_screen.dart
│   │   │   ├── write_review_screen.dart
│   │   │   └── widgets/
│   │   │       └── review_tile.dart
│   │   └── ...
│   ├── seller/                  # US-006 to US-010: Seller features
│   │   ├── shop_setup/
│   │   │   ├── presentation/
│   │   │   │   └── shop_registration_screen.dart
│   │   │   └── ...
│   │   ├── product_management/
│   │   │   ├── presentation/
│   │   │   │   ├── product_list_screen.dart
│   │   │   │   ├── add_product_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       └── image_uploader.dart
│   │   │   └── ...
│   │   ├── order_management/
│   │   │   ├── presentation/
│   │   │   │   └── seller_order_screen.dart
│   │   │   └── ...
│   │   ├── voucher_management/
│   │   │   └── ...
│   │   └── analytics/
│   │       ├── presentation/
│   │       │   └── seller_dashboard_screen.dart
│   │       └── ...
│   ├── chat/                    # US-011: Buyer-Seller Messaging
│   │   ├── presentation/
│   │   │   ├── chat_list_screen.dart
│   │   │   ├── chat_screen.dart
│   │   │   └── widgets/
│   │   │       ├── message_bubble.dart
│   │   │       └── chat_input.dart
│   │   ├── domain/
│   │   │   └── repositories/
│   │   │       └── message_repository.dart
│   │   └── data/
│   │       ├── data_sources/
│   │       │   ├── message_local_data_source.dart  # Cache recent messages
│   │       │   └── message_ws_data_source.dart     # WebSocket
│   │       └── repositories/
│   │           └── message_repository_impl.dart
│   ├── admin/                   # US-014, US-015: Admin features
│   │   ├── user_management/
│   │   │   └── ...
│   │   ├── content_moderation/
│   │   │   └── ...
│   │   └── reports/
│   │       └── ...
│   ├── profile/                 # User profile, settings
│   │   ├── presentation/
│   │   │   ├── profile_screen.dart
│   │   │   └── edit_profile_screen.dart
│   │   └── ...
│   ├── notifications/           # US-012: Push Notifications
│   │   ├── presentation/
│   │   │   └── notification_list_screen.dart
│   │   ├── domain/
│   │   │   └── repositories/
│   │   │       └── notification_repository.dart
│   │   └── data/
│   │       └── fcm_service.dart  # Firebase Cloud Messaging
│   └── search/                  # US-001 extended: Advanced search
│       ├── presentation/
│       │   ├── search_screen.dart
│       │   └── widgets/
│       │       ├── filter_dialog.dart
│       │       └── sort_options.dart
│       └── ...

test/
├── widget/                      # Widget tests (flutter_test)
│   ├── features/
│   │   ├── home/
│   │   │   └── home_screen_test.dart
│   │   ├── auth/
│   │   │   └── login_screen_test.dart
│   │   ├── cart/
│   │   │   └── cart_screen_test.dart
│   │   └── ...                  # Mirror lib/features structure
│   └── core/
│       └── widgets/
│           └── custom_button_test.dart
├── integration/                 # Integration tests (integration_test package)
│   ├── guest_shopping_flow_test.dart      # US-001 to US-003
│   ├── buyer_order_flow_test.dart         # US-004, US-005
│   ├── seller_product_management_test.dart # US-006 to US-010
│   ├── chat_flow_test.dart                # US-011
│   └── admin_moderation_test.dart         # US-014, US-015
├── unit/                        # Unit tests (mockito)
│   ├── core/
│   │   ├── api/
│   │   │   └── api_client_test.dart
│   │   └── utils/
│   │       └── validators_test.dart
│   ├── features/
│   │   ├── home/
│   │   │   ├── domain/
│   │   │   │   └── use_cases/
│   │   │   │       └── get_products_test.dart
│   │   │   └── data/
│   │   │       └── repositories/
│   │   │           └── product_repository_impl_test.dart
│   │   ├── auth/
│   │   │   └── ...
│   │   └── ...                  # Mirror lib/features structure
│   └── mocks/
│       ├── mock_api_client.dart
│       ├── mock_product_repository.dart
│       └── ...                  # Generated mocks via mockito
└── fixtures/                    # Test data (JSON, images)
    ├── products.json
    ├── users.json
    └── orders.json

assets/
├── images/
│   ├── logo.png
│   ├── placeholder_product.png
│   └── icons/
├── fonts/                       # Custom fonts if needed
└── translations/                # i18n JSON files (Vietnamese)
    └── vi_VN.json
```

**Structure Decision**: 
- **Feature-Based Architecture** chosen for clear separation of concerns and scalability across 15 user stories
- Each feature module follows **Clean Architecture** layers:
  - `presentation/`: UI (screens, widgets, state management providers/controllers)
  - `domain/`: Business logic (use cases, repository interfaces)
  - `data/`: Data sources (REST API, WebSocket, SQLite), repository implementations
- **Core module** for shared infrastructure (API client, models, widgets, utilities)
- **Test mirroring**: Test directory structure mirrors `lib/` for easy navigation
- **Platform-specific directories** (`ios/`, `android/`, `web/`) remain unchanged for native configurations

## Complexity Tracking

**No violations to justify** - All architectural decisions comply with Constitution principles. See Constitution Check section for detailed compliance assessment.

---

## Implementation Artifacts

This plan generated the following artifacts for Phase 0 (Research) and Phase 1 (Design):

### Phase 0: Technology Research ✅ COMPLETE
- **File**: `research.md`
- **Content**: 
  - State management decision (Riverpod selected over Provider)
  - HTTP client selection (Dio with interceptors)
  - Image handling strategy (cached_network_image)
  - Local storage approach (hybrid: SharedPreferences + SecureStorage + SQLite)
  - Navigation/routing (GoRouter with deep linking)
  - WebSocket client for chat
  - Push notifications (Firebase Cloud Messaging)
  - Form handling (flutter_form_builder)
  - Architecture pattern (Clean Architecture with feature-based modules)
  - Testing strategy (TDD with >80% coverage target)
  - Performance optimization patterns
  - Localization setup (Vietnamese with intl)
  - Error handling and logging

### Phase 1a: Data Model ✅ COMPLETE
- **File**: `data-model.md`
- **Content**: 
  - 15 entity definitions with fields, types, constraints
  - Entity relationships (ERD in Mermaid format)
  - Business rules and validation logic
  - State transition diagrams for Order, User, Shop
  - Database indexes for performance
  - Dart validation examples
  - Computed fields documentation

**Entities Defined**:
1. User (authentication, roles, profile)
2. Address (shipping addresses)
3. Shop (seller storefronts)
4. Category (hierarchical product classification)
5. Product (sellable items with variants)
6. ProductVariant (size/color/attribute combinations)
7. CartItem (shopping basket)
8. Order (transaction records)
9. OrderItem (line items in orders)
10. Review (product ratings and feedback)
11. Voucher (discount codes)
12. Message (buyer-seller chat)
13. Notification (system alerts)
14. Campaign (flash sales, promotions)
15. Report (content moderation flags)

### Phase 1b: API Contracts ✅ COMPLETE
- **Directory**: `contracts/`
- **Files**:
  - `README.md` - Overview, base URLs, authentication, pagination, error codes
  - `common.yaml` - Shared schemas (ErrorResponse, Pagination, Address, Money, Image)
  - `auth.yaml` - Authentication endpoints (register, login, OTP, token refresh, password reset)
  - `products.yaml` - Product catalog (list, search, details, reviews, categories, autocomplete)
  - `cart.yaml` - Shopping cart operations (get, add, update, remove, sync)
  - `orders.yaml` - Order management (create/checkout, history, details, cancel, complete)
  - `seller.yaml` - Seller features (shop setup, product CRUD, order fulfillment, analytics) *[To be created]*
  - `chat.yaml` - Messaging (REST for history, WebSocket protocol) *[To be created]*
  - `admin.yaml` - Platform administration (content moderation, user management, campaigns) *[To be created]*

**API Specification Standard**: OpenAPI 3.0.3 with request/response examples, error codes, authentication requirements

### Phase 1c: Development Setup ✅ COMPLETE
- **File**: `quickstart.md`
- **Content**:
  - Prerequisites (Flutter 3.5.4+, Xcode, Android Studio, Git)
  - Initial setup (clone repo, flutter doctor, pub get)
  - Backend configuration (environment URLs)
  - Running on iOS/Android (simulator, emulator, physical device)
  - Project structure walkthrough
  - TDD workflow (Red-Green-Refactor cycle)
  - Running tests (unit, widget, integration)
  - Code generation for mocks
  - Linting and formatting
  - Firebase configuration (iOS APNs, Android FCM)
  - Common tasks (add packages, create feature modules, debug API)
  - Platform-specific permissions (iOS Info.plist, Android Manifest)
  - Troubleshooting guide
  - Performance profiling
  - Next steps and resources

---

## Ready for Phase 2: Task Breakdown

All planning and design artifacts are complete. The next step is to break down P1 user stories (Guest Discovery, Authentication, Shopping Cart & Checkout) into actionable development tasks using the `/speckit.tasks` command.

**To continue**:
```bash
# Generate task breakdown from P1 user stories
/speckit.tasks
```

This will create `tasks.md` with:
- Detailed technical tasks for each P1 user story
- Task dependencies and estimated effort
- Acceptance criteria linked to tests
- Implementation order optimized for MVP delivery
