# Backend Implementation Tasks

**Project**: E-Commerce Marketplace API  
**Framework**: FastAPI (Python 3.11+)  
**Created**: 2025-12-05

---

## Task Status Legend

- `[ ]` Not Started
- `[~]` In Progress
- `[✓]` Completed
- `[X]` Blocked

---

## Phase 1: Project Setup & Infrastructure

### Setup Tasks

- [✓] **T001**: Initialize Python project structure
  - Create `backend/` directory
  - Create `app/` directory with `__init__.py`
  - Create `tests/` directory structure
  - Create `scripts/` directory

- [✓] **T002**: Set up Python dependencies
  - Create `requirements.txt` with core dependencies:
    - fastapi>=0.104.0
    - uvicorn[standard]>=0.24.0
    - sqlalchemy>=2.0.0
    - asyncpg>=0.29.0
    - alembic>=1.12.0
    - pydantic>=2.0.0
    - pydantic-settings>=2.0.0
    - python-jose[cryptography]>=3.3.0
    - passlib[bcrypt]>=1.7.4
    - python-multipart>=0.0.6
  - Create `requirements-dev.txt` with dev dependencies:
    - pytest>=7.4.0
    - pytest-asyncio>=0.21.0
    - httpx>=0.25.0
    - pytest-cov>=4.1.0
    - black>=23.0.0
    - flake8>=6.1.0
    - mypy>=1.6.0

- [✓] **T003**: Configure environment variables
  - Create `.env.example` with all required variables
  - Create `.gitignore` with Python/FastAPI patterns
  - Document environment variables in `backend/README.md`

- [✓] **T004**: Set up PostgreSQL database connection
  - Create `app/database.py` with async engine
  - Implement `get_db()` dependency
  - Configure connection pooling
  - Add database session management

- [ ] **T005**: Configure Alembic for migrations
  - Initialize Alembic: `alembic init alembic`
  - Configure `alembic.ini` with database URL
  - Update `alembic/env.py` for async support
  - Create migration template

- [✓] **T006**: Create base SQLAlchemy model
  - Create `app/models/base.py`
  - Implement `Base` declarative base
  - Add common fields (id, created_at, updated_at)
  - Add UUID primary key mixin

- [✓] **T007**: Set up FastAPI application
  - Create `app/main.py`
  - Initialize FastAPI app with metadata
  - Configure CORS middleware
  - Add exception handlers
  - Add health check endpoint

- [✓] **T008**: Configure application settings
  - Create `app/config.py`
  - Implement `Settings` class with Pydantic BaseSettings
  - Load environment variables
  - Add settings dependency

- [✓] **T009**: Set up Docker environment
  - Create `Dockerfile` for API
  - Create `docker-compose.yml` with PostgreSQL and API services
  - Configure volume mounts for development
  - Document Docker commands in README

- [✓] **T010**: Set up pytest configuration
  - Create `pytest.ini`
  - Create `tests/conftest.py` with fixtures
  - Implement `db_session` fixture
  - Implement `client` fixture (AsyncClient)
  - Implement `auth_token` fixture

---

## Phase 2: Authentication Module

### Model & Schema Tasks

- [✓] **T011**: Create User model
  - Create `app/models/user.py`
  - Define User table with fields:
    - id (UUID, PK)
    - phone_number (String, UNIQUE)
    - email (String, UNIQUE, nullable)
    - password_hash (String)
    - full_name (String)
    - avatar_url (String, nullable)
    - role (Enum: BUYER, SELLER, ADMIN)
    - is_verified (Boolean)
    - is_suspended (Boolean)
    - created_at, updated_at
  - Add indexes on phone_number and email

- [✓] **T012**: Create User schemas
  - Create `app/schemas/user.py`
  - Define `UserCreate` (input)
  - Define `UserResponse` (output)
  - Define `UserUpdate` (partial update)
  - Define `UserRole` enum

- [✓] **T013**: Create Auth schemas
  - Create `app/schemas/auth.py`
  - Define `RegisterRequest`
  - Define `LoginRequest`
  - Define `TokenResponse` (access_token, refresh_token)
  - Define `OTPVerifyRequest`
  - Define `PasswordResetRequest`

- [ ] **T014**: Create initial database migration
  - Run `alembic revision --autogenerate -m "Create users table"`
  - Review generated migration
  - Test migration: `alembic upgrade head`
  - Test rollback: `alembic downgrade -1`

### Core Implementation Tasks

- [✓] **T015**: Implement password hashing utilities
  - Create `app/core/security.py`
  - Implement `hash_password(password: str) -> str`
  - Implement `verify_password(plain: str, hashed: str) -> bool`
  - Use passlib with bcrypt

- [✓] **T016**: Implement JWT token utilities
  - In `app/core/security.py`
  - Implement `create_access_token(user_id: str, role: str) -> str`
  - Implement `create_refresh_token(user_id: str) -> str`
  - Implement `decode_token(token: str) -> dict`
  - Handle token expiration

- [✓] **T017**: Create authentication dependencies
  - Create `app/dependencies.py`
  - Implement `get_current_user(token: str) -> User` dependency
  - Implement `require_seller(user: User) -> User` dependency
  - Implement `require_admin(user: User) -> User` dependency
  - Add HTTPBearer security scheme

- [✓] **T018**: Create User repository
  - Create `app/repositories/base.py` with BaseRepository
  - Create `app/repositories/user.py`
  - Implement `get_by_phone(phone: str) -> User | None`
  - Implement `get_by_email(email: str) -> User | None`
  - Implement `get_by_id(user_id: UUID) -> User | None`
  - Implement `create(user: User) -> User`
  - Implement `update(user: User) -> User`

- [✓] **T019**: Create OTP utility
  - Create `app/utils/otp.py`
  - Implement `generate_otp() -> str` (6 digits)
  - Implement `store_otp(phone: str, otp: str)` (in-memory for now)
  - Implement `verify_otp(phone: str, otp: str) -> bool`
  - Add 5-minute expiration

- [✓] **T020**: Implement Auth service
  - Create `app/services/auth.py`
  - Implement `register_user(phone, password, name) -> UserResponse`
  - Implement `verify_otp(phone, otp) -> TokenResponse`
  - Implement `login(phone, password) -> TokenResponse`
  - Implement `refresh_token(refresh_token) -> TokenResponse`
  - Implement `forgot_password(phone) -> None`
  - Implement `reset_password(phone, otp, new_password) -> None`
  - Add validation for Vietnamese phone numbers

- [✓] **T021**: Create Auth API routes
  - Create `app/api/v1/auth.py`
  - Implement `POST /auth/register`
  - Implement `POST /auth/verify-otp`
  - Implement `POST /auth/login`
  - Implement `POST /auth/logout`
  - Implement `POST /auth/refresh`
  - Implement `POST /auth/forgot-password`
  - Implement `POST /auth/reset-password`

