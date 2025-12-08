# Backend Specification: E-Commerce Marketplace API

**Version**: 1.0.0  
**Created**: 2025-12-05  
**Framework**: FastAPI (Python 3.11+)  
**Database**: PostgreSQL 14+  
**ORM**: SQLAlchemy 2.0 (async)

---

## 1. Architecture Overview

### 1.1 Layered Design

```
┌─────────────────────────────────────────┐
│  FastAPI Application (main.py)          │
│  - CORS middleware                       │
│  - Exception handlers                    │
│  - Lifespan events                       │
└─────────────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
┌───────▼────────┐  ┌──────▼────────┐
│  API Routers   │  │  Middleware   │
│  /api/v1/*     │  │  - Auth       │
│                │  │  - Rate limit │
└───────┬────────┘  └───────────────┘
        │
┌───────▼────────┐
│  Services      │
│  Business logic│
│  Validation    │
└───────┬────────┘
        │
┌───────▼────────┐
│  Repositories  │
│  DB operations │
│  SQLAlchemy    │
└───────┬────────┘
        │
┌───────▼────────┐
│  PostgreSQL    │
└────────────────┘
```

### 1.2 Technology Stack

- **FastAPI 0.104+**: Async web framework
- **SQLAlchemy 2.0+**: Async ORM with declarative models
- **asyncpg**: PostgreSQL async driver
- **Alembic**: Database migrations
- **Pydantic v2**: Request/response validation
- **python-jose**: JWT token handling
- **passlib[bcrypt]**: Password hashing
- **httpx**: HTTP client (for payment gateways)
- **pytest + pytest-asyncio**: Testing
- **uvicorn**: ASGI server

### 1.3 Project Structure

```
backend/
├── alembic/                 # Database migrations
│   ├── versions/
│   └── env.py
├── app/
│   ├── main.py             # FastAPI app entry
│   ├── config.py           # Settings (env vars)
│   ├── database.py         # DB session management
│   ├── dependencies.py     # Common dependencies (auth, pagination)
│   ├── models/             # SQLAlchemy models
│   │   ├── user.py
│   │   ├── product.py
│   │   ├── order.py
│   │   └── ...
│   ├── schemas/            # Pydantic schemas
│   │   ├── user.py
│   │   ├── product.py
│   │   └── ...
│   ├── repositories/       # Data access layer
│   │   ├── base.py
│   │   ├── user.py
│   │   ├── product.py
│   │   └── ...
│   ├── services/           # Business logic
│   │   ├── auth.py
│   │   ├── product.py
│   │   ├── order.py
│   │   └── ...
│   ├── api/
│   │   └── v1/
│   │       ├── router.py   # Main router
│   │       ├── auth.py
│   │       ├── products.py
│   │       ├── cart.py
│   │       ├── orders.py
│   │       ├── profile.py
│   │       ├── seller.py
│   │       └── admin.py
│   ├── core/
│   │   ├── security.py     # JWT, password hashing
│   │   ├── exceptions.py   # Custom exceptions
│   │   └── constants.py    # Enums, constants
│   └── utils/
│       ├── pagination.py
│       ├── storage.py      # Image upload helper
│       └── validators.py
├── tests/
│   ├── unit/
│   └── integration/
├── requirements.txt
├── .env.example
└── README.md
```

---

## 2. Domain Model

### 2.1 Core Entities

#### **User**
```python
class User(Base):
    id: UUID (PK)
    phone_number: str (UNIQUE, NOT NULL)
    email: str (UNIQUE, NULLABLE)
    password_hash: str (NOT NULL)
    full_name: str (NOT NULL)
    avatar_url: str (NULLABLE)
    role: Enum['BUYER', 'SELLER', 'ADMIN'] (NOT NULL, default='BUYER')
    is_verified: bool (NOT NULL, default=False)
    is_suspended: bool (NOT NULL, default=False)
    created_at: datetime
    updated_at: datetime
    
    # Relationships
    addresses: List[Address]
    shop: Shop (one-to-one, nullable)
    orders: List[Order]
    cart_items: List[CartItem]
    reviews: List[Review]
```

#### **Address**
```python
class Address(Base):
    id: UUID (PK)
    user_id: UUID (FK → User.id, NOT NULL)
    recipient_name: str (NOT NULL)
    phone_number: str (NOT NULL)
    street_address: str (NOT NULL)
    ward: str (NOT NULL)
    district: str (NOT NULL)
    city: str (NOT NULL)
    is_default: bool (NOT NULL, default=False)
    created_at: datetime
    
    # Relationships
    user: User
```

#### **Shop**
```python
class Shop(Base):
    id: UUID (PK)
    owner_id: UUID (FK → User.id, UNIQUE, NOT NULL)
    shop_name: str (UNIQUE, NOT NULL)
    description: str (NULLABLE)
    logo_url: str (NULLABLE)
    cover_image_url: str (NULLABLE)
    business_address: str (NOT NULL)
    rating: float (default=0.0)
    total_ratings: int (default=0)
    follower_count: int (default=0)
    status: Enum['PENDING', 'ACTIVE', 'SUSPENDED'] (default='PENDING')
    shipping_fee: Decimal (NOT NULL, default=0)
    free_shipping_threshold: Decimal (NULLABLE)
    created_at: datetime
    updated_at: datetime
    
    # Relationships
    owner: User
    products: List[Product]
    vouchers: List[Voucher]
```

