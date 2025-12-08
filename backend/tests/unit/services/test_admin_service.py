"""
Unit tests for AdminService.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4
from datetime import datetime, timedelta

from fastapi import HTTPException

from app.models.user import User, UserRole
from app.models.shop import Shop
from app.models.product import Product
from app.services.admin import AdminService


@pytest.fixture
def mock_user_repo():
    """Mock UserRepository."""
    return AsyncMock()


@pytest.fixture
def mock_shop_repo():
    """Mock ShopRepository."""
    return AsyncMock()


@pytest.fixture
def mock_product_repo():
    """Mock ProductRepository."""
    return AsyncMock()


@pytest.fixture
def mock_order_repo():
    """Mock OrderRepository."""
    return AsyncMock()


@pytest.fixture
def mock_db():
    """Mock database session."""
    mock = AsyncMock()
    mock.execute = AsyncMock()
    mock.commit = AsyncMock()
    mock.refresh = AsyncMock()
    return mock


@pytest.fixture
def admin_service(mock_user_repo, mock_shop_repo, mock_product_repo, mock_order_repo, mock_db):
    """AdminService with mocked dependencies."""
    return AdminService(
        user_repo=mock_user_repo,
        shop_repo=mock_shop_repo,
        product_repo=mock_product_repo,
        order_repo=mock_order_repo,
        db=mock_db,
    )


@pytest.fixture
def buyer_user():
    """Sample buyer user."""
    user = MagicMock(spec=User)
    user.id = uuid4()
    user.role = UserRole.BUYER
    user.is_suspended = False
    user.full_name = "Test Buyer"
    user.phone_number = "+84901234567"
    user.email = "buyer@test.com"
    user.created_at = datetime.utcnow()
    return user


@pytest.fixture
def admin_user():
    """Sample admin user."""
    user = MagicMock(spec=User)
    user.id = uuid4()
    user.role = UserRole.ADMIN
    user.is_suspended = False
    user.full_name = "Admin User"
    user.phone_number = "+84909999999"
    user.email = "admin@test.com"
    user.created_at = datetime.utcnow()
    return user


@pytest.fixture
def shop():
    """Sample shop."""
    shop = MagicMock(spec=Shop)
    shop.id = uuid4()
    shop.name = "Test Shop"
    shop.is_active = True
    shop.created_at = datetime.utcnow()
    return shop


@pytest.fixture
def product():
    """Sample product."""
    product = MagicMock(spec=Product)
    product.id = uuid4()
    product.name = "Test Product"
    product.is_active = True
    product.created_at = datetime.utcnow()
    return product


class TestGetPlatformMetrics:
    """Tests for getting platform metrics."""

    @pytest.mark.asyncio
    async def test_get_platform_metrics_success(self, admin_service, mock_db):
        """Test getting platform metrics successfully."""
        # Mock database query results
        mock_result = MagicMock()
        mock_result.scalar_one.side_effect = [
            100,  # total users
            95,   # active users
            10,   # total shops
            8,    # active shops
            50,   # total products
            45,   # active products
            200,  # total orders
            1000000.0,  # total revenue
            20,   # recent orders
            50000.0,    # recent revenue
        ]
        mock_db.execute.return_value = mock_result

        # Act
        metrics = await admin_service.get_platform_metrics()

        # Assert
        assert metrics["users"]["total"] == 100
        assert metrics["users"]["active"] == 95
        assert metrics["users"]["suspended"] == 5
        assert metrics["shops"]["total"] == 10
        assert metrics["shops"]["active"] == 8
        assert metrics["products"]["total"] == 50
        assert metrics["products"]["active"] == 45
        assert metrics["orders"]["total"] == 200
        assert metrics["revenue"]["total"] == 1000000.0


class TestListUsers:
    """Tests for listing users."""

    @pytest.mark.asyncio
    async def test_list_users_success(self, admin_service, mock_db, buyer_user):
        """Test listing users successfully."""
        # Mock query results
        mock_count_result = MagicMock()
        mock_count_result.scalar_one.return_value = 1
        
        mock_list_result = MagicMock()
        mock_list_result.scalars.return_value.all.return_value = [buyer_user]
        
        mock_db.execute.side_effect = [mock_count_result, mock_list_result]

        # Act
        users, total = await admin_service.list_users(page=1, page_size=20)

        # Assert
        assert len(users) == 1
        assert total == 1
        assert users[0].id == buyer_user.id

    @pytest.mark.asyncio
    async def test_list_users_with_filters(self, admin_service, mock_db):
        """Test listing users with filters."""
        # Mock query results
        mock_count_result = MagicMock()
        mock_count_result.scalar_one.return_value = 0
        
        mock_list_result = MagicMock()
        mock_list_result.scalars.return_value.all.return_value = []
        
        mock_db.execute.side_effect = [mock_count_result, mock_list_result]

        # Act
        users, total = await admin_service.list_users(
            page=1,
            page_size=10,
            role=UserRole.SELLER,
            is_suspended=False,
            search="test"
        )

        # Assert
        assert len(users) == 0
        assert total == 0


class TestSuspendUser:
    """Tests for suspending users."""

    @pytest.mark.asyncio
    async def test_suspend_user_success(self, admin_service, mock_user_repo, mock_db, buyer_user):
        """Test suspending user successfully."""
        # Arrange
        mock_user_repo.get.return_value = buyer_user

        # Act
        result = await admin_service.suspend_user(buyer_user.id, "Policy violation")

        # Assert
        assert result.is_suspended == True
        mock_db.commit.assert_called_once()
        mock_db.refresh.assert_called_once()

    @pytest.mark.asyncio
    async def test_suspend_user_not_found(self, admin_service, mock_user_repo):
        """Test suspending non-existent user."""
        # Arrange
        mock_user_repo.get.return_value = None

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await admin_service.suspend_user(uuid4())

        assert exc_info.value.status_code == 404

    @pytest.mark.asyncio
    async def test_suspend_admin_user_fails(self, admin_service, mock_user_repo, admin_user):
        """Test that admin users cannot be suspended."""
        # Arrange
        mock_user_repo.get.return_value = admin_user

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await admin_service.suspend_user(admin_user.id)

        assert exc_info.value.status_code == 403
        assert "admin" in exc_info.value.detail.lower()

    @pytest.mark.asyncio
    async def test_suspend_already_suspended_user(self, admin_service, mock_user_repo, buyer_user):
        """Test suspending already suspended user."""
        # Arrange
        buyer_user.is_suspended = True
        mock_user_repo.get.return_value = buyer_user

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await admin_service.suspend_user(buyer_user.id)

        assert exc_info.value.status_code == 400


class TestUnsuspendUser:
    """Tests for unsuspending users."""

    @pytest.mark.asyncio
    async def test_unsuspend_user_success(self, admin_service, mock_user_repo, mock_db, buyer_user):
        """Test unsuspending user successfully."""
        # Arrange
        buyer_user.is_suspended = True
        mock_user_repo.get.return_value = buyer_user

        # Act
        result = await admin_service.unsuspend_user(buyer_user.id)

        # Assert
        assert result.is_suspended == False
        mock_db.commit.assert_called_once()

    @pytest.mark.asyncio
    async def test_unsuspend_user_not_found(self, admin_service, mock_user_repo):
        """Test unsuspending non-existent user."""
        # Arrange
        mock_user_repo.get.return_value = None

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await admin_service.unsuspend_user(uuid4())

        assert exc_info.value.status_code == 404

    @pytest.mark.asyncio
    async def test_unsuspend_not_suspended_user(self, admin_service, mock_user_repo, buyer_user):
        """Test unsuspending user that isn't suspended."""
        # Arrange
        buyer_user.is_suspended = False
        mock_user_repo.get.return_value = buyer_user

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await admin_service.unsuspend_user(buyer_user.id)

        assert exc_info.value.status_code == 400


