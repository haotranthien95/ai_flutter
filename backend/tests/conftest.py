"""
Pytest configuration and fixtures
"""
import asyncio
from typing import AsyncGenerator, Generator

import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from app.config import settings
from app.database import Base, get_db
from app.main import app

# Test database URL
TEST_DATABASE_URL = "postgresql+asyncpg://postgres:postgres@localhost:5432/marketplace_test"

# Create test engine
test_engine = create_async_engine(
    TEST_DATABASE_URL,
    echo=False,
    future=True,
)

# Create test session factory
TestSessionLocal = async_sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create event loop for async tests"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="function")
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """
    Create a fresh database session for each test
    """
    # Create tables
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Create session
    async with TestSessionLocal() as session:
        yield session
    
    # Drop tables after test
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture(scope="function")
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """
    Create test client with database session override
    """
    async def override_get_db():
        yield db_session
    
    app.dependency_overrides[get_db] = override_get_db
    
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac
    
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def auth_token(client: AsyncClient, db_session: AsyncSession) -> str:
    """
    Create authenticated user and return access token
    
    This fixture will be implemented after auth endpoints are created
    """
    # TODO: Implement after auth module is ready
    # 1. Create test user in database
    # 2. Call login endpoint
    # 3. Return access token
    return "test-token"


# Helper fixtures for creating test data
@pytest.fixture
def sample_user_data() -> dict:
    """Sample user data for tests"""
    return {
        "phone_number": "+84912345678",
        "password": "Test@1234",
        "full_name": "Test User",
        "email": "test@example.com",
    }


@pytest.fixture
def sample_product_data() -> dict:
    """Sample product data for tests"""
    return {
        "title": "Test Product",
        "description": "This is a test product",
        "base_price": 100000,
        "currency": "VND",
        "total_stock": 50,
        "condition": "NEW",
    }


@pytest.fixture
def sample_order_data() -> dict:
    """Sample order data for tests"""
    return {
        "payment_method": "COD",
        "notes": "Please deliver in the morning",
    }
