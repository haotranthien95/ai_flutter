"""
Integration tests for User Profile and Address API endpoints
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.models.address import Address
from app.core.security import create_access_token


@pytest.fixture
async def test_user(db_session: AsyncSession):
    """Create a test user"""
    user = User(
        email="testuser@example.com",
        full_name="Test User",
        hashed_password="$2b$12$test.hashed.password"
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
async def test_address(db_session: AsyncSession, test_user):
    """Create a test address"""
    address = Address(
        user_id=test_user.id,
        recipient_name="Test Recipient",
        phone_number="0912345678",
        street_address="123 Test St",
        ward="Ward 1",
        district="District 1",
        city="Ho Chi Minh City",
        is_default=True
    )
    db_session.add(address)
    await db_session.commit()
    await db_session.refresh(address)
    return address


class TestGetProfile:
    """Tests for GET /api/v1/users/profile"""
    
    async def test_get_profile_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_user
    ):
        """Test getting user profile successfully"""
        response = await client.get(
            "/api/v1/users/profile",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == test_user.email
        assert data["full_name"] == test_user.full_name
        assert "id" in data
    
    async def test_get_profile_unauthorized(self, client: AsyncClient):
        """Test getting profile without authentication"""
        response = await client.get("/api/v1/users/profile")
        
        assert response.status_code == 401


class TestUpdateProfile:
    """Tests for PUT /api/v1/users/profile"""
    
    async def test_update_profile_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_user
    ):
        """Test updating profile successfully"""
        update_data = {
            "full_name": "Updated Name",
            "phone_number": "0987654321"
        }
        
        response = await client.put(
            "/api/v1/users/profile",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["full_name"] == "Updated Name"
        assert data["phone_number"] == "0987654321"
    
    async def test_update_profile_email(
        self,
        client: AsyncClient,
        auth_headers,
        test_user
    ):
        """Test updating email"""
        update_data = {"email": "newemail@example.com"}
        
        response = await client.put(
            "/api/v1/users/profile",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "newemail@example.com"
    
    async def test_update_profile_duplicate_email(
        self,
        client: AsyncClient,
        auth_headers,
        db_session: AsyncSession
    ):
        """Test updating to an email that's already taken"""
        # Create another user
        other_user = User(
            email="other@example.com",
            full_name="Other User",
            hashed_password="$2b$12$test.hashed.password"
        )
        db_session.add(other_user)
        await db.commit()
        
        # Try to update to other user's email
        update_data = {"email": "other@example.com"}
        
        response = await client.put(
            "/api/v1/users/profile",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 400
        assert "already registered" in response.json()["detail"].lower()
    
    async def test_update_profile_unauthorized(self, client: AsyncClient):
        """Test updating profile without authentication"""
        response = await client.put(
            "/api/v1/users/profile",
            json={"full_name": "Updated"}
        )
        
        assert response.status_code == 401


class TestUploadAvatar:
    """Tests for POST /api/v1/users/profile/avatar"""
    
    async def test_upload_avatar_placeholder(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test avatar upload (placeholder implementation)"""
        # Create a fake image file
        files = {
            "file": ("test.jpg", b"fake image content", "image/jpeg")
        }
        
        response = await client.post(
            "/api/v1/users/profile/avatar",
            files=files,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "avatar_url" in data
    
    async def test_upload_avatar_invalid_type(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test uploading non-image file"""
        files = {
            "file": ("test.txt", b"not an image", "text/plain")
        }
        
        response = await client.post(
            "/api/v1/users/profile/avatar",
            files=files,
            headers=auth_headers
        )
        
        assert response.status_code == 400
        assert "image" in response.json()["detail"].lower()
    
    async def test_upload_avatar_unauthorized(self, client: AsyncClient):
        """Test avatar upload without authentication"""
        files = {
            "file": ("test.jpg", b"fake image", "image/jpeg")
        }
        
        response = await client.post(
            "/api/v1/users/profile/avatar",
            files=files
        )
        
        assert response.status_code == 401


class TestListAddresses:
    """Tests for GET /api/v1/users/profile/addresses"""
    
    async def test_list_addresses_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_address
    ):
        """Test listing addresses successfully"""
        response = await client.get(
            "/api/v1/users/profile/addresses",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["recipient_name"] == test_address.recipient_name
    
    async def test_list_addresses_empty(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test listing addresses when user has none"""
        response = await client.get(
            "/api/v1/users/profile/addresses",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 0
    
    async def test_list_addresses_unauthorized(self, client: AsyncClient):
        """Test listing addresses without authentication"""
        response = await client.get("/api/v1/users/profile/addresses")
        
        assert response.status_code == 401


class TestCreateAddress:
    """Tests for POST /api/v1/users/profile/addresses"""
    
    async def test_create_address_success(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test creating address successfully"""
        address_data = {
            "recipient_name": "John Doe",
            "phone_number": "0912345678",
            "street_address": "123 Main St",
            "ward": "Ward 1",
            "district": "District 1",
            "city": "Ho Chi Minh City",
            "is_default": False
        }
        
        response = await client.post(
            "/api/v1/users/profile/addresses",
            json=address_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["recipient_name"] == "John Doe"
        assert data["phone_number"] == "0912345678"
        assert "id" in data
    
    async def test_create_first_address_auto_default(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test that first address is automatically set as default"""
        address_data = {
            "recipient_name": "John Doe",
            "phone_number": "0912345678",
            "street_address": "123 Main St",
            "ward": "Ward 1",
            "district": "District 1",
            "city": "Ho Chi Minh City",
            "is_default": False  # Explicitly not default
        }
        
        response = await client.post(
            "/api/v1/users/profile/addresses",
            json=address_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["is_default"] is True  # Should be auto-set
    
    async def test_create_address_invalid_phone(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test creating address with invalid phone number"""
        address_data = {
            "recipient_name": "John Doe",
            "phone_number": "123",  # Invalid
            "street_address": "123 Main St",
            "ward": "Ward 1",
            "district": "District 1",
            "city": "Ho Chi Minh City"
        }
        
        response = await client.post(
            "/api/v1/users/profile/addresses",
            json=address_data,
            headers=auth_headers
        )
        
        assert response.status_code == 422
    
    async def test_create_address_unauthorized(self, client: AsyncClient):
        """Test creating address without authentication"""
        address_data = {
            "recipient_name": "John Doe",
            "phone_number": "0912345678",
            "street_address": "123 Main St",
            "ward": "Ward 1",
            "district": "District 1",
            "city": "Ho Chi Minh City"
        }
        
        response = await client.post(
            "/api/v1/users/profile/addresses",
            json=address_data
        )
        
        assert response.status_code == 401


class TestGetAddress:
    """Tests for GET /api/v1/users/profile/addresses/{address_id}"""
    
    async def test_get_address_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_address
    ):
        """Test getting address successfully"""
        response = await client.get(
            f"/api/v1/users/profile/addresses/{test_address.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(test_address.id)
        assert data["recipient_name"] == test_address.recipient_name
    
    async def test_get_address_not_found(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test getting non-existent address"""
        fake_id = "00000000-0000-0000-0000-000000000000"
        
        response = await client.get(
            f"/api/v1/users/profile/addresses/{fake_id}",
            headers=auth_headers
        )
        
        assert response.status_code == 404
    
    async def test_get_address_unauthorized(self, client: AsyncClient, test_address):
        """Test getting address without authentication"""
        response = await client.get(
            f"/api/v1/users/profile/addresses/{test_address.id}"
        )
        
        assert response.status_code == 401


class TestUpdateAddress:
    """Tests for PUT /api/v1/users/profile/addresses/{address_id}"""
    
    async def test_update_address_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_address
    ):
        """Test updating address successfully"""
        update_data = {
            "recipient_name": "Updated Name",
            "phone_number": "0987654321"
        }
        
        response = await client.put(
            f"/api/v1/users/profile/addresses/{test_address.id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["recipient_name"] == "Updated Name"
        assert data["phone_number"] == "0987654321"
    
    async def test_update_address_not_found(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test updating non-existent address"""
        fake_id = "00000000-0000-0000-0000-000000000000"
        update_data = {"recipient_name": "Updated"}
        
        response = await client.put(
            f"/api/v1/users/profile/addresses/{fake_id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 404
    
    async def test_update_address_unauthorized(
        self,
        client: AsyncClient,
        test_address
    ):
        """Test updating address without authentication"""
        response = await client.put(
            f"/api/v1/users/profile/addresses/{test_address.id}",
            json={"recipient_name": "Updated"}
        )
        
        assert response.status_code == 401


class TestDeleteAddress:
    """Tests for DELETE /api/v1/users/profile/addresses/{address_id}"""
    
    async def test_delete_address_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_address,
        db_session: AsyncSession,
        test_user
    ):
        """Test deleting address successfully"""
        # Create a second address so we can delete the first
        second_address = Address(
            user_id=test_user.id,
            recipient_name="Second Address",
            phone_number="0987654321",
            street_address="456 Other St",
            ward="Ward 2",
            district="District 2",
            city="Hanoi",
            is_default=False
        )
        db_session.add(second_address)
        await db.commit()
        
        response = await client.delete(
            f"/api/v1/users/profile/addresses/{test_address.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 204
    
    async def test_delete_last_address_fails(
        self,
        client: AsyncClient,
        auth_headers,
        test_address
    ):
        """Test that deleting last address fails"""
        response = await client.delete(
            f"/api/v1/users/profile/addresses/{test_address.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 400
        assert "only address" in response.json()["detail"].lower()
    
    async def test_delete_address_not_found(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test deleting non-existent address"""
        fake_id = "00000000-0000-0000-0000-000000000000"
        
        response = await client.delete(
            f"/api/v1/users/profile/addresses/{fake_id}",
            headers=auth_headers
        )
        
        assert response.status_code == 404
    
    async def test_delete_address_unauthorized(
        self,
        client: AsyncClient,
        test_address
    ):
        """Test deleting address without authentication"""
        response = await client.delete(
            f"/api/v1/users/profile/addresses/{test_address.id}"
        )
        
        assert response.status_code == 401


class TestSetDefaultAddress:
    """Tests for POST /api/v1/users/profile/addresses/{address_id}/set-default"""
    
    async def test_set_default_address_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_address,
        db_session: AsyncSession,
        test_user
    ):
        """Test setting address as default successfully"""
        # Create a second non-default address
        second_address = Address(
            user_id=test_user.id,
            recipient_name="Second Address",
            phone_number="0987654321",
            street_address="456 Other St",
            ward="Ward 2",
            district="District 2",
            city="Hanoi",
            is_default=False
        )
        db_session.add(second_address)
        await db.commit()
        await db.refresh(second_address)
        
        response = await client.post(
            f"/api/v1/users/profile/addresses/{second_address.id}/set-default",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["is_default"] is True
    
    async def test_set_default_address_not_found(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test setting non-existent address as default"""
        fake_id = "00000000-0000-0000-0000-000000000000"
        
        response = await client.post(
            f"/api/v1/users/profile/addresses/{fake_id}/set-default",
            headers=auth_headers
        )
        
        assert response.status_code == 404
    
    async def test_set_default_address_unauthorized(
        self,
        client: AsyncClient,
        test_address
    ):
        """Test setting default address without authentication"""
        response = await client.post(
            f"/api/v1/users/profile/addresses/{test_address.id}/set-default"
        )
        
        assert response.status_code == 401