- [✓] **T022**: Create main API router
  - Create `app/api/v1/router.py`
  - Include auth router with prefix `/auth`
  - Mount v1 router in `app/main.py` with prefix `/api/v1`

### Testing Tasks

- [✓] **T023**: Write unit tests for security utilities
  - Create `tests/unit/core/test_security.py`
  - Test password hashing and verification
  - Test JWT token creation and decoding
  - Test token expiration

- [✓] **T024**: Write unit tests for Auth service
  - Create `tests/unit/services/test_auth.py`
  - Test user registration
  - Test OTP verification
  - Test login with valid credentials
  - Test login with invalid credentials
  - Test password reset flow

- [✓] **T025**: Write integration tests for Auth endpoints
  - Create `tests/integration/api/test_auth.py`
  - Test registration flow (POST /auth/register)
  - Test OTP verification flow
  - Test login flow
  - Test token refresh flow
  - Test password reset flow

---

## Phase 3: User Profile & Address Module ✅

### Model & Schema Tasks

- [✓] **T026**: Create Address model
  - Create `app/models/address.py`
  - Define Address table with fields:
    - id (UUID, PK)
    - user_id (UUID, FK → users.id)
    - recipient_name (String)
    - phone_number (String)
    - street_address (Text)
    - ward (String)
    - district (String)
    - city (String)
    - is_default (Boolean)
    - created_at, updated_at
  - Add index on user_id
  - Add foreign key relationship to User
  - Add cascade delete on user deletion

- [✓] **T027**: Create Address schemas
  - Create `app/schemas/address.py`
  - Define `AddressCreate`
  - Define `AddressUpdate`
  - Define `AddressResponse`
  - Define `AddressListResponse`
  - Add validation for Vietnamese addresses
  - Add Vietnamese phone number validation (10 digits, starts with 0)

- [✓] **T028**: Create database migration for addresses
  - Run `alembic revision --autogenerate -m "Create addresses table"`
  - Review and apply migration (ID: 1057f9b17e36)
  - Database migration applied successfully

### Core Implementation Tasks

- [✓] **T029**: Create Address repository
  - Create `app/repositories/address.py`
  - Implement `list_by_user(user_id: UUID) -> List[Address]`
  - Implement `get_by_id_and_user(address_id, user_id) -> Address | None`
  - Implement `get_default_address(user_id) -> Address | None`
  - Implement `unset_all_defaults(user_id) -> None`
  - Implement `set_default(user_id: UUID, address_id: UUID) -> None`
  - Implement `delete_by_id_and_user(address_id, user_id) -> None`
  - Implement `count_by_user(user_id) -> int`
  - All operations include user ownership validation

- [✓] **T030**: Implement User service
  - Create `app/services/user.py`
  - Implement `get_profile(user_id: UUID) -> UserResponse`
  - Implement `update_profile(user_id, data) -> UserResponse`
  - Implement `upload_avatar(user_id, file) -> str` (placeholder)
  - Add email uniqueness validation
  - Add file type and size validation (image, 5MB max)

- [✓] **T031**: Implement Address service
  - Create `app/services/address.py`
  - Implement `list_addresses(user_id) -> List[AddressResponse]`
  - Implement `get_address(user_id, address_id) -> AddressResponse`
  - Implement `create_address(user_id, data) -> AddressResponse`
  - Implement `update_address(user_id, address_id, data) -> AddressResponse`
  - Implement `delete_address(user_id, address_id) -> None`
  - Implement `set_default_address(user_id, address_id) -> AddressResponse`
  - Ensure only one default address per user (atomic operation)
  - First address is automatically set as default
  - Cannot delete last address (validation)
  - Auto-assign new default when deleting current default

- [✓] **T032**: Create Profile API routes
  - Create `app/api/v1/users.py`
  - Implement `GET /users/profile` - Get current user profile
  - Implement `PUT /users/profile` - Update profile
  - Implement `POST /users/profile/avatar` - Upload avatar
  - Implement `GET /users/profile/addresses` - List addresses
  - Implement `POST /users/profile/addresses` - Create address
  - Implement `GET /users/profile/addresses/{address_id}` - Get specific address
  - Implement `PUT /users/profile/addresses/{address_id}` - Update address
  - Implement `DELETE /users/profile/addresses/{address_id}` - Delete address
  - Implement `POST /users/profile/addresses/{address_id}/set-default` - Set default
  - All endpoints require authentication

- [✓] **T033**: Include users router in main router
  - Update `app/api/v1/router.py`
  - Include users router with prefix `/users` and tag "Users"
  - All endpoints accessible under `/api/v1/users/...`

### Testing Tasks

- [✓] **T034**: Write unit tests for Address service
  - Create `tests/unit/services/test_address_service.py`
  - Test address creation (3 tests)
  - Test default address logic (automatic first address, setting default)
  - Test address update and delete (6 tests)
  - Test validation and error handling (3 tests)
  - Test list and get operations (4 tests)
  - **16 tests total - ALL PASSING ✓**

- [✓] **T035**: Write integration tests for Profile endpoints
  - Create `tests/integration/api/test_users.py`
  - Test get profile (2 tests)
  - Test update profile (4 tests including duplicate email)
  - Test avatar upload (3 tests including validation)
  - Test address CRUD operations (15 tests)
  - Test set default address (3 tests)
  - Test authentication requirement for all endpoints
  - **29 tests created** (require local PostgreSQL test database to run)

---

## Phase 4: Shop & Seller Module ✅

### Model & Schema Tasks

- [✓] **T036**: Create Shop model
  - Create `app/models/shop.py`
  - Define Shop table with fields:
    - id (UUID, PK)
    - owner_id (UUID, FK → users.id, UNIQUE)
    - shop_name (String, UNIQUE)
    - description (Text)
    - logo_url (String)
    - cover_image_url (String)
    - business_address (Text)
    - rating (Float, default=0.0)
    - total_ratings (Integer, default=0)
    - follower_count (Integer, default=0)
    - status (Enum: PENDING, ACTIVE, SUSPENDED)
    - shipping_fee (Decimal)
    - free_shipping_threshold (Decimal, nullable)
    - created_at, updated_at
  - Add index on shop_name and status
  - Add relationship to User model with cascade delete

- [✓] **T037**: Create Shop schemas
  - Create `app/schemas/shop.py`
  - Define `ShopCreate`
  - Define `ShopUpdate`
  - Define `ShopResponse`
  - Define `ShopListResponse`
  - Define `ShopStatus` enum
  - Add validation for shop name (3-255 chars, trim whitespace)
  - Add validation for decimal precision (max 2 decimal places)

