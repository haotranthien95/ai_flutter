# E-Commerce Marketplace Backend

FastAPI backend service for the E-Commerce Marketplace application.

## Features

- **FastAPI** framework with async/await support
- **PostgreSQL** database with SQLAlchemy ORM
- **JWT** authentication
- **Alembic** database migrations
- **Docker** support for development and production
- **Pytest** for unit and integration testing

## Project Structure

```
backend/
├── app/
│   ├── api/
│   │   └── v1/          # API route handlers
│   ├── core/            # Core utilities (security, config)
│   ├── models/          # SQLAlchemy models
│   ├── repositories/    # Data access layer
│   ├── schemas/         # Pydantic schemas
│   ├── services/        # Business logic layer
│   ├── utils/           # Helper functions
│   ├── config.py        # Application configuration
│   ├── database.py      # Database connection
│   └── main.py          # FastAPI application
├── tests/
│   ├── unit/            # Unit tests
│   └── integration/     # Integration tests
├── scripts/             # Utility scripts
├── alembic/             # Database migrations
├── requirements.txt     # Production dependencies
├── requirements-dev.txt # Development dependencies
├── Dockerfile           # Docker image
├── docker-compose.yml   # Docker services
└── .env.example         # Environment variables template
```

## Prerequisites

- Python 3.11+
- PostgreSQL 14+
- Docker & Docker Compose (optional)

## Setup

### 1. Clone the repository

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
