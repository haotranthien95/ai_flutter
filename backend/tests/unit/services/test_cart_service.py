"""
Unit tests for Cart service
"""
import pytest
from unittest.mock import AsyncMock
from decimal import Decimal
from uuid import uuid4

from fastapi import HTTPException

from app.services.cart import CartService
from app.models.cart import CartItem
from app.models.product import Product, ProductVariant, ProductCondition
from app.models.shop import Shop
from app.schemas.cart import CartItemCreate, CartItemUpdate, CartSyncRequest


@pytest.fixture
def mock_cart_repo():
    """Mock cart repository"""
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
def cart_service(mock_cart_repo, mock_product_repo, mock_variant_repo):
    """Create cart service with mocked dependencies"""
    return CartService(
        cart_repo=mock_cart_repo,
        product_repo=mock_product_repo,
        variant_repo=mock_variant_repo,
    )


@pytest.fixture
def sample_user_id():
    """Sample user ID"""
    return uuid4()


@pytest.fixture
def sample_product():
    """Sample product"""
    product = Product(
        id=uuid4(),
        shop_id=uuid4(),
        category_id=uuid4(),
        title="Test Product",
        description="Test description",
        base_price=Decimal("100000"),
        currency="VND",
        total_stock=10,
        images=["image1.jpg"],
        condition=ProductCondition.NEW,
        is_active=True
    )
    # Set relationships
    product.shop = Shop(
        id=product.shop_id,
        name="Test Shop",
        description="Test shop",
        business_address="123 Test St",
        shipping_fee=Decimal("20000")
    )
    return product


@pytest.fixture
def sample_variant(sample_product):
    """Sample variant"""
    return ProductVariant(
        id=uuid4(),
        product_id=sample_product.id,
        name="Red - Large",
        attributes={"color": "red", "size": "L"},
        sku="TEST-PROD-RED-L",
        price=Decimal("110000"),
        stock=5,
        is_active=True
    )


@pytest.fixture
def sample_cart_item(sample_user_id, sample_product):
    """Sample cart item"""
    item = CartItem(
        id=uuid4(),
        user_id=sample_user_id,
        product_id=sample_product.id,
        variant_id=None,
        quantity=2
    )
    item.product = sample_product
    item.variant = None
    return item


class TestGetCart:
    """Tests for get_cart method"""
    
    @pytest.mark.asyncio
    async def test_get_cart_success(
        self,
        cart_service,
        mock_cart_repo,
        mock_product_repo,
        sample_user_id,
        sample_cart_item
    ):
        """Test successful cart retrieval"""
        # Setup mocks
        mock_cart_repo.list_by_user.return_value = [sample_cart_item]
        mock_product_repo.get.return_value = sample_cart_item.product
        
        # Execute
        result = await cart_service.get_cart(sample_user_id)
        
        # Verify
        assert result.total_items == 1
        assert result.total_quantity == 2
        assert len(result.items) == 1
        mock_cart_repo.list_by_user.assert_called_once_with(sample_user_id, load_relations=True)
    
    @pytest.mark.asyncio
    async def test_get_cart_empty(
        self,
        cart_service,
        mock_cart_repo,
        sample_user_id
    ):
        """Test getting empty cart"""
        # Setup mocks
        mock_cart_repo.list_by_user.return_value = []
        
        # Execute
        result = await cart_service.get_cart(sample_user_id)
        
        # Verify
        assert result.total_items == 0
        assert result.total_quantity == 0
        assert result.total_price == Decimal('0')
        assert len(result.items) == 0