#### **Category**
```python
class Category(Base):
    id: UUID (PK)
    name: str (NOT NULL)
    icon_url: str (NULLABLE)
    parent_id: UUID (FK → Category.id, NULLABLE)
    level: int (NOT NULL, default=0)
    sort_order: int (NOT NULL, default=0)
    is_active: bool (NOT NULL, default=True)
    
    # Relationships
    parent: Category (self-referential)
    subcategories: List[Category]
    products: List[Product]
```

#### **Product**
```python
class Product(Base):
    id: UUID (PK)
    shop_id: UUID (FK → Shop.id, NOT NULL)
    category_id: UUID (FK → Category.id, NOT NULL)
    title: str (NOT NULL)
    description: str (NOT NULL)
    base_price: Decimal (NOT NULL, CHECK > 0)
    currency: str (NOT NULL, default='VND')
    total_stock: int (NOT NULL, default=0)
    images: JSON (Array of URLs, NOT NULL)
    condition: Enum['NEW', 'USED', 'REFURBISHED'] (default='NEW')
    average_rating: float (default=0.0)
    total_reviews: int (default=0)
    sold_count: int (default=0)
    is_active: bool (NOT NULL, default=True)
    created_at: datetime
    updated_at: datetime
    
    # Relationships
    shop: Shop
    category: Category
    variants: List[ProductVariant]
    reviews: List[Review]
```

#### **ProductVariant**
```python
class ProductVariant(Base):
    id: UUID (PK)
    product_id: UUID (FK → Product.id, NOT NULL)
    name: str (NOT NULL)
    attributes: JSON ({"color": "Red", "size": "M"})
    sku: str (UNIQUE, NULLABLE)
    price: Decimal (NOT NULL, CHECK > 0)
    stock: int (NOT NULL, default=0, CHECK >= 0)
    is_active: bool (NOT NULL, default=True)
    
    # Relationships
    product: Product
```

#### **CartItem**
```python
class CartItem(Base):
    id: UUID (PK)
    user_id: UUID (FK → User.id, NOT NULL)
    product_id: UUID (FK → Product.id, NOT NULL)
    variant_id: UUID (FK → ProductVariant.id, NULLABLE)
    quantity: int (NOT NULL, CHECK > 0)
    added_at: datetime
    
    # Relationships
    user: User
    product: Product
    variant: ProductVariant (nullable)
    
    # Constraints
    UNIQUE(user_id, product_id, variant_id)
```

#### **Order**
```python
class Order(Base):
    id: UUID (PK)
    order_number: str (UNIQUE, NOT NULL)  # ORD-YYYYMMDD-XXXX
    buyer_id: UUID (FK → User.id, NOT NULL)
    shop_id: UUID (FK → Shop.id, NOT NULL)
    address_id: UUID (FK → Address.id, NOT NULL)
    shipping_address: JSON (snapshot, NOT NULL)
    status: Enum['PENDING', 'CONFIRMED', 'PACKED', 'SHIPPING', 'DELIVERED', 'COMPLETED', 'CANCELLED'] (default='PENDING')
    payment_method: Enum['COD', 'BANK_TRANSFER', 'E_WALLET'] (NOT NULL)
    payment_status: Enum['PENDING', 'PAID', 'FAILED', 'REFUNDED'] (default='PENDING')
    subtotal: Decimal (NOT NULL)
    shipping_fee: Decimal (NOT NULL, default=0)
    discount: Decimal (NOT NULL, default=0)
    total: Decimal (NOT NULL)
    currency: str (NOT NULL, default='VND')
    voucher_code: str (NULLABLE)
    notes: str (NULLABLE)
    cancellation_reason: str (NULLABLE)
    created_at: datetime
    updated_at: datetime
    completed_at: datetime (NULLABLE)
    
    # Relationships
    buyer: User
    shop: Shop
    address: Address
    items: List[OrderItem]
    voucher: Voucher (nullable)
```

#### **OrderItem**
```python
class OrderItem(Base):
    id: UUID (PK)
    order_id: UUID (FK → Order.id, NOT NULL)
    product_id: UUID (FK → Product.id, NOT NULL)
    variant_id: UUID (FK → ProductVariant.id, NULLABLE)
    product_snapshot: JSON (title, image, price at order time)
    variant_snapshot: JSON (NULLABLE)
    quantity: int (NOT NULL, CHECK > 0)
    unit_price: Decimal (NOT NULL)
    subtotal: Decimal (NOT NULL)
    currency: str (NOT NULL, default='VND')
    
    # Relationships
    order: Order
    product: Product
    variant: ProductVariant (nullable)
```

#### **Voucher**
```python
class Voucher(Base):
    id: UUID (PK)
    shop_id: UUID (FK → Shop.id, NOT NULL)
    code: str (UNIQUE, NOT NULL)
    title: str (NOT NULL)
    description: str (NULLABLE)
    type: Enum['PERCENTAGE', 'FIXED_AMOUNT'] (NOT NULL)
    value: Decimal (NOT NULL, CHECK > 0)
    min_order_value: Decimal (NULLABLE)
    max_discount: Decimal (NULLABLE)
    usage_limit: int (NULLABLE)
    usage_count: int (NOT NULL, default=0)
    start_date: datetime (NOT NULL)
    end_date: datetime (NOT NULL)
    is_active: bool (NOT NULL, default=True)
    
    # Relationships
    shop: Shop
```

