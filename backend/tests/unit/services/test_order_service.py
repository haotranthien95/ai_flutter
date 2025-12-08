"""
Unit tests for Order Service
"""
import pytest
from uuid import uuid4
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi import HTTPException
from decimal import Decimal
from datetime import datetime, timezone

from app.models.order import Order, OrderItem, OrderStatus, PaymentMethod, PaymentStatus
from app.models.product import Product, ProductVariant, ProductCondition
from app.models.shop import Shop, ShopStatus
from app.models.address import Address
from app.schemas.order import (
    OrderCreate,
    OrderItemCreate,
    OrderCancelRequest,
    OrderStatusUpdate,
)
from app.services.order import OrderService


pytestmark = pytest.mark.asyncio


@pytest.fixture
def mock_order_repo():
    """Mock order repository"""
    return AsyncMock()


@pytest.fixture
def mock_order_item_repo():
    """Mock order item repository"""
    return AsyncMock()


@pytest.fixture
def mock_product_repo():
    """Mock product repository"""
    return AsyncMock()


@pytest.fixture
def mock_variant_repo():
    """Mock variant repository"""
    return AsyncMock()


@pytest.fixture
def mock_cart_repo():
    """Mock cart repository"""
    return AsyncMock()


@pytest.fixture
def mock_shop_repo():
    """Mock shop repository"""
    return AsyncMock()


@pytest.fixture
def mock_db():
    """Mock database session"""
    db = AsyncMock()
    db.commit = AsyncMock()
    return db


@pytest.fixture
def order_service(
    mock_order_repo,
    mock_order_item_repo,
    mock_product_repo,
    mock_variant_repo,
    mock_cart_repo,
    mock_shop_repo,
    mock_db
):
    """Create order service with mocked dependencies"""
    return OrderService(
        order_repo=mock_order_repo,
        order_item_repo=mock_order_item_repo,
        product_repo=mock_product_repo,
        variant_repo=mock_variant_repo,
        cart_repo=mock_cart_repo,
        shop_repo=mock_shop_repo,
        db=mock_db,
    )


@pytest.fixture
def sample_user_id():
    """Sample user ID"""
    return uuid4()


@pytest.fixture
def sample_shop_id():
    """Sample shop ID"""
    return uuid4()


@pytest.fixture
def sample_shop(sample_shop_id):
    """Sample shop"""
    return Shop(
        id=sample_shop_id,
        owner_id=uuid4(),
        user_id=uuid4(),
        shop_name="Test Shop",
        description="Test shop",
        business_address="123 Test St",
        shipping_fee=Decimal("20000"),
        status=ShopStatus.ACTIVE,
    )


@pytest.fixture
def sample_address(sample_user_id):
    """Sample address"""
    return Address(
        id=uuid4(),
        user_id=sample_user_id,
        full_name="John Doe",
        phone_number="0912345678",
        address_line1="123 Test St",
        address_line2=None,
        ward="Ward 1",
        district="District 1",
        city="Ho Chi Minh",
        postal_code="700000",
        is_default=True,
    )


@pytest.fixture
def sample_product(sample_shop_id):
    """Sample product"""
    return Product(
        id=uuid4(),
        shop_id=sample_shop_id,
        category_id=uuid4(),
        title="Test Product",
        description="Test description",
        base_price=Decimal("100000"),
        currency="VND",
        total_stock=10,
        images=["image1.jpg"],
        condition=ProductCondition.NEW,
        is_active=True,
    )


@pytest.fixture
def sample_variant(sample_product):
    """Sample variant"""
    return ProductVariant(
        id=uuid4(),
        product_id=sample_product.id,
        name="Red - Large",
        sku="TEST-RED-L",
        price=Decimal("110000"),
        stock=5,
        attributes={"color": "red", "size": "L"},
        is_active=True,
    )


@pytest.fixture
def sample_order(sample_user_id, sample_shop_id):
    """Sample order"""
    order = Order(
        id=uuid4(),
        order_number="ORD-20251205-ABC123",
        buyer_id=sample_user_id,
        shop_id=sample_shop_id,
        address_id=uuid4(),
        shipping_address={"full_name": "John Doe"},
        status=OrderStatus.PENDING,
        payment_method=PaymentMethod.COD,
        payment_status=PaymentStatus.PENDING,
        subtotal=Decimal("200000"),
        shipping_fee=Decimal("20000"),
        discount=Decimal("0"),
        total=Decimal("220000"),
        currency="VND",
    )
    order.items = []
    order.shop = Shop(
        id=sample_shop_id,
        shop_name="Test Shop",
        shipping_fee=Decimal("20000")
    )
    return order


