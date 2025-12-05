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

## Phase 4: Shop & Seller Module

### Model & Schema Tasks

- [ ] **T036**: Create Shop model
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
  - Add index on owner_id and status

- [ ] **T037**: Create Shop schemas
  - Create `app/schemas/shop.py`
  - Define `ShopCreate`
  - Define `ShopUpdate`
  - Define `ShopResponse`
  - Define `ShopStatus` enum

- [ ] **T038**: Create database migration for shops
  - Run `alembic revision --autogenerate -m "Create shops table"`
  - Review and apply migration

### Core Implementation Tasks

- [ ] **T039**: Create Shop repository
  - Create `app/repositories/shop.py`
  - Implement `get_by_id(shop_id: UUID) -> Shop | None`
  - Implement `get_by_owner(owner_id: UUID) -> Shop | None`
  - Implement `get_by_name(shop_name: str) -> Shop | None`
  - Implement `create(shop: Shop) -> Shop`
  - Implement `update(shop: Shop) -> Shop`
  - Implement `list_all(filters, pagination) -> List[Shop]`

- [ ] **T040**: Implement Shop service
  - Create `app/services/shop.py`
  - Implement `register_shop(user_id, data) -> ShopResponse`
  - Implement `get_shop(shop_id) -> ShopResponse`
  - Implement `get_my_shop(user_id) -> ShopResponse`
  - Implement `update_shop(user_id, data) -> ShopResponse`
  - Validate user doesn't already have a shop
  - Update user role to SELLER after shop creation

- [ ] **T041**: Create Seller API routes
  - Create `app/api/v1/seller.py`
  - Implement `POST /seller/shops` (register as seller)
  - Implement `GET /seller/shops/me`
  - Implement `PUT /seller/shops/me`
  - Add seller role requirement

- [ ] **T042**: Include seller router in main router
  - Update `app/api/v1/router.py`
  - Include seller router with prefix `/seller`

### Testing Tasks

- [ ] **T043**: Write unit tests for Shop service
  - Create `tests/unit/services/test_shop.py`
  - Test shop registration
  - Test duplicate shop prevention
  - Test user role update to SELLER
  - Test shop update

- [ ] **T044**: Write integration tests for Seller endpoints
  - Create `tests/integration/api/test_seller.py`
  - Test shop registration flow
  - Test get own shop
  - Test update shop
  - Test authentication and authorization

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

- [ ] **T048**: Create Product schemas
  - Create `app/schemas/product.py`
  - Define `ProductCreate`
  - Define `ProductUpdate`
  - Define `ProductResponse`
  - Define `ProductListResponse` with pagination
  - Define `ProductVariantCreate`
  - Define `ProductVariantResponse`
  - Define `ProductCondition` enum

- [ ] **T049**: Create Category schemas
  - Create `app/schemas/category.py`
  - Define `CategoryCreate`
  - Define `CategoryResponse` with subcategories
  - Define `CategoryTree` for hierarchical display

- [ ] **T050**: Create database migration for categories and products
  - Run `alembic revision --autogenerate -m "Create categories and products tables"`
  - Review and apply migration

### Core Implementation Tasks

- [ ] **T051**: Create Category repository
  - Create `app/repositories/category.py`
  - Implement `list_all() -> List[Category]`
  - Implement `get_by_id(category_id: UUID) -> Category | None`
  - Implement `get_root_categories() -> List[Category]`
  - Implement `get_subcategories(parent_id: UUID) -> List[Category]`
  - Implement `create(category: Category) -> Category`
  - Implement `update(category: Category) -> Category`

- [ ] **T052**: Create Product repository
  - Create `app/repositories/product.py`
  - Implement `list_with_filters(filters, pagination) -> List[Product]`
  - Implement `search(query, filters, pagination) -> List[Product]`
  - Implement `get_by_id(product_id: UUID) -> Product | None`
  - Implement `get_by_shop(shop_id: UUID) -> List[Product]`
  - Implement `create(product: Product) -> Product`
  - Implement `update(product: Product) -> Product`
  - Implement `delete(product_id: UUID) -> None`

