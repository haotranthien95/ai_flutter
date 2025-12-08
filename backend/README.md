# E-Commerce Marketplace Backend

A comprehensive FastAPI backend service for a full-featured e-commerce marketplace platform supporting buyers, sellers, and administrators.

## 🚀 Features

### Core Functionality
- **User Management**: Customer, Seller, and Admin roles with profile management
- **Authentication**: JWT-based authentication with access & refresh tokens
- **Shop Management**: Sellers can create and manage their shops
- **Product Catalog**: Categories, products with variants, search, and filtering
- **Shopping Cart**: Persistent cart with multi-shop support
- **Order Processing**: Complete checkout flow with multiple payment methods
- **Voucher System**: Platform-wide and shop-specific discount vouchers
- **Review & Rating**: Product reviews with star ratings
- **Notifications**: Real-time notifications for order updates and messages
- **Admin Panel**: Platform management, user moderation, shop approval

### Technical Features
- **Async/Await**: Full async support with asyncpg and SQLAlchemy 2.0
- **Database Migrations**: Alembic for version-controlled schema changes
- **Comprehensive Testing**: 478+ unit and integration tests
- **Exception Handling**: Global exception handlers with structured logging
- **Validation**: Vietnamese phone numbers, prices, images, passwords
- **API Documentation**: Auto-generated OpenAPI/Swagger docs
- **CORS Support**: Configurable cross-origin resource sharing
- **Rate Limiting**: Ready for slowapi integration
- **Logging**: Structured logging with loguru

## 📋 Prerequisites

- **Python**: 3.11+ (tested with 3.13.2)
- **PostgreSQL**: 14+
- **pip**: Latest version
- **Docker** (optional): For containerized deployment

## 🛠️ Project Structure

```
backend/
├── app/
│   ├── api/
│   │   └── v1/              # API route handlers
│   │       ├── auth.py      # Authentication endpoints
│   │       ├── users.py     # User profile & addresses
│   │       ├── seller.py    # Shop management
│   │       ├── products.py  # Product catalog
│   │       ├── categories.py
│   │       ├── cart.py      # Shopping cart
│   │       ├── orders.py    # Order management
│   │       ├── vouchers.py  # Discount vouchers
│   │       ├── reviews.py   # Product reviews
│   │       ├── notifications.py
│   │       ├── admin.py     # Admin endpoints
│   │       └── router.py    # Main router
│   ├── core/
│   │   ├── security.py      # JWT & password hashing
│   │   ├── exceptions.py    # Custom exceptions
│   │   └── logging.py       # Logging configuration
│   ├── models/              # SQLAlchemy models (16 models)
│   ├── repositories/        # Data access layer
│   ├── schemas/             # Pydantic validation schemas
│   ├── services/            # Business logic layer
│   ├── utils/
│   │   └── validators.py    # Validation utilities
│   ├── config.py            # Settings management
│   ├── database.py          # Database connection
│   ├── dependencies.py      # FastAPI dependencies
│   └── main.py              # Application entry point
├── tests/
│   ├── unit/                # Unit tests (~350 tests)
│   │   ├── services/
│   │   └── utils/
│   ├── integration/         # Integration tests (~128 tests)
│   │   └── api/
│   └── conftest.py          # Test configuration
├── scripts/
│   ├── create_admin.py      # Create admin users
│   ├── seed_data.py         # Seed test data
│   └── reset_db.py          # Reset database
├── alembic/                 # Database migrations
│   ├── versions/            # 12 migration files
│   └── env.py
├── requirements.txt         # Production dependencies
├── requirements-dev.txt     # Development dependencies
├── pytest.ini               # Pytest configuration
├── alembic.ini              # Alembic configuration
├── Dockerfile               # Container image
├── docker-compose.yml       # Docker services
└── .env.example             # Environment template
```

## 🚦 Quick Start

### 1. Clone and Setup

```bash
# Clone repository
git clone <repository-url>
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt  # For development
```

### 2. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your configuration
nano .env  # or use your preferred editor
```

Required environment variables:
```env
# Database
DATABASE_URL=postgresql+asyncpg://user:password@host:5432/database

# Security
SECRET_KEY=your-secret-key-here-minimum-32-characters
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Environment
ENVIRONMENT=development
DEBUG=True
LOG_LEVEL=INFO

# API
API_PREFIX=/api/v1
APP_NAME=E-Commerce Marketplace API
APP_VERSION=1.0.0
```

### 3. Database Setup

```bash
# Run database migrations
alembic upgrade head

# Create admin user (interactive)
python3 scripts/create_admin.py

# Seed test data (optional)
python3 scripts/seed_data.py
```

### 4. Run Development Server

```bash
# Run with uvicorn
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Or run with specific settings
uvicorn app.main:app --reload --log-level info
```

The API will be available at:
- **API**: http://localhost:8000
- **Docs**: http://localhost:8000/api/v1/docs
- **ReDoc**: http://localhost:8000/api/v1/redoc

## 🐳 Docker Development

```bash
# Build and start services
docker-compose up --build