class TestCreateOrders:
    """Tests for create_orders method"""
    
    async def test_create_orders_single_shop_success(
        self,
        order_service,
        mock_product_repo,
        mock_shop_repo,
        mock_order_repo,
        mock_order_item_repo,
        mock_cart_repo,
        sample_user_id,
        sample_product,
        sample_shop,
        sample_address,
    ):
        """Test successful order creation from single shop"""
        # Setup mocks
        mock_product_repo.get_with_variants.return_value = sample_product
        mock_shop_repo.get.return_value = sample_shop
        
        created_order = Order(
            id=uuid4(),
            order_number="ORD-20251205-ABC123",
            buyer_id=sample_user_id,
            shop_id=sample_shop.id,
            status=OrderStatus.PENDING,
            subtotal=Decimal("200000"),
            total=Decimal("220000"),
        )
        created_order.items = []
        created_order.shop = sample_shop
        
        mock_order_repo.create.return_value = created_order
        mock_order_repo.get_with_items.return_value = created_order
        mock_order_item_repo.create.return_value = OrderItem()
        mock_product_repo.update.return_value = sample_product
        mock_cart_repo.clear_user_cart.return_value = None
        
        # Execute
        order_data = OrderCreate(
            items=[
                OrderItemCreate(
                    product_id=sample_product.id,
                    variant_id=None,
                    quantity=2
                )
            ],
            address_id=sample_address.id,
            payment_method=PaymentMethod.COD,
        )
        
        with patch.object(order_service, '_generate_order_number', return_value="ORD-20251205-ABC123"):
            result = await order_service.create_orders(
                sample_user_id,
                order_data,
                sample_address
            )
        
        # Verify
        assert len(result) == 1
        mock_product_repo.get_with_variants.assert_called_once()
        mock_order_repo.create.assert_called_once()
        mock_cart_repo.clear_user_cart.assert_called_once_with(sample_user_id)
    
    async def test_create_orders_product_not_found(
        self,
        order_service,
        mock_product_repo,
        sample_user_id,
        sample_address,
    ):
        """Test order creation fails if product not found"""
        # Setup mocks
        mock_product_repo.get_with_variants.return_value = None
        
        # Execute & Verify
        order_data = OrderCreate(
            items=[
                OrderItemCreate(
                    product_id=uuid4(),
                    variant_id=None,
                    quantity=1
                )
            ],
            address_id=sample_address.id,
            payment_method=PaymentMethod.COD,
        )
        
        with pytest.raises(HTTPException) as exc_info:
            await order_service.create_orders(
                sample_user_id,
                order_data,
                sample_address
            )
        
        assert exc_info.value.status_code == 404
        assert "not found" in exc_info.value.detail.lower()
    
    async def test_create_orders_insufficient_stock(
        self,
        order_service,
        mock_product_repo,
        sample_user_id,
        sample_product,
        sample_address,
    ):
        """Test order creation fails with insufficient stock"""
        # Setup mocks
        sample_product.total_stock = 5
        mock_product_repo.get_with_variants.return_value = sample_product
        
        # Execute & Verify
        order_data = OrderCreate(
            items=[
                OrderItemCreate(
                    product_id=sample_product.id,
                    variant_id=None,
                    quantity=10  # More than available
                )
            ],
            address_id=sample_address.id,
            payment_method=PaymentMethod.COD,
        )
        
        with pytest.raises(HTTPException) as exc_info:
            await order_service.create_orders(
                sample_user_id,
                order_data,
                sample_address
            )
        
        assert exc_info.value.status_code == 400
        assert "stock" in exc_info.value.detail.lower()
    
    async def test_create_orders_with_variant(
        self,
        order_service,
        mock_product_repo,
        mock_variant_repo,
        mock_shop_repo,
        mock_order_repo,
        mock_order_item_repo,
        mock_cart_repo,
        sample_user_id,
        sample_product,
        sample_variant,
        sample_shop,
        sample_address,
    ):
        """Test order creation with product variant"""
        # Setup mocks
        mock_product_repo.get_with_variants.return_value = sample_product
        mock_variant_repo.get.return_value = sample_variant
        mock_shop_repo.get.return_value = sample_shop
        
        created_order = Order(
            id=uuid4(),
            order_number="ORD-20251205-ABC123",
            buyer_id=sample_user_id,
            shop_id=sample_shop.id,
            status=OrderStatus.PENDING,
            total=Decimal("130000"),
        )
        created_order.items = []
        created_order.shop = sample_shop
        
        mock_order_repo.create.return_value = created_order
        mock_order_repo.get_with_items.return_value = created_order
        mock_order_item_repo.create.return_value = OrderItem()
        mock_variant_repo.update.return_value = sample_variant
        
        # Execute
        order_data = OrderCreate(
            items=[
                OrderItemCreate(
                    product_id=sample_product.id,
                    variant_id=sample_variant.id,
                    quantity=1
                )
            ],
            address_id=sample_address.id,
            payment_method=PaymentMethod.COD,
        )
        
        with patch.object(order_service, '_generate_order_number', return_value="ORD-20251205-ABC123"):
            result = await order_service.create_orders(
                sample_user_id,
                order_data,
                sample_address
            )
        
        # Verify
        assert len(result) == 1
        mock_variant_repo.get.assert_called_once_with(sample_variant.id)
        mock_variant_repo.update.assert_called_once()