- [ ] **T053**: Implement Product service (buyer view)
  - Create `app/services/product.py`
  - Implement `list_products(filters, sort, pagination) -> ProductListResponse`
  - Implement `search_products(query, filters, pagination) -> ProductListResponse`
  - Implement `get_product_detail(product_id) -> ProductResponse`
  - Implement `get_product_variants(product_id) -> List[ProductVariantResponse]`
  - Implement `get_autocomplete_suggestions(query) -> List[str]`

- [ ] **T054**: Implement Product service (seller management)
  - In `app/services/product.py`
  - Implement `create_product(shop_id, data) -> ProductResponse`
  - Implement `update_product(shop_id, product_id, data) -> ProductResponse`
  - Implement `delete_product(shop_id, product_id) -> None`
  - Implement `list_shop_products(shop_id, filters) -> List[ProductResponse]`
  - Validate product ownership

- [ ] **T055**: Implement Category service
  - Create `app/services/category.py`
  - Implement `list_categories() -> List[CategoryResponse]`
  - Implement `get_category_tree() -> CategoryTree`

- [ ] **T056**: Create Product API routes (public)
  - Create `app/api/v1/products.py`
  - Implement `GET /products` (list with filters)
  - Implement `GET /products/search` (keyword search)
  - Implement `GET /products/search/autocomplete`
  - Implement `GET /products/{id}` (detail)
  - Implement `GET /products/{id}/variants`
  - No authentication required

- [ ] **T057**: Create Category API routes
  - Create `app/api/v1/categories.py`
  - Implement `GET /categories`
  - No authentication required

- [ ] **T058**: Create Product API routes (seller)
  - Update `app/api/v1/seller.py`
  - Implement `POST /seller/products`
  - Implement `GET /seller/products`
  - Implement `GET /seller/products/{id}`
  - Implement `PUT /seller/products/{id}`
  - Implement `DELETE /seller/products/{id}`
  - Add seller authentication

- [ ] **T059**: Include product and category routers
  - Update `app/api/v1/router.py`
  - Include products router with prefix `/products`
  - Include categories router with prefix `/categories`

### Testing Tasks

- [ ] **T060**: Write unit tests for Product service
  - Create `tests/unit/services/test_product.py`
  - Test product listing with filters
  - Test product search
  - Test product creation (seller)
  - Test product update and delete
  - Test ownership validation

- [ ] **T061**: Write integration tests for Product endpoints
  - Create `tests/integration/api/test_products.py`
  - Test GET /products with various filters
  - Test product search
  - Test product detail
  - Test seller product CRUD
  - Test authorization checks

---

## Phase 6: Shopping Cart Module

### Model & Schema Tasks

- [ ] **T062**: Create CartItem model
  - Create `app/models/cart.py`
  - Define CartItem table with fields:
    - id (UUID, PK)
    - user_id (UUID, FK → users.id)
    - product_id (UUID, FK → products.id)
    - variant_id (UUID, FK → product_variants.id, nullable)
    - quantity (Integer)
    - added_at
  - Add unique constraint on (user_id, product_id, variant_id)
  - Add index on user_id

- [ ] **T063**: Create Cart schemas
  - Create `app/schemas/cart.py`
  - Define `CartItemCreate`
  - Define `CartItemUpdate`
  - Define `CartItemResponse` (with product details)
  - Define `CartResponse` (grouped by shop)
  - Define `CartSyncRequest`

- [ ] **T064**: Create database migration for cart
  - Run `alembic revision --autogenerate -m "Create cart_items table"`
  - Review and apply migration

### Core Implementation Tasks

- [ ] **T065**: Create Cart repository
  - Create `app/repositories/cart.py`
  - Implement `list_by_user(user_id: UUID) -> List[CartItem]`
  - Implement `get_by_id(cart_item_id: UUID) -> CartItem | None`
  - Implement `find_item(user_id, product_id, variant_id) -> CartItem | None`
  - Implement `create(cart_item: CartItem) -> CartItem`
  - Implement `update(cart_item: CartItem) -> CartItem`
  - Implement `delete(cart_item_id: UUID) -> None`
  - Implement `clear_user_cart(user_id: UUID) -> None`

- [ ] **T066**: Implement Cart service
  - Create `app/services/cart.py`
  - Implement `get_cart(user_id) -> CartResponse`
  - Implement `add_to_cart(user_id, product_id, variant_id, quantity) -> CartItemResponse`
  - Implement `update_cart_item(user_id, cart_item_id, quantity) -> CartItemResponse`
  - Implement `remove_from_cart(user_id, cart_item_id) -> None`
  - Implement `sync_cart(user_id, items) -> CartResponse`
  - Add stock validation
  - Group items by shop in response