# Run in detached mode
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down

# Reset and rebuild
docker-compose down -v
docker-compose up --build
```

Access:
- API: http://localhost:8000
- Database: localhost:5432

## 🧪 Testing

### Run All Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/unit/services/test_auth_service.py

# Run specific test
pytest tests/unit/services/test_auth_service.py::TestRegisterUser

# Run with verbose output
pytest -v

# Run integration tests only
pytest tests/integration/

# Run unit tests only
pytest tests/unit/
```

### Test Coverage

Current test coverage: **478 tests**
- Unit tests: ~350 tests
- Integration tests: ~128 tests
- Modules: Auth, Users, Shop, Products, Cart, Orders, Vouchers, Reviews, Notifications, Admin, Validators

## 📊 Database Management

### Migrations

```bash
# Create new migration
alembic revision --autogenerate -m "Description of changes"

# Apply migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# View migration history
alembic history

# Check current version
alembic current
```

### Database Scripts

```bash
# Create admin user (interactive)
python3 scripts/create_admin.py

# Seed test data
python3 scripts/seed_data.py

# Reset database (WARNING: Deletes all data)
python3 scripts/reset_db.py
```

**Test Credentials** (after seeding):
- Customer: `user1@example.com` / `password123`
- Seller: `user3@example.com` / `password123`
- Admin: `admin@example.com` / `password123`

## 📡 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/verify-email` - Verify email

### Users
- `GET /api/v1/users/me` - Get current user
- `PUT /api/v1/users/me` - Update profile
- `GET /api/v1/users/me/addresses` - List addresses
- `POST /api/v1/users/me/addresses` - Create address
- `PUT /api/v1/users/me/addresses/{id}` - Update address
- `DELETE /api/v1/users/me/addresses/{id}` - Delete address

### Seller & Shop
- `POST /api/v1/seller/register` - Register as seller
- `GET /api/v1/seller/shop` - Get my shop
- `PUT /api/v1/seller/shop` - Update shop
- `GET /api/v1/seller/orders` - List shop orders
- `PUT /api/v1/seller/orders/{id}/status` - Update order status

### Products & Categories
- `GET /api/v1/products` - List products (with filters)
- `GET /api/v1/products/{id}` - Get product details
- `POST /api/v1/products` - Create product (seller)
- `PUT /api/v1/products/{id}` - Update product
- `DELETE /api/v1/products/{id}` - Delete product
- `GET /api/v1/categories` - List categories
- `GET /api/v1/categories/{id}/products` - Products by category

### Shopping Cart
- `GET /api/v1/cart` - Get cart
- `POST /api/v1/cart/items` - Add to cart
- `PUT /api/v1/cart/items/{id}` - Update cart item
- `DELETE /api/v1/cart/items/{id}` - Remove from cart
- `DELETE /api/v1/cart` - Clear cart

### Orders
- `POST /api/v1/orders/checkout` - Create order
- `GET /api/v1/orders` - List my orders
- `GET /api/v1/orders/{id}` - Get order details
- `PUT /api/v1/orders/{id}/cancel` - Cancel order
- `POST /api/v1/orders/{id}/payment-proof` - Upload payment proof

### Vouchers
- `GET /api/v1/vouchers` - List available vouchers
- `POST /api/v1/vouchers/validate` - Validate voucher
- `POST /api/v1/vouchers` - Create voucher (seller/admin)
- `PUT /api/v1/vouchers/{id}` - Update voucher
- `DELETE /api/v1/vouchers/{id}` - Delete voucher

### Reviews
- `GET /api/v1/reviews/products/{id}` - Get product reviews
- `POST /api/v1/reviews` - Create review
- `PUT /api/v1/reviews/{id}` - Update review
- `DELETE /api/v1/reviews/{id}` - Delete review
- `GET /api/v1/reviews/me` - My reviews

### Notifications
- `GET /api/v1/notifications` - List notifications
- `GET /api/v1/notifications/unread-count` - Get unread count
- `PUT /api/v1/notifications/{id}/read` - Mark as read
- `PUT /api/v1/notifications/mark-all-read` - Mark all as read
- `DELETE /api/v1/notifications/{id}` - Delete notification

### Admin
- `GET /api/v1/admin/dashboard` - Platform metrics
- `GET /api/v1/admin/users` - List all users
- `PATCH /api/v1/admin/users/{id}/suspend` - Suspend user
- `PATCH /api/v1/admin/users/{id}/unsuspend` - Unsuspend user
- `GET /api/v1/admin/shops` - List all shops
- `PATCH /api/v1/admin/shops/{id}/status` - Approve/suspend shop
- `GET /api/v1/admin/products` - List all products
- `PATCH /api/v1/admin/products/{id}/status` - Moderate product
- `POST /api/v1/admin/categories` - Create category
- `PUT /api/v1/admin/categories/{id}` - Update category
- `DELETE /api/v1/admin/categories/{id}` - Delete category

Full API documentation available at `/api/v1/docs` when server is running.

## 🔒 Security