#### **Review**
```python
class Review(Base):
    id: UUID (PK)
    product_id: UUID (FK → Product.id, NOT NULL)
    user_id: UUID (FK → User.id, NOT NULL)
    order_id: UUID (FK → Order.id, NOT NULL)
    rating: int (NOT NULL, CHECK 1-5)
    content: str (NULLABLE)
    images: JSON (Array of URLs, max 5)
    is_verified_purchase: bool (NOT NULL, default=True)
    is_visible: bool (NOT NULL, default=True)
    created_at: datetime
    updated_at: datetime
    
    # Relationships
    product: Product
    user: User
    order: Order
    
    # Constraints
    UNIQUE(user_id, product_id)
```

#### **Notification**
```python
class Notification(Base):
    id: UUID (PK)
    user_id: UUID (FK → User.id, NOT NULL)
    type: Enum['ORDER_UPDATE', 'MESSAGE', 'PROMOTION', 'SYSTEM']
    title: str (NOT NULL)
    message: str (NOT NULL)
    related_entity_type: str (NULLABLE)
    related_entity_id: UUID (NULLABLE)
    is_read: bool (NOT NULL, default=False)
    created_at: datetime
    
    # Relationships
    user: User
```

### 2.2 Entity Relationships Summary

```
User (1) ──────→ (N) Address
User (1) ──────→ (1) Shop [seller role]
User (1) ──────→ (N) Order [as buyer]
User (1) ──────→ (N) CartItem
User (1) ──────→ (N) Review
User (1) ──────→ (N) Notification

Shop (1) ──────→ (N) Product
Shop (1) ──────→ (N) Voucher
Shop (1) ──────→ (N) Order [as seller]

Category (1) ──→ (N) Product
Category (1) ──→ (N) Category [self-ref: subcategories]

Product (1) ───→ (N) ProductVariant
Product (1) ───→ (N) Review
Product (1) ───→ (N) CartItem
Product (1) ───→ (N) OrderItem

Order (1) ─────→ (N) OrderItem
Order (N) ─────→ (1) Address [snapshot]
Order (N) ─────→ (1) Voucher [optional]

CartItem (N) ──→ (1) Product
CartItem (N) ──→ (1) ProductVariant [optional]

OrderItem (N) ─→ (1) Product [reference]
OrderItem (N) ─→ (1) ProductVariant [optional, reference]
```

---

## 3. API Design

### 3.1 Base URL
```
http://localhost:8000/api/v1
```

### 3.2 Authentication

All authenticated endpoints require:
```
Authorization: Bearer {access_token}
```

**JWT Token Structure**:
```json
{
  "sub": "user_id",
  "role": "BUYER|SELLER|ADMIN",
  "exp": 1234567890
}
```

### 3.3 API Endpoints Summary

#### **Auth Endpoints** (`/api/v1/auth`)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/register` | Register new user | Public |
| POST | `/verify-otp` | Verify phone OTP | Public |
| POST | `/login` | Login with phone/password | Public |
| POST | `/logout` | Invalidate refresh token | Required |
| POST | `/refresh` | Refresh access token | Public |
| POST | `/forgot-password` | Request password reset OTP | Public |
| POST | `/reset-password` | Reset password with OTP | Public |

**Example: POST /auth/register**
```json
Request:
{
  "phone_number": "+84901234567",
  "password": "SecurePass123",
  "full_name": "Nguyen Van A"
}

Response (200):
{
  "id": "uuid",
  "phone_number": "+84901234567",
  "full_name": "Nguyen Van A",
  "is_verified": false,
  "created_at": "2025-12-05T10:00:00Z"
}
```

**Example: POST /auth/login**
```json
Request:
{
  "phone_number": "+84901234567",
  "password": "SecurePass123"
}

Response (200):
{
  "user": {
    "id": "uuid",
    "phone_number": "+84901234567",
    "full_name": "Nguyen Van A",
    "role": "BUYER",
    "is_verified": true
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

#### **Product Endpoints** (`/api/v1/products`)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | `/` | List products with filters & pagination | Public |
| GET | `/search` | Search products by keyword | Public |
| GET | `/search/autocomplete` | Get search suggestions | Public |
| GET | `/{id}` | Get product details | Public |
| GET | `/{id}/variants` | Get product variants | Public |
| GET | `/{id}/reviews` | Get product reviews | Public |

**Query Parameters for GET /**:
- `limit` (int, default: 20, max: 100)
- `cursor` (str, optional) - for pagination
- `category_id` (UUID, optional)
- `min_price` (Decimal, optional)
- `max_price` (Decimal, optional)
- `rating` (int, optional, 1-5)
- `condition` (str, optional)
- `sort_by` (str, optional: "price_asc", "price_desc", "rating", "newest", "best_selling")

**Example: GET /products?category_id={uuid}&min_price=100000&sort_by=price_asc&limit=20**
```json
Response (200):
{
  "data": [
    {
      "id": "uuid",
      "title": "Wireless Headphones",
      "description": "...",
      "price": 150000,
      "currency": "VND",
      "images": ["https://cdn.../img1.jpg"],
      "rating": 4.5,
      "review_count": 120,
      "sold_count": 500,
      "stock": 50,
      "shop_id": "uuid",
      "shop_name": "Electronics Store",
      "category_name": "Electronics > Audio"
    }
  ],
  "next_cursor": "eyJpZCI6InV1aWQifQ=="
}
```

#### **Category Endpoints** (`/api/v1/categories`)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | `/` | List all categories (hierarchical) | Public |

#### **Cart Endpoints** (`/api/v1/cart`)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | `/` | Get current user's cart | Required |
| POST | `/` | Add item to cart | Required |
| PATCH | `/items/{cart_item_id}` | Update cart item quantity | Required |
| DELETE | `/items/{cart_item_id}` | Remove item from cart | Required |
| POST | `/sync` | Sync local cart with server | Required |

**Example: POST /cart**
```json
Request:
{
  "product_id": "uuid",
  "variant_id": "uuid",  // optional
  "quantity": 2
}