- [ ] **T067**: Create Cart API routes
  - Create `app/api/v1/cart.py`
  - Implement `GET /cart`
  - Implement `POST /cart`
  - Implement `PATCH /cart/items/{cart_item_id}`
  - Implement `DELETE /cart/items/{cart_item_id}`
  - Implement `POST /cart/sync`
  - Add authentication requirement

- [ ] **T068**: Include cart router in main router
  - Update `app/api/v1/router.py`
  - Include cart router with prefix `/cart`

### Testing Tasks

- [ ] **T069**: Write unit tests for Cart service
  - Create `tests/unit/services/test_cart.py`
  - Test add to cart
  - Test update quantity
  - Test remove from cart
  - Test stock validation
  - Test cart sync

- [ ] **T070**: Write integration tests for Cart endpoints
  - Create `tests/integration/api/test_cart.py`
  - Test full cart flow (add, update, delete)
  - Test cart sync
  - Test authentication requirement
  - Test stock validation errors

---

## Phase 7: Order & Checkout Module

### Model & Schema Tasks

- [ ] **T071**: Create Order model
  - Create `app/models/order.py`
  - Define Order table with fields:
    - id (UUID, PK)
    - order_number (String, UNIQUE)
    - buyer_id (UUID, FK → users.id)
    - shop_id (UUID, FK → shops.id)
    - address_id (UUID, FK → addresses.id)
    - shipping_address (JSON snapshot)
    - status (Enum: PENDING, CONFIRMED, PACKED, SHIPPING, DELIVERED, COMPLETED, CANCELLED)
    - payment_method (Enum: COD, BANK_TRANSFER, E_WALLET)
    - payment_status (Enum: PENDING, PAID, FAILED, REFUNDED)
    - subtotal (Decimal)
    - shipping_fee (Decimal)
    - discount (Decimal)
    - total (Decimal)
    - currency (String)
    - voucher_code (String, nullable)
    - notes (Text, nullable)
    - cancellation_reason (Text, nullable)
    - created_at, updated_at, completed_at
  - Add indexes on buyer_id, shop_id, status, order_number

- [ ] **T072**: Create OrderItem model
  - In `app/models/order.py`
  - Define OrderItem table with fields:
    - id (UUID, PK)
    - order_id (UUID, FK → orders.id)
    - product_id (UUID, FK → products.id)
    - variant_id (UUID, FK → product_variants.id, nullable)
    - product_snapshot (JSON)
    - variant_snapshot (JSON, nullable)
    - quantity (Integer)
    - unit_price (Decimal)
    - subtotal (Decimal)
    - currency (String)
  - Add index on order_id

- [ ] **T073**: Create Order schemas
  - Create `app/schemas/order.py`
  - Define `OrderCreate`
  - Define `OrderItemCreate`
  - Define `OrderResponse`
  - Define `OrderItemResponse`
  - Define `OrderListResponse` with pagination
  - Define `OrderCancelRequest`
  - Define `OrderStatusUpdate`
  - Define enums for OrderStatus, PaymentMethod, PaymentStatus

- [ ] **T074**: Create database migration for orders
  - Run `alembic revision --autogenerate -m "Create orders and order_items tables"`
  - Review and apply migration

### Core Implementation Tasks

- [ ] **T075**: Create Order repository
  - Create `app/repositories/order.py`
  - Implement `get_by_id(order_id: UUID) -> Order | None`
  - Implement `get_by_order_number(order_number: str) -> Order | None`
  - Implement `list_by_buyer(buyer_id, filters, pagination) -> List[Order]`
  - Implement `list_by_shop(shop_id, filters, pagination) -> List[Order]`
  - Implement `create(order: Order) -> Order`
  - Implement `update(order: Order) -> Order`

- [ ] **T076**: Implement Order service (buyer)
  - Create `app/services/order.py`
  - Implement `create_orders(user_id, items, address_id, payment_method, voucher_code, notes) -> List[OrderResponse]`
    - Validate stock availability
    - Group items by shop
    - Create multiple orders for multi-shop cart
    - Create product snapshots
    - Calculate totals (subtotal, shipping, discount)
    - Decrement product stock
    - Clear cart after order creation
    - Generate unique order_number
  - Implement `list_orders(user_id, filters, pagination) -> OrderListResponse`
  - Implement `get_order_detail(user_id, order_id) -> OrderResponse`
  - Implement `cancel_order(user_id, order_id, reason) -> OrderResponse`