class TestListOrders:
    """Tests for list_orders method"""
    
    async def test_list_orders_success(
        self,
        order_service,
        mock_order_repo,
        sample_user_id,
    ):
        """Test successful order listing"""
        # Setup mocks
        mock_orders = [
            Order(
                id=uuid4(),
                order_number=f"ORD-20251205-{i}",
                buyer_id=sample_user_id,
                shop_id=uuid4(),
                status=OrderStatus.PENDING,
                total=Decimal("100000"),
                items=[],
                shop=Shop(shop_name=f"Shop {i}")
            )
            for i in range(5)
        ]
        mock_order_repo.list_by_buyer.return_value = (mock_orders, 5)
        
        # Execute
        result = await order_service.list_orders(
            sample_user_id,
            status_filter=None,
            page=1,
            page_size=20
        )
        
        # Verify
        assert result.total == 5
        assert len(result.orders) == 5
        assert result.page == 1
        mock_order_repo.list_by_buyer.assert_called_once()
    
    async def test_list_orders_with_status_filter(
        self,
        order_service,
        mock_order_repo,
        sample_user_id,
    ):
        """Test order listing with status filter"""
        # Setup mocks
        mock_order_repo.list_by_buyer.return_value = ([], 0)
        
        # Execute
        result = await order_service.list_orders(
            sample_user_id,
            status_filter=OrderStatus.COMPLETED,
            page=1,
            page_size=20
        )
        
        # Verify
        mock_order_repo.list_by_buyer.assert_called_once_with(
            buyer_id=sample_user_id,
            status=OrderStatus.COMPLETED,
            skip=0,
            limit=20
        )


class TestGetOrderDetail:
    """Tests for get_order_detail method"""
    
    async def test_get_order_detail_success(
        self,
        order_service,
        mock_order_repo,
        sample_user_id,
        sample_order,
    ):
        """Test successful order detail retrieval"""
        # Setup mocks
        mock_order_repo.get_with_items.return_value = sample_order
        
        # Execute
        result = await order_service.get_order_detail(
            sample_user_id,
            sample_order.id
        )
        
        # Verify
        assert result.id == sample_order.id
        assert result.order_number == sample_order.order_number
    
    async def test_get_order_detail_not_found(
        self,
        order_service,
        mock_order_repo,
        sample_user_id,
    ):
        """Test order detail with non-existent order"""
        # Setup mocks
        mock_order_repo.get_with_items.return_value = None
        
        # Execute & Verify
        with pytest.raises(HTTPException) as exc_info:
            await order_service.get_order_detail(sample_user_id, uuid4())
        
        assert exc_info.value.status_code == 404
    
    async def test_get_order_detail_wrong_user(
        self,
        order_service,
        mock_order_repo,
        sample_order,
    ):
        """Test order detail with wrong user"""
        # Setup mocks
        mock_order_repo.get_with_items.return_value = sample_order
        
        # Execute & Verify
        different_user = uuid4()
        with pytest.raises(HTTPException) as exc_info:
            await order_service.get_order_detail(different_user, sample_order.id)
        
        assert exc_info.value.status_code == 404