Response (200):
{
  "id": "uuid",
  "product_id": "uuid",
  "variant_id": "uuid",
  "quantity": 2,
  "added_at": "2025-12-05T10:00:00Z"
}
```

#### **Order Endpoints** (`/api/v1/orders`)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/` | Create order(s) from cart | Required |
| GET | `/` | List user's orders with filters | Required |
| GET | `/{order_id}` | Get order details | Required |
| POST | `/{order_id}/cancel` | Cancel order | Required |

**Example: POST /orders**
```json
Request:
{
  "items": [
    {
      "product_id": "uuid",
      "variant_id": "uuid",
      "quantity": 2
    }
  ],
  "address_id": "uuid",
  "payment_method": "COD",
  "voucher_code": "SALE20",
  "notes": "Please deliver after 5pm"
}

Response (200):
{
  "orders": [  // Multiple orders if items from different shops
    {
      "id": "uuid",
      "order_number": "ORD-20251205-AB12",
      "shop_id": "uuid",
      "shop_name": "Electronics Store",
      "items": [
        {
          "product_id": "uuid",
          "product_name": "Wireless Headphones",
          "product_image": "https://...",
          "variant_name": "Black - Bluetooth 5.0",
          "quantity": 2,
          "unit_price": 150000,
          "subtotal": 300000
        }
      ],
      "subtotal": 300000,
      "shipping_fee": 30000,
      "discount": 60000,
      "total": 270000,
      "status": "PENDING",
      "payment_method": "COD",
      "shipping_address": {
        "recipient_name": "Nguyen Van A",
        "phone_number": "+84901234567",
        "street_address": "123 Main St",
        "ward": "Ward 1",
        "district": "District 1",
        "city": "Ho Chi Minh City"
      },
      "created_at": "2025-12-05T10:00:00Z"
    }
  ]
}
```

#### **Voucher Endpoints** (`/api/v1/vouchers`)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/validate` | Validate voucher for order | Required |
| GET | `/available` | Get available vouchers for shop | Required |

#### **Profile Endpoints** (`/api/v1/profile`)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | `/` | Get user profile | Required |
| PUT | `/` | Update user profile | Required |
| GET | `/addresses` | List user addresses | Required |
| POST | `/addresses` | Add new address | Required |
| PUT | `/addresses/{address_id}` | Update address | Required |
| DELETE | `/addresses/{address_id}` | Delete address | Required |
| POST | `/addresses/{address_id}/set-default` | Set default address | Required |

#### **Seller Endpoints** (`/api/v1/seller`)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/shops` | Register as seller (create shop) | Required (BUYER) |
| GET | `/shops/me` | Get own shop details | Required (SELLER) |
| PUT | `/shops/me` | Update shop information | Required (SELLER) |
| POST | `/products` | Create product | Required (SELLER) |
| GET | `/products` | List own products | Required (SELLER) |
| GET | `/products/{product_id}` | Get product details | Required (SELLER) |
| PUT | `/products/{product_id}` | Update product | Required (SELLER) |
| DELETE | `/products/{product_id}` | Delete product | Required (SELLER) |
| GET | `/orders` | List shop orders | Required (SELLER) |
| GET | `/orders/{order_id}` | Get order details | Required (SELLER) |
| PATCH | `/orders/{order_id}/status` | Update order status | Required (SELLER) |
| POST | `/vouchers` | Create voucher | Required (SELLER) |
| GET | `/vouchers` | List shop vouchers | Required (SELLER) |
| PUT | `/vouchers/{voucher_id}` | Update voucher | Required (SELLER) |