- **Password Hashing**: bcrypt with salt
- **JWT Tokens**: RS256 algorithm with configurable expiration
- **CORS**: Configurable origins, restrictive in production
- **SQL Injection**: Protected via SQLAlchemy ORM
- **Input Validation**: Pydantic schemas on all endpoints
- **Rate Limiting**: Ready for integration (slowapi)
- **Environment Variables**: Secrets via .env files

## 🐛 Debugging

### Enable Debug Mode

```env
# .env
DEBUG=True
LOG_LEVEL=DEBUG
```

### View Logs

```bash
# Application logs (when running)
tail -f logs/app.log

# SQLAlchemy queries (in debug mode)
# Set LOG_LEVEL=DEBUG in .env
```

### Common Issues

**Database connection error**:
```bash
# Check PostgreSQL is running
psql -h localhost -U postgres -d marketplace

# Verify DATABASE_URL in .env
```

**Migration conflicts**:
```bash
# Reset migrations (WARNING: Loses data)
python3 scripts/reset_db.py
```

**Import errors**:
```bash
# Ensure you're in virtual environment
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

## 📈 Performance

- **Async Operations**: Full async/await for I/O operations
- **Database Indexes**: Strategic indexes on foreign keys and search fields
- **Connection Pooling**: SQLAlchemy async pool
- **Pagination**: Offset-based pagination on list endpoints
- **Eager Loading**: Optimized query joins to avoid N+1 queries

## 🚀 Production Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed production setup instructions.

Quick checklist:
- [ ] Set `ENVIRONMENT=production`
- [ ] Set `DEBUG=False`
- [ ] Use strong `SECRET_KEY` (32+ random characters)
- [ ] Configure production database
- [ ] Set restrictive `ALLOWED_ORIGINS`
- [ ] Enable HTTPS
- [ ] Set up monitoring and logging
- [ ] Configure backup strategy

## 📚 Additional Documentation

- [DATABASE.md](DATABASE.md) - Database schema and relationships
- [DEPLOYMENT.md](DEPLOYMENT.md) - Production deployment guide
- [TASKS.md](TASKS.md) - Development task tracking
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) - Implementation details

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Run tests: `pytest`
4. Run linters: `black app tests && flake8 app tests`
5. Commit: `git commit -am 'Add your feature'`
6. Push: `git push origin feature/your-feature`
7. Create Pull Request

## 📝 License

[Specify your license here]

## 👥 Support

For issues and questions:
- Create an issue in the repository
- Contact: [Your contact information]

---

**Built with ❤️ using FastAPI, SQLAlchemy, and PostgreSQL**


```bash
cd backend
```

### 2. Create virtual environment

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

### 4. Configure environment variables

```bash
cp .env.example .env
# Edit .env with your database credentials and settings
```

Required environment variables:
- `DATABASE_URL`: PostgreSQL connection string
- `SECRET_KEY`: Secret key for JWT tokens (change in production!)
- `ALLOWED_ORIGINS`: CORS allowed origins

### 5. Set up database

Create PostgreSQL database:

```bash
createdb marketplace_dev
createdb marketplace_test  # For testing
```

### 6. Run database migrations

```bash
# Initialize Alembic (first time only)
alembic init alembic

# Create migration
alembic revision --autogenerate -m "Initial migration"

# Apply migrations
alembic upgrade head
```

## Running the Application

### Development (local)

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at:
- API: http://localhost:8000
- Swagger Docs: http://localhost:8000/api/v1/docs
- ReDoc: http://localhost:8000/api/v1/redoc

### Development (Docker)

```bash
docker-compose up --build
```

The API will be available at http://localhost:8000

## Testing

### Run all tests

```bash
pytest
```

### Run with coverage

```bash
pytest --cov=app --cov-report=html
```

### Run specific test file

```bash
pytest tests/unit/test_auth.py
```

### Run integration tests only

```bash
pytest tests/integration/
```

## Database Migrations

### Create new migration

```bash
alembic revision --autogenerate -m "Description of changes"
```

### Apply migrations

```bash
alembic upgrade head
```

### Rollback migration

```bash
alembic downgrade -1
```

### View migration history

```bash
alembic history
```

## API Documentation

Once the application is running, visit:
- Swagger UI: http://localhost:8000/api/v1/docs
- ReDoc: http://localhost:8000/api/v1/redoc

For complete API specification, refer to `BACKEND_SPEC.md`

## Development Workflow

1. Create a new branch for your feature
2. Implement the feature following the task list in `TASKS.md`
3. Write unit tests for services and repositories
4. Write integration tests for API endpoints
5. Run tests: `pytest`
6. Check code formatting: `black app/ tests/`
7. Check code quality: `flake8 app/ tests/`
8. Create a pull request

## Project Status

**Phase 1 (Setup & Infrastructure)** - ✅ Completed
- ✅ T001-T010: Project structure, dependencies, config, Docker, testing setup

**Next Phase**: Phase 2 - Authentication Module (T011-T025)

See `TASKS.md` for the full implementation roadmap.

## License

Proprietary - All rights reserved