- [✓] **T038**: Create database migration for shops
  - Run `alembic revision --autogenerate -m "Create shops table"`
  - Review and apply migration (ID: 798d909b992e)
  - Database migration applied successfully

### Core Implementation Tasks

- [✓] **T039**: Create Shop repository
  - Create `app/repositories/shop.py`
  - Implement `get_by_id(shop_id: UUID) -> Shop | None`
  - Implement `get_by_owner(owner_id: UUID) -> Shop | None`
  - Implement `get_by_name(shop_name: str) -> Shop | None`
  - Implement `list_all(status, skip, limit) -> List[Shop]`
  - Implement `count_all(status) -> int`
  - Extends BaseRepository[Shop] for CRUD operations

- [✓] **T040**: Implement Shop service
  - Create `app/services/shop.py`
  - Implement `register_shop(user_id, data) -> ShopResponse`
  - Implement `get_shop(shop_id) -> ShopResponse`
  - Implement `get_my_shop(user_id) -> ShopResponse`
  - Implement `update_shop(user_id, data) -> ShopResponse`
  - Implement `list_shops(status, page, page_size) -> tuple[List, int]`
  - Validate user doesn't already have a shop
  - Update user role to SELLER after shop creation
  - Validate shop name uniqueness on create and update

- [✓] **T041**: Create Seller API routes
  - Create `app/api/v1/seller.py`
  - Implement `POST /seller/shops` (register as seller)
  - Implement `GET /seller/shops/me` (get own shop)
  - Implement `PUT /seller/shops/me` (update own shop)
  - All endpoints require authentication

- [✓] **T042**: Include seller router in main router
  - Update `app/api/v1/router.py`
  - Include seller router with prefix `/seller` and tag "Seller"
  - All endpoints accessible under `/api/v1/seller/...`

### Testing Tasks

- [✓] **T043**: Write unit tests for Shop service
  - Create `tests/unit/services/test_shop_service.py`
  - Test shop registration (5 tests including role upgrade)
  - Test duplicate shop prevention (2 tests)
  - Test user role update to SELLER (verified in registration tests)
  - Test shop update (4 tests including name uniqueness)
  - Test get shop operations (4 tests)
  - Test list shops with pagination and filters (3 tests)
  - **16 tests total - ALL PASSING ✓**

- [✓] **T044**: Write integration tests for Seller endpoints
  - Create `tests/integration/api/test_seller.py`
  - Test shop registration flow (5 tests)
  - Test get own shop (3 tests)
  - Test update shop (6 tests including validation)
  - Test authentication and authorization
  - **14 tests created** (require local PostgreSQL test database to run)

---

## Phase 5: Product & Category Module

### Model & Schema Tasks

- [ ] **T045**: Create Category model
  - Create `app/models/category.py`
  - Define Category table with fields:
    - id (UUID, PK)
    - name (String)
    - icon_url (String, nullable)
    - parent_id (UUID, FK → categories.id, nullable)
    - level (Integer, default=0)
    - sort_order (Integer, default=0)
    - is_active (Boolean, default=True)
  - Add index on parent_id
  - Add self-referential relationship

- [ ] **T046**: Create Product model
  - Create `app/models/product.py`
  - Define Product table with fields:
    - id (UUID, PK)
    - shop_id (UUID, FK → shops.id)
    - category_id (UUID, FK → categories.id)
    - title (String)
    - description (Text)
    - base_price (Decimal)
    - currency (String, default='VND')
    - total_stock (Integer, default=0)
    - images (JSON array)
    - condition (Enum: NEW, USED, REFURBISHED)
    - average_rating (Float, default=0.0)
    - total_reviews (Integer, default=0)
    - sold_count (Integer, default=0)
    - is_active (Boolean, default=True)
    - created_at, updated_at
  - Add indexes on shop_id, category_id, is_active, rating, sold_count
  - Add full-text search index on title + description

- [ ] **T047**: Create ProductVariant model
  - In `app/models/product.py`
  - Define ProductVariant table with fields:
    - id (UUID, PK)
    - product_id (UUID, FK → products.id)
    - name (String)
    - attributes (JSON)
    - sku (String, UNIQUE, nullable)
    - price (Decimal)
    - stock (Integer, default=0)
    - is_active (Boolean, default=True)
  - Add index on product_id

- [x] **T048**: Create Product schemas ✅
  - Created `app/schemas/product.py`
  - Defined `ProductCreate`, `ProductUpdate`, `ProductResponse`
  - Defined `ProductListResponse` with pagination
  - Defined `ProductVariantCreate`, `ProductVariantUpdate`, `ProductVariantResponse`
  - Defined `ProductCondition` enum
  - Defined `ProductSearchFilters` for advanced search
  - Added validation for prices, stock, title length, image limits

- [x] **T049**: Create Category schemas ✅
  - Created `app/schemas/category.py`
  - Defined `CategoryCreate`, `CategoryUpdate`, `CategoryResponse`
  - Defined `CategoryWithSubcategories` with recursive subcategories
  - Defined `CategoryTree` for hierarchical display
  - Defined `CategoryListResponse` for list endpoints

- [x] **T050**: Create database migration for categories and products ✅
  - Generated migration: `1ffce4077b14_create_categories_and_products_tables.py`
  - Created tables: categories, products, product_variants
  - Applied migration successfully
  - All indexes and foreign keys created

### Core Implementation Tasks

- [x] **T051**: Create Category repository ✅
  - Created `app/repositories/category.py`
  - Implemented `get_root_categories()` - get categories without parent
  - Implemented `get_subcategories(parent_id)` - get children of a category
  - Implemented `get_with_subcategories(category_id)` - eager load subcategories
  - Implemented `get_all_active()` - all active categories sorted
  - Implemented `get_category_tree(parent_id)` - recursive tree structure
  - Implemented `exists_by_name()` - check name uniqueness under parent

- [x] **T052**: Create Product repository ✅
  - Created `app/repositories/product.py` and `ProductVariantRepository`
  - Implemented `list_with_filters()` - comprehensive filtering and pagination
  - Implemented `get_with_variants()` - eager load product variants
  - Implemented `get_by_shop()` - list products for a shop
  - Implemented `search_autocomplete()` - title suggestions
  - Implemented `update_stock()`, `update_rating()`, `increment_sold_count()` - statistics
  - Variant repo: `get_by_product()`, `get_by_sku()`, `update_stock()`

- [x] **T053**: Implement Product service (buyer view) ✅
  - Created `app/services/product.py`
  - Implemented `list_products()` - list with filters, sort, pagination
  - Implemented `get_product_detail()` - product with variants (active only)
  - Implemented `get_product_variants()` - active variants for product
  - Implemented `search_autocomplete()` - title suggestions