**Example: POST /seller/products**
```json
Request:
{
  "title": "Wireless Headphones Premium",
  "description": "High quality wireless headphones with noise cancellation",
  "category_id": "uuid",
  "base_price": 150000,
  "total_stock": 100,
  "images": ["https://cdn.../img1.jpg", "https://cdn.../img2.jpg"],
  "condition": "NEW",
  "variants": [
    {
      "name": "Black - Bluetooth 5.0",
      "attributes": {"color": "Black", "connectivity": "Bluetooth 5.0"},
      "price": 150000,
      "stock": 50,
      "sku": "WH-BLK-BT5"
    },
    {
      "name": "White - Bluetooth 5.0",
      "attributes": {"color": "White", "connectivity": "Bluetooth 5.0"},
      "price": 160000,
      "stock": 50,
      "sku": "WH-WHT-BT5"
    }
  ]
}

Response (201):
{
  "id": "uuid",
  "title": "Wireless Headphones Premium",
  "shop_id": "uuid",
  "category_id": "uuid",
  "base_price": 150000,
  "total_stock": 100,
  "images": ["https://cdn.../img1.jpg"],
  "is_active": true,
  "created_at": "2025-12-05T10:00:00Z"
}
```

#### **Admin Endpoints** (`/api/v1/admin`)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | `/dashboard` | Get platform metrics | Required (ADMIN) |
| GET | `/users` | List all users with filters | Required (ADMIN) |
| PATCH | `/users/{user_id}/suspend` | Suspend/unsuspend user | Required (ADMIN) |
| GET | `/shops` | List all shops with filters | Required (ADMIN) |
| PATCH | `/shops/{shop_id}/status` | Approve/suspend shop | Required (ADMIN) |
| GET | `/products` | List all products | Required (ADMIN) |
| PATCH | `/products/{product_id}/status` | Activate/deactivate product | Required (ADMIN) |
| GET | `/orders` | List all orders | Required (ADMIN) |
| GET | `/categories` | List categories | Required (ADMIN) |
| POST | `/categories` | Create category | Required (ADMIN) |
| PUT | `/categories/{category_id}` | Update category | Required (ADMIN) |

### 3.4 Common Response Formats

#### Success Response
```json
{
  "data": {...} or [...]
}
```

#### Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": {
      "field": "phone_number",
      "reason": "Must be a valid Vietnamese phone number"
    }
  }
}
```

#### Common HTTP Status Codes
- `200 OK` - Successful request
- `201 Created` - Resource created
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required or failed
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists
- `422 Unprocessable Entity` - Validation error
- `500 Internal Server Error` - Server error

---

## 4. Business Flows

### 4.1 User Registration & Login

**Registration Flow**:
1. Client: POST `/auth/register` with phone, password, name
2. Server: Validate inputs, hash password, create User (is_verified=False)
3. Server: Generate OTP (6 digits), store in cache (Redis/DB) with 5min expiry
4. Server: Send OTP via SMS (mock in dev)
5. Server: Return user object (201 Created)
6. Client: POST `/auth/verify-otp` with phone + OTP
7. Server: Validate OTP, mark user as verified, generate JWT tokens
8. Server: Return user + access_token + refresh_token

**Login Flow**:
1. Client: POST `/auth/login` with phone + password
2. Server: Find user by phone, verify password (bcrypt)
3. Server: Check if user is suspended (return 403 if true)
4. Server: Generate JWT access token (15min expiry) + refresh token (7 days expiry)
5. Server: Return user + tokens

**Token Refresh Flow**:
1. Client: POST `/auth/refresh` with refresh_token
2. Server: Validate refresh token, check if revoked
3. Server: Generate new access_token + refresh_token
4. Server: Return new tokens

### 4.2 Product Browsing & Search

**Browse Products**:
1. Client: GET `/products?category_id={uuid}&sort_by=price_asc&limit=20`
2. Server: Query products with filters, apply sorting
3. Server: Eager load shop, category relationships
4. Server: Return paginated results with cursor

**Search Products**:
1. Client: GET `/products/search?q=headphones`
2. Server: Full-text search on title + description (PostgreSQL tsvector)
3. Server: Apply filters if provided
4. Server: Return results with relevance ranking

**Get Product Details**:
1. Client: GET `/products/{id}`
2. Server: Fetch product with variants, shop info
3. Server: Calculate average rating from reviews
4. Server: Return complete product details

### 4.3 Shopping Cart & Checkout

**Add to Cart**:
1. Client: POST `/cart` with product_id, variant_id, quantity (authenticated)
2. Server: Validate product exists and has stock
3. Server: Check if item already in cart (upsert: add quantity if exists)
4. Server: Create/update CartItem
5. Server: Return cart item

**Checkout Flow**:
1. Client: GET `/cart` to fetch current cart
2. Client: Display cart grouped by shop
3. Client: Apply voucher if needed: POST `/vouchers/validate`
4. Server: Validate voucher eligibility (min order, usage limit, dates)
5. Client: Select/create shipping address
6. Client: POST `/orders` with items, address_id, payment_method, voucher_code
7. Server: **Transaction start**
8. Server: Re-validate stock availability for all items
9. Server: Calculate totals (subtotal, shipping, discount)
10. Server: Group items by shop → create multiple Order records
11. Server: Create OrderItem records with product snapshots
12. Server: Decrement product/variant stock
13. Server: Increment voucher usage_count
14. Server: Clear cart items
15. Server: Create notifications for buyer + sellers
16. Server: **Transaction commit**
17. Server: Return order(s) array

**Order Status Updates**:
1. Seller: PATCH `/seller/orders/{id}/status` with new status
2. Server: Validate state transition (e.g., PENDING → CONFIRMED)
3. Server: Update order status + updated_at
4. Server: Create notification for buyer
5. Server: If status = DELIVERED, allow buyer to review

### 4.4 Seller Product Management

**Create Product**:
1. Seller: POST `/seller/products` with product data + variants
2. Server: Validate seller has active shop (status=ACTIVE)
3. Server: Validate category exists
4. Server: Upload images to cloud storage (S3/GCS)
5. Server: Create Product + ProductVariant records
6. Server: Return created product

**Update Stock**:
1. Seller: PUT `/seller/products/{id}` with new stock values
2. Server: Update product/variant stock
3. Server: If stock reaches 0, product becomes unavailable in searches

### 4.5 Admin Management

**Approve Shop**:
1. Admin: PATCH `/admin/shops/{id}/status` with status=ACTIVE
2. Server: Update shop.status
3. Server: Create notification for seller
4. Server: Shop products become visible in marketplace

**Moderate Product**:
1. Admin: PATCH `/admin/products/{id}/status` with is_active=False
2. Server: Hide product from search results
3. Server: Create notification for seller with reason

---

## 5. Data Persistence

### 5.1 Database Schema (PostgreSQL)

#### Core Tables

**users**
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    role VARCHAR(20) NOT NULL DEFAULT 'BUYER',
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_suspended BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
```