class TestShopManagement:
    """Tests for shop management."""

    @pytest.mark.asyncio
    async def test_list_shops_success(self, admin_service, mock_db, shop):
        """Test listing shops successfully."""
        # Mock query results
        mock_count_result = MagicMock()
        mock_count_result.scalar_one.return_value = 1
        
        mock_list_result = MagicMock()
        mock_list_result.scalars.return_value.all.return_value = [shop]
        
        mock_db.execute.side_effect = [mock_count_result, mock_list_result]

        # Act
        shops, total = await admin_service.list_shops(page=1, page_size=20)

        # Assert
        assert len(shops) == 1
        assert total == 1

    @pytest.mark.asyncio
    async def test_update_shop_status_success(self, admin_service, mock_shop_repo, mock_db, shop):
        """Test updating shop status successfully."""
        # Arrange
        mock_shop_repo.get.return_value = shop

        # Act
        result = await admin_service.update_shop_status(shop.id, False, "Violation")

        # Assert
        assert result.is_active == False
        mock_db.commit.assert_called_once()

    @pytest.mark.asyncio
    async def test_update_shop_status_not_found(self, admin_service, mock_shop_repo):
        """Test updating non-existent shop status."""
        # Arrange
        mock_shop_repo.get.return_value = None

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await admin_service.update_shop_status(uuid4(), False)

        assert exc_info.value.status_code == 404


class TestProductModeration:
    """Tests for product moderation."""

    @pytest.mark.asyncio
    async def test_list_all_products_success(self, admin_service, mock_db, product):
        """Test listing all products successfully."""
        # Mock query results
        mock_count_result = MagicMock()
        mock_count_result.scalar_one.return_value = 1
        
        mock_list_result = MagicMock()
        mock_list_result.scalars.return_value.all.return_value = [product]
        
        mock_db.execute.side_effect = [mock_count_result, mock_list_result]

        # Act
        products, total = await admin_service.list_all_products(page=1, page_size=20)

        # Assert
        assert len(products) == 1
        assert total == 1

    @pytest.mark.asyncio
    async def test_moderate_product_success(self, admin_service, mock_product_repo, mock_db, product):
        """Test moderating product successfully."""
        # Arrange
        mock_product_repo.get.return_value = product

        # Act
        result = await admin_service.moderate_product(product.id, False, "Policy violation")

        # Assert
        assert result.is_active == False
        mock_db.commit.assert_called_once()

    @pytest.mark.asyncio
    async def test_moderate_product_not_found(self, admin_service, mock_product_repo):
        """Test moderating non-existent product."""
        # Arrange
        mock_product_repo.get.return_value = None

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await admin_service.moderate_product(uuid4(), False)

        assert exc_info.value.status_code == 404