- [x] **T054**: Implement Product service (seller management) ✅
  - In `app/services/product.py`
  - Implemented `create_product()` - with shop ownership validation
  - Implemented `update_product()` - with ownership check
  - Implemented `delete_product()` - with ownership check
  - Implemented `list_shop_products()` - list seller's products
  - Implemented `create_variant()`, `update_variant()`, `delete_variant()`
  - All methods validate shop ownership and active status

- [x] **T055**: Implement Category service ✅
  - Created `app/services/category.py`
  - Implemented `create_category()` - with parent validation
  - Implemented `get_category()`, `get_category_with_subcategories()`
  - Implemented `list_root_categories()`, `list_subcategories()`
  - Implemented `list_all_categories()` - all active
  - Implemented `get_category_tree()` - recursive tree structure
  - Implemented `update_category()` - with circular reference check
  - Implemented `delete_category()` - cascades to subcategories

- [x] **T056**: Create Product API routes (public) ✅
  - Created `app/api/v1/products.py`
  - Implemented `GET /products` - list with filters (category, shop, price, condition, rating, search)
  - Implemented `GET /products/search/autocomplete` - title suggestions
  - Implemented `GET /products/{id}` - product detail with variants
  - Implemented `GET /products/{id}/variants` - product variants
  - All endpoints are public (no authentication required)

- [x] **T057**: Create Category API routes ✅
  - Created `app/api/v1/categories.py`
  - Implemented `GET /categories` - list all active categories
  - Implemented `GET /categories/roots` - root categories only
  - Implemented `GET /categories/tree` - hierarchical tree structure
  - Implemented `GET /categories/{id}` - category with subcategories
  - Implemented `GET /categories/{id}/subcategories` - direct children
  - All endpoints are public (no authentication required)

- [x] **T058**: Create Product API routes (seller) ✅
  - Updated `app/api/v1/seller.py`
  - Implemented `POST /seller/products` - create product with variants
  - Implemented `GET /seller/products` - list seller's products with pagination
  - Implemented `PUT /seller/products/{id}` - update product (ownership validated)
  - Implemented `DELETE /seller/products/{id}` - delete product (ownership validated)
  - Implemented `POST /seller/products/{id}/variants` - create variant
  - Implemented `PUT /seller/variants/{id}` - update variant
  - Implemented `DELETE /seller/variants/{id}` - delete variant
  - All endpoints require seller authentication

- [x] **T059**: Include product and category routers ✅
  - Updated `app/api/v1/router.py`
  - Included `products.router` with prefix `/products`
  - Included `categories.router` with prefix `/categories`
  - Added service dependencies in `app/dependencies.py`:
    * `get_product_service()` - returns ProductService with all repos
    * `get_category_service()` - returns CategoryService

### Testing Tasks

- [x] **T060**: Write unit tests for Product service ✅
  - Created `tests/unit/services/test_product_service.py`
  - 9 test classes with ~30 test methods
  - Test product listing with filters
  - Test product search and autocomplete
  - Test product creation (seller)
  - Test product update and delete
  - Test ownership validation
  - Test variant management

- [x] **T061**: Write integration tests for Product endpoints ✅
  - Created `tests/integration/api/test_products.py`
  - Test GET /products with various filters (category, price, search, pagination, sorting)
  - Test product search and autocomplete
  - Test product detail and variants
  - Test seller product CRUD operations
  - Test authorization checks and ownership validation
  - Test variant management endpoints

---

## Phase 6: Shopping Cart Module

### Model & Schema Tasks

- [x] **T062**: Create CartItem model ✅
  - Created `app/models/cart.py`
  - Defined CartItem table with fields:
    * id (UUID, PK)
    * user_id (UUID, FK → users.id, CASCADE delete)
    * product_id (UUID, FK → products.id, CASCADE delete)
    * variant_id (UUID, FK → product_variants.id, CASCADE delete, nullable)
    * quantity (Integer, default=1)
    * added_at (created_at from BaseModel)
  - Added unique constraint on (user_id, product_id, variant_id)
  - Added index on user_id
  - Added relationships to User, Product, ProductVariant
  - Updated User model with cart_items relationship

- [x] **T063**: Create Cart schemas ✅
  - Created `app/schemas/cart.py`
  - Defined `CartItemCreate` - add item to cart
  - Defined `CartItemUpdate` - update quantity (1-999)
  - Defined `CartItemResponse` - with product details, unit_price, total_price
  - Defined `ProductSummary` and `VariantSummary` - simplified product info
  - Defined `ShopCartGroup` - items grouped by shop with subtotal
  - Defined `CartResponse` - full cart with shop grouping and totals
  - Defined `CartSyncItem` and `CartSyncRequest` - sync cart items
  - Added validation for quantity limits and unique items

- [x] **T064**: Create database migration for cart ✅
  - Generated migration: `a47db99ca9af_create_cart_items_table.py`
  - Created table: cart_items
  - Applied migration successfully
  - All indexes, constraints, and foreign keys created

### Core Implementation Tasks

- [x] **T065**: Create Cart repository ✅
  - Created `app/repositories/cart.py`
  - Implemented `list_by_user()` - get all cart items with eager loading
  - Implemented `find_item()` - find specific product/variant in cart
  - Implemented `get_with_relations()` - get cart item with product and variant
  - Implemented `clear_user_cart()` - remove all items for user
  - Implemented `delete_by_product()` - delete specific product/variant
  - Extended BaseRepository with CartRepository

- [x] **T066**: Implement Cart service ✅
  - Created `app/services/cart.py`
  - Implemented `get_cart()` - get cart with items grouped by shop
  - Implemented `add_to_cart()` - add or increment quantity with stock validation
  - Implemented `update_cart_item()` - update quantity with stock check
  - Implemented `remove_from_cart()` - remove item with ownership check
  - Implemented `sync_cart()` - sync items (guest → logged in)
  - Implemented `clear_cart()` - clear all items
  - Added `_build_cart_item_response()` - compute unit/total prices
  - Added `_group_by_shop()` - group items by shop with subtotals
  - Stock validation on add and update
  - Automatic quantity increment for existing items

- [x] **T067**: Create Cart API routes ✅
  - Created `app/api/v1/cart.py`
  - Implemented `GET /cart` - get user's cart with shop grouping
  - Implemented `POST /cart` - add item to cart
  - Implemented `PATCH /cart/items/{cart_item_id}` - update quantity
  - Implemented `DELETE /cart/items/{cart_item_id}` - remove item
  - Implemented `POST /cart/sync` - sync cart items
  - Implemented `DELETE /cart` - clear entire cart
  - All endpoints require authentication

