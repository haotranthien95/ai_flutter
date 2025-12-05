"""
Unit tests for Shop Service
"""
import pytest
from uuid import uuid4
from unittest.mock import AsyncMock
from fastapi import HTTPException
from decimal import Decimal

from app.models.shop import Shop, ShopStatus
from app.models.user import User, UserRole
from app.schemas.shop import ShopCreate, ShopUpdate
from app.services.shop import ShopService


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
def shop_service(mock_db):
    """Create shop service with mocked db"""
    return ShopService(mock_db)


@pytest.fixture
def sample_user():
    """Sample user object"""
    from datetime import datetime, timezone
    return User(
        id=uuid4(),
        phone_number="0912345678",
        email="test@example.com",
        password_hash="$2b$12$test.hash",
        full_name="Test User",
        role=UserRole.BUYER,
        is_verified=True,
        is_suspended=False,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )


@pytest.fixture
def sample_shop(sample_user):
    """Sample shop object"""
    from datetime import datetime, timezone
    return Shop(
        id=uuid4(),
        owner_id=sample_user.id,
        shop_name="Test Shop",
        description="Test shop description",
        business_address="123 Test St",
        shipping_fee=Decimal("20000"),
        free_shipping_threshold=Decimal("200000"),
        status=ShopStatus.ACTIVE,
        rating=4.5,
        total_ratings=100,
        follower_count=50,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )


@pytest.fixture
def shop_create_data():
    """Sample shop creation data"""
    return ShopCreate(
        shop_name="New Shop",
        description="New shop description",
        business_address="456 New St",
        shipping_fee=Decimal("15000"),
        free_shipping_threshold=Decimal("150000")
    )


class TestRegisterShop:
    """Tests for register_shop"""
    
    async def test_register_shop_success(
        self,
        shop_service,
        sample_user,
        shop_create_data
    ):
        """Test successful shop registration"""
        from datetime import datetime, timezone
        
        def create_shop_with_defaults(shop):
            shop.id = uuid4()
            shop.created_at = datetime.now(timezone.utc)
            shop.updated_at = datetime.now(timezone.utc)
            shop.status = ShopStatus.PENDING
            shop.rating = 0.0
            shop.total_ratings = 0
            shop.follower_count = 0
            return shop
        
        shop_service.shop_repo.get_by_owner = AsyncMock(return_value=None)
        shop_service.shop_repo.get_by_name = AsyncMock(return_value=None)
        shop_service.user_repo.get_by_id = AsyncMock(return_value=sample_user)
        shop_service.shop_repo.create = AsyncMock(side_effect=create_shop_with_defaults)
        shop_service.user_repo.update = AsyncMock()
        
        result = await shop_service.register_shop(sample_user.id, shop_create_data)
        
        assert result.shop_name == shop_create_data.shop_name
        assert result.owner_id == sample_user.id
        shop_service.user_repo.update.assert_called_once()
    
    async def test_register_shop_user_already_has_shop(
        self,
        shop_service,
        sample_user,
        sample_shop,
        shop_create_data
    ):
        """Test registration fails if user already has a shop"""
        shop_service.shop_repo.get_by_owner = AsyncMock(return_value=sample_shop)
        
        with pytest.raises(HTTPException) as exc_info:
            await shop_service.register_shop(sample_user.id, shop_create_data)
        
        assert exc_info.value.status_code == 400
        assert "already has" in exc_info.value.detail.lower()
    
    async def test_register_shop_name_taken(
        self,
        shop_service,
        sample_user,
        sample_shop,
        shop_create_data
    ):
        """Test registration fails if shop name is taken"""
        shop_service.shop_repo.get_by_owner = AsyncMock(return_value=None)
        shop_service.shop_repo.get_by_name = AsyncMock(return_value=sample_shop)
        
        with pytest.raises(HTTPException) as exc_info:
            await shop_service.register_shop(sample_user.id, shop_create_data)
        
        assert exc_info.value.status_code == 400
        assert "already taken" in exc_info.value.detail.lower()
    
    async def test_register_shop_user_not_found(
        self,
        shop_service,
        shop_create_data
    ):
        """Test registration fails if user doesn't exist"""
        user_id = uuid4()
        shop_service.shop_repo.get_by_owner = AsyncMock(return_value=None)
        shop_service.shop_repo.get_by_name = AsyncMock(return_value=None)
        shop_service.user_repo.get_by_id = AsyncMock(return_value=None)
        
        with pytest.raises(HTTPException) as exc_info:
            await shop_service.register_shop(user_id, shop_create_data)
        
        assert exc_info.value.status_code == 404
        assert "user not found" in exc_info.value.detail.lower()
    
    async def test_register_shop_upgrades_user_role(
        self,
        shop_service,
        sample_user,
        shop_create_data
    ):
        """Test that user role is upgraded to SELLER after registration"""
        from datetime import datetime, timezone
        
        def create_shop_with_defaults(shop):
            shop.id = uuid4()
            shop.created_at = datetime.now(timezone.utc)
            shop.updated_at = datetime.now(timezone.utc)
            shop.status = ShopStatus.PENDING
            shop.rating = 0.0
            shop.total_ratings = 0
            shop.follower_count = 0
            return shop
        
        sample_user.role = UserRole.BUYER
        shop_service.shop_repo.get_by_owner = AsyncMock(return_value=None)
        shop_service.shop_repo.get_by_name = AsyncMock(return_value=None)
        shop_service.user_repo.get_by_id = AsyncMock(return_value=sample_user)
        shop_service.shop_repo.create = AsyncMock(side_effect=create_shop_with_defaults)
        shop_service.user_repo.update = AsyncMock()
        
        await shop_service.register_shop(sample_user.id, shop_create_data)
        
        assert sample_user.role == UserRole.SELLER
        shop_service.user_repo.update.assert_called_once()


