"""
Unit tests for Address Service
"""
import pytest
from uuid import uuid4
from unittest.mock import AsyncMock, MagicMock
from fastapi import HTTPException

from app.models.address import Address
from app.schemas.address import AddressCreate, AddressUpdate
from app.services.address import AddressService


# Mark all tests in this module as asyncio
pytestmark = pytest.mark.asyncio


@pytest.fixture
def mock_db():
    """Mock database session"""
    db = AsyncMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    return db


@pytest.fixture
def address_service(mock_db):
    """Create address service with mocked db"""
    return AddressService(mock_db)


@pytest.fixture
def sample_address():
    """Sample address object"""
    from datetime import datetime, timezone
    user_id = uuid4()
    return Address(
        id=uuid4(),
        user_id=user_id,
        recipient_name="John Doe",
        phone_number="0912345678",
        street_address="123 Main St",
        ward="Ward 1",
        district="District 1",
        city="Ho Chi Minh City",
        is_default=True,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )


@pytest.fixture
def address_create_data():
    """Sample address creation data"""
    return AddressCreate(
        recipient_name="John Doe",
        phone_number="0912345678",
        street_address="123 Main St",
        ward="Ward 1",
        district="District 1",
        city="Ho Chi Minh City",
        is_default=False
    )


class TestListAddresses:
    """Tests for list_addresses"""
    
    async def test_list_addresses_success(self, address_service, sample_address):
        """Test listing addresses successfully"""
        user_id = sample_address.user_id
        address_service.address_repo.list_by_user = AsyncMock(return_value=[sample_address])
        
        result = await address_service.list_addresses(user_id)
        
        assert len(result) == 1
        assert result[0].recipient_name == sample_address.recipient_name
        address_service.address_repo.list_by_user.assert_called_once_with(user_id)
    
    async def test_list_addresses_empty(self, address_service):
        """Test listing addresses when user has none"""
        user_id = uuid4()
        address_service.address_repo.list_by_user = AsyncMock(return_value=[])
        
        result = await address_service.list_addresses(user_id)
        
        assert len(result) == 0


class TestGetAddress:
    """Tests for get_address"""
    
    async def test_get_address_success(self, address_service, sample_address):
        """Test getting address successfully"""
        user_id = sample_address.user_id
        address_id = sample_address.id
        address_service.address_repo.get_by_id_and_user = AsyncMock(return_value=sample_address)
        
        result = await address_service.get_address(user_id, address_id)
        
        assert result.id == address_id
        assert result.recipient_name == sample_address.recipient_name
    
    async def test_get_address_not_found(self, address_service):
        """Test getting non-existent address"""
        user_id = uuid4()
        address_id = uuid4()
        address_service.address_repo.get_by_id_and_user = AsyncMock(return_value=None)
        
        with pytest.raises(HTTPException) as exc_info:
            await address_service.get_address(user_id, address_id)
        
        assert exc_info.value.status_code == 404
        assert "not found" in exc_info.value.detail.lower()


class TestCreateAddress:
    """Tests for create_address"""
    
    async def test_create_first_address_auto_default(
        self,
        address_service,
        address_create_data
    ):
        """Test that first address is automatically set as default"""
        from datetime import datetime, timezone
        user_id = uuid4()
        address_create_data.is_default = False  # Explicitly not default
        
        def create_with_defaults(addr):
            addr.id = uuid4()
            addr.created_at = datetime.now(timezone.utc)
            addr.updated_at = datetime.now(timezone.utc)
            return addr
        
        address_service.address_repo.count_by_user = AsyncMock(return_value=0)
        address_service.address_repo.create = AsyncMock(
            side_effect=create_with_defaults
        )
        
        result = await address_service.create_address(user_id, address_create_data)
        
        # Should be set to default since it's the first address
        assert result.is_default is True
    
    async def test_create_address_with_default_flag(
        self,
        address_service,
        address_create_data
    ):
        """Test creating address with is_default=True"""
        from datetime import datetime, timezone
        user_id = uuid4()
        address_create_data.is_default = True
        
        def create_with_defaults(addr):
            addr.id = uuid4()
            addr.created_at = datetime.now(timezone.utc)
            addr.updated_at = datetime.now(timezone.utc)
            return addr
        
        address_service.address_repo.count_by_user = AsyncMock(return_value=1)
        address_service.address_repo.unset_all_defaults = AsyncMock()
        address_service.address_repo.create = AsyncMock(
            side_effect=create_with_defaults
        )
        
        await address_service.create_address(user_id, address_create_data)
        
        # Should unset other defaults
        address_service.address_repo.unset_all_defaults.assert_called_once_with(user_id)
    
    async def test_create_address_not_default(
        self,
        address_service,
        address_create_data
    ):
        """Test creating non-default address when user already has addresses"""
        from datetime import datetime, timezone
        user_id = uuid4()
        address_create_data.is_default = False
        
        def create_with_defaults(addr):
            addr.id = uuid4()
            addr.created_at = datetime.now(timezone.utc)
            addr.updated_at = datetime.now(timezone.utc)
            return addr
        
        address_service.address_repo.count_by_user = AsyncMock(return_value=1)
        address_service.address_repo.unset_all_defaults = AsyncMock()
        address_service.address_repo.create = AsyncMock(
            side_effect=create_with_defaults
        )
        
        result = await address_service.create_address(user_id, address_create_data)
        
        # Should not unset defaults
        address_service.address_repo.unset_all_defaults.assert_not_called()
        assert result.is_default is False


