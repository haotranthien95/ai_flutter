"""
Unit tests for Voucher service
"""
from datetime import datetime, timedelta
from decimal import Decimal
from uuid import uuid4

import pytest
from fastapi import HTTPException
from unittest.mock import AsyncMock

from app.models.voucher import Voucher, VoucherType
from app.models.shop import Shop, ShopStatus
from app.schemas.voucher import VoucherCreate, VoucherUpdate
from app.services.voucher import VoucherService


# Fixtures
@pytest.fixture
def mock_voucher_repo():
    """Mock voucher repository"""
    return AsyncMock()


@pytest.fixture
def mock_shop_repo():
    """Mock shop repository"""
    return AsyncMock()


@pytest.fixture
def voucher_service(mock_voucher_repo, mock_shop_repo):
    """Voucher service instance"""
    return VoucherService(
        voucher_repo=mock_voucher_repo,
        shop_repo=mock_shop_repo
    )


@pytest.fixture
def test_shop():
    """Test shop"""
    return Shop(
        id=uuid4(),
        owner_id=uuid4(),
        shop_name="Test Shop",
        status=ShopStatus.ACTIVE,
        shipping_fee=Decimal("5.00")
    )


@pytest.fixture
def test_percentage_voucher(test_shop):
    """Test percentage voucher"""
    return Voucher(
        id=uuid4(),
        shop_id=test_shop.id,
        code="SAVE20",
        title="20% Off",
        description="Save 20% on your order",
        type=VoucherType.PERCENTAGE,
        value=Decimal("20"),
        min_order_value=Decimal("100"),
        max_discount=Decimal("50"),
        usage_limit=100,
        usage_count=0,
        start_date=datetime.utcnow() - timedelta(days=1),
        end_date=datetime.utcnow() + timedelta(days=30),
        is_active=True
    )


@pytest.fixture
def test_fixed_voucher(test_shop):
    """Test fixed amount voucher"""
    return Voucher(
        id=uuid4(),
        shop_id=test_shop.id,
        code="FLAT50",
        title="$50 Off",
        description="Save $50 on your order",
        type=VoucherType.FIXED_AMOUNT,
        value=Decimal("50"),
        min_order_value=Decimal("200"),
        max_discount=None,
        usage_limit=None,  # Unlimited
        usage_count=0,
        start_date=datetime.utcnow() - timedelta(days=1),
        end_date=datetime.utcnow() + timedelta(days=30),
        is_active=True
    )