- [x] **T068**: Include cart router in main router ✅
  - Updated `app/api/v1/router.py`
  - Included cart router with prefix `/cart`
  - Added cart service dependency in `app/dependencies.py`:
    * `get_cart_service()` - returns CartService with all repos

### Testing Tasks

- [x] **T069**: Write unit tests for Cart service ✅
  - Created `tests/unit/services/test_cart_service.py`
  - 7 test classes with ~30 test methods
  - Test add to cart (new item, existing item, with variant)
  - Test update quantity with stock validation
  - Test remove from cart with ownership check
  - Test stock validation and error handling
  - Test cart sync (guest → logged in)
  - Test clear cart

- [x] **T070**: Write integration tests for Cart endpoints ✅
  - Created `tests/integration/api/test_cart.py`
  - Test full cart flow (add, update, remove, clear)
  - Test cart sync and replace existing items
  - Test authentication requirement on all endpoints
  - Test stock validation errors
  - Test shop grouping functionality
  - Test complete cart workflow end-to-end

---

## Phase 7: Order & Checkout Module

### Model & Schema Tasks

- [x] **T071**: Create Order model ✅
  - Created `app/models/order.py`
  - Defined Order table with fields:
    * id (UUID, PK)
    * order_number (String, UNIQUE)
    * buyer_id (UUID, FK → users.id, CASCADE)
    * shop_id (UUID, FK → shops.id, CASCADE)
    * address_id (UUID, FK → addresses.id, SET NULL)
    * shipping_address (JSON snapshot)
    * status (Enum: PENDING, CONFIRMED, PACKED, SHIPPING, DELIVERED, COMPLETED, CANCELLED)
    * payment_method (Enum: COD, BANK_TRANSFER, E_WALLET)
    * payment_status (Enum: PENDING, PAID, FAILED, REFUNDED)
    * subtotal, shipping_fee, discount, total, currency
    * voucher_code, notes, cancellation_reason
    * created_at, updated_at, completed_at
  - Added composite indexes: (buyer_id, status), (shop_id, status)
  - Added relationships to buyer, shop, address, items

- [x] **T072**: Create OrderItem model ✅
  - In `app/models/order.py`
  - Defined OrderItem table with fields:
    * id (UUID, PK)
    * order_id (UUID, FK → orders.id, CASCADE)
    * product_id (UUID, FK → products.id, SET NULL)
    * variant_id (UUID, FK → product_variants.id, SET NULL)
    * product_snapshot (JSON) - immutable product data
    * variant_snapshot (JSON, nullable) - immutable variant data
    * quantity, unit_price, subtotal, currency
  - Added index on order_id
  - Added relationships to order, product, variant

- [x] **T073**: Create Order schemas ✅
  - Created `app/schemas/order.py`
  - Defined request schemas:
    * OrderItemCreate - product_id, variant_id, quantity
    * OrderCreate - items, address_id, payment_method, voucher_code, notes
    * OrderCancelRequest - reason
    * OrderStatusUpdate - status
  - Defined response schemas:
    * OrderItemResponse - with snapshots
    * OrderResponse - full order with items
    * OrderSummaryResponse - for list views
    * OrderListResponse - paginated list
    * CheckoutSummaryResponse - pre-order summary
  - Defined enums: OrderStatus, PaymentMethod, PaymentStatus
  - Updated `app/schemas/__init__.py` with exports

- [x] **T074**: Create database migration for orders ✅
  - Generated migration: `ca608a4c3040_create_orders_and_order_items_tables.py`
  - Applied migration with `alembic upgrade head`
  - Created tables: orders, order_items
  - Created indexes: buyer_id, shop_id, status, order_number, composite indexes

### Core Implementation Tasks

- [x] **T075**: Create Order repository ✅
  - Created `app/repositories/order.py`
  - OrderRepository methods:
    * `get_by_order_number(order_number)` - find by order number
    * `get_with_items(order_id)` - load with items, buyer, shop
    * `list_by_buyer(buyer_id, status, pagination)` - buyer's orders with filtering
    * `list_by_shop(shop_id, status, pagination)` - shop's orders with filtering
    * Inherited from BaseRepository: create, update, get, delete
  - OrderItemRepository methods:
    * `list_by_order(order_id)` - get all items for order
    * Inherited from BaseRepository: create, update, get, delete
  - Both repositories support eager loading with joinedload/selectinload

- [x] **T076**: Implement Order service (buyer) ✅
  - Created `app/services/order.py`
  - Implemented `create_orders()` - create orders from cart
    * Validates stock availability
    * Groups items by shop (one order per shop)
    * Creates product/variant snapshots (immutable)
    * Calculates totals (subtotal, shipping, discount)
    * Decrements product stock atomically
    * Clears cart after successful order creation
    * Generates unique order_number (ORD-YYYYMMDD-XXXXXX)
  - Implemented `list_orders()` - list with filters and pagination
  - Implemented `get_order_detail()` - order detail with ownership check
  - Implemented `cancel_order()` - cancel with stock restoration
    * Only PENDING/CONFIRMED orders can be cancelled
    * Restores stock for cancelled items

- [x] **T077**: Implement Order service (seller) ✅
  - In `app/services/order.py`
  - Implemented `list_shop_orders()` - list shop orders with filters
  - Implemented `get_shop_order_detail()` - shop order detail with ownership check
  - Implemented `update_order_status()` - update with transition validation
    * Valid transitions: PENDING → CONFIRMED → PACKED → SHIPPING → DELIVERED → COMPLETED
    * Can cancel from PENDING or CONFIRMED
    * Auto-set completed_at and payment_status on COMPLETED
  - Helper: `_is_valid_status_transition()` - validates state machine
  - Helper: `_generate_order_number()` - generates unique order numbers
  - Helper: `_build_order_response()` / `_build_order_summary()` - response builders

- [x] **T078**: Create Order API routes (buyer) ✅
  - Created `app/api/v1/orders.py`
  - Implemented `POST /orders` - create orders from cart
    * Validates shipping address ownership
    * Creates multiple orders for multi-shop carts
    * Returns list of created orders
  - Implemented `GET /orders` - list user orders with status filter
  - Implemented `GET /orders/{order_id}` - order detail
  - Implemented `POST /orders/{order_id}/cancel` - cancel order
  - All endpoints require authentication

- [x] **T079**: Create Order API routes (seller) ✅
  - Updated `app/api/v1/seller.py`
  - Implemented `GET /seller/orders` - list shop orders with status filter
  - Implemented `GET /seller/orders/{order_id}` - shop order detail
  - Implemented `PATCH /seller/orders/{order_id}/status` - update order status
    * Validates status transitions
    * Requires shop ownership
  - All endpoints require seller authentication

- [x] **T080**: Include orders router in main router ✅
  - Updated `app/api/v1/router.py`
  - Included orders router with prefix `/orders`
  - Added order service dependency in `app/dependencies.py`:
    * `get_order_service()` - returns OrderService with all repos and db session