class TestGetShop:
    """Tests for get_shop"""
    
    async def test_get_shop_success(self, shop_service, sample_shop):
        """Test getting shop by ID successfully"""
        shop_service.shop_repo.get_by_id = AsyncMock(return_value=sample_shop)
        
        result = await shop_service.get_shop(sample_shop.id)
        
        assert result.id == sample_shop.id
        assert result.shop_name == sample_shop.shop_name
    
    async def test_get_shop_not_found(self, shop_service):
        """Test getting non-existent shop"""
        shop_id = uuid4()
        shop_service.shop_repo.get_by_id = AsyncMock(return_value=None)
        
        with pytest.raises(HTTPException) as exc_info:
            await shop_service.get_shop(shop_id)
        
        assert exc_info.value.status_code == 404
        assert "not found" in exc_info.value.detail.lower()


class TestGetMyShop:
    """Tests for get_my_shop"""
    
    async def test_get_my_shop_success(self, shop_service, sample_user, sample_shop):
        """Test getting user's own shop successfully"""
        shop_service.shop_repo.get_by_owner = AsyncMock(return_value=sample_shop)
        
        result = await shop_service.get_my_shop(sample_user.id)
        
        assert result.owner_id == sample_user.id
        assert result.shop_name == sample_shop.shop_name
    
    async def test_get_my_shop_not_registered(self, shop_service, sample_user):
        """Test getting shop when user doesn't have one"""
        shop_service.shop_repo.get_by_owner = AsyncMock(return_value=None)
        
        with pytest.raises(HTTPException) as exc_info:
            await shop_service.get_my_shop(sample_user.id)
        
        assert exc_info.value.status_code == 404
        assert "don't have" in exc_info.value.detail.lower()


