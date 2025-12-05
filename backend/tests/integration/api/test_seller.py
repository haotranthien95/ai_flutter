"""
Integration tests for Seller API endpoints
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from decimal import Decimal

from app.models.user import User, UserRole
from app.models.shop import Shop, ShopStatus
from app.core.security import create_access_token


@pytest.fixture
async def test_user(db_session: AsyncSession):
    """Create a test user"""
    user = User(
        email="seller@example.com",
        phone_number="0912345678",
        full_name="Test Seller",
        password_hash="$2b$12$test.hashed.password",
        role=UserRole.BUYER,
        is_verified=True,
        is_suspended=False
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
def auth_headers(test_user):
    """Create authentication headers"""
    token = create_access_token({"sub": str(test_user.id)})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
async def test_shop(db_session: AsyncSession, test_user):
    """Create a test shop"""
    shop = Shop(
        owner_id=test_user.id,
        shop_name="Test Shop",
        description="Test shop description",
        business_address="123 Test St",
        shipping_fee=Decimal("20000"),
        free_shipping_threshold=Decimal("200000"),
        status=ShopStatus.ACTIVE
    )
    db_session.add(shop)
    await db_session.commit()
    await db_session.refresh(shop)
    return shop


class TestRegisterShop:
    """Tests for POST /seller/shops"""
    
    async def test_register_shop_success(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test successful shop registration"""
        shop_data = {
            "shop_name": "New Test Shop",
            "description": "My amazing shop",
            "business_address": "456 Business St",
            "shipping_fee": "15000",
            "free_shipping_threshold": "150000"
        }
        
        response = await client.post(
            "/api/v1/seller/shops",
            json=shop_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["shop_name"] == "New Test Shop"
        assert data["description"] == "My amazing shop"
        assert data["status"] == "pending"
        assert "id" in data
        assert "owner_id" in data
    
    async def test_register_shop_duplicate_name(
        self,
        client: AsyncClient,
        auth_headers,
        test_shop
    ):
        """Test registration fails with duplicate shop name"""
        shop_data = {
            "shop_name": test_shop.shop_name,  # Same name as existing
            "description": "Another shop",
            "shipping_fee": "10000"
        }
        
        # First, delete the test shop to allow creating a new one
        # Then try to register with the same name
        response = await client.post(
            "/api/v1/seller/shops",
            json=shop_data,
            headers=auth_headers
        )
        
        assert response.status_code == 400
        assert "already" in response.json()["detail"].lower()
    
    async def test_register_shop_already_has_shop(
        self,
        client: AsyncClient,
        auth_headers,
        test_shop
    ):
        """Test registration fails if user already has a shop"""
        shop_data = {
            "shop_name": "Another Shop",
            "description": "Second shop attempt",
            "shipping_fee": "10000"
        }
        
        response = await client.post(
            "/api/v1/seller/shops",
            json=shop_data,
            headers=auth_headers
        )
        
        assert response.status_code == 400
        assert "already has" in response.json()["detail"].lower()
    
    async def test_register_shop_unauthorized(
        self,
        client: AsyncClient
    ):
        """Test registration requires authentication"""
        shop_data = {
            "shop_name": "Unauthorized Shop",
            "shipping_fee": "10000"
        }
        
        response = await client.post(
            "/api/v1/seller/shops",
            json=shop_data
        )
        
        assert response.status_code == 401
    
    async def test_register_shop_invalid_data(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test registration with invalid data"""
        shop_data = {
            "shop_name": "AB",  # Too short
            "shipping_fee": "-1000"  # Negative
        }
        
        response = await client.post(
            "/api/v1/seller/shops",
            json=shop_data,
            headers=auth_headers
        )
        
        assert response.status_code == 422


class TestGetMyShop:
    """Tests for GET /seller/shops/me"""
    
    async def test_get_my_shop_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_shop
    ):
        """Test getting own shop successfully"""
        response = await client.get(
            "/api/v1/seller/shops/me",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(test_shop.id)
        assert data["shop_name"] == test_shop.shop_name
        assert data["description"] == test_shop.description
    
    async def test_get_my_shop_not_registered(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test getting shop when user doesn't have one"""
        response = await client.get(
            "/api/v1/seller/shops/me",
            headers=auth_headers
        )
        
        assert response.status_code == 404
        assert "don't have" in response.json()["detail"].lower()
    
    async def test_get_my_shop_unauthorized(
        self,
        client: AsyncClient
    ):
        """Test getting shop requires authentication"""
        response = await client.get("/api/v1/seller/shops/me")
        
        assert response.status_code == 401


class TestUpdateMyShop:
    """Tests for PUT /seller/shops/me"""
    
    async def test_update_my_shop_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_shop
    ):
        """Test updating own shop successfully"""
        update_data = {
            "description": "Updated description",
            "shipping_fee": "25000",
            "free_shipping_threshold": "250000"
        }
        
        response = await client.put(
            "/api/v1/seller/shops/me",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["description"] == "Updated description"
        assert float(data["shipping_fee"]) == 25000
        assert float(data["free_shipping_threshold"]) == 250000
    
    async def test_update_my_shop_change_name(
        self,
        client: AsyncClient,
        auth_headers,
        test_shop
    ):
        """Test updating shop name"""
        update_data = {
            "shop_name": "New Shop Name"
        }
        
        response = await client.put(
            "/api/v1/seller/shops/me",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["shop_name"] == "New Shop Name"
    
    async def test_update_my_shop_not_registered(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test updating shop when user doesn't have one"""
        update_data = {
            "description": "New description"
        }
        
        response = await client.put(
            "/api/v1/seller/shops/me",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 404
        assert "don't have" in response.json()["detail"].lower()
    
    async def test_update_my_shop_unauthorized(
        self,
        client: AsyncClient,
        test_shop
    ):
        """Test updating shop requires authentication"""
        update_data = {
            "description": "Unauthorized update"
        }
        
        response = await client.put(
            "/api/v1/seller/shops/me",
            json=update_data
        )
        
        assert response.status_code == 401
    
    async def test_update_my_shop_invalid_data(
        self,
        client: AsyncClient,
        auth_headers,
        test_shop
    ):
        """Test updating shop with invalid data"""
        update_data = {
            "shop_name": "A",  # Too short
            "shipping_fee": "-5000"  # Negative
        }
        
        response = await client.put(
            "/api/v1/seller/shops/me",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 422