- [ ] **T077**: Implement Order service (seller)
  - In `app/services/order.py`
  - Implement `list_shop_orders(shop_id, filters, pagination) -> OrderListResponse`
  - Implement `get_shop_order_detail(shop_id, order_id) -> OrderResponse`
  - Implement `update_order_status(shop_id, order_id, new_status) -> OrderResponse`
  - Validate status transitions
  - Create notifications on status change

- [ ] **T078**: Create Order API routes (buyer)
  - Create `app/api/v1/orders.py`
  - Implement `POST /orders` (create from cart)
  - Implement `GET /orders` (list with filters)
  - Implement `GET /orders/{order_id}` (detail)
  - Implement `POST /orders/{order_id}/cancel`
  - Add authentication

- [ ] **T079**: Create Order API routes (seller)
  - Update `app/api/v1/seller.py`
  - Implement `GET /seller/orders`
  - Implement `GET /seller/orders/{order_id}`
  - Implement `PATCH /seller/orders/{order_id}/status`
  - Add seller authentication

- [ ] **T080**: Include orders router in main router
  - Update `app/api/v1/router.py`
  - Include orders router with prefix `/orders`

### Testing Tasks

- [ ] **T081**: Write unit tests for Order service
  - Create `tests/unit/services/test_order.py`
  - Test order creation (single shop)
  - Test order creation (multi-shop)
  - Test stock validation
  - Test order status updates
  - Test order cancellation

- [ ] **T082**: Write integration tests for Order endpoints
  - Create `tests/integration/api/test_orders.py`
  - Test full checkout flow
  - Test order listing and filtering
  - Test order cancellation
  - Test seller order management
  - Test status update validation

---

## Phase 8: Voucher Module

### Model & Schema Tasks

- [ ] **T083**: Create Voucher model
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

- [ ] **T084**: Create Voucher schemas
  - Create `app/schemas/voucher.py`
  - Define `VoucherCreate`
  - Define `VoucherUpdate`
  - Define `VoucherResponse`
  - Define `VoucherValidateRequest`
  - Define `VoucherValidateResponse`
  - Define `VoucherType` enum

- [ ] **T085**: Create database migration for vouchers
  - Run `alembic revision --autogenerate -m "Create vouchers table"`
  - Review and apply migration

### Core Implementation Tasks

- [ ] **T086**: Create Voucher repository
  - Create `app/repositories/voucher.py`
  - Implement `get_by_id(voucher_id: UUID) -> Voucher | None`
  - Implement `get_by_code(code: str) -> Voucher | None`
  - Implement `list_by_shop(shop_id: UUID) -> List[Voucher]`
  - Implement `get_available_for_order(shop_id, subtotal) -> List[Voucher]`
  - Implement `create(voucher: Voucher) -> Voucher`
  - Implement `update(voucher: Voucher) -> Voucher`
  - Implement `increment_usage(voucher_id: UUID) -> None`

- [ ] **T087**: Implement Voucher service
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

- [ ] **T088**: Create Voucher API routes (buyer)
  - Create `app/api/v1/vouchers.py`
  - Implement `POST /vouchers/validate`
  - Implement `GET /vouchers/available?shop_id=...&subtotal=...`
  - Add authentication

- [ ] **T089**: Create Voucher API routes (seller)
  - Update `app/api/v1/seller.py`
  - Implement `POST /seller/vouchers`
  - Implement `GET /seller/vouchers`
  - Implement `PUT /seller/vouchers/{voucher_id}`
  - Add seller authentication

- [ ] **T090**: Include vouchers router in main router
  - Update `app/api/v1/router.py`
  - Include vouchers router with prefix `/vouchers`

### Testing Tasks

- [ ] **T091**: Write unit tests for Voucher service
  - Create `tests/unit/services/test_voucher.py`
  - Test voucher validation
  - Test discount calculation (percentage and fixed)
  - Test usage limit enforcement
  - Test min order value check

- [ ] **T092**: Write integration tests for Voucher endpoints
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