### Testing Tasks

- [x] **T081**: Write unit tests for Order service ✅
  - Created `tests/unit/services/test_order_service.py`
  - 6 test classes with ~20 test methods
  - Test order creation (single shop, multi-shop scenarios)
  - Test stock validation and error handling
  - Test order listing with filters
  - Test order detail retrieval
  - Test order cancellation with stock restoration
  - Test seller order management (list, detail, status update)
  - Test status transition validation
  - Mock all repositories and database

- [x] **T082**: Write integration tests for Order endpoints ✅
  - Created `tests/integration/api/test_orders.py`
  - 7 test classes with complete workflow tests
  - Test full checkout flow (create, list, view, cancel)
  - Test order listing and filtering by status
  - Test order cancellation with stock restoration verification
  - Test seller order management endpoints
  - Test status update validation and transitions
  - Test complete order lifecycle: PENDING → CONFIRMED → PACKED → SHIPPING → DELIVERED → COMPLETED
  - Test authentication and authorization on all endpoints

---

## Phase 8: Voucher Module ✅ COMPLETE

### Model & Schema Tasks

- [x] **T083**: Create Voucher model ✅ 2025-01-XX
  - Create `app/models/voucher.py`
  - Define Voucher table with fields:
    - id (UUID, PK)
    - shop_id (UUID, FK → shops.id)
    - code (String, UNIQUE)
    - title (String)
    - description (Text, nullable)
    - type (Enum: PERCENTAGE, FIXED_AMOUNT)
    - value (Decimal)
    - min_order_value (Decimal, nullable)
    - max_discount (Decimal, nullable)
    - usage_limit (Integer, nullable)
    - usage_count (Integer, default=0)
    - start_date, end_date
    - is_active (Boolean)
  - Add index on shop_id and code

- [x] **T084**: Create Voucher schemas ✅ 2025-01-XX
  - Create `app/schemas/voucher.py`
  - Define `VoucherCreate`
  - Define `VoucherUpdate`
  - Define `VoucherResponse`
  - Define `VoucherValidateRequest`
  - Define `VoucherValidateResponse`
  - Define `VoucherType` enum

- [x] **T085**: Create database migration for vouchers ✅ 2025-01-XX
  - Run `alembic revision --autogenerate -m "Create vouchers table"`
  - Review and apply migration

### Core Implementation Tasks

- [x] **T086**: Create Voucher repository ✅ 2025-01-XX
  - Create `app/repositories/voucher.py`
  - Implement `get_by_id(voucher_id: UUID) -> Voucher | None`
  - Implement `get_by_code(code: str) -> Voucher | None`
  - Implement `list_by_shop(shop_id: UUID) -> List[Voucher]`
  - Implement `get_available_for_order(shop_id, subtotal) -> List[Voucher]`
  - Implement `create(voucher: Voucher) -> Voucher`
  - Implement `update(voucher: Voucher) -> Voucher`
  - Implement `increment_usage(voucher_id: UUID) -> None`

- [x] **T087**: Implement Voucher service ✅ 2025-01-XX
  - Create `app/services/voucher.py`
  - Implement `validate_voucher(code, shop_id, subtotal) -> VoucherValidateResponse`
    - Check if active
    - Check date range
    - Check usage limit
    - Check min order value
  - Implement `calculate_discount(voucher, subtotal) -> Decimal`
  - Implement `get_available_vouchers(shop_id, subtotal) -> List[VoucherResponse]`
  - Implement `create_voucher(shop_id, data) -> VoucherResponse` (seller)
  - Implement `update_voucher(shop_id, voucher_id, data) -> VoucherResponse`
  - Implement `list_shop_vouchers(shop_id) -> List[VoucherResponse]`

- [x] **T088**: Create Voucher API routes (buyer) ✅ 2025-01-XX
  - Create `app/api/v1/vouchers.py`
  - Implement `POST /vouchers/validate`
  - Implement `GET /vouchers/available?shop_id=...&subtotal=...`
  - Add authentication

- [x] **T089**: Create Voucher API routes (seller) ✅ 2025-01-XX
  - Update `app/api/v1/seller.py`
  - Implement `POST /seller/vouchers`
  - Implement `GET /seller/vouchers`
  - Implement `PUT /seller/vouchers/{voucher_id}`
  - Add seller authentication

- [x] **T090**: Include vouchers router in main router ✅ 2025-01-XX
  - Update `app/api/v1/router.py`
  - Include vouchers router with prefix `/vouchers`

### Testing Tasks

- [x] **T091**: Write unit tests for Voucher service ✅ 2025-01-XX
  - Create `tests/unit/services/test_voucher.py`
  - Test voucher validation
  - Test discount calculation (percentage and fixed)
  - Test usage limit enforcement
  - Test min order value check

- [x] **T092**: Write integration tests for Voucher endpoints ✅ 2025-01-XX
  - Create `tests/integration/api/test_vouchers.py`
  - Test voucher validation endpoint
  - Test get available vouchers
  - Test seller voucher creation
  - Test voucher usage in order creation

---

## Phase 9: Review & Rating Module

### Model & Schema Tasks

- [ ] **T093**: Create Review model
  - Create `app/models/review.py`
  - Define Review table with fields:
    - id (UUID, PK)
    - product_id (UUID, FK → products.id)
    - user_id (UUID, FK → users.id)
    - order_id (UUID, FK → orders.id)
    - rating (Integer, 1-5)
    - content (Text, nullable)
    - images (JSON array, nullable)
    - is_verified_purchase (Boolean, default=True)
    - is_visible (Boolean, default=True)
    - created_at, updated_at
  - Add unique constraint on (user_id, product_id)
  - Add indexes on product_id and user_id

- [ ] **T094**: Create Review schemas
  - Create `app/schemas/review.py`
  - Define `ReviewCreate`
  - Define `ReviewUpdate`
  - Define `ReviewResponse`
  - Define `ReviewListResponse` with pagination

- [ ] **T095**: Create database migration for reviews
  - Run `alembic revision --autogenerate -m "Create reviews table"`
  - Review and apply migration

### Core Implementation Tasks

- [ ] **T096**: Create Review repository
  - Create `app/repositories/review.py`
  - Implement `get_by_id(review_id: UUID) -> Review | None`
  - Implement `list_by_product(product_id, filters, pagination) -> List[Review]`
  - Implement `list_by_user(user_id) -> List[Review]`
  - Implement `find_user_review(user_id, product_id) -> Review | None`
  - Implement `create(review: Review) -> Review`
  - Implement `update(review: Review) -> Review`
  - Implement `delete(review_id: UUID) -> None`