class TestAddToCart:
    """Tests for add_to_cart method"""
    
    @pytest.mark.asyncio
    async def test_add_to_cart_new_item(
        self,
        cart_service,
        mock_cart_repo,
        mock_product_repo,
        sample_user_id,
        sample_product,
        sample_cart_item
    ):
        """Test adding new item to cart"""
        # Setup mocks
        mock_product_repo.get_with_variants.return_value = sample_product
        mock_cart_repo.find_item.return_value = None
        mock_cart_repo.create.return_value = sample_cart_item
        mock_cart_repo.get_with_relations.return_value = sample_cart_item
        
        # Execute
        item_data = CartItemCreate(
            product_id=sample_product.id,
            variant_id=None,
            quantity=2
        )
        result = await cart_service.add_to_cart(sample_user_id, item_data)
        
        # Verify
        assert result.quantity == 2
        mock_product_repo.get_with_variants.assert_called_once_with(sample_product.id)
        mock_cart_repo.find_item.assert_called_once()
        mock_cart_repo.create.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_add_to_cart_existing_item(
        self,
        cart_service,
        mock_cart_repo,
        mock_product_repo,
        sample_user_id,
        sample_product,
        sample_cart_item
    ):
        """Test adding to existing cart item (increment quantity)"""
        # Setup mocks
        existing_item = sample_cart_item
        existing_item.quantity = 2
        
        mock_product_repo.get_with_variants.return_value = sample_product
        mock_cart_repo.find_item.return_value = existing_item
        
        updated_item = sample_cart_item
        updated_item.quantity = 4
        mock_cart_repo.update.return_value = updated_item
        mock_cart_repo.get_with_relations.return_value = updated_item
        
        # Execute
        item_data = CartItemCreate(
            product_id=sample_product.id,
            variant_id=None,
            quantity=2
        )
        result = await cart_service.add_to_cart(sample_user_id, item_data)
        
        # Verify
        assert result.quantity == 4
        mock_cart_repo.update.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_add_to_cart_product_not_found(
        self,
        cart_service,
        mock_product_repo,
        sample_user_id
    ):
        """Test adding non-existent product"""
        # Setup mocks
        mock_product_repo.get_with_variants.return_value = None
        
        # Execute & Verify
        item_data = CartItemCreate(
            product_id=uuid4(),
            variant_id=None,
            quantity=1
        )
        with pytest.raises(HTTPException) as exc_info:
            await cart_service.add_to_cart(sample_user_id, item_data)
        
        assert exc_info.value.status_code == 404
        assert "not found" in exc_info.value.detail.lower()
    
    @pytest.mark.asyncio
    async def test_add_to_cart_inactive_product(
        self,
        cart_service,
        mock_product_repo,
        sample_user_id,
        sample_product
    ):
        """Test adding inactive product"""
        # Setup mocks
        sample_product.is_active = False
        mock_product_repo.get_with_variants.return_value = sample_product
        
        # Execute & Verify
        item_data = CartItemCreate(
            product_id=sample_product.id,
            variant_id=None,
            quantity=1
        )
        with pytest.raises(HTTPException) as exc_info:
            await cart_service.add_to_cart(sample_user_id, item_data)
        
        assert exc_info.value.status_code == 404
    
    @pytest.mark.asyncio
    async def test_add_to_cart_insufficient_stock(
        self,
        cart_service,
        mock_cart_repo,
        mock_product_repo,
        sample_user_id,
        sample_product
    ):
        """Test adding more than available stock"""
        # Setup mocks
        sample_product.total_stock = 5
        mock_product_repo.get_with_variants.return_value = sample_product
        mock_cart_repo.find_item.return_value = None
        
        # Execute & Verify
        item_data = CartItemCreate(
            product_id=sample_product.id,
            variant_id=None,
            quantity=10  # More than available
        )
        with pytest.raises(HTTPException) as exc_info:
            await cart_service.add_to_cart(sample_user_id, item_data)
        
        assert exc_info.value.status_code == 400
        assert "stock" in exc_info.value.detail.lower()
    
    @pytest.mark.asyncio
    async def test_add_to_cart_with_variant(
        self,
        cart_service,
        mock_cart_repo,
        mock_product_repo,
        mock_variant_repo,
        sample_user_id,
        sample_product,
        sample_variant,
        sample_cart_item
    ):
        """Test adding item with variant"""
        # Setup mocks
        mock_product_repo.get_with_variants.return_value = sample_product
        mock_variant_repo.get.return_value = sample_variant
        mock_cart_repo.find_item.return_value = None
        
        cart_item_with_variant = sample_cart_item
        cart_item_with_variant.variant_id = sample_variant.id
        cart_item_with_variant.variant = sample_variant
        
        mock_cart_repo.create.return_value = cart_item_with_variant
        mock_cart_repo.get_with_relations.return_value = cart_item_with_variant
        
        # Execute
        item_data = CartItemCreate(
            product_id=sample_product.id,
            variant_id=sample_variant.id,
            quantity=2
        )
        result = await cart_service.add_to_cart(sample_user_id, item_data)
        
        # Verify
        assert result.variant_id == sample_variant.id
        mock_variant_repo.get.assert_called_once_with(sample_variant.id)
    
    @pytest.mark.asyncio
    async def test_add_to_cart_invalid_variant(
        self,
        cart_service,
        mock_product_repo,
        mock_variant_repo,
        sample_user_id,
        sample_product
    ):
        """Test adding with non-existent variant"""
        # Setup mocks
        mock_product_repo.get_with_variants.return_value = sample_product
        mock_variant_repo.get.return_value = None
        
        # Execute & Verify
        item_data = CartItemCreate(
            product_id=sample_product.id,
            variant_id=uuid4(),
            quantity=1
        )
        with pytest.raises(HTTPException) as exc_info:
            await cart_service.add_to_cart(sample_user_id, item_data)
        
        assert exc_info.value.status_code == 404
        assert "variant" in exc_info.value.detail.lower()