# Test Create Voucher
class TestCreateVoucher:
    """Tests for creating vouchers"""
    
    @pytest.mark.asyncio
    async def test_create_voucher_success(
        self,
        voucher_service,
        mock_voucher_repo,
        mock_shop_repo,
        test_shop
    ):
        """Test successful voucher creation"""
        seller_id = test_shop.owner_id
        
        voucher_data = VoucherCreate(
            code="NEWCODE",
            title="New Voucher",
            description="Test voucher",
            type=VoucherType.PERCENTAGE,
            value=Decimal("10"),
            min_order_value=Decimal("50"),
            max_discount=Decimal("20"),
            usage_limit=50,
            start_date=datetime.utcnow(),
            end_date=datetime.utcnow() + timedelta(days=30),
            is_active=True
        )
        
        # Mock shop exists and belongs to seller
        mock_shop_repo.get.return_value = test_shop
        
        # Mock code doesn't exist
        mock_voucher_repo.code_exists.return_value = False
        
        # Mock voucher creation
        created_voucher = Voucher(
            id=uuid4(),
            shop_id=test_shop.id,
            **voucher_data.model_dump()
        )
        mock_voucher_repo.create.return_value = created_voucher
        
        # Create voucher
        result = await voucher_service.create_voucher(
            shop_id=test_shop.id,
            voucher_data=voucher_data,
            seller_id=seller_id
        )
        
        assert result.code == "NEWCODE"
        assert result.type == VoucherType.PERCENTAGE
        assert result.value == Decimal("10")
        mock_voucher_repo.create.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_create_voucher_shop_not_found(
        self,
        voucher_service,
        mock_shop_repo
    ):
        """Test voucher creation with non-existent shop"""
        voucher_data = VoucherCreate(
            code="TEST",
            title="Test",
            type=VoucherType.PERCENTAGE,
            value=Decimal("10"),
            start_date=datetime.utcnow(),
            end_date=datetime.utcnow() + timedelta(days=1)
        )
        
        mock_shop_repo.get.return_value = None
        
        with pytest.raises(HTTPException) as exc_info:
            await voucher_service.create_voucher(
                shop_id=uuid4(),
                voucher_data=voucher_data,
                seller_id=uuid4()
            )
        
        assert exc_info.value.status_code == 404
        assert "Shop not found" in exc_info.value.detail
    
    @pytest.mark.asyncio
    async def test_create_voucher_unauthorized(
        self,
        voucher_service,
        mock_shop_repo,
        test_shop
    ):
        """Test voucher creation by unauthorized seller"""
        voucher_data = VoucherCreate(
            code="TEST",
            title="Test",
            type=VoucherType.PERCENTAGE,
            value=Decimal("10"),
            start_date=datetime.utcnow(),
            end_date=datetime.utcnow() + timedelta(days=1)
        )
        
        mock_shop_repo.get.return_value = test_shop
        
        # Different seller ID
        wrong_seller_id = uuid4()
        
        with pytest.raises(HTTPException) as exc_info:
            await voucher_service.create_voucher(
                shop_id=test_shop.id,
                voucher_data=voucher_data,
                seller_id=wrong_seller_id
            )
        
        assert exc_info.value.status_code == 403
        assert "Not authorized" in exc_info.value.detail
    
    @pytest.mark.asyncio
    async def test_create_voucher_duplicate_code(
        self,
        voucher_service,
        mock_voucher_repo,
        mock_shop_repo,
        test_shop
    ):
        """Test voucher creation with duplicate code"""
        voucher_data = VoucherCreate(
            code="EXISTING",
            title="Test",
            type=VoucherType.PERCENTAGE,
            value=Decimal("10"),
            start_date=datetime.utcnow(),
            end_date=datetime.utcnow() + timedelta(days=1)
        )
        
        mock_shop_repo.get.return_value = test_shop
        mock_voucher_repo.code_exists.return_value = True
        
        with pytest.raises(HTTPException) as exc_info:
            await voucher_service.create_voucher(
                shop_id=test_shop.id,
                voucher_data=voucher_data,
                seller_id=test_shop.owner_id
            )
        
        assert exc_info.value.status_code == 400
        assert "already exists" in exc_info.value.detail
    
    @pytest.mark.asyncio
    async def test_create_voucher_invalid_percentage(
        self,
        voucher_service,
        mock_voucher_repo,
        mock_shop_repo,
        test_shop
    ):
        """Test voucher creation with percentage > 100"""
        voucher_data = VoucherCreate(
            code="INVALID",
            title="Test",
            type=VoucherType.PERCENTAGE,
            value=Decimal("150"),  # Invalid
            start_date=datetime.utcnow(),
            end_date=datetime.utcnow() + timedelta(days=1)
        )
        
        mock_shop_repo.get.return_value = test_shop
        mock_voucher_repo.code_exists.return_value = False
        
        with pytest.raises(HTTPException) as exc_info:
            await voucher_service.create_voucher(
                shop_id=test_shop.id,
                voucher_data=voucher_data,
                seller_id=test_shop.owner_id
            )
        
        assert exc_info.value.status_code == 400
        assert "cannot exceed 100" in exc_info.value.detail