class TestUpdateAddress:
    """Tests for update_address"""
    
    async def test_update_address_success(self, address_service, sample_address):
        """Test updating address successfully"""
        user_id = sample_address.user_id
        address_id = sample_address.id
        update_data = AddressUpdate(recipient_name="Jane Doe")
        
        address_service.address_repo.get_by_id_and_user = AsyncMock(return_value=sample_address)
        address_service.address_repo.update = AsyncMock(return_value=sample_address)
        
        result = await address_service.update_address(user_id, address_id, update_data)
        
        assert sample_address.recipient_name == "Jane Doe"
    
    async def test_update_address_set_default(self, address_service, sample_address):
        """Test updating address to set as default"""
        user_id = sample_address.user_id
        address_id = sample_address.id
        sample_address.is_default = False
        update_data = AddressUpdate(is_default=True)
        
        address_service.address_repo.get_by_id_and_user = AsyncMock(return_value=sample_address)
        address_service.address_repo.unset_all_defaults = AsyncMock()
        address_service.address_repo.update = AsyncMock(return_value=sample_address)
        
        await address_service.update_address(user_id, address_id, update_data)
        
        address_service.address_repo.unset_all_defaults.assert_called_once_with(user_id)
    
    async def test_update_address_not_found(self, address_service):
        """Test updating non-existent address"""
        user_id = uuid4()
        address_id = uuid4()
        update_data = AddressUpdate(recipient_name="Jane Doe")
        
        address_service.address_repo.get_by_id_and_user = AsyncMock(return_value=None)
        
        with pytest.raises(HTTPException) as exc_info:
            await address_service.update_address(user_id, address_id, update_data)
        
        assert exc_info.value.status_code == 404


class TestDeleteAddress:
    """Tests for delete_address"""
    
    async def test_delete_address_success(self, address_service, sample_address):
        """Test deleting address successfully"""
        user_id = sample_address.user_id
        address_id = sample_address.id
        sample_address.is_default = False  # Not default
        
        address_service.address_repo.get_by_id_and_user = AsyncMock(return_value=sample_address)
        address_service.address_repo.count_by_user = AsyncMock(return_value=2)
        address_service.address_repo.delete_by_id_and_user = AsyncMock()
        
        await address_service.delete_address(user_id, address_id)
        
        address_service.address_repo.delete_by_id_and_user.assert_called_once()
    
    async def test_delete_last_address_fails(self, address_service, sample_address):
        """Test that deleting last address fails"""
        user_id = sample_address.user_id
        address_id = sample_address.id
        
        address_service.address_repo.get_by_id_and_user = AsyncMock(return_value=sample_address)
        address_service.address_repo.count_by_user = AsyncMock(return_value=1)
        
        with pytest.raises(HTTPException) as exc_info:
            await address_service.delete_address(user_id, address_id)
        
        assert exc_info.value.status_code == 400
        assert "only address" in exc_info.value.detail.lower()
    
    async def test_delete_default_address_sets_new_default(
        self,
        address_service,
        sample_address
    ):
        """Test that deleting default address sets another as default"""
        user_id = sample_address.user_id
        address_id = sample_address.id
        sample_address.is_default = True
        
        # Create another address
        other_address = Address(
            id=uuid4(),
            user_id=user_id,
            recipient_name="Other",
            phone_number="0987654321",
            street_address="456 Other St",
            ward="Ward 2",
            district="District 2",
            city="Ho Chi Minh City",
            is_default=False
        )
        
        address_service.address_repo.get_by_id_and_user = AsyncMock(return_value=sample_address)
        address_service.address_repo.count_by_user = AsyncMock(return_value=2)
        address_service.address_repo.list_by_user = AsyncMock(
            return_value=[sample_address, other_address]
        )
        address_service.address_repo.update = AsyncMock()
        address_service.address_repo.delete_by_id_and_user = AsyncMock()
        
        await address_service.delete_address(user_id, address_id)
        
        # Other address should be set as default
        assert other_address.is_default is True
        address_service.address_repo.update.assert_called_once()
    
    async def test_delete_address_not_found(self, address_service):
        """Test deleting non-existent address"""
        user_id = uuid4()
        address_id = uuid4()
        
        address_service.address_repo.get_by_id_and_user = AsyncMock(return_value=None)
        
        with pytest.raises(HTTPException) as exc_info:
            await address_service.delete_address(user_id, address_id)
        
        assert exc_info.value.status_code == 404


class TestSetDefaultAddress:
    """Tests for set_default_address"""
    
    async def test_set_default_address_success(self, address_service, sample_address):
        """Test setting address as default successfully"""
        user_id = sample_address.user_id
        address_id = sample_address.id
        sample_address.is_default = False
        
        address_service.address_repo.get_by_id_and_user = AsyncMock(return_value=sample_address)
        address_service.address_repo.set_default = AsyncMock()
        
        result = await address_service.set_default_address(user_id, address_id)
        
        address_service.address_repo.set_default.assert_called_once_with(user_id, address_id)
    
    async def test_set_default_address_not_found(self, address_service):
        """Test setting non-existent address as default"""
        user_id = uuid4()
        address_id = uuid4()
        
        address_service.address_repo.get_by_id_and_user = AsyncMock(return_value=None)
        
        with pytest.raises(HTTPException) as exc_info:
            await address_service.set_default_address(user_id, address_id)
        
        assert exc_info.value.status_code == 404