class TestUpdateCartItem:
    """Tests for update_cart_item method"""
    
    @pytest.mark.asyncio
    async def test_update_cart_item_success(
        self,
        cart_service,
        mock_cart_repo,
        sample_user_id,
        sample_cart_item
    ):
        """Test successful cart item update"""
        # Setup mocks
        mock_cart_repo.get_with_relations.return_value = sample_cart_item
        
        updated_item = sample_cart_item
        updated_item.quantity = 5
        mock_cart_repo.update.return_value = updated_item
        
        # Execute
        update_data = CartItemUpdate(quantity=5)
        result = await cart_service.update_cart_item(
            sample_user_id,
            sample_cart_item.id,
            update_data
        )
        
        # Verify
        assert result.quantity == 5
        mock_cart_repo.update.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_update_cart_item_not_found(
        self,
        cart_service,
        mock_cart_repo,
        sample_user_id
    ):
        """Test updating non-existent cart item"""
        # Setup mocks
        mock_cart_repo.get_with_relations.return_value = None
        
        # Execute & Verify
        update_data = CartItemUpdate(quantity=5)
        with pytest.raises(HTTPException) as exc_info:
            await cart_service.update_cart_item(
                sample_user_id,
                uuid4(),
                update_data
            )
        
        assert exc_info.value.status_code == 404
    
    @pytest.mark.asyncio
    async def test_update_cart_item_wrong_user(
        self,
        cart_service,
        mock_cart_repo,
        sample_cart_item
    ):
        """Test updating other user's cart item"""
        # Setup mocks
        mock_cart_repo.get_with_relations.return_value = sample_cart_item
        
        # Execute & Verify
        different_user = uuid4()
        update_data = CartItemUpdate(quantity=5)
        with pytest.raises(HTTPException) as exc_info:
            await cart_service.update_cart_item(
                different_user,
                sample_cart_item.id,
                update_data
            )
        
        assert exc_info.value.status_code == 404
    
    @pytest.mark.asyncio
    async def test_update_cart_item_insufficient_stock(
        self,
        cart_service,
        mock_cart_repo,
        sample_user_id,
        sample_cart_item,
        sample_product
    ):
        """Test updating quantity beyond stock"""
        # Setup mocks
        sample_product.total_stock = 5
        sample_cart_item.product = sample_product
        mock_cart_repo.get_with_relations.return_value = sample_cart_item
        
        # Execute & Verify
        update_data = CartItemUpdate(quantity=10)
        with pytest.raises(HTTPException) as exc_info:
            await cart_service.update_cart_item(
                sample_user_id,
                sample_cart_item.id,
                update_data
            )
        
        assert exc_info.value.status_code == 400
        assert "stock" in exc_info.value.detail.lower()