# Test Validate Voucher
class TestValidateVoucher:
    """Tests for voucher validation"""
    
    @pytest.mark.asyncio
    async def test_validate_percentage_voucher_success(
        self,
        voucher_service,
        mock_voucher_repo,
        test_percentage_voucher
    ):
        """Test valid percentage voucher"""
        mock_voucher_repo.get_by_code_and_shop.return_value = test_percentage_voucher
        
        result = await voucher_service.validate_voucher(
            code="SAVE20",
            shop_id=test_percentage_voucher.shop_id,
            subtotal=Decimal("150")
        )
        
        assert result.valid is True
        assert result.discount_amount == Decimal("30")  # 20% of 150
        assert result.voucher is not None
    
    @pytest.mark.asyncio
    async def test_validate_percentage_voucher_with_max_cap(
        self,
        voucher_service,
        mock_voucher_repo,
        test_percentage_voucher
    ):
        """Test percentage voucher with max discount cap"""
        mock_voucher_repo.get_by_code_and_shop.return_value = test_percentage_voucher
        
        # Order of 500 would give 100 discount, but max is 50
        result = await voucher_service.validate_voucher(
            code="SAVE20",
            shop_id=test_percentage_voucher.shop_id,
            subtotal=Decimal("500")
        )
        
        assert result.valid is True
        assert result.discount_amount == Decimal("50")  # Capped at max_discount
    
    @pytest.mark.asyncio
    async def test_validate_fixed_voucher_success(
        self,
        voucher_service,
        mock_voucher_repo,
        test_fixed_voucher
    ):
        """Test valid fixed amount voucher"""
        mock_voucher_repo.get_by_code_and_shop.return_value = test_fixed_voucher
        
        result = await voucher_service.validate_voucher(
            code="FLAT50",
            shop_id=test_fixed_voucher.shop_id,
            subtotal=Decimal("250")
        )
        
        assert result.valid is True
        assert result.discount_amount == Decimal("50")
    
    @pytest.mark.asyncio
    async def test_validate_fixed_voucher_exceeds_subtotal(
        self,
        voucher_service,
        mock_voucher_repo,
        test_fixed_voucher
    ):
        """Test fixed voucher doesn't exceed subtotal"""
        mock_voucher_repo.get_by_code_and_shop.return_value = test_fixed_voucher
        
        # Subtotal less than voucher value
        result = await voucher_service.validate_voucher(
            code="FLAT50",
            shop_id=test_fixed_voucher.shop_id,
            subtotal=Decimal("220")  # Still meets min order value of 200
        )
        
        assert result.valid is True
        assert result.discount_amount == Decimal("50")
    
    @pytest.mark.asyncio
    async def test_validate_voucher_not_found(
        self,
        voucher_service,
        mock_voucher_repo
    ):
        """Test validation with non-existent voucher"""
        mock_voucher_repo.get_by_code_and_shop.return_value = None
        
        result = await voucher_service.validate_voucher(
            code="NONEXISTENT",
            shop_id=uuid4(),
            subtotal=Decimal("100")
        )
        
        assert result.valid is False
        assert "not found" in result.message
    
    @pytest.mark.asyncio
    async def test_validate_voucher_inactive(
        self,
        voucher_service,
        mock_voucher_repo,
        test_percentage_voucher
    ):
        """Test validation with inactive voucher"""
        test_percentage_voucher.is_active = False
        mock_voucher_repo.get_by_code_and_shop.return_value = test_percentage_voucher
        
        result = await voucher_service.validate_voucher(
            code="SAVE20",
            shop_id=test_percentage_voucher.shop_id,
            subtotal=Decimal("150")
        )
        
        assert result.valid is False
        assert "not active" in result.message
    
    @pytest.mark.asyncio
    async def test_validate_voucher_not_yet_started(
        self,
        voucher_service,
        mock_voucher_repo,
        test_percentage_voucher
    ):
        """Test validation with voucher not yet valid"""
        test_percentage_voucher.start_date = datetime.utcnow() + timedelta(days=1)
        mock_voucher_repo.get_by_code_and_shop.return_value = test_percentage_voucher
        
        result = await voucher_service.validate_voucher(
            code="SAVE20",
            shop_id=test_percentage_voucher.shop_id,
            subtotal=Decimal("150")
        )
        
        assert result.valid is False
        assert "not yet valid" in result.message
    
    @pytest.mark.asyncio
    async def test_validate_voucher_expired(
        self,
        voucher_service,
        mock_voucher_repo,
        test_percentage_voucher
    ):
        """Test validation with expired voucher"""
        test_percentage_voucher.end_date = datetime.utcnow() - timedelta(days=1)
        mock_voucher_repo.get_by_code_and_shop.return_value = test_percentage_voucher
        
        result = await voucher_service.validate_voucher(
            code="SAVE20",
            shop_id=test_percentage_voucher.shop_id,
            subtotal=Decimal("150")
        )
        
        assert result.valid is False
        assert "expired" in result.message
    
    @pytest.mark.asyncio
    async def test_validate_voucher_usage_limit_reached(
        self,
        voucher_service,
        mock_voucher_repo,
        test_percentage_voucher
    ):
        """Test validation with usage limit reached"""
        test_percentage_voucher.usage_count = 100
        test_percentage_voucher.usage_limit = 100
        mock_voucher_repo.get_by_code_and_shop.return_value = test_percentage_voucher
        
        result = await voucher_service.validate_voucher(
            code="SAVE20",
            shop_id=test_percentage_voucher.shop_id,
            subtotal=Decimal("150")
        )
        
        assert result.valid is False
        assert "usage limit" in result.message
    
    @pytest.mark.asyncio
    async def test_validate_voucher_below_min_order(
        self,
        voucher_service,
        mock_voucher_repo,
        test_percentage_voucher
    ):
        """Test validation with order below minimum"""
        mock_voucher_repo.get_by_code_and_shop.return_value = test_percentage_voucher
        
        result = await voucher_service.validate_voucher(
            code="SAVE20",
            shop_id=test_percentage_voucher.shop_id,
            subtotal=Decimal("50")  # Below min_order_value of 100
        )
        
        assert result.valid is False
        assert "Minimum order value" in result.message