**addresses**
```sql
CREATE TABLE addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    street_address TEXT NOT NULL,
    ward VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_addresses_user ON addresses(user_id);
```

**shops**
```sql
CREATE TABLE shops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    shop_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    logo_url TEXT,
    cover_image_url TEXT,
    business_address TEXT NOT NULL,
    rating FLOAT NOT NULL DEFAULT 0.0,
    total_ratings INTEGER NOT NULL DEFAULT 0,
    follower_count INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    shipping_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
    free_shipping_threshold DECIMAL(10,2),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_shops_owner ON shops(owner_id);
CREATE INDEX idx_shops_status ON shops(status);
```

**categories**
```sql
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    icon_url TEXT,
    parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    level INTEGER NOT NULL DEFAULT 0,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_level ON categories(level);
```

**products**
```sql
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    title VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    base_price DECIMAL(12,2) NOT NULL CHECK (base_price > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'VND',
    total_stock INTEGER NOT NULL DEFAULT 0,
    images JSONB NOT NULL,
    condition VARCHAR(20) NOT NULL DEFAULT 'NEW',
    average_rating FLOAT NOT NULL DEFAULT 0.0,
    total_reviews INTEGER NOT NULL DEFAULT 0,
    sold_count INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_shop ON products(shop_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_rating ON products(average_rating DESC);
CREATE INDEX idx_products_sold ON products(sold_count DESC);
CREATE INDEX idx_products_created ON products(created_at DESC);

-- Full-text search
CREATE INDEX idx_products_search ON products 
    USING GIN (to_tsvector('english', title || ' ' || description));
```

**product_variants**
```sql
CREATE TABLE product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    attributes JSONB NOT NULL,
    sku VARCHAR(100) UNIQUE,
    price DECIMAL(12,2) NOT NULL CHECK (price > 0),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_variants_product ON product_variants(product_id);
```

**cart_items**
```sql
CREATE TABLE cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    added_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, product_id, variant_id)
);

CREATE INDEX idx_cart_user ON cart_items(user_id);
```

**orders**
```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE RESTRICT,
    address_id UUID NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
    shipping_address JSONB NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    payment_method VARCHAR(20) NOT NULL,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    subtotal DECIMAL(12,2) NOT NULL,
    shipping_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount DECIMAL(12,2) NOT NULL DEFAULT 0,
    total DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'VND',
    voucher_code VARCHAR(50),
    notes TEXT,
    cancellation_reason TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP
);

CREATE INDEX idx_orders_buyer ON orders(buyer_id);
CREATE INDEX idx_orders_shop ON orders(shop_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at DESC);
CREATE INDEX idx_orders_number ON orders(order_number);
```

**order_items**
```sql
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    variant_id UUID REFERENCES product_variants(id) ON DELETE RESTRICT,
    product_snapshot JSONB NOT NULL,
    variant_snapshot JSONB,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'VND'
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
```

**vouchers**
```sql
CREATE TABLE vouchers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    code VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL,
    value DECIMAL(12,2) NOT NULL CHECK (value > 0),
    min_order_value DECIMAL(12,2),
    max_discount DECIMAL(12,2),
    usage_limit INTEGER,
    usage_count INTEGER NOT NULL DEFAULT 0,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_vouchers_shop ON vouchers(shop_id);
CREATE INDEX idx_vouchers_code ON vouchers(code);
```

**reviews**
```sql
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    content TEXT,
    images JSONB,
    is_verified_purchase BOOLEAN NOT NULL DEFAULT TRUE,
    is_visible BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_order ON reviews(order_id);
```

**notifications**
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_entity_type VARCHAR(50),
    related_entity_id UUID,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_read ON notifications(is_read);