class TestUpdateShop:
    """Tests for update_shop"""
    
    async def test_update_shop_success(self, shop_service, sample_user, sample_shop):
        """Test updating shop successfully"""
        update_data = ShopUpdate(
            description="Updated description",
            shipping_fee=Decimal("25000")
        )
        
        shop_service.shop_repo.get_by_owner = AsyncMock(return_value=sample_shop)
        shop_service.shop_repo.update = AsyncMock(return_value=sample_shop)
        
        result = await shop_service.update_shop(sample_user.id, update_data)
        
        assert sample_shop.description == "Updated description"
        assert sample_shop.shipping_fee == Decimal("25000")
    
    async def test_update_shop_change_name_success(
        self,
        shop_service,
        sample_user,
        sample_shop
    ):
        """Test updating shop name to a new unique name"""
        update_data = ShopUpdate(shop_name="New Unique Name")
        
        shop_service.shop_repo.get_by_owner = AsyncMock(return_value=sample_shop)
        shop_service.shop_repo.get_by_name = AsyncMock(return_value=None)
        shop_service.shop_repo.update = AsyncMock(return_value=sample_shop)
        
        await shop_service.update_shop(sample_user.id, update_data)
        
        assert sample_shop.shop_name == "New Unique Name"
    
    async def test_update_shop_name_taken(self, shop_service, sample_user, sample_shop):
        """Test updating shop name to one that's already taken"""
        other_shop = Shop(
            id=uuid4(),
            owner_id=uuid4(),
            shop_name="Taken Name",
            shipping_fee=Decimal("20000")
        )
        update_data = ShopUpdate(shop_name="Taken Name")
        
        shop_service.shop_repo.get_by_owner = AsyncMock(return_value=sample_shop)
        shop_service.shop_repo.get_by_name = AsyncMock(return_value=other_shop)
        
        with pytest.raises(HTTPException) as exc_info:
            await shop_service.update_shop(sample_user.id, update_data)
        
        assert exc_info.value.status_code == 400
        assert "already taken" in exc_info.value.detail.lower()
    
    async def test_update_shop_not_registered(self, shop_service, sample_user):
        """Test updating shop when user doesn't have one"""
        update_data = ShopUpdate(description="New description")
        
        shop_service.shop_repo.get_by_owner = AsyncMock(return_value=None)
        
        with pytest.raises(HTTPException) as exc_info:
            await shop_service.update_shop(sample_user.id, update_data)
        
        assert exc_info.value.status_code == 404
        assert "don't have" in exc_info.value.detail.lower()


class TestListShops:
    """Tests for list_shops"""
    
    async def test_list_shops_success(self, shop_service, sample_shop):
        """Test listing shops successfully"""
        shop_service.shop_repo.list_all = AsyncMock(return_value=[sample_shop])
        shop_service.shop_repo.count_all = AsyncMock(return_value=1)
        
        shops, total = await shop_service.list_shops()
        
        assert len(shops) == 1
        assert total == 1
        assert shops[0].shop_name == sample_shop.shop_name
    
    async def test_list_shops_with_filter(self, shop_service, sample_shop):
        """Test listing shops with status filter"""
        shop_service.shop_repo.list_all = AsyncMock(return_value=[sample_shop])
        shop_service.shop_repo.count_all = AsyncMock(return_value=1)
        
        shops, total = await shop_service.list_shops(status=ShopStatus.ACTIVE)
        
        assert len(shops) == 1
        shop_service.shop_repo.list_all.assert_called_once()
        call_kwargs = shop_service.shop_repo.list_all.call_args.kwargs
        assert call_kwargs['status'] == ShopStatus.ACTIVE
    
    async def test_list_shops_pagination(self, shop_service):
        """Test listing shops with pagination"""
        shop_service.shop_repo.list_all = AsyncMock(return_value=[])
        shop_service.shop_repo.count_all = AsyncMock(return_value=0)
        
        await shop_service.list_shops(page=2, page_size=10)
        
        call_kwargs = shop_service.shop_repo.list_all.call_args.kwargs
        assert call_kwargs['skip'] == 10
        assert call_kwargs['limit'] == 10