class TestRemoveFromCart:
    """Tests for remove_from_cart method"""
    
    @pytest.mark.asyncio
    async def test_remove_from_cart_success(
        self,
        cart_service,
        mock_cart_repo,
        sample_user_id,
        sample_cart_item
    ):
        """Test successful cart item removal"""
        # Setup mocks
        mock_cart_repo.get.return_value = sample_cart_item
        mock_cart_repo.delete.return_value = None
        
        # Execute
        await cart_service.remove_from_cart(sample_user_id, sample_cart_item.id)
        
        # Verify
        mock_cart_repo.delete.assert_called_once_with(sample_cart_item.id)
    
    @pytest.mark.asyncio
    async def test_remove_from_cart_not_found(
        self,
        cart_service,
        mock_cart_repo,
        sample_user_id
    ):
        """Test removing non-existent cart item"""
        # Setup mocks
        mock_cart_repo.get.return_value = None
        
        # Execute & Verify
        with pytest.raises(HTTPException) as exc_info:
            await cart_service.remove_from_cart(sample_user_id, uuid4())
        
        assert exc_info.value.status_code == 404
    
    @pytest.mark.asyncio
    async def test_remove_from_cart_wrong_user(
        self,
        cart_service,
        mock_cart_repo,
        sample_cart_item
    ):
        """Test removing other user's cart item"""
        # Setup mocks
        mock_cart_repo.get.return_value = sample_cart_item
        
        # Execute & Verify
        different_user = uuid4()
        with pytest.raises(HTTPException) as exc_info:
            await cart_service.remove_from_cart(different_user, sample_cart_item.id)
        
        assert exc_info.value.status_code == 404


class TestSyncCart:
    """Tests for sync_cart method"""
    
    @pytest.mark.asyncio
    async def test_sync_cart_success(
        self,
        cart_service,
        mock_cart_repo,
        mock_product_repo,
        mock_variant_repo,
        sample_user_id,
        sample_product,
        sample_cart_item
    ):
        """Test successful cart sync"""
        # Setup mocks
        mock_cart_repo.clear_user_cart.return_value = None
        mock_product_repo.get_with_variants.return_value = sample_product
        mock_cart_repo.find_item.return_value = None
        mock_cart_repo.create.return_value = sample_cart_item
        mock_cart_repo.get_with_relations.return_value = sample_cart_item
        mock_cart_repo.list_by_user.return_value = [sample_cart_item]
        mock_product_repo.get.return_value = sample_product
        
        # Execute
        sync_request = CartSyncRequest(
            items=[
                CartItemCreate(
                    product_id=sample_product.id,
                    variant_id=None,
                    quantity=2
                )
            ]
        )
        result = await cart_service.sync_cart(sample_user_id, sync_request)
        
        # Verify
        assert result.total_items >= 1
        mock_cart_repo.clear_user_cart.assert_called_once_with(sample_user_id)
    
    @pytest.mark.asyncio
    async def test_sync_cart_skip_invalid_items(
        self,
        cart_service,
        mock_cart_repo,
        mock_product_repo,
        sample_user_id
    ):
        """Test sync cart skips invalid items"""
        # Setup mocks - product not found
        mock_cart_repo.clear_user_cart.return_value = None
        mock_product_repo.get_with_variants.return_value = None
        mock_cart_repo.list_by_user.return_value = []
        
        # Execute
        sync_request = CartSyncRequest(
            items=[
                CartItemCreate(
                    product_id=uuid4(),  # Non-existent product
                    variant_id=None,
                    quantity=1
                )
            ]
        )
        result = await cart_service.sync_cart(sample_user_id, sync_request)
        
        # Verify - should skip invalid item and return empty cart
        assert result.total_items == 0
        mock_cart_repo.clear_user_cart.assert_called_once()


class TestClearCart:
    """Tests for clear_cart method"""
    
    @pytest.mark.asyncio
    async def test_clear_cart_success(
        self,
        cart_service,
        mock_cart_repo,
        sample_user_id
    ):
        """Test successful cart clearing"""
        # Setup mocks
        mock_cart_repo.clear_user_cart.return_value = None
        
        # Execute
        await cart_service.clear_cart(sample_user_id)
        
        # Verify
        mock_cart_repo.clear_user_cart.assert_called_once_with(sample_user_id)
