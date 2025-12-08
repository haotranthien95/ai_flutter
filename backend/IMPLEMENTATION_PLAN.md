# Backend Implementation Plan

**Project**: E-Commerce Marketplace API  
**Framework**: FastAPI (Python 3.11+)  
**Database**: PostgreSQL 14+  
**Created**: 2025-12-05

---

## 1. System Architecture

### 1.1 Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Application                       │
│  - CORS Middleware                                           │
│  - Exception Handlers                                        │
│  - Request/Response Logging                                  │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  API Routers  │   │  Dependencies │   │   Middleware  │
│  /api/v1/*    │   │  - Auth       │   │  - Rate Limit │
│               │   │  - Pagination │   │  - CORS       │
└───────┬───────┘   └───────────────┘   └───────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│                      Service Layer                         │
│  - Business Logic                                          │
│  - Validation                                              │
│  - Transaction Management                                  │
└───────┬───────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│                   Repository Layer                         │
│  - Data Access                                             │
│  - SQLAlchemy Queries                                      │
│  - CRUD Operations                                         │
└───────┬───────────────────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│                PostgreSQL Database                         │
│  - Users, Products, Orders, etc.                           │
└───────────────────────────────────────────────────────────┘
```

### 1.2 Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Framework | FastAPI | 0.104+ |
| ORM | SQLAlchemy | 2.0+ |
| Database | PostgreSQL | 14+ |
| DB Driver | asyncpg | Latest |
| Migrations | Alembic | Latest |
| Auth | python-jose | Latest |
| Password | passlib[bcrypt] | Latest |
| Validation | Pydantic | v2 |
| Testing | pytest, pytest-asyncio | Latest |
| Server | uvicorn/gunicorn | Latest |

---

## 2. Project Structure

```
backend/
├── alembic/                          # Database migrations
│   ├── versions/                     # Migration files
│   ├── env.py                        # Alembic configuration
│   └── script.py.mako                # Migration template
│
├── app/
│   ├── main.py                       # FastAPI app initialization
│   ├── config.py                     # Settings (environment variables)
│   ├── database.py                   # Database session management
│   ├── dependencies.py               # Common dependencies (auth, DB)
│   │
│   ├── models/                       # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── base.py                   # Base model with common fields
│   │   ├── user.py                   # User, Address
│   │   ├── shop.py                   # Shop
│   │   ├── product.py                # Product, ProductVariant, Category
│   │   ├── cart.py                   # CartItem
│   │   ├── order.py                  # Order, OrderItem
│   │   ├── voucher.py                # Voucher
│   │   ├── review.py                 # Review
│   │   └── notification.py           # Notification
│   │
│   ├── schemas/                      # Pydantic schemas
│   │   ├── __init__.py
│   │   ├── user.py                   # UserCreate, UserResponse, etc.
│   │   ├── auth.py                   # LoginRequest, TokenResponse
│   │   ├── address.py                # AddressCreate, AddressResponse
│   │   ├── shop.py                   # ShopCreate, ShopResponse
│   │   ├── product.py                # ProductCreate, ProductResponse
│   │   ├── cart.py                   # CartItemCreate, CartResponse
│   │   ├── order.py                  # OrderCreate, OrderResponse
│   │   ├── voucher.py                # VoucherCreate, VoucherResponse
│   │   ├── review.py                 # ReviewCreate, ReviewResponse
│   │   └── common.py                 # PaginationParams, ErrorResponse
│   │
│   ├── repositories/                 # Data access layer
│   │   ├── __init__.py
│   │   ├── base.py                   # BaseRepository (generic CRUD)
│   │   ├── user.py                   # UserRepository
│   │   ├── address.py                # AddressRepository
│   │   ├── shop.py                   # ShopRepository
│   │   ├── product.py                # ProductRepository
│   │   ├── cart.py                   # CartRepository
│   │   ├── order.py                  # OrderRepository
│   │   ├── voucher.py                # VoucherRepository
│   │   └── review.py                 # ReviewRepository
│   │
│   ├── services/                     # Business logic
│   │   ├── __init__.py
│   │   ├── auth.py                   # Registration, login, token management
│   │   ├── user.py                   # User profile management
│   │   ├── address.py                # Address management
│   │   ├── shop.py                   # Shop registration, management
│   │   ├── product.py                # Product CRUD, search
│   │   ├── cart.py                   # Cart operations
│   │   ├── order.py                  # Order creation, status updates
│   │   ├── voucher.py                # Voucher validation, application
│   │   ├── review.py                 # Review creation, moderation
│   │   └── notification.py           # Notification creation, delivery
│   │
│   ├── api/                          # API routes
│   │   └── v1/                       # API version 1
│   │       ├── __init__.py
│   │       ├── router.py             # Main router aggregator
│   │       ├── auth.py               # Auth endpoints
│   │       ├── users.py              # User profile endpoints
│   │       ├── products.py           # Product browsing endpoints
│   │       ├── categories.py         # Category endpoints
│   │       ├── cart.py               # Cart endpoints
│   │       ├── orders.py             # Order endpoints
│   │       ├── vouchers.py           # Voucher endpoints
│   │       ├── reviews.py            # Review endpoints
│   │       ├── seller.py             # Seller-specific endpoints
│   │       └── admin.py              # Admin endpoints
│   │
│   ├── core/                         # Core utilities
│   │   ├── __init__.py
│   │   ├── security.py               # JWT, password hashing
│   │   ├── exceptions.py             # Custom exceptions
│   │   ├── constants.py              # Enums, constants
│   │   └── config.py                 # Configuration models
│   │
│   └── utils/                        # Helper utilities
│       ├── __init__.py
│       ├── pagination.py             # Cursor-based pagination
│       ├── storage.py                # Image upload (S3/GCS)
│       ├── validators.py             # Custom validators
│       └── otp.py                    # OTP generation/validation
│
├── tests/                            # Test suite
│   ├── __init__.py
│   ├── conftest.py                   # Pytest fixtures
│   ├── unit/                         # Unit tests
│   │   ├── services/                 # Service layer tests
│   │   └── repositories/             # Repository tests
│   └── integration/                  # Integration tests
│       └── api/                      # API endpoint tests
│
├── scripts/                          # Utility scripts
│   ├── seed_data.py                  # Database seeding
│   └── create_admin.py               # Create admin user
│
├── logs/                             # Application logs (gitignored)
├── .env                              # Environment variables (gitignored)
├── .env.example                      # Environment template
├── requirements.txt                  # Python dependencies
├── requirements-dev.txt              # Development dependencies
├── alembic.ini                       # Alembic configuration
├── pytest.ini                        # Pytest configuration
├── Dockerfile                        # Docker image
├── docker-compose.yml                # Local development stack
└── README.md                         # Setup instructions
```

---

## 3. Module Breakdown

### 3.1 Auth Module (`auth.py`)

**Responsibilities**:
- User registration with phone/email
- OTP generation and verification
- Login/logout
- JWT token generation and refresh
- Password reset flow

**Key Functions**:
- `register_user(phone, password, name)` → User
- `verify_otp(phone, otp_code)` → TokenPair
- `login(phone, password)` → TokenPair + User
- `refresh_token(refresh_token)` → TokenPair
- `forgot_password(phone)` → Send OTP
- `reset_password(phone, otp, new_password)` → Success

### 3.2 Users Module (`users.py`, `address.py`)

**Responsibilities**:
- User profile management
- Address CRUD operations
- Role management

**Key Functions**:
- `get_user_profile(user_id)` → User
- `update_profile(user_id, data)` → User
- `list_addresses(user_id)` → List[Address]
- `create_address(user_id, data)` → Address
- `set_default_address(user_id, address_id)` → Address

### 3.3 Products Module (`product.py`, `categories.py`)

**Responsibilities**:
- Product browsing and search
- Product detail retrieval
- Category management
- Variant handling

**Key Functions**:
- `list_products(filters, pagination)` → PaginatedProducts
- `search_products(query, filters)` → PaginatedProducts
- `get_product_detail(product_id)` → ProductDetail
- `get_product_variants(product_id)` → List[Variant]
- `list_categories()` → List[Category]

### 3.4 Cart Module (`cart.py`)

**Responsibilities**:
- Cart item management
- Stock validation
- Cart synchronization

**Key Functions**:
- `get_cart(user_id)` → CartResponse
- `add_to_cart(user_id, product_id, variant_id, quantity)` → CartItem
- `update_cart_item(user_id, cart_item_id, quantity)` → CartItem
- `remove_from_cart(user_id, cart_item_id)` → Success
- `sync_cart(user_id, local_items)` → CartResponse

### 3.5 Orders Module (`order.py`)

**Responsibilities**:
- Order creation from cart
- Order status management
- Order history retrieval
- Cancellation handling

**Key Functions**:
- `create_order(user_id, items, address_id, payment_method, voucher)` → List[Order]
- `list_orders(user_id, filters)` → PaginatedOrders
- `get_order_detail(user_id, order_id)` → OrderDetail
- `cancel_order(user_id, order_id, reason)` → Order
- `update_order_status(order_id, new_status)` → Order (seller/admin)

### 3.6 Vouchers Module (`voucher.py`)

**Responsibilities**:
- Voucher validation
- Discount calculation
- Usage tracking

**Key Functions**:
- `validate_voucher(code, shop_id, subtotal)` → VoucherDetail
- `get_available_vouchers(shop_id, subtotal)` → List[Voucher]
- `apply_voucher(order_id, voucher_code)` → DiscountAmount

### 3.7 Reviews Module (`review.py`)

**Responsibilities**:
- Review submission
- Review retrieval and filtering
- Rating aggregation

**Key Functions**:
- `create_review(user_id, product_id, order_id, rating, content, images)` → Review
- `list_product_reviews(product_id, filters)` → PaginatedReviews
- `update_review(user_id, review_id, data)` → Review
- `moderate_review(admin_id, review_id, action)` → Review

### 3.8 Seller Module (`shop.py`, seller endpoints)

**Responsibilities**:
- Shop registration
- Product management (seller-owned)
- Order fulfillment
- Voucher creation
- Shop analytics

**Key Functions**:
- `register_shop(user_id, shop_data)` → Shop
- `update_shop(shop_id, data)` → Shop
- `create_product(shop_id, product_data)` → Product
- `update_product(shop_id, product_id, data)` → Product
- `list_shop_orders(shop_id, filters)` → PaginatedOrders
- `update_order_status(shop_id, order_id, status)` → Order
- `create_voucher(shop_id, voucher_data)` → Voucher

### 3.9 Admin Module (`admin.py`)

**Responsibilities**:
- User management
- Shop approval/suspension
- Product moderation
- Category management
- Platform analytics

**Key Functions**:
- `get_platform_metrics()` → DashboardMetrics
- `list_users(filters)` → PaginatedUsers
- `suspend_user(user_id, reason)` → User
- `list_shops(filters)` → PaginatedShops
- `approve_shop(shop_id)` → Shop
- `moderate_product(product_id, action)` → Product
- `manage_categories()` → CRUD operations

---

## 4. Database Design Summary

### 4.1 Core Tables

| Table | Primary Key | Key Foreign Keys | Purpose |
|-------|-------------|------------------|---------|
| `users` | id (UUID) | - | User accounts |
| `addresses` | id (UUID) | user_id → users | Shipping addresses |
| `shops` | id (UUID) | owner_id → users | Seller shops |
| `categories` | id (UUID) | parent_id → categories | Product categories |
| `products` | id (UUID) | shop_id → shops, category_id → categories | Product listings |
| `product_variants` | id (UUID) | product_id → products | Product variants |
| `cart_items` | id (UUID) | user_id → users, product_id → products, variant_id → product_variants | Shopping cart |
| `orders` | id (UUID) | buyer_id → users, shop_id → shops, address_id → addresses | Orders |
| `order_items` | id (UUID) | order_id → orders, product_id → products, variant_id → product_variants | Order line items |
| `vouchers` | id (UUID) | shop_id → shops | Discount codes |
| `reviews` | id (UUID) | product_id → products, user_id → users, order_id → orders | Product reviews |
| `notifications` | id (UUID) | user_id → users | User notifications |

### 4.2 Key Relationships

```
User (1) ──→ (N) Address
User (1) ──→ (1) Shop [if seller]
User (1) ──→ (N) Order [as buyer]
User (1) ──→ (N) CartItem
User (1) ──→ (N) Review

Shop (1) ──→ (N) Product
Shop (1) ──→ (N) Order [as seller]
Shop (1) ──→ (N) Voucher

Product (1) ──→ (N) ProductVariant
Product (1) ──→ (N) Review
Product (1) ──→ (N) CartItem
Product (1) ──→ (N) OrderItem

Order (1) ──→ (N) OrderItem
Order (N) ──→ (1) Address [snapshot]
Order (N) ──→ (1) Voucher [optional]

Category (1) ──→ (N) Category [self-ref]
Category (1) ──→ (N) Product
```

### 4.3 Critical Indexes

```sql
-- User lookups
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_email ON users(email);

-- Product browsing
CREATE INDEX idx_products_shop ON products(shop_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_rating ON products(average_rating DESC);
CREATE INDEX idx_products_sold ON products(sold_count DESC);
CREATE INDEX idx_products_search ON products USING GIN (to_tsvector('english', title || ' ' || description));

-- Order queries
CREATE INDEX idx_orders_buyer ON orders(buyer_id);
CREATE INDEX idx_orders_shop ON orders(shop_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at DESC);

-- Cart
CREATE INDEX idx_cart_user ON cart_items(user_id);
```

---

## 5. API Routing Structure

### 5.1 Route Organization

```python
# app/api/v1/router.py
from fastapi import APIRouter
from app.api.v1 import (
    auth, users, products, categories, cart,
    orders, vouchers, reviews, seller, admin
)

api_router = APIRouter()

# Public routes
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(products.router, prefix="/products", tags=["products"])
api_router.include_router(categories.router, prefix="/categories", tags=["categories"])

# Authenticated user routes
api_router.include_router(users.router, prefix="/profile", tags=["profile"])
api_router.include_router(cart.router, prefix="/cart", tags=["cart"])
api_router.include_router(orders.router, prefix="/orders", tags=["orders"])
api_router.include_router(vouchers.router, prefix="/vouchers", tags=["vouchers"])
api_router.include_router(reviews.router, prefix="/reviews", tags=["reviews"])

# Seller routes
api_router.include_router(seller.router, prefix="/seller", tags=["seller"])

# Admin routes
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
```

### 5.2 URL Patterns

| Module | Base Path | Example Endpoints |
|--------|-----------|-------------------|
| Auth | `/api/v1/auth` | `POST /register`, `POST /login`, `POST /refresh` |
| Profile | `/api/v1/profile` | `GET /`, `PUT /`, `GET /addresses` |
| Products | `/api/v1/products` | `GET /`, `GET /search`, `GET /{id}` |
| Categories | `/api/v1/categories` | `GET /` |
| Cart | `/api/v1/cart` | `GET /`, `POST /`, `DELETE /items/{id}` |
| Orders | `/api/v1/orders` | `POST /`, `GET /`, `GET /{id}`, `POST /{id}/cancel` |
| Vouchers | `/api/v1/vouchers` | `POST /validate`, `GET /available` |
| Reviews | `/api/v1/reviews` | `POST /`, `GET /`, `PUT /{id}` |
| Seller | `/api/v1/seller` | `POST /shops`, `POST /products`, `GET /orders` |
| Admin | `/api/v1/admin` | `GET /dashboard`, `PATCH /shops/{id}/status` |

---

## 6. Implementation Phases

### **Phase 1: Foundation Setup** (Week 1)

**Goal**: Set up project structure and core infrastructure

**Tasks**:
1. Initialize FastAPI project structure
2. Set up PostgreSQL database connection (SQLAlchemy + asyncpg)
3. Configure Alembic for migrations
4. Create base SQLAlchemy models (User, Address)
5. Implement authentication system:
   - Password hashing (bcrypt)
   - JWT token generation/validation
   - Auth dependencies (get_current_user)
6. Create base repository and service patterns
7. Set up pytest with fixtures for testing
8. Configure environment variables (.env)
9. Create Docker setup (docker-compose.yml)

**Deliverables**:
- [ ] Project structure created
- [ ] Database connection working
- [ ] Auth endpoints functional (`/auth/register`, `/auth/login`)
- [ ] Unit tests for auth service
- [ ] Docker environment running

---

### **Phase 2: User & Shop Management** (Week 2)

**Goal**: Implement user profiles and seller shop registration

**Tasks**:
1. Complete User model with profile fields
2. Implement Address CRUD (repository + service + routes)
3. Create Shop model and registration flow
4. Implement profile endpoints:
   - `GET /profile` - Get user profile
   - `PUT /profile` - Update profile
   - `GET /profile/addresses` - List addresses
   - `POST /profile/addresses` - Add address
5. Implement seller registration:
   - `POST /seller/shops` - Register as seller
   - `GET /seller/shops/me` - Get own shop
   - `PUT /seller/shops/me` - Update shop
6. Add role-based access control (BUYER, SELLER, ADMIN)
7. Write integration tests for profile and shop flows

**Deliverables**:
- [ ] User profile management working
- [ ] Address CRUD functional
- [ ] Seller shop registration implemented
- [ ] Integration tests passing

---

### **Phase 3: Product Catalog** (Week 3)

**Goal**: Build product browsing and search functionality

**Tasks**:
1. Create Category, Product, ProductVariant models
2. Implement category endpoints:
   - `GET /categories` - List all categories
3. Implement product browsing endpoints:
   - `GET /products` - List with filters (category, price, rating)
   - `GET /products/search` - Keyword search
   - `GET /products/{id}` - Product details
   - `GET /products/{id}/variants` - Get variants
4. Add full-text search (PostgreSQL tsvector)
5. Implement cursor-based pagination
6. Add seller product management:
   - `POST /seller/products` - Create product
   - `GET /seller/products` - List own products
   - `PUT /seller/products/{id}` - Update product
   - `DELETE /seller/products/{id}` - Delete product
7. Write tests for product search and filtering

**Deliverables**:
- [ ] Product catalog browsing working
- [ ] Search functionality implemented
- [ ] Seller product CRUD operational
- [ ] Pagination working

---

### **Phase 4: Shopping Cart** (Week 4)

**Goal**: Implement shopping cart functionality

**Tasks**:
1. Create CartItem model
2. Implement cart endpoints:
   - `GET /cart` - Get user's cart
   - `POST /cart` - Add item to cart
   - `PATCH /cart/items/{id}` - Update quantity
   - `DELETE /cart/items/{id}` - Remove item
   - `POST /cart/sync` - Sync local cart
3. Add stock validation logic
4. Implement cart grouping by shop (business logic)
5. Add cart persistence across sessions
6. Write unit tests for cart service
7. Write integration tests for cart flows

**Deliverables**:
- [ ] Cart CRUD functional
- [ ] Stock validation working
- [ ] Cart sync implemented
- [ ] Tests passing

---

### **Phase 5: Order & Checkout** (Week 5)

**Goal**: Implement order creation and management

**Tasks**:
1. Create Order, OrderItem models
2. Implement order creation flow:
   - `POST /orders` - Create order(s) from cart
   - Stock validation and reservation
   - Multi-shop order splitting
   - Product snapshot creation
3. Implement order endpoints:
   - `GET /orders` - List user orders
   - `GET /orders/{id}` - Get order details
   - `POST /orders/{id}/cancel` - Cancel order
4. Add order status management:
   - `PATCH /seller/orders/{id}/status` - Update status (seller)
   - Status validation (state machine)
5. Implement voucher system:
   - Voucher model
   - `POST /vouchers/validate` - Validate voucher
   - `GET /vouchers/available` - List available vouchers
6. Add seller order management:
   - `GET /seller/orders` - List shop orders
   - `GET /seller/orders/{id}` - Order details
7. Write comprehensive tests for checkout flow

**Deliverables**:
- [ ] Order creation functional
- [ ] Multi-shop orders working
- [ ] Order status updates implemented
- [ ] Voucher validation working
- [ ] Checkout flow tests passing

---

### **Phase 6: Reviews & Notifications** (Week 6)

**Goal**: Add review system and notifications

**Tasks**:
1. Create Review model
2. Implement review endpoints:
   - `POST /reviews` - Create review (verified purchase)
   - `GET /products/{id}/reviews` - List product reviews
   - `PUT /reviews/{id}` - Edit review
3. Add rating aggregation logic (update product.average_rating)
4. Create Notification model
5. Implement notification creation on events:
   - Order status changes
   - New orders (for sellers)
   - Review submissions
6. Add notification endpoints:
   - `GET /notifications` - List user notifications
   - `PATCH /notifications/{id}/read` - Mark as read
7. Write tests for review and notification flows

**Deliverables**:
- [ ] Review system functional
- [ ] Rating aggregation working
- [ ] Notifications created on events
- [ ] Tests passing

---

### **Phase 7: Admin Panel** (Week 7)

**Goal**: Build admin management interface

**Tasks**:
1. Implement admin endpoints:
   - `GET /admin/dashboard` - Platform metrics
   - `GET /admin/users` - List users with filters
   - `PATCH /admin/users/{id}/suspend` - Suspend user
   - `GET /admin/shops` - List shops
   - `PATCH /admin/shops/{id}/status` - Approve/suspend shop
   - `GET /admin/products` - List all products
   - `PATCH /admin/products/{id}/status` - Moderate product
   - `POST /admin/categories` - Create category
2. Add admin role validation (require_admin dependency)
3. Implement shop approval workflow
4. Add content moderation features
5. Write admin integration tests

**Deliverables**:
- [ ] Admin dashboard working
- [ ] User/shop management functional
- [ ] Content moderation implemented
- [ ] Tests passing

---

### **Phase 8: Polish & Production Prep** (Week 8)

**Goal**: Prepare for production deployment

**Tasks**:
1. Add rate limiting (slowapi)
2. Implement comprehensive logging
3. Add error tracking setup (Sentry integration)
4. Optimize database queries (eager loading, indexes)
5. Add API documentation (OpenAPI/Swagger UI)
6. Set up image upload to S3/GCS
7. Configure CORS for production
8. Create deployment scripts
9. Write deployment documentation
10. Perform load testing
11. Security audit (SQL injection, XSS, etc.)
12. Create database backup strategy

**Deliverables**:
- [ ] Rate limiting active
- [ ] Logging comprehensive
- [ ] API docs complete
- [ ] Image upload working
- [ ] Production config ready
- [ ] Load tests passed
- [ ] Security audit complete

---

## 7. Testing Strategy

### 7.1 Unit Tests

**Target**: Service and repository layers

**Coverage**: >80%

**Example**:
```python
# tests/unit/services/test_auth.py
@pytest.mark.asyncio
async def test_register_user():
    mock_repo = AsyncMock()
    service = AuthService(mock_repo)
    
    result = await service.register_user(
        phone="+84901234567",
        password="SecurePass123",
        full_name="Test User"
    )
    
    assert result.phone_number == "+84901234567"
    assert result.is_verified == False
    mock_repo.create.assert_called_once()
```

### 7.2 Integration Tests

**Target**: API endpoints (end-to-end)

**Coverage**: All critical user flows

**Example**:
```python
# tests/integration/api/test_checkout.py
@pytest.mark.asyncio
async def test_checkout_flow(client, auth_token):
    # Add item to cart
    response = await client.post(
        "/api/v1/cart",
        json={"product_id": "uuid", "quantity": 2},
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    
    # Create order
    response = await client.post(
        "/api/v1/orders",
        json={
            "items": [{"product_id": "uuid", "quantity": 2}],
            "address_id": "uuid",
            "payment_method": "COD"
        },
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    assert "orders" in response.json()
```

### 7.3 Test Database

- Use separate test database: `marketplace_test`
- Reset database before each test suite
- Use fixtures for common test data
- Mock external services (SMS, cloud storage)

### 7.4 Test Execution

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/unit/services/test_auth.py

# Run integration tests only
pytest tests/integration/
```

---

## 8. Deployment Strategy

### 8.1 Environment Configuration

#### **Development** (`dev`)
- Local PostgreSQL database
- Mock external services (SMS, cloud storage)
- Debug logging enabled
- Hot reload enabled
- CORS: Allow all origins

#### **Staging** (`staging`)
- Cloud PostgreSQL (e.g., AWS RDS)
- Real external services with test credentials
- Info logging
- HTTPS enforced
- CORS: Specific staging domain

#### **Production** (`prod`)
- Cloud PostgreSQL with read replicas
- Production external services
- Error logging only
- HTTPS enforced
- Rate limiting strict
- CORS: Production domain only

### 8.2 Environment Variables

**.env.example**:
```env
# App
ENVIRONMENT=development
DEBUG=true
SECRET_KEY=your-secret-key-here
API_V1_PREFIX=/api/v1

# Database
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/marketplace
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=0

# JWT
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
ALGORITHM=HS256

# CORS
CORS_ORIGINS=["http://localhost:3000"]

# AWS S3
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_S3_BUCKET=marketplace-images
AWS_REGION=us-east-1

# SMS Service
SMS_API_KEY=your-sms-api-key
SMS_API_URL=https://api.sms-service.com

# Rate Limiting
RATE_LIMIT_PER_MINUTE=60

# Logging
LOG_LEVEL=INFO
```

### 8.3 Docker Deployment

**Dockerfile**:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Run migrations on startup (use init script in production)
CMD alembic upgrade head && \
    gunicorn app.main:app \
    --workers 4 \
    --worker-class uvicorn.workers.UvicornWorker \
    --bind 0.0.0.0:8000 \
    --log-level info
```

**docker-compose.yml** (local development):
```yaml
version: '3.8'

services:
  db:
    image: postgres:14
    environment:
      POSTGRES_DB: marketplace
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql+asyncpg://postgres:postgres@db:5432/marketplace
      DEBUG: "true"
    depends_on:
      - db
    volumes:
      - .:/app
    command: uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

volumes:
  postgres_data:
```

### 8.4 Deployment Checklist

**Pre-Deployment**:
- [ ] All tests passing
- [ ] Environment variables configured
- [ ] Database migrations tested
- [ ] Security audit completed
- [ ] Load testing passed
- [ ] API documentation updated

**Production Setup**:
- [ ] PostgreSQL database provisioned
- [ ] SSL/TLS certificates configured
- [ ] Reverse proxy (Nginx) configured
- [ ] Rate limiting enabled
- [ ] Logging aggregation set up
- [ ] Monitoring/alerting configured
- [ ] Database backups automated
- [ ] CI/CD pipeline configured

**Post-Deployment**:
- [ ] Health check endpoint responding
- [ ] Database migrations applied
- [ ] Admin user created
- [ ] Seed data loaded (if needed)
- [ ] API accessible via HTTPS
- [ ] Monitoring dashboards verified

### 8.5 Database Migration Strategy

**Development**:
```bash
# Create new migration
alembic revision --autogenerate -m "Add new column"

# Apply migrations
alembic upgrade head
```

**Production**:
```bash
# 1. Backup database
pg_dump marketplace > backup_$(date +%Y%m%d).sql

# 2. Test migrations on staging
alembic upgrade head

# 3. If successful, apply to production
alembic upgrade head

# 4. Verify application health
curl https://api.yourdomain.com/health
```

### 8.6 Rollback Strategy

```bash
# Rollback last migration
alembic downgrade -1

# Rollback to specific version
alembic downgrade <revision_id>

# Restore database from backup (if needed)
psql marketplace < backup_20251205.sql
```

---

## 9. Performance Optimization

### 9.1 Database Optimizations

- **Indexes**: Create on frequently queried columns (user lookups, product search)
- **Connection Pooling**: Configure SQLAlchemy pool size (20-50 connections)
- **Query Optimization**: Use `joinedload` for eager loading relationships
- **Read Replicas**: For heavy read operations (product browsing)

### 9.2 Caching Strategy (Future)

- **Redis**: Cache product listings, categories, shop info
- **Cache TTL**: 5-15 minutes for dynamic content
- **Cache Invalidation**: On product updates, order creation

### 9.3 API Response Optimization

- **Pagination**: Cursor-based for large datasets
- **Field Selection**: Allow clients to request specific fields
- **Response Compression**: Enable gzip compression
- **CDN**: Serve images through CDN (CloudFront, Cloudflare)

---

## 10. Monitoring & Observability

### 10.1 Logging

- **Structured Logging**: JSON format for easy parsing
- **Log Levels**: DEBUG (dev), INFO (staging), ERROR (prod)
- **Log Aggregation**: Send to centralized system (ELK, CloudWatch)

### 10.2 Metrics

- **Application Metrics**:
  - Request rate (requests/second)
  - Response time (p50, p95, p99)
  - Error rate (%)
  - Active users
  
- **Business Metrics**:
  - Orders created per hour
  - Products listed
  - Active sellers
  - Revenue (total)

### 10.3 Health Checks

```python
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "version": "1.0.0",
        "database": await check_db_connection(),
        "timestamp": datetime.utcnow()
    }
```

---

## 11. Security Checklist

- [ ] JWT secret key is strong (32+ bytes)
- [ ] Passwords hashed with bcrypt
- [ ] SQL injection prevented (parameterized queries)
- [ ] Rate limiting enabled
- [ ] CORS configured properly
- [ ] HTTPS enforced in production
- [ ] Environment variables not committed
- [ ] Input validation on all endpoints
- [ ] Authentication required for protected routes
- [ ] Role-based access control implemented
- [ ] File upload validation (size, type)
- [ ] Sensitive data not logged

---

## 12. Next Steps

1. **Week 1**: Start Phase 1 - Set up project structure and authentication
2. **Week 2**: Complete Phase 2 - User and shop management
3. **Week 3**: Implement Phase 3 - Product catalog
4. **Week 4**: Build Phase 4 - Shopping cart
5. **Week 5**: Develop Phase 5 - Order and checkout
6. **Week 6**: Add Phase 6 - Reviews and notifications
7. **Week 7**: Create Phase 7 - Admin panel
8. **Week 8**: Polish and prepare for production (Phase 8)

**Estimated Total Time**: 8 weeks (1 developer, full-time)

**Adjustment for Team**: With 2-3 developers, timeline can be reduced to 4-5 weeks

---

**End of Implementation Plan**