```

### 5.2 Migrations with Alembic

**Setup**:
```bash
alembic init alembic
```

**Create migration**:
```bash
alembic revision --autogenerate -m "Create initial tables"
```

**Apply migrations**:
```bash
alembic upgrade head
```

**Rollback**:
```bash
alembic downgrade -1
```

### 5.3 Seed Data Strategy

Create seed script: `scripts/seed_data.py`

**Development Seed Data**:
- 10 test users (buyer, seller, admin roles)
- 5 shops (various categories)
- 50 products with variants
- 10 categories (2-level hierarchy)
- Sample orders with different statuses
- Sample reviews

**Run seed**:
```bash
python scripts/seed_data.py
```

---

## 6. Security & Non-Functional Requirements

### 6.1 Authentication & Authorization

**JWT Configuration**:
```python
# app/config.py
class Settings(BaseSettings):
    SECRET_KEY: str  # From environment
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
```

**Password Hashing**:
```python
# app/core/security.py
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)
```

**JWT Token Generation**:
```python
from jose import jwt
from datetime import datetime, timedelta

def create_access_token(user_id: str, role: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=15)
    payload = {
        "sub": user_id,
        "role": role,
        "exp": expire,
        "type": "access"
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
```

**Role-Based Access Control**:
```python
# app/dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> User:
    token = credentials.credentials
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    user_id = payload.get("sub")
    # Fetch user from DB
    return user

async def require_seller(user: User = Depends(get_current_user)) -> User:
    if user.role not in ["SELLER", "ADMIN"]:
        raise HTTPException(status_code=403, detail="Seller access required")
    return user

async def require_admin(user: User = Depends(get_current_user)) -> User:
    if user.role != "ADMIN":
        raise HTTPException(status_code=403, detail="Admin access required")
    return user
```

### 6.2 Validation Rules

**Phone Number** (Vietnamese):
```python
import re

def validate_phone_number(phone: str) -> bool:
    pattern = r'^\+84[3|5|7|8|9][0-9]{8}$'
    return bool(re.match(pattern, phone))
```

**Password Policy**:
- Minimum 8 characters
- Must contain: letter + number
- No maximum length (bcrypt handles long passwords)

**Price Validation**:
- Must be > 0
- Maximum: 1,000,000,000 VND (1 billion)
- Precision: 2 decimal places

**Product Title**:
- Minimum: 10 characters
- Maximum: 500 characters

### 6.3 Error Handling

**Custom Exceptions**:
```python
# app/core/exceptions.py
class AppException(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400):
        self.code = code
        self.message = message
        self.status_code = status_code

class ValidationError(AppException):
    def __init__(self, message: str):
        super().__init__("VALIDATION_ERROR", message, 400)

class NotFoundError(AppException):
    def __init__(self, resource: str):
        super().__init__("NOT_FOUND", f"{resource} not found", 404)

class UnauthorizedError(AppException):
    def __init__(self):
        super().__init__("UNAUTHORIZED", "Authentication required", 401)
```

**Global Exception Handler**:
```python
# app/main.py
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()

@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": exc.code,
                "message": exc.message
            }
        }
    )
```

### 6.4 Logging

**Configuration**:
```python
# app/core/logging.py
import logging
import sys

def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler('logs/app.log')
        ]
    )

logger = logging.getLogger("marketplace")
```

**Usage**:
```python
from app.core.logging import logger

logger.info(f"User {user_id} logged in")
logger.error(f"Failed to create order: {error}", exc_info=True)
```

### 6.5 Rate Limiting

**Using slowapi**:
```python
# app/main.py
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Apply to endpoints
@app.post("/auth/login")
@limiter.limit("5/minute")
async def login(request: Request, ...):
    ...
```

### 6.6 CORS Configuration

```python
# app/main.py
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 6.7 Environment Configuration

```python
# app/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # App
    APP_NAME: str = "Marketplace API"
    DEBUG: bool = False
    
    # Database
    DATABASE_URL: str
    
    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    
    # Storage
    AWS_ACCESS_KEY_ID: str
    AWS_SECRET_ACCESS_KEY: str
    AWS_S3_BUCKET: str
    
    # External Services
    SMS_API_KEY: str
    SMS_API_URL: str
    
    class Config:
        env_file = ".env"

settings = Settings()
```

**.env.example**:
```env
# Database
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/marketplace

# Security
SECRET_KEY=your-secret-key-here-use-openssl-rand-hex-32
ALGORITHM=HS256

# AWS S3
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_S3_BUCKET=marketplace-images

# SMS Service
SMS_API_KEY=your-sms-api-key
SMS_API_URL=https://api.sms-service.com

# Environment
DEBUG=true
ENVIRONMENT=development
```

### 6.8 Health Check

```python
# app/api/v1/health.py
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db

router = APIRouter()

@router.get("/health")
async def health_check(db: AsyncSession = Depends(get_db)):
    try:
        # Check DB connection
        await db.execute("SELECT 1")
        return {
            "status": "healthy",
            "database": "connected"
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e)
        }
```

---

## 7. Implementation Guidelines

### 7.1 Repository Pattern

```python
# app/repositories/base.py
from typing import Generic, TypeVar, Type, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID

ModelType = TypeVar("ModelType")

class BaseRepository(Generic[ModelType]):
    def __init__(self, model: Type[ModelType], db: AsyncSession):
        self.model = model
        self.db = db
    
    async def get_by_id(self, id: UUID) -> Optional[ModelType]:
        result = await self.db.execute(
            select(self.model).where(self.model.id == id)
        )
        return result.scalar_one_or_none()
    
    async def list(self, skip: int = 0, limit: int = 20) -> List[ModelType]:
        result = await self.db.execute(
            select(self.model).offset(skip).limit(limit)
        )
        return result.scalars().all()
    
    async def create(self, obj: ModelType) -> ModelType:
        self.db.add(obj)
        await self.db.commit()
        await self.db.refresh(obj)
        return obj
    
    async def update(self, obj: ModelType) -> ModelType:
        await self.db.commit()
        await self.db.refresh(obj)
        return obj
    
    async def delete(self, obj: ModelType) -> None:
        await self.db.delete(obj)
        await self.db.commit()
```