- [ ] **T097**: Implement Review service
  - Create `app/services/review.py`
  - Implement `create_review(user_id, product_id, order_id, rating, content, images) -> ReviewResponse`
    - Validate order exists and is delivered
    - Validate product in order
    - Prevent duplicate reviews
  - Implement `get_product_reviews(product_id, filters, pagination) -> ReviewListResponse`
  - Implement `update_review(user_id, review_id, data) -> ReviewResponse`
  - Implement `delete_review(user_id, review_id) -> None`
  - Implement `update_product_rating(product_id) -> None` (recalculate average)

- [ ] **T098**: Create Review API routes
  - Update `app/api/v1/products.py`
  - Implement `GET /products/{id}/reviews`
  - Create separate reviews route if needed
  - Implement `POST /reviews`
  - Implement `PUT /reviews/{review_id}`
  - Implement `DELETE /reviews/{review_id}`
  - Add authentication for create/update/delete

### Testing Tasks

- [ ] **T099**: Write unit tests for Review service
  - Create `tests/unit/services/test_review.py`
  - Test review creation
  - Test duplicate review prevention
  - Test rating aggregation
  - Test review update and delete

- [ ] **T100**: Write integration tests for Review endpoints
  - Create `tests/integration/api/test_reviews.py`
  - Test review creation after order delivered
  - Test get product reviews
  - Test review update
  - Test authentication and ownership validation

---

## Phase 10: Notification Module

### Model & Schema Tasks

- [ ] **T101**: Create Notification model
  - Create `app/models/notification.py`
  - Define Notification table with fields:
    - id (UUID, PK)
    - user_id (UUID, FK → users.id)
    - type (Enum: ORDER_UPDATE, MESSAGE, PROMOTION, SYSTEM)
    - title (String)
    - message (Text)
    - related_entity_type (String, nullable)
    - related_entity_id (UUID, nullable)
    - is_read (Boolean, default=False)
    - created_at
  - Add indexes on user_id, is_read, created_at

- [ ] **T102**: Create Notification schemas
  - Create `app/schemas/notification.py`
  - Define `NotificationResponse`
  - Define `NotificationListResponse` with pagination
  - Define `NotificationType` enum

- [ ] **T103**: Create database migration for notifications
  - Run `alembic revision --autogenerate -m "Create notifications table"`
  - Review and apply migration

### Core Implementation Tasks

- [ ] **T104**: Create Notification repository
  - Create `app/repositories/notification.py`
  - Implement `list_by_user(user_id, pagination) -> List[Notification]`
  - Implement `get_unread_count(user_id: UUID) -> int`
  - Implement `create(notification: Notification) -> Notification`
  - Implement `mark_as_read(notification_id: UUID) -> None`
  - Implement `mark_all_as_read(user_id: UUID) -> None`

- [ ] **T105**: Implement Notification service
  - Create `app/services/notification.py`
  - Implement `create_notification(user_id, type, title, message, entity_type, entity_id) -> None`
  - Implement `get_user_notifications(user_id, pagination) -> NotificationListResponse`
  - Implement `get_unread_count(user_id) -> int`
  - Implement `mark_as_read(user_id, notification_id) -> None`
  - Implement `mark_all_as_read(user_id) -> None`

- [ ] **T106**: Integrate notifications with order status updates
  - Update `app/services/order.py`
  - Call notification service when order status changes
  - Create notifications for buyer and seller

- [ ] **T107**: Create Notification API routes
  - Create `app/api/v1/notifications.py`
  - Implement `GET /notifications`
  - Implement `GET /notifications/unread-count`
  - Implement `PATCH /notifications/{id}/read`
  - Implement `POST /notifications/mark-all-read`
  - Add authentication

- [ ] **T108**: Include notifications router
  - Update `app/api/v1/router.py`
  - Include notifications router with prefix `/notifications`

### Testing Tasks

- [ ] **T109**: Write unit tests for Notification service
  - Create `tests/unit/services/test_notification.py`
  - Test notification creation
  - Test mark as read
  - Test unread count

- [ ] **T110**: Write integration tests for Notification endpoints
  - Create `tests/integration/api/test_notifications.py`
  - Test get notifications
  - Test mark as read
  - Test notifications created on order events

---

## Phase 11: Admin Module

### Core Implementation Tasks

- [ ] **T111**: Implement Admin service
  - Create `app/services/admin.py`
  - Implement `get_platform_metrics() -> dict` (users, products, orders, revenue)
  - Implement `list_users(filters, pagination) -> List[UserResponse]`
  - Implement `suspend_user(user_id, reason) -> UserResponse`
  - Implement `unsuspend_user(user_id) -> UserResponse`
  - Implement `list_shops(filters, pagination) -> List[ShopResponse]`
  - Implement `approve_shop(shop_id) -> ShopResponse`
  - Implement `suspend_shop(shop_id, reason) -> ShopResponse`
  - Implement `list_all_products(filters, pagination) -> List[ProductResponse]`
  - Implement `moderate_product(product_id, action) -> ProductResponse`

- [ ] **T112**: Implement Category management (admin)
  - Update `app/services/category.py`
  - Implement `create_category(data) -> CategoryResponse`
  - Implement `update_category(category_id, data) -> CategoryResponse`
  - Implement `delete_category(category_id) -> None`

- [ ] **T113**: Create Admin API routes
  - Create `app/api/v1/admin.py`
  - Implement `GET /admin/dashboard`
  - Implement `GET /admin/users`
  - Implement `PATCH /admin/users/{user_id}/suspend`
  - Implement `PATCH /admin/users/{user_id}/unsuspend`
  - Implement `GET /admin/shops`
  - Implement `PATCH /admin/shops/{shop_id}/status`
  - Implement `GET /admin/products`
  - Implement `PATCH /admin/products/{product_id}/status`
  - Implement `POST /admin/categories`
  - Implement `PUT /admin/categories/{category_id}`
  - Implement `DELETE /admin/categories/{category_id}`
  - Add admin role requirement

- [ ] **T114**: Include admin router in main router
  - Update `app/api/v1/router.py`
  - Include admin router with prefix `/admin`

### Testing Tasks

- [ ] **T115**: Write unit tests for Admin service
  - Create `tests/unit/services/test_admin.py`
  - Test platform metrics
  - Test user suspension
  - Test shop approval
  - Test product moderation

- [ ] **T116**: Write integration tests for Admin endpoints
  - Create `tests/integration/api/test_admin.py`
  - Test dashboard metrics
  - Test user management
  - Test shop management
  - Test product moderation
  - Test admin role requirement

---

## Phase 12: Utilities & Polish

### Utility Tasks