# Test Get Available Vouchers
class TestGetAvailableVouchers:
    """Tests for getting available vouchers"""
    
    @pytest.mark.asyncio
    async def test_get_available_vouchers_success(
        self,
        voucher_service,
        mock_voucher_repo,
        test_percentage_voucher,
        test_fixed_voucher
    ):
        """Test getting available vouchers"""
        shop_id = test_percentage_voucher.shop_id
        vouchers = [test_percentage_voucher, test_fixed_voucher]
        
        mock_voucher_repo.get_available_for_order.return_value = vouchers
        
        result = await voucher_service.get_available_vouchers(
            shop_id=shop_id,
            subtotal=Decimal("250")
        )
        
        assert result.total == 2
        assert len(result.available_vouchers) == 2
        mock_voucher_repo.get_available_for_order.assert_called_once_with(
            shop_id=shop_id,
            subtotal=Decimal("250")
        )
    
    @pytest.mark.asyncio
    async def test_get_available_vouchers_empty(
        self,
        voucher_service,
        mock_voucher_repo
    ):
        """Test getting available vouchers when none available"""
        mock_voucher_repo.get_available_for_order.return_value = []
        
        result = await voucher_service.get_available_vouchers(
            shop_id=uuid4(),
            subtotal=Decimal("50")
        )
        
        assert result.total == 0
        assert len(result.available_vouchers) == 0


# Test Update Voucher
class TestUpdateVoucher:
    """Tests for updating vouchers"""
    
    @pytest.mark.asyncio
    async def test_update_voucher_success(
        self,
        voucher_service,
        mock_voucher_repo,
        mock_shop_repo,
        test_percentage_voucher,
        test_shop
    ):
        """Test successful voucher update"""
        mock_voucher_repo.get.return_value = test_percentage_voucher
        mock_shop_repo.get.return_value = test_shop
        
        update_data = VoucherUpdate(
            title="Updated Title",
            value=Decimal("25")
        )
        
        mock_voucher_repo.update.return_value = test_percentage_voucher
        
        result = await voucher_service.update_voucher(
            voucher_id=test_percentage_voucher.id,
            voucher_data=update_data,
            seller_id=test_shop.owner_id
        )
        
        assert result is not None
        mock_voucher_repo.update.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_update_voucher_not_found(
        self,
        voucher_service,
        mock_voucher_repo
    ):
        """Test updating non-existent voucher"""
        mock_voucher_repo.get.return_value = None
        
        update_data = VoucherUpdate(title="New Title")
        
        with pytest.raises(HTTPException) as exc_info:
            await voucher_service.update_voucher(
                voucher_id=uuid4(),
                voucher_data=update_data,
                seller_id=uuid4()
            )
        
        assert exc_info.value.status_code == 404


# Test Apply Voucher to Order
class TestApplyVoucherToOrder:
    """Tests for applying vouchers to orders"""
    
    @pytest.mark.asyncio
    async def test_apply_voucher_success(
        self,
        voucher_service,
        mock_voucher_repo,
        test_percentage_voucher
    ):
        """Test successfully applying voucher to order"""
        mock_voucher_repo.get.return_value = test_percentage_voucher
        
        discount = await voucher_service.apply_voucher_to_order(
            voucher_id=test_percentage_voucher.id,
            subtotal=Decimal("150")
        )
        
        assert discount == Decimal("30")  # 20% of 150
        mock_voucher_repo.increment_usage.assert_called_once_with(test_percentage_voucher.id)
    
    @pytest.mark.asyncio
    async def test_apply_voucher_not_found(
        self,
        voucher_service,
        mock_voucher_repo
    ):
        """Test applying non-existent voucher"""
        mock_voucher_repo.get.return_value = None
        
        with pytest.raises(HTTPException) as exc_info:
            await voucher_service.apply_voucher_to_order(
                voucher_id=uuid4(),
                subtotal=Decimal("150")
            )
        
        assert exc_info.value.status_code == 404
    
    @pytest.mark.asyncio
    async def test_apply_voucher_cannot_apply(
        self,
        voucher_service,
        mock_voucher_repo,
        test_percentage_voucher
    ):
        """Test applying voucher that doesn't meet conditions"""
        test_percentage_voucher.is_active = False
        mock_voucher_repo.get.return_value = test_percentage_voucher
        
        with pytest.raises(HTTPException) as exc_info:
            await voucher_service.apply_voucher_to_order(
                voucher_id=test_percentage_voucher.id,
                subtotal=Decimal("150")
            )
        
        assert exc_info.value.status_code == 400
        assert "cannot be applied" in exc_info.value.detail