**Usage**:
```python
# app/repositories/product.py
from app.repositories.base import BaseRepository
from app.models.product import Product

class ProductRepository(BaseRepository[Product]):
    async def find_by_shop(self, shop_id: UUID) -> List[Product]:
        result = await self.db.execute(
            select(Product).where(Product.shop_id == shop_id)
        )
        return result.scalars().all()
```

### 7.2 Service Layer

```python
# app/services/product.py
from app.repositories.product import ProductRepository
from app.schemas.product import ProductCreate, ProductResponse
from app.core.exceptions import NotFoundError
from uuid import UUID

class ProductService:
    def __init__(self, repo: ProductRepository):
        self.repo = repo
    
    async def create_product(self, shop_id: UUID, data: ProductCreate) -> ProductResponse:
        # Business logic
        product = Product(
            shop_id=shop_id,
            title=data.title,
            description=data.description,
            ...
        )
        created = await self.repo.create(product)
        return ProductResponse.from_orm(created)
    
    async def get_product(self, product_id: UUID) -> ProductResponse:
        product = await self.repo.get_by_id(product_id)
        if not product:
            raise NotFoundError("Product")
        return ProductResponse.from_orm(product)
```

### 7.3 Router Pattern

```python
# app/api/v1/products.py
from fastapi import APIRouter, Depends, Query
from app.dependencies import get_current_user, get_db
from app.services.product import ProductService
from app.repositories.product import ProductRepository
from app.schemas.product import ProductListResponse

router = APIRouter(prefix="/products", tags=["products"])

@router.get("/", response_model=ProductListResponse)
async def list_products(
    category_id: Optional[UUID] = Query(None),
    min_price: Optional[float] = Query(None),
    max_price: Optional[float] = Query(None),
    limit: int = Query(20, le=100),
    cursor: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    repo = ProductRepository(Product, db)
    service = ProductService(repo)
    return await service.list_products(
        category_id=category_id,
        min_price=min_price,
        max_price=max_price,
        limit=limit,
        cursor=cursor
    )
```

### 7.4 Testing Strategy

**Unit Tests** (service/repository layer):
```python
# tests/unit/services/test_product.py
import pytest
from unittest.mock import AsyncMock
from app.services.product import ProductService

@pytest.mark.asyncio
async def test_create_product():
    mock_repo = AsyncMock()
    mock_repo.create.return_value = Product(id="uuid", title="Test")
    
    service = ProductService(mock_repo)
    result = await service.create_product(shop_id="uuid", data=ProductCreate(...))
    
    assert result.title == "Test"
    mock_repo.create.assert_called_once()
```

**Integration Tests** (API endpoints):
```python
# tests/integration/test_products.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_list_products():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/api/v1/products?limit=10")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
```

**Test Database**:
```python
# tests/conftest.py
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from app.database import Base

TEST_DATABASE_URL = "postgresql+asyncpg://test:test@localhost:5432/test_db"

@pytest.fixture
async def db_session():
    engine = create_async_engine(TEST_DATABASE_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async with AsyncSession(engine) as session:
        yield session
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
```

---

## 8. Deployment Checklist

### 8.1 Production Setup

- [ ] Set up PostgreSQL database with connection pooling
- [ ] Configure environment variables in production
- [ ] Set `DEBUG=false` in production
- [ ] Use strong `SECRET_KEY` (32+ random bytes)
- [ ] Enable HTTPS/TLS
- [ ] Set up reverse proxy (Nginx) with rate limiting
- [ ] Configure CORS with specific origins (no wildcard)
- [ ] Set up database backups (daily)
- [ ] Configure log rotation
- [ ] Set up monitoring (health checks, metrics)
- [ ] Implement CDN for image delivery
- [ ] Set up Redis for caching (optional, future)
- [ ] Configure SMS service for OTP
- [ ] Set up error tracking (Sentry)

### 8.2 Running the Application

**Development**:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Production**:
```bash
gunicorn app.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

**Docker**:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["gunicorn", "app.main:app", "--workers", "4", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]
```

---

## Appendix: Quick Reference

### HTTP Status Codes
- `200` OK - Success
- `201` Created - Resource created
- `400` Bad Request - Invalid input
- `401` Unauthorized - Auth required
- `403` Forbidden - Insufficient permissions
- `404` Not Found - Resource doesn't exist
- `409` Conflict - Duplicate resource
- `422` Unprocessable Entity - Validation error
- `500` Internal Server Error - Server error

### Common Query Parameters
- `limit` (int): Page size (default: 20, max: 100)
- `cursor` (str): Pagination cursor
- `sort_by` (str): Sort field + direction
- `filter_*`: Various filters

### Authentication Header
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

**End of Backend Specification**