- [ ] **T117**: Implement pagination utility
  - Create `app/utils/pagination.py`
  - Implement cursor-based pagination helper
  - Implement `encode_cursor(id: UUID) -> str`
  - Implement `decode_cursor(cursor: str) -> UUID`
  - Create pagination models in schemas

- [ ] **T118**: Implement image upload utility
  - Create `app/utils/storage.py`
  - Implement `upload_image(file, folder) -> str` (placeholder for S3/GCS)
  - Implement local file storage for development
  - Add file validation (size, type)

- [ ] **T119**: Implement validators
  - Create `app/utils/validators.py`
  - Implement `validate_vietnamese_phone(phone: str) -> bool`
  - Implement `validate_price(price: Decimal) -> bool`
  - Implement `validate_image_file(file) -> bool`

- [ ] **T120**: Implement custom exceptions
  - Create `app/core/exceptions.py`
  - Define `AppException` base class
  - Define `ValidationError`
  - Define `NotFoundError`
  - Define `UnauthorizedError`
  - Define `ForbiddenError`
  - Define `ConflictError`

- [ ] **T121**: Add global exception handler
  - Update `app/main.py`
  - Add exception handler for `AppException`
  - Add exception handler for validation errors
  - Add exception handler for database errors
  - Return consistent error format

- [ ] **T122**: Implement logging
  - Create `app/core/logging.py`
  - Configure structured logging
  - Add request/response logging middleware
  - Add error logging
  - Configure log levels per environment

- [ ] **T123**: Add rate limiting
  - Install `slowapi`
  - Add rate limiter to main app
  - Apply rate limits to auth endpoints (5/minute for login)
  - Apply rate limits to order creation (10/minute)
  - Configure limits in settings

- [ ] **T124**: Configure CORS properly
  - Update CORS middleware in `app/main.py`
  - Read allowed origins from settings
  - Use restrictive CORS in production

- [ ] **T125**: Add API documentation
  - Configure OpenAPI metadata in FastAPI app
  - Add descriptions to all endpoints
  - Add request/response examples
  - Group endpoints with tags
  - Document authentication scheme

### Testing Tasks

- [ ] **T126**: Write utility tests
  - Create `tests/unit/utils/test_validators.py`
  - Test phone number validation
  - Test price validation
  - Test pagination helpers

- [ ] **T127**: Write end-to-end integration tests
  - Create `tests/integration/test_e2e.py`
  - Test full user journey: register → login → browse → add to cart → checkout
  - Test seller journey: register shop → create product → receive order → update status

---

## Phase 13: Database Seeding & Scripts

### Script Tasks

- [ ] **T128**: Create database seed script
  - Create `scripts/seed_data.py`
  - Seed 10 test users (different roles)
  - Seed 5 shops
  - Seed 20 categories (2-level hierarchy)
  - Seed 100 products with variants
  - Seed 50 orders with different statuses
  - Seed 200 reviews
  - Make script idempotent (check before insert)

- [ ] **T129**: Create admin user script
  - Create `scripts/create_admin.py`
  - Prompt for admin credentials
  - Create admin user with ADMIN role
  - Verify admin created successfully

- [ ] **T130**: Create database reset script
  - Create `scripts/reset_db.py`
  - Drop all tables
  - Run migrations
  - Optionally seed data
  - Add confirmation prompt

---

## Phase 14: Documentation

### Documentation Tasks

- [ ] **T131**: Write backend README
  - Create comprehensive `backend/README.md`
  - Document setup instructions
  - Document environment variables
  - Document running locally (with/without Docker)
  - Document running tests
  - Document running migrations
  - Document API endpoints (link to Swagger)

- [ ] **T132**: Document database schema
  - Create `backend/DATABASE.md`
  - Document all tables with descriptions
  - Document relationships
  - Document indexes
  - Add ER diagram (mermaid or image)

- [ ] **T133**: Write deployment guide
  - Create `backend/DEPLOYMENT.md`
  - Document production setup steps
  - Document environment configuration
  - Document Docker deployment
  - Document database migration strategy
  - Document rollback procedures

---

## Phase 15: Production Preparation

### Production Tasks

- [ ] **T134**: Security audit
  - Review all endpoints for SQL injection vulnerabilities
  - Review authentication implementation
  - Review password hashing
  - Review JWT token security
  - Review CORS configuration
  - Review rate limiting

- [ ] **T135**: Performance optimization
  - Add database query indexes (verify with EXPLAIN)
  - Implement eager loading for relationships
  - Optimize N+1 queries
  - Test with large datasets
  - Profile slow endpoints

- [ ] **T136**: Load testing
  - Set up load testing tool (locust/k6)
  - Test product listing endpoint (100 req/s)
  - Test checkout flow (50 req/s)
  - Test search endpoint (100 req/s)
  - Identify bottlenecks

- [ ] **T137**: Set up monitoring
  - Integrate error tracking (Sentry)
  - Set up health check endpoint monitoring
  - Configure log aggregation
  - Set up database connection monitoring
  - Set up alert rules

- [ ] **T138**: Create CI/CD pipeline
  - Create GitHub Actions workflow (or similar)
  - Run tests on every commit
  - Run linters (black, flake8, mypy)
  - Build Docker image
  - Deploy to staging on merge to develop
  - Deploy to production on release tag

---

## Task Summary

**Total Tasks**: 138

**By Phase**:
- Phase 1 (Setup): 10 tasks
- Phase 2 (Auth): 15 tasks
- Phase 3 (Users): 10 tasks
- Phase 4 (Shop): 9 tasks
- Phase 5 (Products): 17 tasks
- Phase 6 (Cart): 8 tasks
- Phase 7 (Orders): 12 tasks
- Phase 8 (Vouchers): 10 tasks
- Phase 9 (Reviews): 8 tasks
- Phase 10 (Notifications): 10 tasks
- Phase 11 (Admin): 6 tasks
- Phase 12 (Utilities): 11 tasks
- Phase 13 (Scripts): 3 tasks
- Phase 14 (Documentation): 3 tasks
- Phase 15 (Production): 5 tasks

**By Type**:
- Models & Schemas: ~25 tasks
- Repositories: ~15 tasks
- Services: ~30 tasks
- API Routes: ~20 tasks
- Tests: ~25 tasks
- Utilities: ~10 tasks
- Setup & Infrastructure: ~13 tasks

**Estimated Timeline**:
- 1 developer: 8-10 weeks
- 2 developers: 5-6 weeks
- 3 developers: 4 weeks

---

## Next Steps

1. Start with **Phase 1** (T001-T010): Project setup
2. Proceed to **Phase 2** (T011-T025): Authentication
3. Continue sequentially through phases
4. Each task is atomic and can be implemented independently within its phase
5. Run tests after each module completion
6. Deploy to staging after Phase 11
7. Complete production prep (Phase 15) before production deployment

---

**End of Tasks**