class TestCancelOrder:
    """Tests for cancel_order method"""
    
    async def test_cancel_order_success(
        self,
        order_service,
        mock_order_repo,
        mock_product_repo,
        sample_user_id,
        sample_order,
        sample_product,
    ):
        """Test successful order cancellation"""
        # Setup mocks
        sample_order.status = OrderStatus.PENDING
        sample_order.items = [
            OrderItem(
                id=uuid4(),
                order_id=sample_order.id,
                product_id=sample_product.id,
                variant_id=None,
                quantity=2,
                unit_price=Decimal("100000"),
                subtotal=Decimal("200000"),
            )
        ]
        
        mock_order_repo.get_with_items.return_value = sample_order
        mock_order_repo.update.return_value = sample_order
        mock_product_repo.get.return_value = sample_product
        mock_product_repo.update.return_value = sample_product
        
        # Execute
        cancel_request = OrderCancelRequest(reason="Changed my mind")
        result = await order_service.cancel_order(
            sample_user_id,
            sample_order.id,
            cancel_request
        )
        
        # Verify
        assert result.status == OrderStatus.CANCELLED
        assert result.cancellation_reason == "Changed my mind"
        mock_product_repo.update.assert_called_once()  # Stock restored
    
    async def test_cancel_order_invalid_status(
        self,
        order_service,
        mock_order_repo,
        sample_user_id,
        sample_order,
    ):
        """Test cannot cancel order with invalid status"""
        # Setup mocks
        sample_order.status = OrderStatus.SHIPPING
        mock_order_repo.get_with_items.return_value = sample_order
        
        # Execute & Verify
        cancel_request = OrderCancelRequest(reason="Want to cancel")
        with pytest.raises(HTTPException) as exc_info:
            await order_service.cancel_order(
                sample_user_id,
                sample_order.id,
                cancel_request
            )
        
        assert exc_info.value.status_code == 400
        assert "cannot cancel" in exc_info.value.detail.lower()


class TestSellerOrderManagement:
    """Tests for seller order management methods"""
    
    async def test_list_shop_orders_success(
        self,
        order_service,
        mock_order_repo,
        sample_shop_id,
    ):
        """Test successful shop order listing"""
        # Setup mocks
        mock_orders = [
            Order(
                id=uuid4(),
                order_number=f"ORD-20251205-{i}",
                shop_id=sample_shop_id,
                buyer_id=uuid4(),
                status=OrderStatus.PENDING,
                total=Decimal("100000"),
                items=[],
                shop=Shop(shop_name="Test Shop")
            )
            for i in range(3)
        ]
        mock_order_repo.list_by_shop.return_value = (mock_orders, 3)
        
        # Execute
        result = await order_service.list_shop_orders(
            sample_shop_id,
            status_filter=None,
            page=1,
            page_size=20
        )
        
        # Verify
        assert result.total == 3
        assert len(result.orders) == 3
    
    async def test_update_order_status_success(
        self,
        order_service,
        mock_order_repo,
        sample_shop_id,
        sample_order,
    ):
        """Test successful order status update"""
        # Setup mocks
        sample_order.status = OrderStatus.PENDING
        mock_order_repo.get_with_items.return_value = sample_order
        mock_order_repo.update.return_value = sample_order
        
        # Execute
        status_update = OrderStatusUpdate(status=OrderStatus.CONFIRMED)
        result = await order_service.update_order_status(
            sample_shop_id,
            sample_order.id,
            status_update
        )
        
        # Verify
        assert result.status == OrderStatus.CONFIRMED
        mock_order_repo.update.assert_called_once()
    
    async def test_update_order_status_invalid_transition(
        self,
        order_service,
        mock_order_repo,
        sample_shop_id,
        sample_order,
    ):
        """Test invalid status transition"""
        # Setup mocks
        sample_order.status = OrderStatus.PENDING
        mock_order_repo.get_with_items.return_value = sample_order
        
        # Execute & Verify - Try to go from PENDING to SHIPPING (must go through CONFIRMED, PACKED first)
        status_update = OrderStatusUpdate(status=OrderStatus.SHIPPING)
        with pytest.raises(HTTPException) as exc_info:
            await order_service.update_order_status(
                sample_shop_id,
                sample_order.id,
                status_update
            )
        
        assert exc_info.value.status_code == 400
        assert "transition" in exc_info.value.detail.lower()


class TestStatusTransitionValidation:
    """Tests for status transition validation"""
    
    def test_valid_transitions(self, order_service):
        """Test valid status transitions"""
        assert order_service._is_valid_status_transition(
            OrderStatus.PENDING, OrderStatus.CONFIRMED
        )
        assert order_service._is_valid_status_transition(
            OrderStatus.CONFIRMED, OrderStatus.PACKED
        )
        assert order_service._is_valid_status_transition(
            OrderStatus.PACKED, OrderStatus.SHIPPING
        )
        assert order_service._is_valid_status_transition(
            OrderStatus.SHIPPING, OrderStatus.DELIVERED
        )
        assert order_service._is_valid_status_transition(
            OrderStatus.DELIVERED, OrderStatus.COMPLETED
        )
    
    def test_invalid_transitions(self, order_service):
        """Test invalid status transitions"""
        assert not order_service._is_valid_status_transition(
            OrderStatus.PENDING, OrderStatus.SHIPPING
        )
        assert not order_service._is_valid_status_transition(
            OrderStatus.CONFIRMED, OrderStatus.DELIVERED
        )
        assert not order_service._is_valid_status_transition(
            OrderStatus.COMPLETED, OrderStatus.PENDING
        )
